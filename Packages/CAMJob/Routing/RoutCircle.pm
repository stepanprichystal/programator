#-------------------------------------------------------------------------------------------#
# Description: Helper function for splitting rout circle
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Routing::RoutCircle;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamLayer';
use aliased 'Packages::Routing::RoutLayer::RoutParser::RoutParser';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Split all arcs which are circle by "break_feat" function to two arcs
# break is done exactly in the middle of the arc
sub SplitCircles2Arc {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $layer   = shift;
	my $resData = shift // {};

	my $result = 0;

	$resData->{"splitedArcsCnt"} = 0;
	$resData->{"splitedArcs"}    = ();

	my @types = ( EnumsGeneral->LAYERTYPE_nplt_nMill, EnumsGeneral->LAYERTYPE_plt_nMill );

	my @arcs = grep { $_->{"type"} eq "A" } RoutParser->GetFeatures( $inCAM, $jobId, $step, $layer, 0 );
	RoutParser->AddGeometricAtt($_) for (@arcs);

	@arcs = grep { $_->{"innerangle"} == 360 } @arcs;

	CamHelper->SetStep( $inCAM, $step );
	CamLayer->WorkLayer( $inCAM, $layer );

	foreach my $arc (@arcs) {

		$resData->{"splitedArcsCnt"}++;
		push( @{ $resData->{"splitedArcs"} }, $arc->{"id"} );

		$result = 1;

		my $breakX = $arc->{"xmid"} + ( $arc->{"xmid"} - $arc->{"x1"} );
		my $breakY = $arc->{"ymid"} + ( $arc->{"ymid"} - $arc->{"y1"} );

		$inCAM->COM( "break_feat", "ind" => $arc->{"id"} - 1, "x" => $breakX, "y" => $breakY, "length" => "0", "tol" => 0 );
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::Routing::RoutCircle';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d113609";
	my $step  = "o+1";

	my @steps = ("o+1");

	if ( CamHelper->StepExists( $inCAM, $jobId, "panel" ) ) {
		@steps = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueNestedStepAndRepeat( $inCAM, $jobId );
	}

	foreach my $step (@steps) {

		foreach my $l ( CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_nMill, EnumsGeneral->LAYERTYPE_plt_nMill ] ) )
		{

			my %resData = ();

			my $res = RoutCircle->SplitCircles2Arc( $inCAM, $jobId, \%resData );
 

		}
	}

}

1;
