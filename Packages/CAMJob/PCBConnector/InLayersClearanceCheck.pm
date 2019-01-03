#-------------------------------------------------------------------------------------------#
# Description: GoldFingerChecks check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::PCBConnector::InLayersClearanceCheck;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use Math::Trig;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamFilter';
use aliased 'Packages::CAMJob::PCBConnector::PCBConnectorCheck';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::CAMJob::PCBConnector::PCBConnectorCheck';
use aliased 'Packages::Stackup::Enums' => "EnumsStack";
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAM::FeatureFilter::Enums' => 'FilterEnums';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#
my $EDGE2LAYERDIST = 1000;    # 1000µm clearance of inner layer from chamfered connector edge

sub CheckInLayer {
	my $self           = shift;
	my $inCAM          = shift;
	my $jobId          = shift;
	my $step           = shift;
	my $layer          = shift;
	my $chamferSide    = shift;         # top/bot
	my $connectorEdges = shift;
	my $stackup        = shift;
	my $chamferAngle   = shift;         # angle of chamfer tool 90°/120°/140°
	my $chamferDepth   = shift;         # routing depth of chamfer tool
	my $resultData     = shift // {};

	my $result = 1;

	my $lDepth;

	if ( $chamferSide eq "top" ) {
		$lDepth = $self->__GetLayerDepth( $layer, $stackup );    # layer depth from top
	}
	else {
		$lDepth = $stackup->GetFinalThick() - $self->__GetLayerDepth( $layer, $stackup );    # layer depth from bot
	}

	# Compute min distance of chamfered edge for inner layer
	my $minProfDist;

	if ( $lDepth >= $chamferDepth ) {

		$minProfDist = $EDGE2LAYERDIST;
	}
	else {

		$minProfDist = tan( deg2rad( $chamferAngle / 2 ) ) * ( $chamferDepth - $lDepth ) + $EDGE2LAYERDIST;
	}

	$resultData->{"minProfDist"} = $minProfDist;

	# Draw edge with thick of computed min distance from profile to inner layer
	# Celect all features from inner layer which are touched bz theses edges (if selected, min distance is not keeped)
	my $edgeL = GeneralHelper->GetGUID();
	CamMatrix->CreateLayer( $inCAM, $jobId, $edgeL, "document", "positive", 0 );
	CamLayer->WorkLayer( $inCAM, $edgeL );

	foreach my $edge ( @{$connectorEdges} ) {

		CamSymbol->AddLine( $inCAM,
							{ "x" => $edge->{"x1"}, "y" => $edge->{"y1"} },
							{ "x" => $edge->{"x2"}, "y" => $edge->{"y2"} },
							"s" . ( 2 * $minProfDist ) );

	}

	my $testLayer = GeneralHelper->GetGUID();
	CamMatrix->CopyLayer( $inCAM, $jobId, $layer, $step, $testLayer, $step );
	my $negLayer = 0;
	if ( CamMatrix->GetLayerPolarity( $inCAM, $jobId, $layer ) eq "negative" ) {

		my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );
		CamLayer->NegativeLayerData( $inCAM, $testLayer, \%lim );
		$negLayer = 1;
	}

	CamLayer->WorkLayer( $inCAM, $testLayer );
	CamLayer->Contourize( $inCAM, $testLayer );

	my $f = FeatureFilter->new( $inCAM, $jobId, $testLayer );
	$f->SetRefLayer($edgeL);
	$f->SetReferenceMode( FilterEnums->RefMode_TOUCH );
	$f->SetProfile( FilterEnums->ProfileMode_INSIDE );
	if ( $f->Select() ) {

		$result = 0;
	}

	CamMatrix->DeleteLayer( $inCAM, $jobId, $edgeL );
	CamMatrix->DeleteLayer( $inCAM, $jobId, $testLayer );

	return $result;
}

sub CheckAllInLayers {
	my $self         = shift;
	my $inCAM        = shift;
	my $jobId        = shift;
	my $step         = shift;
	my $chamferAngle = shift // 90;    # angle of chamfer tool 90°/120°/140°, default 90°
	my $resultData   = shift // ();

	my $result = 1;

	die "Job is not multilayer" unless ( CamJob->GetSignalLayerCnt( $inCAM, $jobId ) > 2 );

	my $stackup = Stackup->new($jobId);

	my $chamferDepth = $stackup->GetFinalThick() / 3;    # routing depth of chamfer tool, assume 1/3 material

	# Get board edges for top connector

	my @topEdges = ();
	my $topConnector = PCBConnectorCheck->ConnectorDetection( $inCAM, $jobId, $step, "c", \@topEdges );

#	if ($topConnector) {
#		PCBConnectorCheck->DrawConnectorResult( $inCAM, $jobId, \@topEdges, "topCon" );
#	}

	# Get board edges for bot connector
	my @botEdges = ();
	my $botConnector = PCBConnectorCheck->ConnectorDetection( $inCAM, $jobId, $step, "s", \@botEdges );

#	if ($botConnector) {
#		PCBConnectorCheck->DrawConnectorResult( $inCAM, $jobId, \@botEdges, "botCon" );
#	}

	foreach my $inLayer ( map { $_->{"gROWname"} } CamJob->GetSignalLayer( $inCAM, $jobId, 1 ) ) {

		my $depth = $self->__GetLayerDepth( $inLayer, $stackup );

		my $clrOk = 1;

		if ( $depth < $stackup->GetFinalThick() / 2 && $topConnector ) {
			my %lResultData = ();
			$clrOk = $self->CheckInLayer( $inCAM, $jobId, $step, $inLayer, "top", \@topEdges, $stackup, $chamferAngle, $chamferDepth, \%lResultData );
			push(
				  @{$resultData},
				  {
					 "layer"       => $inLayer,
					 "result"      => $clrOk,
					 "edges"       => \@topEdges,
					 "minProfDist" => $lResultData{"minProfDist"}
				  }
			);
		}
		elsif ( $depth >= $stackup->GetFinalThick() / 2 && $botConnector ) {

			my %lResultData = ();
			$clrOk = $self->CheckInLayer( $inCAM, $jobId, $step, $inLayer, "bot", \@botEdges, $stackup, $chamferAngle, $chamferDepth, \%lResultData );
			push(
				  @{$resultData},
				  {
					 "layer"       => $inLayer,
					 "result"      => $clrOk,
					 "edges"       => \@botEdges,
					 "minProfDist" => $lResultData{"minProfDist"}
				  }
			);
		}

		$result = 0 unless ($clrOk);

	}

	return $result;
}

sub __GetLayerDepth {
	my $self    = shift;
	my $layer   = shift;
	my $stackup = shift;

	my $depth = 0;

	foreach my $l ( $stackup->GetAllLayers() ) {
		$depth += $l->GetThick();
		if ( $l->GetType() eq EnumsStack->MaterialType_COPPER && $l->GetCopperName() eq $layer ) {
			$depth -= $l->GetThick() / 2;    # depth is computed to half of thick of searched Cu
			last;
		}
	}

	return $depth;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::PCBConnector::InLayersClearanceCheck';
	use Data::Dump qw(dump);
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d228881";
	my $step  = "o+1";
	my $mess  = "";

	my @resultData = ();
	my $res = InLayersClearanceCheck->CheckAllInLayers( $inCAM, $jobId, $step, 90, \@resultData );

	print STDERR "Result of cleareance chcek:" . $res . "\n";

	foreach my $res (@resultData) {

		print STDERR "Layer: " . $res->{"layer"} . " - result: " . $res->{"result"} . " \n";

	}

	#uhel je

}

1;
