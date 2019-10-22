#-------------------------------------------------------------------------------------------#
# Description: Responsible for prepare layers which contains tool depth drawing
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::PrepareLayers::PrepareNCDrawing;

#3th party library
use strict;
use warnings;
use List::Util qw[max min];
use List::MoreUtils qw(uniq);
use Math::Trig;
use Math::Geometry::Planar;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::OutputData::Enums';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAMJob::OutputData::LayerData::LayerData';
use aliased 'CamHelpers::CamFilter';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAMJob::OutputData::Drawing::Drawing';
use aliased 'Packages::CAMJob::OutputData::Helper';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Enums::EnumsDrill';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamSymbol';
use aliased 'Packages::Tooling::CountersinkHelper';
use aliased 'CamHelpers::CamSymbolArc';
use aliased 'Packages::Polygon::Polygon::PolygonAttr';

use aliased 'CamHelpers::CamSymbolSurf';
use aliased 'Packages::CAMJob::OutputParser::OutputParserNC::Enums' => 'OutEnums';

#use aliased 'Packages::SystemCall::SystemCall';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}     = shift;
	$self->{"jobId"}     = shift;
	$self->{"step"}      = shift;
	$self->{"layerList"} = shift;

	$self->{"profileLim"} = shift;    # limits of pdf step

	$self->{"outputNClayer"} = shift;

	$self->{"pcbThick"}    = CamJob->GetFinalPcbThick( $self->{"inCAM"}, $self->{"jobId"} ) / 1000;    # in mm
	$self->{"dataOutline"} = "200";                                                     # symbol def, which is used for outline

	return $self;
}

sub Prepare {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	@layers = grep {
		     $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cbMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cbMillBot
	} @layers;

	foreach my $l (@layers) {

		$self->__ProcessNClayer( $l, $type );

	}

}

# MEthod do necessary stuff for each layer by type
# like resizing, copying, change polarity, merging, ...
sub __ProcessNClayer {
	my $self = shift;
	my $l    = shift;
	my $type = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my $enTit = Helper->GetJobLayerTitle($l, $type);
	my $czTit = Helper->GetJobLayerTitle($l, $type, 1 );
	my $enInf = Helper->GetJobLayerInfo($l);
	my $czInf = Helper->GetJobLayerInfo($l, 1 );

	#my $drawingPos = Point->new( 0, abs( $self->{"profileLim"}->{"yMax"} - $self->{"profileLim"}->{"yMin"} ) + 50 );    # starts 150

	# Get if NC operation is from top/bot
	my $side = $l->{"gROWname"} =~ /c/ ? "top" : "bot";

	my $result = $self->{"outputNClayer"}->Prepare($l);

	foreach my $classRes ( $result->GetClassResults(1) ) {

		my $t = $classRes->GetType();

		$self->__ProcessLayerData( $classRes, $l, );
		$self->__ProcessDrawing( $classRes, $l, $side, $t );

		foreach my $layerRes ( $classRes->GetLayers() ) {

			my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $layerRes->GetLayerName() );
			$self->{"layerList"}->AddLayer($lData);

		}

	}
}

# Prpare layer data
sub __ProcessLayerData {
	my $self     = shift;
	my $classRes = shift;
	my $l        = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	foreach my $layerRes ( $classRes->GetLayers() ) {

		# ----------------------------------------------------------------
		# 1) adjust copied feature data. Create outlilne from each feature
		# ----------------------------------------------------------------

		if (    $classRes->GetType() eq OutEnums->Type_COUNTERSINKSURF
			 || $classRes->GetType() eq OutEnums->Type_COUNTERSINKARC )
		{
			# Parsed data from "parser class result"
			my $drawLayer = $layerRes->GetLayerName();
			my @chains    = @{ $layerRes->GetDataVal("chainSeq") };

			my $radiusReal = $layerRes->GetDataVal("radiusReal");

			#my $lName    = $l->{"gROWname"};

			CamLayer->WorkLayer( $inCAM, $drawLayer );
			CamLayer->DeleteFeatures($inCAM);

			foreach my $chainS (@chains) {

				my $centerX = undef;
				my $centerY = undef;

				if ( $classRes->GetType() eq OutEnums->Type_COUNTERSINKARC ) {

					# get centr point of chain
					$centerX = ( $chainS->GetOriFeatures() )[0]->{"xmid"};
					$centerY = ( $chainS->GetOriFeatures() )[0]->{"ymid"};

				}
				elsif ( $classRes->GetType() eq OutEnums->Type_COUNTERSINKSURF ) {

					my $surf = ( $chainS->GetOriFeatures() )[0];
					PolygonAttr->AddSurfAtt($surf);
					$centerX = $surf->{"surfaces"}->[0]->{"xmid"};
					$centerY = $surf->{"surfaces"}->[0]->{"ymid"};
				}

				#CamSymbolSurf->SurfaceLinePattern( $inCAM, 0, 1, $self->{"dataOutline"}, 45, 0, 20, 1000, 1 );

				#CamSymbolSurf->AddSurfaceCircle( $inCAM, $radiusReal, { "x" => $centerX, "y" => $centerY }, 1);

				CamSymbolArc->AddCircleRadiusCenter( $inCAM, $radiusReal, { "x" => $centerX, "y" => $centerY }, undef, "r" . $self->{"dataOutline"} );
			}

		}
		elsif (    $classRes->GetType() eq OutEnums->Type_COUNTERSINKPAD
				|| $classRes->GetType() eq OutEnums->Type_ZAXISPAD )
		{

			# Parsed data from "parser class result"
			my $drawLayer  = $layerRes->GetLayerName();
			my @pads       = @{ $layerRes->GetDataVal("padFeatures") };
			my $radiusReal = undef;

			if ( $classRes->GetType() eq OutEnums->Type_COUNTERSINKPAD ) {

				$radiusReal = $layerRes->GetDataVal("radiusReal");

			}
			elsif ( $classRes->GetType() eq OutEnums->Type_ZAXISPAD ) {

				$radiusReal = $layerRes->GetDataVal("radiusReal");
			}

			# 1) adjust copied feature data. Create outlilne from each feature
			CamLayer->WorkLayer( $inCAM, $drawLayer );
			CamLayer->DeleteFeatures($inCAM);

			foreach my $pad (@pads) {

				CamSymbolArc->AddCircleRadiusCenter( $inCAM, $radiusReal, { "x" => $pad->{"x1"}, "y" => $pad->{"y1"} },
													 undef, "r" . $self->{"dataOutline"} );
			}
		}
		elsif (    $classRes->GetType() eq OutEnums->Type_ZAXISSLOTCHAMFER
				|| $classRes->GetType() eq OutEnums->Type_ZAXISSURFCHAMFER )
		{

			# Parsed data from "parser class result"
			my $drawLayer  = $layerRes->GetLayerName();
			my $radiusReal = $layerRes->GetDataVal("radiusReal");

			# Resize tool diameter by real material removal
			my $DTMTool     = $layerRes->GetDataVal("DTMTool");
			my $newDiameter = tan( deg2rad( $DTMTool->GetAngle() / 2 ) ) * $DTMTool->GetDepth() * 2;
			my $resizeFeats = ( $layerRes->GetDataVal("DTMTool")->GetDrillSize() - $newDiameter * 1000 );

			CamLayer->WorkLayer( $inCAM, $drawLayer );
			CamLayer->Contourize( $inCAM, $drawLayer, "area", "25000" );
			CamLayer->WorkLayer( $inCAM, $drawLayer );
			CamLayer->ResizeFeatures( $inCAM, -$resizeFeats );

			# Adjust copied feature data. Create outlilne from each feature
			$inCAM->COM( "sel_feat2outline", "width" => $self->{"dataOutline"}, "location" => "on_edge" );

		}
		elsif (    $classRes->GetType() eq OutEnums->Type_ZAXISSURF
				|| $classRes->GetType() eq OutEnums->Type_ZAXISSLOT )
		{

			# Parsed data from "parser class result"
			my $drawLayer  = $layerRes->GetLayerName();
			my $radiusReal = $layerRes->GetDataVal("radiusReal");

			# Adjust copied feature data. Create outlilne from each feature
			CamLayer->WorkLayer( $inCAM, $drawLayer );
			CamLayer->Contourize( $inCAM, $drawLayer ); # onlz counourize, no fill empty places

			CamLayer->WorkLayer( $inCAM, $drawLayer );

			#CamSymbolSurf->SetSurfaceLinePattern( $inCAM, 1, $self->{"dataOutline"}, 45, 0, 20, 1000, 1 );

			$inCAM->COM( "sel_feat2outline", "width" => $self->{"dataOutline"}, "location" => "on_edge" );

		}

	}
}

# Prepare image
sub __ProcessDrawing {
	my $self     = shift;
	my $classRes = shift;
	my $l        = shift;
	my $side     = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	foreach my $layerRes ( $classRes->GetLayers() ) {

		# ----------------------------------------------------------------
		# 2) Create countersink drawing
		# ----------------------------------------------------------------
		my $lTmp = GeneralHelper->GetGUID();
		$inCAM->COM( 'create_layer', layer => $lTmp );

		my $draw = Drawing->new( $inCAM, $jobId, $lTmp, Point->new( 0, 0 ), $self->{"pcbThick"}, $side, $l->{"plated"} );

		if (    $classRes->GetType() eq OutEnums->Type_COUNTERSINKSURF
			 || $classRes->GetType() eq OutEnums->Type_COUNTERSINKARC )
		{

			# Compute depth of "imagine drill tool"
			# If countersink is done by surface, edge of drill tool goes around according "surface border"
			# Image for this case will show "image tool", where center of tool is same as center of surface, thus "image tool"
			# not go around surface bordr but just like normal drill tool, which drill hole

			my @chains = @{ $layerRes->GetDataVal("chainSeq") };

			#$toolDepth    = $chains[0]->GetChain()->GetChainTool()->GetUniDTMTool()->GetDepth();    # angle of tool
			my $imgToolAngle = $chains[0]->GetChain()->GetChainTool()->GetUniDTMTool()->GetAngle();               # angle of tool
			my $imgToolDepth = cotan( deg2rad( ( $imgToolAngle / 2 ) ) ) * $layerRes->GetDataVal("radiusReal");

			$draw->CreateDetailCountersink( $layerRes->GetDataVal("radiusReal"),
											$imgToolDepth, $layerRes->GetDataVal("exceededDepth"),
											$imgToolAngle, "hole" );

		}
		elsif ( $classRes->GetType() eq OutEnums->Type_COUNTERSINKPAD ) {

			# Compute depth of "imagine drill tool"
			# If countersink is done by surface, edge of drill tool goes around according "surface border"
			# Image for this case will show "image tool", where center of tool is same as center of surface, thus "image tool"
			# not go around surface bordr but just like normal drill tool, which drill hole
			my $dtmTool = $layerRes->GetDataVal("DTMTool");

			#$toolDepth    = $dtmTool->GetDepth();                                                   # angle of tool
			my $imgToolAngle = $dtmTool->GetAngle();    # angle of tool

			my $imgToolDepth = cotan( deg2rad( ( $imgToolAngle / 2 ) ) ) * $layerRes->GetDataVal("radiusReal");

			#			if ( $l->{"plated"} ) {
			#				$imgToolDepth -= OutEnums->Plating_THICKMM;
			#			}

			$draw->CreateDetailCountersink( $layerRes->GetDataVal("radiusReal"),
											$imgToolDepth, $layerRes->GetDataVal("exceededDepth"),
											$imgToolAngle, "hole" );

		}
		elsif (    $classRes->GetType() eq OutEnums->Type_ZAXISSLOTCHAMFER
				|| $classRes->GetType() eq OutEnums->Type_ZAXISSURFCHAMFER )
		{

			my @chains = @{ $layerRes->GetDataVal("chainSeq") };

			my $imgToolAngle = $chains[0]->GetChain()->GetChainTool()->GetUniDTMTool()->GetAngle();               # angle of tool
			my $imgToolDepth = cotan( deg2rad( ( $imgToolAngle / 2 ) ) ) * $layerRes->GetDataVal("radiusReal");

			#			if ( $l->{"plated"} ) {
			#				$imgToolDepth -= OutEnums->Plating_THICKMM;
			#			}

			$draw->CreateDetailCountersink( $layerRes->GetDataVal("radiusReal"),
											$imgToolDepth, $layerRes->GetDataVal("exceededDepth"),
											$imgToolAngle, "slot" );

		}
		elsif (    $classRes->GetType() eq OutEnums->Type_ZAXISSLOT
				|| $classRes->GetType() eq OutEnums->Type_ZAXISPAD )
		{

			my $dtmTool = $layerRes->GetDataVal("DTMTool");

			my $imgToolDepth = $dtmTool->GetDepth();    # depth of tool

			if ( $l->{"plated"} ) {
				$imgToolDepth -= OutEnums->Plating_THICKMM;
			}

			if ( $classRes->GetType() eq OutEnums->Type_ZAXISSLOT ) {

				$draw->CreateDetailZaxis( $layerRes->GetDataVal("radiusReal"), $imgToolDepth, "slot" );

			}
			elsif ( $classRes->GetType() eq OutEnums->Type_ZAXISPAD ) {

				$draw->CreateDetailZaxis( $layerRes->GetDataVal("radiusReal"), $imgToolDepth, "hole" );
			}

		}
		elsif ( $classRes->GetType() eq OutEnums->Type_ZAXISSURF ) {

			my $dtmTool = $layerRes->GetDataVal("DTMTool");

			my $imgToolDepth = $dtmTool->GetDepth();    # depth of tool

			if ( $l->{"plated"} ) {
				$imgToolDepth -= OutEnums->Plating_THICKMM;
			}

			$draw->CreateDetailZaxisSurf($imgToolDepth);

		}

		# get limits of drawing and place it above layer data
		CamLayer->WorkLayer( $inCAM, $lTmp );
		my %lim = CamJob->GetLayerLimits2( $inCAM, $jobId, $step, $lTmp );

		$inCAM->COM( "sel_move", "dx" => 0, "dy" => $self->{"profileLim"}->{"yMax"} - $lim{"yMin"} + 10 );    # drawing 10 mm above profile data

		CamLayer->WorkLayer( $inCAM, $lTmp );
		CamLayer->CopySelOtherLayer( $inCAM, [ $layerRes->GetLayerName() ] );
		CamMatrix->DeleteLayer( $inCAM, $jobId, $lTmp );

	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
