
#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for step placement to panel
# Import/Export settings method are meant for using class in bacground
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::StepsPnlCreator::SetSteps;
use base('Programs::Panelisation::PnlCreator::PnlCreatorBase');

use Class::Interface;
&implements('Programs::Panelisation::PnlCreator::StepsPnlCreator::ISteps');

#3th party library
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Panelisation::PnlCreator::Enums';
use aliased 'Programs::Panelisation::PnlCreator::Helpers::PnlToJSON';
use aliased 'Programs::Panelisation::PnlCreator::Helpers::Helper';
use aliased 'Packages::CAMJob::Panelization::SRStep';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';
use aliased 'Programs::Panelisation::PnlCreator::Helpers::PnlToJSON';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class   = shift;
	my $jobId   = shift;
	my $pnlType = shift;
	my $key     = Enums->StepPnlCreator_SET;

	my $self = $class->SUPER::new( $jobId, $pnlType, $key );
	bless $self;

	$self->{"settings"}->{"setStepList"}           = [];
	$self->{"settings"}->{"setMultiplicity"}       = 0;
	$self->{"settings"}->{"manualPlacementJSON"}   = undef;
	$self->{"settings"}->{"manualPlacementStatus"} = EnumsGeneral->ResultType_NA;

	return $self;    #
}

#-------------------------------------------------------------------------------------------#
# Interface method
#-------------------------------------------------------------------------------------------#

# Init creator class in order process panelisation
# (instead of Init method is possible init by import JSON settings)
# Return 1 if succes 0 if fail
sub Init {
	my $self     = shift;
	my $inCAM    = shift;
	my $stepName = shift;
	

	$self->SetStep($stepName);

	my $jobId = $self->{"jobId"};

	my $result = 1;

	my @editStep = Helper->GetEditSteps( $inCAM, $jobId );

	my @stepList = ();

	foreach my $step (@editStep) {

		push( @stepList, { "stepName" => $step, "stepCount" => 1 } );
	}

	$self->SetStepList( \@stepList );

	return $result;

}

# Do necessary check before processing panelisation
# This method is called always before Process method
# Return 1 if succes 0 if fail
sub Check {
	my $self    = shift;
	my $inCAM   = shift;
	my $errMess = shift;    # reference to err message

	my $result = 1;

	my $jobId = $self->{"jobId"};
	my $step  = $self->GetStep();

	if ( $self->GetManualPlacementStatus() eq EnumsGeneral->ResultType_OK ) {

		unless ( defined $self->GetManualPlacementJSON() ) {

			# JSON placement is not defined
			$result = 0;
			$$errMess .= "Manual panel step palcement error. Missing JSON panel placement.";
		}

	}
	else {

		if ( !CamHelper->StepExists( $inCAM, $jobId, $step ) ) {
			$result = 0;
			$$errMess .= "Panel step: $step doesn't exist in job.";
		}
		else {

			my @stepList = @{ $self->GetStepList() };

			# Die if there are no steps
			if ( scalar(@stepList) == 0 ) {

				$result = 0;
				$$errMess .= "No step definet for steps"

			}

			# Check if step count is greater than 0
			foreach my $step (@stepList) {

				my $cnt = $step->{"stepCount"};

				if ( !defined $cnt || $cnt eq "" || !looks_like_number($cnt) || $cnt <= 0 ) {

					$result = 0;
					$$errMess .= "Step count for step: " . $step->{"stepName"} . " must be > 0";

				}
			}
		}

	}

	# Step multiplicity must be greater than 0
	my $multipl = $self->GetSetMultiplicity();

	if ( !defined $multipl || $multipl eq "" || !looks_like_number($multipl) || $multipl <= 0 ) {
		$result = 0;
		$$errMess .= "Set multicity must be > 0";

	}

	if ( $multipl > 0 ) {
		foreach my $step ( @{ $self->GetStepList() } ) {

			if ( $step->{"stepCount"} % $multipl != 0 ) {

				$result = 0;
				$$errMess .=
				    "Set multiplicity (${multipl}) is wrong. Unable to devide \"Step count: "
				  . $step->{"stepCount"}
				  . "\" by \"Set multiplicity: $multipl\" for step: "
				  . $step->{"stepName"} . "\n";
			}

		}
	}

	return $result;

}

# Return 1 if succes 0 if fail
sub Process {
	my $self    = shift;
	my $inCAM   = shift;
	my $errMess = shift;    # reference to err message
		my $resultData = shift // {};

	my $result = 1;

	my $jobId = $self->{"jobId"};
	my $step  = $self->GetStep();

	if ( $self->GetManualPlacementStatus() eq EnumsGeneral->ResultType_OK ) {

		my $pnlToJSON = PnlToJSON->new( $inCAM, $jobId, $step );
		$pnlToJSON->CreatePnlByJSON( $self->GetManualPlacementJSON(), 1, 1, 0 );
	}
	else {

		my @stepList = @{ $self->GetStepList() };

		# 4) Create new panel
		my $SRStep = SRStep->new( $inCAM, $jobId, $step );

		foreach my $s ( CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $step ) ) {
			CamStepRepeat->DeleteStepAndRepeat( $inCAM, $jobId, $step, $s->{"stepName"} );
		}

		my $xPos = 0;
		for ( my $i = 0 ; $i < scalar(@stepList) ; $i++ ) {

			my $setStep = $stepList[$i];

			my $nestStep = $setStep->{"stepName"};

			my %profLim   = CamJob->GetProfileLimits2( $inCAM, $jobId, $nestStep );
			my $nestStepW = abs( $profLim{"xMax"} - $profLim{"xMin"} );
			my $nestStepH = abs( $profLim{"yMax"} - $profLim{"yMin"} );
			my %dtOri     = CamStep->GetDatumPoint( $inCAM, $jobId, $nestStep, 1 );
			my %zeroOri   = ( "x" => -1 * $profLim{"xMin"}, "y" => -1 * $profLim{"yMin"} );

			my %oriProfLimPnl = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );
			my %oriAreaLimPnl = CamStep->GetActiveAreaLim( $inCAM, $jobId, $step );

			my $oriBL = abs( $oriProfLimPnl{"xMin"} - $oriAreaLimPnl{"xMin"} );
			my $oriBB = abs( $oriProfLimPnl{"yMin"} - $oriAreaLimPnl{"yMin"} );

			$SRStep->AddSRStep( $nestStep,
								$dtOri{"x"} + $zeroOri{"x"} + $oriBL + $xPos,
								$dtOri{"y"} + $zeroOri{"y"} + $oriBB,
								0, $setStep->{"stepCount"},
								1, $nestStepW + 4.5, 0 );

			$xPos += ( $setStep->{"stepCount"} * ( $nestStepW + 4.5 ) );

		}

	}

	# Store set attributes

	CamJob->SetJobAttribute( $inCAM, 'cust_set_multipl', $self->GetSetMultiplicity(), $jobId );
	CamJob->SetJobAttribute( $inCAM, 'customer_set', 'yes', $jobId );


	# Store result data (total step cnt)
	my $total = 0;
	my @repeats = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $self->GetStep() );
	foreach my $sr (@repeats) {

		$total += $sr->{"totalCnt"};
	}

	$resultData->{"totalStepCnt"} = $total if ($result);


	return $result;
}

#-------------------------------------------------------------------------------------------#
# Get/Set method for adjusting settings after Init/ImportSetting
#-------------------------------------------------------------------------------------------#

sub SetStepList {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"setStepList"} = $val;

}

sub GetStepList {
	my $self = shift;

	return $self->{"settings"}->{"setStepList"};

}

sub SetSetMultiplicity {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"setMultiplicity"} = $val;

}

sub GetSetMultiplicity {
	my $self = shift;

	return $self->{"settings"}->{"setMultiplicity"};

}

sub SetManualPlacementJSON {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"manualPlacementJSON"} = $val;

}

sub GetManualPlacementJSON {
	my $self = shift;

	return $self->{"settings"}->{"manualPlacementJSON"};

}

sub SetManualPlacementStatus {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"manualPlacementStatus"} = $val;

}

sub GetManualPlacementStatus {
	my $self = shift;

	return $self->{"settings"}->{"manualPlacementStatus"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

