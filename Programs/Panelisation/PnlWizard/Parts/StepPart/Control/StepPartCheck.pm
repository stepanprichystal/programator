#-------------------------------------------------------------------------------------------#
# Description: Check class for checking before processing panel creator
# Class should contain OnItemResult event
# Class must implement ICheckClass
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::StepPart::Control::StepPartCheck;
use base 'Programs::Panelisation::PnlWizard::Parts::PartCheckBase';

use Class::Interface;

&implements('Packages::InCAMHelpers::AppLauncher::PopupChecker::ICheckClass');

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased "Programs::Panelisation::PnlWizard::Enums";
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};

	$self = $class->SUPER::new(@_);
	bless $self;

	# PROPERTIES

	return $self;
}

# Do check of creator settings and part settings
sub Check {
	my $self      = shift;
	my $pnlType   = shift;    # Panelisation type
	my $partModel = shift;    # Part model

	if ( $pnlType eq PnlCreEnums->PnlType_CUSTOMERPNL ) {

		$self->__CheckCustomerPanel($partModel);

	}
	elsif ( $pnlType eq PnlCreEnums->PnlType_PRODUCTIONPNL ) {

		$self->__CheckProductionPanel($partModel);
	}

	$self->__CheckGeneral($partModel);

}

# Check only customer panel errors
sub __CheckCustomerPanel {
	my $self      = shift;
	my $partModel = shift;    # Part model

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

}

# Check only production panel errors
sub __CheckProductionPanel {
	my $self      = shift;
	my $partModel = shift;    # Part model

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

}

# Check all panels
sub __CheckGeneral {
	my $self      = shift;
	my $partModel = shift;    # Part model

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $creator      = $partModel->GetSelectedCreator();
	my $creatorModel = $partModel->GetCreatorModelByKey($creator);

	if (    $creator eq PnlCreEnums->StepPnlCreator_CLASSUSER
		 || $creator eq PnlCreEnums->StepPnlCreator_CLASSHEG )
	{

		my $actionType = $creatorModel->GetActionType();
		my $status     = $creatorModel->GetManualPlacementStatus();

		if ( $actionType eq PnlCreEnums->StepPlacementMode_MANUAL() && $status ne EnumsGeneral->ResultType_OK ) {

			$self->_AddError(
							  "Manuální úprava panelu",
							  "Je aktivní přepínač pro manuální výběr rozmístění stepů v panelu, "
								. "ale rozmístění nebylo řádně nastaveno (nesvítí zelená fajka)"
			);
		}
	}

}

