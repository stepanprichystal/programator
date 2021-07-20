
#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for step placement to panel
# Import/Export settings method are meant for using class in bacground
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::StepsPnlCreator::MatrixSteps;
use base('Programs::Panelisation::PnlCreator::PnlCreatorBase');

use Class::Interface;
&implements('Programs::Panelisation::PnlCreator::StepsPnlCreator::ISteps');

#3th party library
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

#local library
use aliased 'Programs::Panelisation::PnlCreator::Enums';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';
use aliased 'Packages::CAMJob::Panelization::SRStep';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Programs::Panelisation::PnlCreator::Helpers::Helper';
use aliased 'Programs::Panelisation::PnlCreator::Helpers::StepProfile';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Panelisation::PnlCreator::Helpers::PnlToJSON';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class   = shift;
	my $jobId   = shift;
	my $pnlType = shift;
	my $key     = Enums->StepPnlCreator_MATRIX;

	my $self = $class->SUPER::new( $jobId, $pnlType, $key );
	bless $self;

	# Setting values necessary for procesing panelisation
	$self->{"settings"}->{"pcbStepsList"}          = [];
	$self->{"settings"}->{"pcbStep"}               = undef;
	$self->{"settings"}->{"pcbStepProfile"}        = Enums->PCBStepProfile_STANDARD;
	$self->{"settings"}->{"stepMultiX"}            = 0;
	$self->{"settings"}->{"stepMultiY"}            = 0;
	$self->{"settings"}->{"stepSpaceX"}            = 0;
	$self->{"settings"}->{"stepSpaceY"}            = 0;
	$self->{"settings"}->{"stepRotation"}          = 0;
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

	my $result = 1;

	my $jobId = $self->{"jobId"};

	# Panel step
	$self->SetStep($stepName);

	my @childs = grep { $_ =~ /^\w+\+1$/ } CamStep->GetAllStepNames( $inCAM, $jobId );
	@childs = grep { $_ ne $stepName } @childs;
	$self->SetPCBStepsList( \@childs );

	if ( $self->GetPnlType() eq Enums->PnlType_CUSTOMERPNL ) {

		# Create step list choice

		$self->SetPCBStep( $childs[0] );
	}
	elsif ( $self->GetPnlType() eq Enums->PnlType_PRODUCTIONPNL ) {

		die "Not implemnted";

	}

	$self->SetPCBStepProfile( Enums->PCBStepProfile_STANDARD );

	if ( CamHelper->LayerExists( $inCAM, $jobId, "cvrlpins" ) && $self->GetPCBStep() ne "mpanel" ) {

		$self->SetPCBStepProfile( Enums->PCBStepProfile_CVRLPINS );
	}

	# Load Pnl class

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

		# Check if panel step exist
		if ( !CamHelper->StepExists( $inCAM, $jobId, $step ) ) {
			$result = 0;
			$$errMess .= "Panel step: $step doesn't exist in job.";
		}
		else {

			# 1) Check if nested step exists
			my $nestStep = $self->GetPCBStep();
			if ( !defined $nestStep || $nestStep eq "" ) {
				$result = 0;
				$$errMess .= "Nested step name is not defined\n";

			}

			# Check if nested step exist in job
			if ( defined $nestStep && $nestStep ne "" ) {

				if ( !CamHelper->StepExists( $inCAM, $jobId, $nestStep ) ) {
					$result = 0;
					$$errMess .= "Nested step: $nestStep doesn't exist in job.\n";
				}
			}

			my $multiplX = $self->GetStepMultiplX();
			my $multiplY = $self->GetStepMultiplY();
			my $spaceX   = $self->GetStepSpaceX();
			my $spaceY   = $self->GetStepSpaceY();
			my $rotation = $self->GetStepRotation();

			# Multiplicity
			if ( !defined $multiplX || $multiplX eq "" || !looks_like_number($multiplX) || $multiplX <= 0 ) {
				$result = 0;
				$$errMess .= "Wrong value of step multiplicity X: $multiplX\n";
			}

			if ( !defined $multiplY || $multiplY eq "" || !looks_like_number($multiplY) || $multiplY <= 0 ) {
				$result = 0;
				$$errMess .= "Wrong value of step multiplicity Y: $multiplY\n";
			}

			# Space X

			if ( !defined $spaceX || $spaceX eq "" || !looks_like_number($spaceX) ) {
				$result = 0;
				$$errMess .= "Wrong value of Space X: $spaceX\n";
			}

			# Space Y
			if ( !defined $spaceY || $spaceY eq "" || !looks_like_number($spaceY) ) {
				$result = 0;
				$$errMess .= "Wrong value of Space Y: $spaceY\n";
			}

			# Rotation
			if (    !defined $rotation
				 || $rotation eq ""
				 || !looks_like_number($rotation)
				 || ( $rotation != 0 && $rotation != 90 && $rotation != 180 && $rotation != 270 ) )
			{
				$result = 0;
				$$errMess .= "Wrong value of pcb rotation Y: $rotation\n";
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

	my $result = 1;

	my $jobId = $self->{"jobId"};
	my $step  = $self->GetStep();

	if ( $self->GetManualPlacementStatus() eq EnumsGeneral->ResultType_OK ) {

		my $pnlToJSON = PnlToJSON->new( $inCAM, $jobId, $step );
		$pnlToJSON->CreatePnlByJSON( $self->GetManualPlacementJSON(), 0, 1, 0 );

	}
	else {

		my $nestStep = $self->GetPCBStep();
		$nestStep .= "_cvrlpins" if ( $self->GetPCBStepProfile() eq Enums->PCBStepProfile_CVRLPINS );

		my %profLim   = CamJob->GetProfileLimits2( $inCAM, $jobId, $nestStep );
		my $nestStepW = abs( $profLim{"xMax"} - $profLim{"xMin"} );
		my $nestStepH = abs( $profLim{"yMax"} - $profLim{"yMin"} );
		my $spaceX    = $self->GetStepSpaceX();
		my $spaceY    = $self->GetStepSpaceY();
		my $rotation  = $self->GetStepRotation();

		# 1) Get position of datum point with Left Down corner of profile
		# For all posssible rotations 0,90,180,270
		# CCW
		my %datumRot = ( 0 => undef, 90 => undef, 180 => undef, 270 => undef );

		my %dtOri = CamStep->GetDatumPoint( $inCAM, $jobId, $nestStep, 1 );
		my %zeroOri = ( "x" => -1 * $profLim{"xMin"}, "y" => -1 * $profLim{"yMin"} );

		foreach my $angle ( keys %datumRot ) {

			if ( $angle == 0 ) {

				$datumRot{"0"}->{"x"} = $dtOri{"x"} + $zeroOri{"x"};
				$datumRot{"0"}->{"y"} = $dtOri{"y"} + $zeroOri{"y"};

			}
			elsif ( $angle == 90 ) {

				$datumRot{"90"}->{"x"} = $nestStepH - $dtOri{"y"} - $zeroOri{"y"};
				$datumRot{"90"}->{"y"} = $dtOri{"x"} + $zeroOri{"x"};

			}
			elsif ( $angle == 180 ) {

				$datumRot{"180"}->{"x"} = $nestStepW - $dtOri{"x"} - $zeroOri{"x"};
				$datumRot{"180"}->{"y"} = $nestStepH - $dtOri{"y"} - $zeroOri{"y"};

			}
			elsif ( $angle == 270 ) {

				$datumRot{"270"}->{"x"} = $dtOri{"y"} + $zeroOri{"y"};
				$datumRot{"270"}->{"y"} = $nestStepW - $dtOri{"x"} - $zeroOri{"x"};
			}

		}

		# 2) Get step size for all posssible rotations 0,90,180,270
		my %stepPitchRot = ( 0 => undef, 90 => undef, 180 => undef, 270 => undef );

		foreach my $angle ( keys %stepPitchRot ) {
			if ( $angle == 0 || $angle == 180 ) {

				$stepPitchRot{"0"}->{"x"}   = $nestStepW + $spaceX;
				$stepPitchRot{"0"}->{"y"}   = $nestStepH + $spaceY;
				$stepPitchRot{"180"}->{"x"} = $nestStepW + $spaceX;
				$stepPitchRot{"180"}->{"y"} = $nestStepH + $spaceY;

			}
			if ( $angle == 90 || $angle == 270 ) {

				$stepPitchRot{"90"}->{"x"}  = $nestStepH + $spaceX;
				$stepPitchRot{"90"}->{"y"}  = $nestStepW + $spaceY;
				$stepPitchRot{"270"}->{"x"} = $nestStepH + $spaceX;
				$stepPitchRot{"270"}->{"y"} = $nestStepW + $spaceY;
			}
		}

		# 3) Get all borders from existin panel
		my %oriProfLimPnl = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );
		my %oriAreaLimPnl = CamStep->GetActiveAreaLim( $inCAM, $jobId, $step );

		my $oriBL = abs( $oriProfLimPnl{"xMin"} - $oriAreaLimPnl{"xMin"} );
		my $oriBR = abs( $oriProfLimPnl{"xMax"} - $oriAreaLimPnl{"xMax"} );
		my $oriBT = abs( $oriProfLimPnl{"yMax"} - $oriAreaLimPnl{"yMax"} );
		my $oriBB = abs( $oriProfLimPnl{"yMin"} - $oriAreaLimPnl{"yMin"} );

		# 4) Create new panel
		my $SRStep = SRStep->new( $inCAM, $jobId, $step );

		# Compute active area
		my $multiplX = $self->GetStepMultiplX();
		my $multiplY = $self->GetStepMultiplY();

		my $areaW = $multiplX * ( ( $rotation / 90 ) % 2 == 0 ? $nestStepW : $nestStepH ) + ( $multiplX - 1 ) * $spaceX;
		my $areaH = $multiplY * ( ( $rotation / 90 ) % 2 == 0 ? $nestStepH : $nestStepW ) + ( $multiplY - 1 ) * $spaceY;

		my $w = $areaW + $oriBL + $oriBR;
		my $h = $areaH + $oriBT + $oriBB;

		CamHelper->SetStep( $inCAM, $step );
		$SRStep->Edit( $w, $h, $oriBT, $oriBB, $oriBL, $oriBR );

		foreach my $s ( CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $step ) ) {
			CamStepRepeat->DeleteStepAndRepeat( $inCAM, $jobId, $step, $s->{"stepName"} );
		}

		$SRStep->AddSRStep( $self->GetPCBStep(),
							$datumRot{$rotation}->{"x"} + $oriBL,
							$datumRot{$rotation}->{"y"} + $oriBB,
							$rotation, $multiplX, $multiplY,
							$stepPitchRot{$rotation}->{"x"},
							$stepPitchRot{$rotation}->{"y"} );
	}
	return $result;
}

#-------------------------------------------------------------------------------------------#
# Get/Set method for adjusting settings after Init/ImportSetting
#-------------------------------------------------------------------------------------------#

sub SetPCBStepsList {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"pcbStepsList"} = $val;

}

sub GetPCBStepsList {
	my $self = shift;

	return $self->{"settings"}->{"pcbStepsList"};

}

sub SetPCBStep {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"pcbStep"} = $val;

}

sub GetPCBStep {
	my $self = shift;

	return $self->{"settings"}->{"pcbStep"};

}

sub SetPCBStepProfile {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"pcbStepProfile"} = $val;

}

sub GetPCBStepProfile {
	my $self = shift;

	return $self->{"settings"}->{"pcbStepProfile"};

}

sub SetStepMultiplX {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"stepMultiX"};
}

sub GetStepMultiplX {
	my $self = shift;

	return $self->{"settings"}->{"stepMultiX"};
}

sub SetStepMultiplY {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"stepMultiY"};
}

sub GetStepMultiplY {
	my $self = shift;

	return $self->{"settings"}->{"stepMultiY"};
}

sub SetStepSpaceX {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"stepSpaceX"};
}

sub GetStepSpaceX {
	my $self = shift;

	return $self->{"settings"}->{"stepSpaceX"};
}

sub SetStepSpaceY {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"stepSpaceY"};
}

sub GetStepSpaceY {
	my $self = shift;

	return $self->{"settings"}->{"stepSpaceY"};
}

sub SetStepRotation {
	my $self = shift;
	my $val  = shift;
	$self->{"settings"}->{"stepRotation"};
}

sub GetStepRotation {
	my $self = shift;

	return $self->{"settings"}->{"stepRotation"};
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

