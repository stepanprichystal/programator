#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ChangeReorder::Changes::SCHEMA;
use base('Packages::Reorder::ChangeReorder::Changes::ChangeBase');

use Class::Interface;
&implements('Packages::Reorder::ChangeReorder::Changes::IChange');

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamStep';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Reorder::Enums';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# Delete and add new schema
sub Run {
	my $self = shift;
	my $errMess = shift;
	my $infMess = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $reorderType = $self->{"reorderType"};

	my $result = 1;

	# Check only standard orders
	if ( CamHelper->StepExists( $inCAM, $jobId, "panel" ) ) {

		# 1) Delete coupons (test coupons were be put to pcb panel previously, today not)

		my @couponSteps = grep { $_ =~ /coupon_\d+vv/i } CamStep->GetAllStepNames( $inCAM, $jobId );

		foreach my $s (@couponSteps) {

			if ( CamHelper->StepExists( $inCAM, $jobId, $s ) ) {
				$inCAM->COM( "delete_entity", "job" => $jobId, "name" => $s, "type" => "step" );
			}
		}

		# 2) Delete old schema + all from panel board layer (if autopan_delete, it doesnt delete non schema features)

		my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

		my @steps = CamStepRepeatPnl->GetUniqueStepAndRepeat( $inCAM, $jobId );

		$inCAM->COM( "set_subsystem", "name" => "Panel-Design" );

		CamHelper->SetStep( $inCAM, "panel" );
		CamLayer->ClearLayers($inCAM);
		my @layers = CamJob->GetBoardLayers( $inCAM, $jobId );

		@layers = grep { $_->{"gROWname"} ne "fsch" } @layers;    # we want keep old fsch
		@layers = map  { $_->{"gROWname"} } @layers;

		CamLayer->AffectLayers( $inCAM, \@layers );
		$inCAM->COM('sel_delete');
		CamLayer->ClearLayers($inCAM);

		# 3) Insert new schema

		my $schema = undef;

		if ( $layerCnt <= 2 ) {

			$schema = "1a2v";
		}
		else {

			my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, "panel" );

			my $pnlH = abs( $lim{"yMax"} - $lim{"yMin"} );

			use constant tol => 2;
			if ( abs( $pnlH - 407 ) < tol ) {
				$schema = '4v-407';
			}
			elsif ( abs( $pnlH - 485 ) < tol ) {
				$schema = '4v-485';
			}
			elsif ( abs( $pnlH - 538 ) < tol ) {
				$schema = '4v-538';
			}
			else {
				die "Schema was not found for panel height: $pnlH mm.";
			}
		}
		$inCAM->COM( 'autopan_run_scheme', "job" => $jobId, "panel" => "panel", "pcb" => $steps[0]->{"stepName"}, "scheme" => $schema );

	}

	return $result;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::ChangeReorder::Changes::SCHEMA' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52457";

	my $check = Change->new( "key", $inCAM, $jobId );

	my $errMess = "";
	print "Change result: " . $check->Run( \$errMess );
}

1;

