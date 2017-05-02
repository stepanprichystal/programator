
#-------------------------------------------------------------------------------------------#
# Description: Responsible for prepare layers before print as pdf
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::FinalPreview::OutputPrepare;

#3th party library
use threads;
use strict;
use warnings;
use PDF::API2;
use List::Util qw[max min];
use Math::Trig;
use Image::Size;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Pdf::ControlPdf::FinalPreview::Enums';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAM::UniDTM::Enums' => "DTMEnums";
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamSymbol';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::SystemCall::SystemCall';
use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';

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

	$self->{"profileLim"} = undef;    # limits of pdf step

	return $self;
}

sub PrepareLayers {
	my $self      = shift;
	my $layerList = shift;

	# get limits of step
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

	$self->__PreparePCBMAT( $layerList->GetLayerByType( Enums->Type_PCBMAT ) );
	$self->__PrepareOUTERCU( $layerList->GetLayerByType( Enums->Type_OUTERCU ) );
	$self->__PrepareOUTERSURFACE( $layerList->GetLayerByType( Enums->Type_OUTERSURFACE ) );
	$self->__PrepareGOLDFINGER( $layerList->GetLayerByType( Enums->Type_GOLDFINGER ) );
	$self->__PrepareMASK( $layerList->GetLayerByType( Enums->Type_MASK ) );
	$self->__PrepareSILK( $layerList->GetLayerByType( Enums->Type_SILK ) );
	$self->__PreparePLTDEPTHNC( $layerList->GetLayerByType( Enums->Type_PLTDEPTHNC ) );
	$self->__PrepareNPLTDEPTHNC( $layerList->GetLayerByType( Enums->Type_NPLTDEPTHNC ) );
	$self->__PreparePLTTHROUGHNC( $layerList->GetLayerByType( Enums->Type_PLTTHROUGHNC ) );
	$self->__PrepareNPLTTHROUGHNC( $layerList->GetLayerByType( Enums->Type_NPLTTHROUGHNC ) );

}

# Create layer and fill profile - simulate pcb material
sub __PreparePCBMAT {
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

# Dont do nothing and export cu layer as is
sub __PrepareOUTERCU {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layer->GetSingleLayers();

	if ( $layers[0] ) {

		my $lName = GeneralHelper->GetGUID();

		$inCAM->COM( "merge_layers", "source_layer" => $layers[0]->{"gROWname"}, "dest_layer" => $lName );

		$layer->SetOutputLayer($lName);
	}
}

# Dont do nothing and export cu layer as is
sub __PrepareOUTERSURFACE {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @layers = $layer->GetSingleLayers();

	if ( $layers[0] ) {

		my $lName = GeneralHelper->GetGUID();
		$inCAM->COM( "merge_layers", "source_layer" => $layers[0]->{"gROWname"}, "dest_layer" => $lName );

		my $mask = "m" . $layers[0]->{"gROWname"};

		# If mask exist,
		# 1) copy to help layer, 2) do negative and conturize
		if ( CamHelper->LayerExists( $inCAM, $jobId, $mask ) ) {

			my $lNameMask = GeneralHelper->GetGUID();
			$inCAM->COM( "merge_layers", "source_layer" => $mask, "dest_layer" => $lNameMask );

			CamLayer->WorkLayer( $inCAM, $lNameMask );
			CamLayer->NegativeLayerData( $inCAM, $lNameMask, $self->{"profileLim"} );
			CamLayer->Contourize( $inCAM, $lNameMask );
			$inCAM->COM( "merge_layers", "source_layer" => $lNameMask, "dest_layer" => $lName, "invert" => "yes" );
			$inCAM->COM( "delete_layer", "layer" => $lNameMask );

			#CamLayer->Contourize( $inCAM, $lName );
		}

		$layer->SetOutputLayer($lName);
	}
}

# goldfinger layer
sub __PrepareGOLDFINGER {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @layers = $layer->GetSingleLayers();

	if ( $layers[0] ) {

		my $lNameCu = GeneralHelper->GetGUID();

		my $mask = "m" . $layers[0]->{"gROWname"};

		# If mask exist,
		# 1) copy mask, where gold plating pads are placed in cu
		# 2) do negative from this mask, contourize
		# 3) copy cu layer to temp
		# 4) Merge this temp mask (negative) with tem cu
		if ( CamHelper->LayerExists( $inCAM, $jobId, $mask ) ) {

			my $lNameMask = GeneralHelper->GetGUID();

			 
			my $result = CamFilter->SelectByReferenece( $inCAM, $jobId, "touch", $mask, undef, undef, "positive", $layers[0]->{"gROWname"},
														".gold_plating", "", undef );
	 									 
			if ( $result > 0 ) {

				my @l = ($lNameMask);
				CamLayer->CopySelected( $inCAM, \@l, 0 );
				CamLayer->WorkLayer( $inCAM, $lNameMask );
				CamLayer->NegativeLayerData( $inCAM, $lNameMask, $self->{"profileLim"} );
				CamLayer->Contourize( $inCAM, $lNameMask );
				
				 

				# copy copper to temp layer
				$inCAM->COM( "merge_layers", "source_layer" => $layers[0]->{"gROWname"}, "dest_layer" => $lNameCu );

				# copy mask temp negati to cu temp
				$inCAM->COM( "merge_layers", "source_layer" => $lNameMask, "dest_layer" => $lNameCu, "invert" => "yes" );
				$inCAM->COM( "delete_layer", "layer" => $lNameMask );
				
				 
			}

		}
		else {

			$inCAM->COM( "merge_layers", "source_layer" => $layers[0]->{"gROWname"}, "dest_layer" => $lNameCu );
		}

		$layer->SetOutputLayer($lNameCu);
	}
}

# Invert solder mask
sub __PrepareMASK {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layer->GetSingleLayers();

	if ( $layers[0] ) {
		my $lName = GeneralHelper->GetGUID();

		my $maskLayer = $layers[0]->{"gROWname"};

		# Select layer as work

		CamLayer->WorkLayer( $inCAM, $maskLayer );

		$inCAM->COM( "merge_layers", "source_layer" => $maskLayer, "dest_layer" => $lName );

		CamLayer->WorkLayer( $inCAM, $lName );

		CamLayer->NegativeLayerData( $self->{"inCAM"}, $lName, $self->{"profileLim"} );

		$layer->SetOutputLayer($lName);

	}
}

# Dont do nothing and export silk as is
sub __PrepareSILK {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layer->GetSingleLayers();

	if ( $layers[0] ) {

		my $lName = GeneralHelper->GetGUID();

		$inCAM->COM( "merge_layers", "source_layer" => $layers[0]->{"gROWname"}, "dest_layer" => $lName );

		$layer->SetOutputLayer($lName);
	}
}

# Compensate this layer and resize about 100µm (plating)
sub __PreparePLTDEPTHNC {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layer->GetSingleLayers();

	my $lName = GeneralHelper->GetGUID();

	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	# compensate
	foreach my $l (@layers) {

		if ( $l->{"gROWlayer_type"} eq "rout" ) {
			CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );
			my $lComp = CamLayer->RoutCompensation( $inCAM, $l->{"gROWname"}, "document" );

			# check for special rout 6.5mm with depth
			$self->__CheckCountersink( $l, $lComp );

			$inCAM->COM( "merge_layers", "source_layer" => $lComp, "dest_layer" => $lName );
			$inCAM->COM( 'delete_layer', "layer" => $lComp );

		}
		else {

			$inCAM->COM( "merge_layers", "source_layer" => $l->{"gROWname"}, "dest_layer" => $lName );
		}

	}

	# resize
	CamLayer->WorkLayer( $inCAM, $lName );
	$inCAM->COM( "sel_resize", "size" => -100, "corner_ctl" => "no" );

	$layer->SetOutputLayer($lName);

}

# Compensate this layer and resize about 100µm (plating)
sub __PrepareNPLTDEPTHNC {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layer->GetSingleLayers();
	my $lName  = GeneralHelper->GetGUID();

	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	# compensate
	foreach my $l (@layers) {

		if ( $l->{"gROWlayer_type"} eq "rout" ) {
			CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );
			my $lComp = CamLayer->RoutCompensation( $inCAM, $l->{"gROWname"}, "document" );

			# check for special rout 6.5mm with depth
			$self->__CheckCountersink( $l, $lComp );

			$inCAM->COM( "merge_layers", "source_layer" => $lComp, "dest_layer" => $lName );
			$inCAM->COM( 'delete_layer', "layer" => $lComp );
		}
		else {

			$inCAM->COM( "merge_layers", "source_layer" => $l->{"gROWname"}, "dest_layer" => $lName );
		}
	}

	$layer->SetOutputLayer($lName);

}

# Compensate this layer and resize about 100µm (plating)
sub __PreparePLTTHROUGHNC {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layer->GetSingleLayers();
	my $lName  = GeneralHelper->GetGUID();

	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	# compensate
	foreach my $l (@layers) {

		if ( $l->{"gROWlayer_type"} eq "rout" ) {

			CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );
			my $lComp = CamLayer->RoutCompensation( $inCAM, $l->{"gROWname"}, "document" );

			$inCAM->COM( "merge_layers", "source_layer" => $lComp, "dest_layer" => $lName );

			$inCAM->COM( 'delete_layer', "layer" => $lComp );

		}
		else {

			$inCAM->COM( "merge_layers", "source_layer" => $l->{"gROWname"}, "dest_layer" => $lName );
		}

	}

	CamLayer->WorkLayer( $inCAM, $lName );
	$inCAM->COM( "sel_resize", "size" => -100, "corner_ctl" => "no" );

	$layer->SetOutputLayer($lName);

}

# Nonplated layer
sub __PrepareNPLTTHROUGHNC {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layer->GetSingleLayers();
	my $lName  = GeneralHelper->GetGUID();

	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	# compensate
	foreach my $l (@layers) {

		if ( $l->{"gROWlayer_type"} eq "rout" ) {

			CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );
			my $lComp = CamLayer->RoutCompensation( $inCAM, $l->{"gROWname"}, "document" );

			$inCAM->COM( "merge_layers", "source_layer" => $lComp, "dest_layer" => $lName );

			$inCAM->COM( 'delete_layer', "layer" => $lComp );

		}
		else {

			$inCAM->COM( "merge_layers", "source_layer" => $l->{"gROWname"}, "dest_layer" => $lName );
		}
 
		


		# There can by small remains of pcb material, which is not milled
		# We don't want see this pieces in pdf, so delete tem from layer $lName
		 
		#$inCAM->COM( "merge_layers", "source_layer" => $lName, "dest_layer" => $lTmp );
		
		
		my $unitRTM = UniRTM->new( $inCAM, $self->{"jobId"}, $self->{"pdfStep"}, $l->{"gROWname"} );
		my @outline = $unitRTM->GetOutlineChains();
		my @outFeatsId =  map {$_->{"id"}} map { $_->GetFeatures() } @outline;
		#my $f = FeatureFilter->new( $inCAM, $self->{"jobId"}, $l->{"gROWname"} );
		#$f->AddFeatureIndexes(\@outFeatsId);
		#$f->Select();
		
		CamFilter->SelectByFeatureIndexes($inCAM, $self->{"jobId"}, \@outFeatsId);
		
		
		$inCAM->COM("sel_reverse");
		my $tmpRout = GeneralHelper->GetGUID();
		$inCAM->COM(
				 "sel_copy_other",
				 "dest"         => "layer_name",
				 "target_layer" => $tmpRout,
				 "invert"       => "no"
		);
		
		my $lTmp = CamLayer->RoutCompensation( $inCAM, $tmpRout, "document" );
		$inCAM->COM( 'delete_layer', "layer" => $tmpRout );

		# 1) do negative of prepared rout layer
		CamLayer->NegativeLayerData( $inCAM, $lTmp, $self->{"profileLim"} );
		CamLayer->WorkLayer( $inCAM, $lTmp );

		# 2) Select all 'small pieces'/surfaces and copy them negative to $lName
		CamLayer->Contourize( $inCAM, $lTmp );
		CamLayer->WorkLayer( $inCAM, $lTmp );

		# Select 'surface pieces'

		my $profileArea =
		  abs( $self->{"profileLim"}->{"xMin"} - $self->{"profileLim"}->{"xMax"} ) *
		  abs( $self->{"profileLim"}->{"yMin"} - $self->{"profileLim"}->{"yMax"} );
		#my $maxArea = $profileArea / 10;
		my $maxArea = $profileArea / 2;

		if ( CamFilter->BySurfaceArea( $inCAM, 0, $maxArea ) > 0 ) {
			my @layers = ($lName);
			CamLayer->CopySelected( $inCAM, \@layers, 0, 100 );
		}

		$inCAM->COM( 'delete_layer', "layer" => $lTmp );
	}

	$layer->SetOutputLayer($lName);
}

sub __CheckCountersink {
	my $self      = shift;
	my $layer     = shift;
	my $layerComp = shift;

	if (    $layer->{"type"} ne EnumsGeneral->LAYERTYPE_plt_bMillTop
		 && $layer->{"type"} ne EnumsGeneral->LAYERTYPE_nplt_bMillTop
		 && $layer->{"type"} ne EnumsGeneral->LAYERTYPE_plt_bMillBot
		 && $layer->{"type"} ne EnumsGeneral->LAYERTYPE_nplt_bMillBot )
	{
		return 0;
	}

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $stepName = $self->{"pdfStep"};
	$stepName =~ s/pdf_//;
	my $lName = $layer->{"gROWname"};

	my $result = 1;

	#get depths for all diameter
	 
	# load UniDTM for layer
	my $unitDTM = UniDTM->new( $inCAM, $jobId, $stepName, $lName, 1 );

	 
	# 2) check if tool depth is set
	foreach my $t ($unitDTM->GetUniqueTools()){
		
		if ( $t->GetSpecial() && defined $t->GetAngle() && $t->GetAngle() > 0 ) {
			
			#vypocitej realne odebrani materialu na zaklade hloubky pojezdu/vrtani
 
			my $toolAngl = $t->GetAngle();

			my $newDiameter = tan( deg2rad( $toolAngl / 2 ) ) * $t->GetDepth();
			$newDiameter *= 2;       #whole diameter
			$newDiameter *= 1000;    #um
			$newDiameter = int($newDiameter);

			# now change old diameter to new diameter
			CamLayer->WorkLayer( $inCAM, $layerComp );
			my @syms = ("r".$t->GetDrillSize());
			CamFilter->BySymbols( $inCAM, \@syms);
			$inCAM->COM( "sel_change_sym", "symbol" => "r" . $newDiameter, "reset_angle" => "no" );
		}
	}

	return $result;
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
		"margin"      => "-2", # cut 2µm inside of pcb, because cut exactly on border can coause ilegal surfaces, in nplt mill example
		"feat_types"  => "line\;pad;surface;arc;text",
		"pol_types"   => "positive\;negative"
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
	CamSymbol->AddPolyline( $self->{"inCAM"}, \@coord, "r10", "positive" );

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

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
