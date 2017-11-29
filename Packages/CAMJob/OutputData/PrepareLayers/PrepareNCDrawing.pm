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
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAMJob::OutputData::LayerData::LayerData';
use aliased 'Helpers::ValueConvertor';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamDTM';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';
use aliased 'Packages::CAM::UniDTM::Enums' => "DTMEnums";
use aliased 'Packages::CAM::UniRTM::Enums' => "RTMEnums";
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAMJob::OutputData::Drawing::Drawing';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Enums::EnumsDrill';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamSymbol';
use aliased 'Packages::Tooling::CountersinkHelper';
use aliased 'CamHelpers::CamSymbolArc';
use aliased 'Packages::Polygon::Polygon::PolygonAttr';
use aliased 'Packages::CAMJob::OutputData::OutputLayer::OutputNCLayer';
use aliased 'Packages::CAMJob::OutputData::OutputLayer::Enums' => 'OutEnums';
use aliased 'CamHelpers::CamSymbolSurf';

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

	$self->{"platingThick"} = 0.05;   # plating constant is 50µm thick of Cu

	$self->{"pcbThick"}    = JobHelper->GetFinalPcbThick( $self->{"jobId"} ) / 1000;    # in mm
	$self->{"dataOutline"} = "200";                                                     # symbol def, which is used for outline

	$self->{"outputNClayer"} = OutputNCLayer->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );

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
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillBot
	} @layers;

	foreach my $l (@layers) {

		#		# load UniDTM for layer
		#		$l->{"uniDTM"} = UniDTM->new( $inCAM, $jobId, $step, $l->{"gROWname"}, 1 );
		#
		#		# check if depths are ok
		#		my $mess = "";
		#		unless ( $l->{"uniDTM"}->GetChecks()->CheckToolDepthSet( \$mess ) ) {
		#			die $mess;
		#		}
		#
		#		$l->{"uniRTM"} = UniRTM->new( $inCAM, $jobId, $step, $l->{"gROWname"}, 1, $l->{"uniDTM"} );

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

	my $enTit = ValueConvertor->GetJobLayerTitle($l);
	my $czTit = ValueConvertor->GetJobLayerTitle( $l, 1 );
	my $enInf = ValueConvertor->GetJobLayerInfo($l);
	my $czInf = ValueConvertor->GetJobLayerInfo( $l, 1 );

	my $drawingPos = Point->new( 0, abs( $self->{"profileLim"}->{"yMax"} - $self->{"profileLim"}->{"yMin"} ) + 50 );    # starts 150

	#my %lines_arcs = %{ $l->{"symHist"}->{"lines_arcs"} };
	#my %pads       = %{ $l->{"symHist"}->{"pads"} };

	# Get if NC operation is from top/bot
	my $side = $l->{"gROWname"} =~ /c/ ? "top" : "bot";

	my $result = $self->{"outputNClayer"}->Prepare($l);

	foreach my $classRes ( $result->GetClassResults(1) ) {

		my $t = $classRes->GetType();

		$self->__ProcessLayerData( $classRes, $l, );
		$self->__ProcessDrawing( $classRes, $l, $side, $drawingPos, $t );

	}
}

# Process countersink Surfaces
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
			my $drawLayer = $layerRes->GetLayer();
			my @chains    = @{ $layerRes->{"chainSeq"} };

			my $radiusReal = $layerRes->{"radiusReal"};

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
			my $drawLayer  = $layerRes->GetLayer();
			my @pads       = @{ $layerRes->{"padFeatures"} };
			my $radiusReal = undef;

			if ( $classRes->GetType() eq OutEnums->Type_COUNTERSINKPAD ) {

				$radiusReal = $layerRes->{"radiusReal"};

			}
			elsif ( $classRes->GetType() eq OutEnums->Type_ZAXISPAD ) {

				$radiusReal = $layerRes->{"DTMTool"}->GetDrillSize() / 1000;    # convert to mm
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
				|| $classRes->GetType() eq OutEnums->Type_ZAXISSURFCHAMFER
				|| $classRes->GetType() eq OutEnums->Type_ZAXISSURF
				|| $classRes->GetType() eq OutEnums->Type_ZAXISSLOT )
		{

			# Parsed data from "parser class result"
			my $drawLayer  = $layerRes->GetLayer();
			my $radiusReal = $layerRes->{"radiusReal"};

			# Adjust copied feature data. Create outlilne from each feature

			if ( $classRes->GetType() eq OutEnums->Type_ZAXISSURF ) {
				CamLayer->Contourize( $inCAM, $drawLayer, "area", "1000" );
			}

			CamLayer->WorkLayer( $inCAM, $drawLayer );

			#CamSymbolSurf->SetSurfaceLinePattern( $inCAM, 1, $self->{"dataOutline"}, 45, 0, 20, 1000, 1 );

			$inCAM->COM( "sel_feat2outline", "width" => $self->{"dataOutline"}, "location" => "on_edge" );

		}

	}
}

# Process countersink Surfaces
sub __ProcessDrawing {
	my $self       = shift;
	my $classRes   = shift;
	my $l          = shift;
	my $side       = shift;
	my $drawingPos = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	foreach my $layerRes ( $classRes->GetLayers() ) {

		# ----------------------------------------------------------------
		# 2) Create countersink drawing
		# ----------------------------------------------------------------
		my $draw = Drawing->new( $inCAM, $jobId, $layerRes->GetLayer(), $drawingPos, $self->{"pcbThick"}, $side, $l->{"plated"} );

		if (    $classRes->GetType() eq OutEnums->Type_COUNTERSINKSURF
			 || $classRes->GetType() eq OutEnums->Type_COUNTERSINKARC )
		{

			# Compute depth of "imagine drill tool"
			# If countersink is done by surface, edge of drill tool goes around according "surface border"
			# Image for this case will show "image tool", where center of tool is same as center of surface, thus "image tool"
			# not go around surface bordr but just like normal drill tool, which drill hole

			my @chains = @{ $layerRes->{"chainSeq"} };

			#$toolDepth    = $chains[0]->GetChain()->GetChainTool()->GetUniDTMTool()->GetDepth();    # angle of tool
			my $imgToolAngle = $chains[0]->GetChain()->GetChainTool()->GetUniDTMTool()->GetAngle();    # angle of tool

			my $imgToolDepth = cotan( deg2rad( ( $imgToolAngle / 2 ) ) ) * $layerRes->{"radiusReal"};

			$draw->CreateDetailCountersink(  $layerRes->{"radiusReal"}, $imgToolDepth, $imgToolAngle, "hole" );

		}
		elsif ( $classRes->GetType() eq OutEnums->Type_COUNTERSINKPAD ) {

			# Compute depth of "imagine drill tool"
			# If countersink is done by surface, edge of drill tool goes around according "surface border"
			# Image for this case will show "image tool", where center of tool is same as center of surface, thus "image tool"
			# not go around surface bordr but just like normal drill tool, which drill hole
			my $dtmTool = $layerRes->{"DTMTool"};

			#$toolDepth    = $dtmTool->GetDepth();                                                   # angle of tool
			my $imgToolAngle = $dtmTool->GetAngle();    # angle of tool

			my $imgToolDepth = cotan( deg2rad( ( $imgToolAngle / 2 ) ) ) * $layerRes->{"radiusReal"};

			if ( $l->{"plated"} ) {
				$imgToolDepth -= 0.05;
			}

			$draw->CreateDetailCountersink(  $layerRes->{"radiusReal"}, $imgToolDepth, $imgToolAngle, "hole" );

		}
		elsif ( $classRes->GetType() eq OutEnums->Type_ZAXISSLOTCHAMFER ) {

			die "test";
		}

		# Draw picture

	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
