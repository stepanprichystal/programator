
#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for step placement to panel
# Import/Export settings method are meant for using class in bacground
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::StepsPnlCreator::AutoHEGSteps;
use base('Programs::Panelisation::PnlCreator::StepsPnlCreator::AutoCreatorBase');

use Class::Interface;
&implements('Programs::Panelisation::PnlCreator::StepsPnlCreator::ISteps');

#3th party library
use strict;
use warnings;
use List::Util qw[max min first];
use Try::Tiny;

#local library
use aliased 'Enums::EnumsGeneral';

use aliased 'Programs::Panelisation::PnlCreator::Enums';
use aliased 'Connectors::HeliosConnector::HegMethods';

#use aliased 'Packages::CAM::PanelClass::Enums' => "PnlClassEnums";
#use aliased 'Programs::Panelisation::PnlCreator::Helpers::PnlClassParser';
#use aliased 'CamHelpers::CamHelper';
#use aliased 'CamHelpers::CamJob';
#use aliased 'CamHelpers::CamStep';
#use aliased 'CamHelpers::CamStepRepeat';
#use aliased 'Packages::CAMJob::Panelization::AutoPart';
#use aliased 'Programs::Panelisation::PnlCreator::Helpers::PnlToJSON';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class   = shift;
	my $jobId   = shift;
	my $pnlType = shift;
	my $key     = Enums->StepPnlCreator_AUTOHEG;

	my $self = $class->SUPER::new( $jobId, $pnlType, $key );
	bless $self;

	# Properties
	$self->{"settings"}->{"ISMultiplFilled"} = undef;

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

	my $jobId = $self->{'jobId'};

	# Set default settings
	$self->SUPER::_Init( $inCAM, $stepName );

	# Set amount settings from HEG

	my $dim = HegMethods->GetInfoDimensions($jobId);

	if ( $self->GetPnlType() eq Enums->PnlType_CUSTOMERPNL ) {

		my $multiplIS = $dim->{"nasobnost_panelu"};

		if ( defined $multiplIS && $multiplIS > 0 ) {

			$self->SetExactQuantity($multiplIS);
			$self->SetISMultiplFilled(1);
		}
		else {

			$self->SetExactQuantity(0);
			$self->SetISMultiplFilled(0);
		}

	}    # Load panel size from HEG
	elsif ( $self->GetPnlType() eq Enums->PnlType_PRODUCTIONPNL ) {

		my $multiplIS = $dim->{"nasobnost"};

		if ( defined $multiplIS && $multiplIS > 0 ) {

			$self->SetExactQuantity($multiplIS);
			$self->SetISMultiplFilled(1);
		}
		else {

			$self->SetExactQuantity(0);
			$self->SetISMultiplFilled(0);
		}
	}

	$self->SetAmountType( Enums->StepAmount_EXACT );

	return $result;

}

# Do necessary check before processing panelisation
# This method is called always before Process method
# Return 1 if succes 0 if fail
sub Check {
	my $self    = shift;
	my $inCAM   = shift;
	my $errMess = shift;    # reference to err message

	my $jobId = $self->{"jobId"};
	my $step  = $self->GetStep();

	my $result = 1;

	$result = $self->SUPER::_Check( $inCAM, $errMess );

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

	$result = $self->SUPER::_Process( $inCAM, $errMess );
	return $result;
}

#-------------------------------------------------------------------------------------------#
# Get/Set method for adjusting settings after Init/ImportSetting
#-------------------------------------------------------------------------------------------#

sub SetISMultiplFilled {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"ISMultiplFilled"} = $val;
}

sub GetISMultiplFilled {
	my $self = shift;

	return $self->{"settings"}->{"ISMultiplFilled"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

