
#-------------------------------------------------------------------------------------------#
# Description: Responsible for prepare layers before print as pdf
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::StencilControlPdf::FinalPreview::OutputPrepare;

#3th party library
use threads;
use strict;
use warnings;
use PDF::API2;
use List::Util qw[max min];
use List::MoreUtils qw(uniq);
use Math::Trig;
use Image::Size;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Pdf::ControlPdf::StencilControlPdf::FinalPreview::Enums';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamSymbolSurf';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAMJob::OutputData::Helper';
use aliased 'Programs::Stencil::StencilSerializer::StencilSerializer';
use aliased 'Programs::Stencil::StencilCreator::Enums' => 'StnclEnums';
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::CAM::SymbolDrawing::SymbolLib::DimV1In';
use aliased 'Packages::CAM::SymbolDrawing::SymbolLib::DimH1Lines';
use aliased 'Packages::CAM::SymbolDrawing::Point';

use aliased 'Packages::Polygon::Features::Features::Features';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"viewType"} = shift;
	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"pdfStep"}  = shift;

	$self->{"profileLim"} = undef;    # limts of pdf step

	# Load deserialiyed stencil parameters
	my $ser = StencilSerializer->new( $self->{"jobId"} );
	$self->{"params"} = $ser->LoadStenciLParams();

	# If only bot stencil, whole psb will be mirrored
	$self->{"mirror"} = $self->{"params"}->GetStencilType() eq StnclEnums->StencilType_BOT ? 1 : 0;

	# size of dimension and dim text and width of dim lines
	# when stencil is standard 480mm height
	$self->{"codeSize"}     = 6;
	$self->{"codeWidth"}    = 400;    # r400
	$self->{"codeTxtThick"} = 1.4;
	$self->{"codeTxtSize"}  = 4.4;

	return $self;
}

sub PrepareLayers {
	my $self      = shift;
	my $layerList = shift;

	my %lim = CamJob->GetProfileLimits2( $self->{"inCAM"}, $self->{"jobId"}, $self->{"pdfStep"}, 1 );
	$self->{"profileLim"} = \%lim;

	# prepare layers
	$self->__PrepareLayers($layerList);
	$self->__OptimizeLayers($layerList);

}

# MEthod do necessary stuff for each layer by type
# like resizing, copying, change polarity, merging, ...
sub __PrepareLayers {
	my $self      = shift;
	my $layerList = shift;

	# recompute code parameters by stencil height (default settings is for 480 mm height)
	my $h = abs( $self->{"profileLim"}->{"yMax"} - $self->{"profileLim"}->{"yMin"} );
	my $w = abs( $self->{"profileLim"}->{"yMax"} - $self->{"profileLim"}->{"yMin"} );

	$self->{"ratio"} = max( $h, $w ) / 480;

	$self->{"codeSize"} *= $self->{"ratio"};
	$self->{"codeWidth"} = "r" . int( $self->{"codeWidth"} * $self->{"ratio"} );
	$self->{"codeTxtThick"} *= $self->{"ratio"};
	$self->{"codeTxtSize"}  *= $self->{"ratio"};

	$self->__PrepareSTNCLMAT( $layerList->GetLayerByType( Enums->Type_STNCLMAT ) );
	$self->__PrepareSTNCLMAT( $layerList->GetLayerByType( Enums->Type_COVER ) );
	$self->__PrepareHOLES( $layerList->GetLayerByType( Enums->Type_HOLES ) );

	$self->__PrepareCODES( $layerList->GetLayerByType( Enums->Type_CODES ) );
	$self->__PreparePROFILE( $layerList->GetLayerByType( Enums->Type_PROFILE ) );
	$self->__PrepareDATAPROFILE( $layerList->GetLayerByType( Enums->Type_DATAPROFILE ) );

	$self->__PrepareHALFFIDUC( $layerList->GetLayerByType( Enums->Type_HALFFIDUC ) );
	$self->__PrepareFIDUCPOS( $layerList->GetLayerByType( Enums->Type_FIDUCPOS ) );

	# if stencil is type bot, mirrro all layers
	if ( $self->{"mirror"} ) {
		foreach my $outputL ( map { $_->GetOutputLayer() } $layerList->GetLayers() ) {

			CamLayer->WorkLayer( $self->{"inCAM"}, $outputL );

			my $w = abs( $self->{"profileLim"}->{"xMax"} - $self->{"profileLim"}->{"xMin"} );
			my $h = abs( $self->{"profileLim"}->{"yMax"} - $self->{"profileLim"}->{"yMin"} );
			$self->{"inCAM"}->COM( "sel_transform", "x_anchor" => $w / 2, "y_anchor" => $h / 2, "oper" => "mirror", "mode" => "anchor" );
		}
	}
}

# Create layer and fill profile - simulate pcb material
sub __PrepareSTNCLMAT {
	my $self  = shift;
	my $layer = shift;

	my $inCAM = $self->{"inCAM"};

	my $lName = GeneralHelper->GetGUID();
	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	$inCAM->COM(
				 "sr_fill",
				 "type"          => "solid",
				 "solid_type"    => "surface",
				 "min_brush"     => "25.4",
				 "cut_prims"     => "no",
				 "polarity"      => "positive",
				 "consider_rout" => "no",
				 "dest"          => "layer_name",
				 "layer"         => $lName,
				 "stop_at_steps" => ""
	);

	$layer->SetOutputLayer($lName);
}

# Create layer and fill profile - simulate pcb material
sub __PrepareCOVER {
	my $self  = shift;
	my $layer = shift;

	my $inCAM = $self->{"inCAM"};

	my $lName = GeneralHelper->GetGUID();
	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	$inCAM->COM(
				 "sr_fill",
				 "type"          => "solid",
				 "solid_type"    => "surface",
				 "min_brush"     => "25.4",
				 "cut_prims"     => "no",
				 "polarity"      => "positive",
				 "consider_rout" => "no",
				 "dest"          => "layer_name",
				 "layer"         => $lName,
				 "stop_at_steps" => ""
	);

	$layer->SetOutputLayer($lName);
}

# Nonplated layer
sub __PrepareHOLES {
	my $self  = shift;
	my $layer = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $lName = GeneralHelper->GetGUID();

	my @layers = $layer->GetSingleLayers();

	if ( $layers[0]->{"gROWlayer_type"} eq "rout" ) {
		CamLayer->WorkLayer( $inCAM, $layers[0]->{"gROWname"} );
		$lName = CamLayer->RoutCompensation( $inCAM, $layers[0]->{"gROWname"}, "document" );

	}
	else {
		$inCAM->COM( "merge_layers", "source_layer" => $layers[0]->{"gROWname"}, "dest_layer" => $lName );
	}

	# Remove fiduc marks, if exist  half lasered fiduc
	my $fiduc = $self->{"params"}->GetFiducial();
	if ( $fiduc->{"halfFiducials"} ) {

		CamLayer->WorkLayer( $inCAM, $lName );

		if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".fiducial_name", "*" ) ) {
			$inCAM->COM("sel_delete");
		}
	}

	$layer->SetOutputLayer($lName);
}

# Dont do nothing and export cu layer as is
sub __PrepareCODES {
	my $self  = shift;
	my $layer = shift;

	my $inCAM = $self->{"inCAM"};

	# New layer
	my $lName = GeneralHelper->GetGUID();
	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	CamLayer->WorkLayer( $inCAM, $lName );

	$self->__PrepareProfCODES( $layer, $lName );
	$self->__PrepareDataCODES( $layer, $lName );
	$self->__PrepareSchemaCODES( $layer, $lName );

	$layer->SetOutputLayer($lName);

}

sub __PrepareProfCODES {
	my $self  = shift;
	my $layer = shift;
	my $lName = shift;
	
	# Do not draw profile codes, if source is customer data, because pcb profile is same size as stencil size
	if ( $self->{"params"}->GetDataSource()->{"sourceType"} eq StnclEnums->StencilSource_CUSTDATA ) {
		return 0;
	}

	my $draw = SymbolDrawing->new( $self->{"inCAM"}, $self->{"jobId"} );

	my $topProf = $self->{"params"}->GetTopProfile();
	my $botProf = $self->{"params"}->GetBotProfile();

	my $area    = $self->{"params"}->GetStencilActiveArea();
	my $stenclH = $self->{"params"}->GetStencilSizeY();
	my $sType   = $self->{"params"}->GetStencilType();

	if ($topProf) {

		# dim from top edge to active area
		my $tpPos = $self->{"params"}->GetTopProfilePos();
		my $dimTopLen = sprintf( "%.1f", $stenclH - ( ( $stenclH - $area->{"h"} ) / 2 ) - ( $tpPos->{"y"} + $topProf->{"h"} ) );

		my $dimTop =
		  DimV1In->new( $self->{"codeSize"}, $dimTopLen, $self->{"codeWidth"}, "$dimTopLen mm", $self->{"codeTxtSize"}, $self->{"codeTxtThick"}, );

		$draw->AddSymbol( $dimTop, Point->new( $tpPos->{"x"}, $tpPos->{"y"} + $topProf->{"h"} ) );

		# if only top psb, draw bot dim too
		if ( !$botProf ) {

			# dim from top edge to active area
			my $dimBotLen = sprintf( "%.1f", $tpPos->{"y"} - ( ( $stenclH - $area->{"h"} ) / 2 ) );
			my $dimTop =
			  DimV1In->new( $self->{"codeSize"}, $dimBotLen, $self->{"codeWidth"}, "$dimBotLen mm", $self->{"codeTxtSize"}, $self->{"codeTxtThick"} );

			$draw->AddSymbol( $dimTop, Point->new( $tpPos->{"x"}, ( $stenclH - $area->{"h"} ) / 2 ) );
		}
	}

	if ($botProf) {

		# dim from bot edge to active area
		my $bpPos     = $self->{"params"}->GetBotProfilePos();
		my $dimBotLen = sprintf( "%.1f", $bpPos->{"y"} - ( ( $stenclH - $area->{"h"} ) / 2 ) );
		my $dimBot    = DimV1In->new( $self->{"codeSize"}, $dimBotLen, $self->{"codeWidth"},
								   "$dimBotLen mm",
								   $self->{"codeTxtSize"},
								   $self->{"codeTxtThick"},
								   $self->{"mirror"} );

		$draw->AddSymbol( $dimBot, Point->new( $bpPos->{"x"}, ( $stenclH - $area->{"h"} ) / 2 ) );

		# if only bot pcb, draw top dim too
		if ( !$topProf ) {

			# dim from top edge to active area

			my $dimTopLen = sprintf( "%.1f", $stenclH - ( ( $stenclH - $area->{"h"} ) / 2 ) - ( $bpPos->{"y"} + $botProf->{"h"} ) );
			my $dimTop = DimV1In->new( $self->{"codeSize"}, $dimTopLen, $self->{"codeWidth"},
									   "$dimTopLen mm",
									   $self->{"codeTxtSize"},
									   $self->{"codeTxtThick"},
									   $self->{"mirror"} );

			$draw->AddSymbol( $dimTop, Point->new( $bpPos->{"x"}, $bpPos->{"y"} + $botProf->{"h"} ) );
		}
	}

	if ( $topProf && $botProf ) {

		my $tpPos = $self->{"params"}->GetTopProfilePos();
		my $bpPos = $self->{"params"}->GetBotProfilePos();

		# draw dim between pcbs
		my $dimLen = sprintf( "%.1f", $tpPos->{"y"} - ( $bpPos->{"y"} + $botProf->{"h"} ) );
		my $dimTop = DimV1In->new( $self->{"codeSize"}, $dimLen, $self->{"codeWidth"}, "$dimLen mm",
								   $self->{"codeTxtSize"},
								   $self->{"codeTxtThick"},
								   $self->{"mirror"} );

		$draw->AddSymbol( $dimTop, Point->new( $bpPos->{"x"}, ( $bpPos->{"y"} + $botProf->{"h"} ) ) );
	}

	$draw->Draw();

}

sub __PrepareDataCODES {
	my $self  = shift;
	my $layer = shift;
	my $lName = shift;
	
	# Do not draw profiles, if source is customer data, because pcb profile is same size as stencil size
	if ( $self->{"params"}->GetDataSource()->{"sourceType"} eq StnclEnums->StencilSource_CUSTDATA ) {
		return 0;
	}

	my $draw = SymbolDrawing->new( $self->{"inCAM"}, $self->{"jobId"} );

	my $topProf = $self->{"params"}->GetTopProfile();
	my $botProf = $self->{"params"}->GetBotProfile();

	my $area    = $self->{"params"}->GetStencilActiveArea();
	my $stenclH = $self->{"params"}->GetStencilSizeY();
	my $sType   = $self->{"params"}->GetStencilType();

	if ($topProf) {

		# dim from top edge of data to active area

		my $tpPos  = $self->{"params"}->GetTopProfilePos();
		my $tdData = $topProf->{"pasteData"};
		my $posX   = $tpPos->{"x"} + $topProf->{"pasteDataPos"}->{"x"};
		my $posY   = $tpPos->{"y"} + $topProf->{"pasteDataPos"}->{"y"};

		my $dimTopLen = sprintf( "%.1f", $stenclH - ( ( $stenclH - $area->{"h"} ) / 2 ) - ( $posY + $tdData->{"h"} ) );
		my $dimTop =
		  DimV1In->new( $self->{"codeSize"}, $dimTopLen, $self->{"codeWidth"}, "$dimTopLen mm", $self->{"codeTxtSize"}, $self->{"codeTxtThick"} );

		$draw->AddSymbol( $dimTop, Point->new( $posX + ( $tdData->{"w"} / 2 ), $posY + $tdData->{"h"} ) );

		# if only top psb, draw bot dim too
		if ( !$botProf ) {

			# dim from top edge to active area
			my $dimBotLen = sprintf( "%.1f", $posY - ( ( $stenclH - $area->{"h"} ) / 2 ) );
			my $dimTop =
			  DimV1In->new( $self->{"codeSize"}, $dimBotLen, $self->{"codeWidth"}, "$dimBotLen mm", $self->{"codeTxtSize"}, $self->{"codeTxtThick"} );

			$draw->AddSymbol( $dimTop, Point->new( $posX + ( $tdData->{"w"} / 2 ), ( $stenclH - $area->{"h"} ) / 2 ) );
		}
	}

	if ($botProf) {

		# dim from bot edge of data to active area
		my $bpPos  = $self->{"params"}->GetBotProfilePos();
		my $bdData = $botProf->{"pasteData"};
		my $posX   = $bpPos->{"x"} + $botProf->{"pasteDataPos"}->{"x"};
		my $posY   = $bpPos->{"y"} + $botProf->{"pasteDataPos"}->{"y"};

		my $dimBotLen = sprintf( "%.1f", $posY - ( ( $stenclH - $area->{"h"} ) / 2 ) );
		my $dimBot = DimV1In->new( $self->{"codeSize"}, $dimBotLen, $self->{"codeWidth"},
								   "$dimBotLen mm",
								   $self->{"codeTxtSize"},
								   $self->{"codeTxtThick"},
								   $self->{"mirror"} );

		$draw->AddSymbol( $dimBot, Point->new( $posX + ( $bdData->{"w"} / 2 ), ( $stenclH - $area->{"h"} ) / 2 ) );

		# if only bot pcb, draw top dim too
		if ( !$topProf ) {

			# dim from top edge  of data  to active area

			my $dimTopLen = sprintf( "%.1f", $stenclH - ( ( $stenclH - $area->{"h"} ) / 2 ) - ( $posY + $bdData->{"h"} ) );
			my $dimTop = DimV1In->new( $self->{"codeSize"}, $dimTopLen, $self->{"codeWidth"},
									   "$dimTopLen mm",
									   $self->{"codeTxtSize"},
									   $self->{"codeTxtThick"},
									   $self->{"mirror"} );

			$draw->AddSymbol( $dimTop, Point->new( $posX + ( $bdData->{"w"} / 2 ), $posY + $bdData->{"h"} ) );
		}
	}

	if ( $topProf && $botProf ) {

		my $tpPos  = $self->{"params"}->GetTopProfilePos();
		my $bpPos  = $self->{"params"}->GetBotProfilePos();
		my $bdData = $botProf->{"pasteData"};
		my $tdPosY = $tpPos->{"y"} + $topProf->{"pasteDataPos"}->{"y"};
		my $bdPosY = $bpPos->{"y"} + $botProf->{"pasteDataPos"}->{"y"};
		my $bdposX = $bpPos->{"x"} + $botProf->{"pasteDataPos"}->{"x"};

		# draw dim between pcbs
		my $dimLen = sprintf( "%.1f", $tdPosY - ( $bdPosY + $bdData->{"h"} ) );
		my $dimTop = DimV1In->new( $self->{"codeSize"}, $dimLen, $self->{"codeWidth"}, "$dimLen mm",
								   $self->{"codeTxtSize"},
								   $self->{"codeTxtThick"},
								   $self->{"mirror"} );

		$draw->AddSymbol( $dimTop, Point->new( $bdposX + ( $bdData->{"w"} / 2 ), $bdPosY + $bdData->{"h"} ) );
	}

	$draw->Draw();

}

sub __PrepareSchemaCODES {
	my $self  = shift;
	my $layer = shift;
	my $lName = shift;

	my $draw = SymbolDrawing->new( $self->{"inCAM"}, $self->{"jobId"} );

	my $schema = $self->{"params"}->GetSchema();
	my $area   = $self->{"params"}->GetStencilActiveArea();

	# Holes diension, distance
	if ( $schema->{"type"} eq StnclEnums->Schema_STANDARD ) {

		my @allHoles = @{ $self->{"params"}->GetSchema()->{"holePositions"} };
		my @holesX   = sort { $a <=> $b } uniq( map { $_->{"x"} } @allHoles );
		my $holeDist = abs( $holesX[0] - $holesX[1] );

		# Add horizontal distance between holes
		my $disHole = DimH1Lines->new( "top", $self->{"mirror"} ? "left" : "right",
									   15, $self->{"codeSize"}, $holeDist, $holeDist, "both", $self->{"codeWidth"}, "$holeDist mm",
									   $self->{"codeTxtSize"},
									   $self->{"codeTxtThick"},
									   $self->{"mirror"} );

		my @holesY = sort { $a <=> $b } uniq( map { $_->{"y"} } @allHoles );
		my $holePosX = int( scalar(@holesX) * 4 / 6 );    # position of hole placed in 2/3 width of stencil

		$draw->AddSymbol( $disHole, Point->new( $holesX[$holePosX], $holesY[0] ) );

		# Add vertical distance between holes

		my $dis2Hole = DimV1In->new( $self->{"codeSize"}, sprintf( "%.1f", $area->{"h"} ),
									 $self->{"codeWidth"},
									 $area->{"h"} . " mm",
									 $self->{"codeTxtSize"},
									 $self->{"codeTxtThick"},
									 $self->{"mirror"} );

		$draw->AddSymbol( $dis2Hole, Point->new( $self->{"mirror"} ? $holesX[ scalar(@holesX) - 2 ] : $holesX[1], $holesY[0] ) );

		# Add size of hole
		my $d = $schema->{"holeSize"};
		my $dHole = DimH1Lines->new( "bot", $self->{"mirror"} ? "left" : "right",
									 15, $self->{"codeSize"}, $d, $holeDist, "both", $self->{"codeWidth"}, "D$d mm",
									 $self->{"codeTxtSize"},
									 $self->{"codeTxtThick"},
									 $self->{"mirror"} );

		$draw->AddSymbol( $dHole, Point->new( $holesX[$holePosX] - $d / 2 + ( $self->{"mirror"} ? $d : 0 ), $holesY[ scalar(@holesY) - 1 ] ) );

	}

	# Active area limit
	if ( $schema->{"type"} eq StnclEnums->Schema_STANDARD || $schema->{"type"} eq StnclEnums->Schema_FRAME ) {

		# Draw top and bottom limit lines

		my $h = $self->{"params"}->GetStencilSizeY();
		my $w = $self->{"params"}->GetStencilSizeX();

		# top

		my $p1Top = { "x" => 0, "y" => $h - ( $h - $area->{"h"} ) / 2 };
		my $p2Top = { "x" => $w, "y" => $h - ( $h - $area->{"h"} ) / 2 };
		$self->__DrawDashedLine( "r300", 4, 3, $p1Top, $p2Top );

		# bot

		my $p1Bot = { "x" => 0, "y" => ( $h - $area->{"h"} ) / 2 };
		my $p2Bot = { "x" => $w, "y" => ( $h - $area->{"h"} ) / 2 };
		$self->__DrawDashedLine( "r300", 4, 3, $p1Bot, $p2Bot );

	}
	$draw->Draw();

}

# Dont do nothing and export cu layer as is
sub __PreparePROFILE {
	my $self  = shift;
	my $layer = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $schema = $self->{"params"}->GetSchema();

	# Do not draw profiles, if source is customer data, because pcb profile is same size as stencil size
	if ( $self->{"params"}->GetDataSource()->{"sourceType"} eq StnclEnums->StencilSource_CUSTDATA ) {
		return 0;
	}
	# New layer
	my $lName = GeneralHelper->GetGUID();
	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	CamLayer->WorkLayer( $inCAM, $lName );

	my $topProfile = $self->{"params"}->GetTopProfile();
	my $botProfile = $self->{"params"}->GetBotProfile();

	if ($topProfile) {

		my $tpPos = $self->{"params"}->GetTopProfilePos();
		my @coord = ();

		push( @coord, { "x" => $tpPos->{"x"},                      "y" => $tpPos->{"y"} } );                         #p1
		push( @coord, { "x" => $tpPos->{"x"},                      "y" => $tpPos->{"y"} + $topProfile->{"h"} } );    #p2
		push( @coord, { "x" => $tpPos->{"x"} + $topProfile->{"w"}, "y" => $tpPos->{"y"} + $topProfile->{"h"} } );    #p3
		push( @coord, { "x" => $tpPos->{"x"} + $topProfile->{"w"}, "y" => $tpPos->{"y"} } );                         #p4

		$self->__DrawDashedRect( 600 * $self->{"ratio"}, 6000 * $self->{"ratio"}, \@coord );
	}

	if ($botProfile) {

		my $bpPos = $self->{"params"}->GetBotProfilePos();
		my @coord = ();

		push( @coord, { "x" => $bpPos->{"x"},                      "y" => $bpPos->{"y"} } );                         #p1
		push( @coord, { "x" => $bpPos->{"x"},                      "y" => $bpPos->{"y"} + $botProfile->{"h"} } );    #p2
		push( @coord, { "x" => $bpPos->{"x"} + $botProfile->{"w"}, "y" => $bpPos->{"y"} + $botProfile->{"h"} } );    #p3
		push( @coord, { "x" => $bpPos->{"x"} + $botProfile->{"w"}, "y" => $bpPos->{"y"} } );                         #p4

		$self->__DrawDashedRect( 600 * $self->{"ratio"}, 6000 * $self->{"ratio"}, \@coord );
	}

	$layer->SetOutputLayer($lName);

}

# Dont do nothing and export cu layer as is
sub __PrepareDATAPROFILE {
	my $self  = shift;
	my $layer = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $schema = $self->{"params"}->GetSchema();

	# Do not draw profiles, if source is customer data, because pcb profile is same size as stencil size
	if ( $self->{"params"}->GetDataSource()->{"sourceType"} eq StnclEnums->StencilSource_CUSTDATA ) {
		return 0;
	}

	# New layer
	my $lName = GeneralHelper->GetGUID();
	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	CamLayer->WorkLayer( $inCAM, $lName );

	my $topProf = $self->{"params"}->GetTopProfile();
	my $botProf = $self->{"params"}->GetBotProfile();

	if ($topProf) {

		my $tpPos  = $self->{"params"}->GetTopProfilePos();
		my $tdData = $topProf->{"pasteData"};
		my $posX   = $tpPos->{"x"} + $topProf->{"pasteDataPos"}->{"x"};
		my $posY   = $tpPos->{"y"} + $topProf->{"pasteDataPos"}->{"y"};

		my @coord = ();

		push( @coord, { "x" => $posX,                  "y" => $posY } );                     #p1
		push( @coord, { "x" => $posX,                  "y" => $posY + $tdData->{"h"} } );    #p2
		push( @coord, { "x" => $posX + $tdData->{"w"}, "y" => $posY + $tdData->{"h"} } );    #p3
		push( @coord, { "x" => $posX + $tdData->{"w"}, "y" => $posY } );                     #p4

		$self->__DrawDashedRect( 200 * $self->{"ratio"}, 2000 * $self->{"ratio"}, \@coord );
	}

	if ($botProf) {

		my $bpPos  = $self->{"params"}->GetBotProfilePos();
		my $tdData = $botProf->{"pasteData"};
		my $posX   = $bpPos->{"x"} + $botProf->{"pasteDataPos"}->{"x"};
		my $posY   = $bpPos->{"y"} + $botProf->{"pasteDataPos"}->{"y"};

		my @coord = ();

		push( @coord, { "x" => $posX,                  "y" => $posY } );                     #p1
		push( @coord, { "x" => $posX,                  "y" => $posY + $tdData->{"h"} } );    #p2
		push( @coord, { "x" => $posX + $tdData->{"w"}, "y" => $posY + $tdData->{"h"} } );    #p3
		push( @coord, { "x" => $posX + $tdData->{"w"}, "y" => $posY } );                     #p4

		$self->__DrawDashedRect( 200 * $self->{"ratio"}, 2000 * $self->{"ratio"}, \@coord );
	}

	$layer->SetOutputLayer($lName);
}

# goldfinger layer
sub __PrepareHALFFIDUC {
	my $self  = shift;
	my $layer = shift;

	my $fiduc = $self->{"params"}->GetFiducial();
	unless ( $fiduc->{"halfFiducials"} && $fiduc->{"fiducSide"} eq "readable" ) {
		return 0;
	}

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @layers = $layer->GetSingleLayers();

	my $lName = GeneralHelper->GetGUID();

	CamLayer->WorkLayer( $inCAM, $layers[0]->{"gROWname"} );
	if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".fiducial_name", "*" ) ) {

		CamLayer->CopySelected( $inCAM, [$lName] );
		$layer->SetOutputLayer($lName);
	}
}

sub __PrepareFIDUCPOS {
	my $self  = shift;
	my $layer = shift;

	my $fiduc = $self->{"params"}->GetFiducial();
	unless ( $fiduc->{"halfFiducials"} ) {
		return 0;
	}

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @layers = $layer->GetSingleLayers();

	my $lName = GeneralHelper->GetGUID();
	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	# get positions of fiducials

	CamLayer->WorkLayer( $inCAM, $layers[0]->{"gROWname"} );
	if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".fiducial_name", "*" ) ) {

		my $f = Features->new();
		$f->Parse( $inCAM, $jobId, $self->{"pdfStep"}, $layers[0]->{"gROWname"}, 0, 1 );

		my @features = $f->GetFeatures();

		CamLayer->WorkLayer( $inCAM, $lName );

		foreach my $f (@features) {

			CamSymbol->AddPad( $inCAM, "donut_rc8000x8000x1000", { "x" => $f->{"x1"}, "y" => $f->{"y1"} } );
		}

	}
	else {
		die "No fiducial mark found.";
	}

	$layer->SetOutputLayer($lName);
}

# Clip area arpound profile
# Create border around pcb which is responsible for keep all layer dimension same
# border is 5mm behind profile
# if preview is bot, mirror data
sub __OptimizeLayers {
	my $self      = shift;
	my $layerList = shift;

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layerList->GetLayers(1);

	# 1) Clip area behind profile

	CamLayer->ClearLayers($inCAM);

	foreach my $l (@layers) {

		$inCAM->COM( "affected_layer", "name" => $l->GetOutputLayer(), "mode" => "single", "affected" => "yes" );
	}

	# clip area around profile
	$inCAM->COM(
		"clip_area_end",
		"layers_mode" => "affected_layers",
		"layer"       => "",
		"area"        => "profile",

		#"area_type"   => "rectangle",
		"inout"       => "outside",
		"contour_cut" => "yes",
		"margin"      => "-2",        # cut 2µm inside of pcb, because cut exactly on border can coause ilegal surfaces, in nplt mill example
		"feat_types" => "line\;pad;surface;arc;text",
		"pol_types"  => "positive\;negative"
	);
	$inCAM->COM( "affected_layer", "mode" => "all", "affected" => "no" );

	# 2) Create frame 5mm behind profile. Frame define border of layer data

	my $lName = GeneralHelper->GetGUID();
	$inCAM->COM( 'create_layer', "layer" => $lName, "context" => 'misc', "type" => 'document', "polarity" => 'positive', "ins_layer" => '' );
	CamLayer->WorkLayer( $inCAM, $lName );

	# frame width 2mm
	my $frame = 4;

	my @coord = ();

	my %p1 = ( "x" => $self->{"profileLim"}->{"xMin"} - $frame, "y" => $self->{"profileLim"}->{"yMin"} - $frame );
	my %p2 = ( "x" => $self->{"profileLim"}->{"xMin"} - $frame, "y" => $self->{"profileLim"}->{"yMax"} + $frame );
	my %p3 = ( "x" => $self->{"profileLim"}->{"xMax"} + $frame, "y" => $self->{"profileLim"}->{"yMax"} + $frame );
	my %p4 = ( "x" => $self->{"profileLim"}->{"xMax"} + $frame, "y" => $self->{"profileLim"}->{"yMin"} - $frame );
	push( @coord, \%p1 );
	push( @coord, \%p2 );
	push( @coord, \%p3 );
	push( @coord, \%p4 );

	# frame 100µm width around pcb (fr frame coordinate)
	CamSymbol->AddPolyline( $self->{"inCAM"}, \@coord, "r10", "positive", 1 );

	# copy border to all output layers

	my @layerStr = map { $_->GetOutputLayer() } @layers;
	my $layerStr = join( "\\;", @layerStr );
	$inCAM->COM(
		"sel_copy_other",
		"dest"         => "layer_name",
		"target_layer" => $layerStr,
		"invert"       => "no"

	);

	$inCAM->COM( 'delete_layer', "layer" => $lName );
	CamLayer->ClearLayers($inCAM);

	# if preview from BOT mirror all layers
	if ( $self->{"viewType"} eq Enums->View_FROMBOT ) {

		my $rotateBy = undef;

		my %lim = %{ $self->{"profileLim"} };

		my $x = abs( $lim{"xMax"} - $lim{"xMin"} );
		my $y = abs( $lim{"yMax"} - $lim{"yMin"} );

		if ( $x <= $y ) {

			$rotateBy = "y";
		}
		else {

			$rotateBy = "x";
		}

		foreach my $l (@layers) {

			CamLayer->WorkLayer( $inCAM, $l->GetOutputLayer() );
			CamLayer->MirrorLayerData( $inCAM, $l->GetOutputLayer(), $rotateBy );
		}
	}

}

sub __DrawDashedRect {
	my $self       = shift;
	my $outline    = shift;            #outline width
	my $segmentLen = shift;
	my @coord      = @{ shift(@_) };

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	CamSymbol->AddPolyline( $self->{"inCAM"}, \@coord, "r$outline", "positive", 1 );
	$outline = $outline * 2 / 1000;

	for ( my $i = 0 ; $i < scalar(@coord) ; $i++ ) {

		if ( $i == 0 ) {
			$coord[$i]->{"x"} -= $outline;
			$coord[$i]->{"y"} -= $outline;
		}
		elsif ( $i == 1 ) {
			$coord[$i]->{"x"} -= $outline;
			$coord[$i]->{"y"} += $outline;
		}
		elsif ( $i == 2 ) {
			$coord[$i]->{"x"} += $outline;
			$coord[$i]->{"y"} += $outline;
		}
		elsif ( $i == 3 ) {
			$coord[$i]->{"x"} += $outline;
			$coord[$i]->{"y"} -= $outline;
		}
	}

	CamSymbolSurf->AddSurfaceLinePattern( $inCAM, undef, undef, 45, 0, $segmentLen * 0.75, $segmentLen );
	CamSymbolSurf->AddSurfacePolyline( $inCAM, \@coord, 1, "negative" );

}

# only strictly horizontal line from left to right

sub __DrawDashedLine {
	my $self       = shift;
	my $lineWidth  = shift;    #outline width
	my $segmentLen = shift;
	my $gapLen     = shift;
	my $p1         = shift;
	my $p2         = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $lineLen = abs( $p1->{"x"} - $p2->{"x"} );
	my $curX    = $p1->{"x"};

	my $curLen = 0;

	while ( ( $curLen + ( $segmentLen + $gapLen ) ) < $lineLen ) {

		CamSymbol->AddLine( $inCAM, { "x" => $curX, "y" => $p1->{"y"} }, { "x" => $curX + $segmentLen, "y" => $p1->{"y"} }, $lineWidth );

		$curX   += ( $segmentLen + $gapLen );
		$curLen += ( $segmentLen + $gapLen );
	}

	# add last segment
	CamSymbol->AddLine( $inCAM, { "x" => $curX, "y" => $p1->{"y"} }, { "x" => $curX + $segmentLen, "y" => $p1->{"y"} }, $lineWidth );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
