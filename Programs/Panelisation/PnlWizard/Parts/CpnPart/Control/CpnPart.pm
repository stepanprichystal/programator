
#-------------------------------------------------------------------------------------------#
# Description: Controler for panelise coupons
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::CpnPart::Control::CpnPart;
use base 'Programs::Panelisation::PnlWizard::Parts::PartBase';

use Class::Interface;
&implements('Programs::Panelisation::PnlWizard::Parts::IPart');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Panelisation::PnlWizard::Enums';
use aliased 'Programs::Panelisation::PnlWizard::Parts::CpnPart::Model::CpnPartModel'   => 'PartModel';
use aliased 'Programs::Panelisation::PnlWizard::Parts::CpnPart::View::CpnPartFrm'      => 'PartFrm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::CpnPart::Control::CpnPartCheck' => 'PartCheckClass';
use aliased 'Programs::Panelisation::PnlCreator::Helpers::Helper'                        => "CreatorHelper";
use aliased 'Programs::Panelisation::PnlCreator::Helpers::PnlToJSON';


#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};

	$self = $class->SUPER::new( Enums->Part_PNLCPN, @_ );
	bless $self;

	# PROPERTIES

	$self->{"model"}      = PartModel->new();         # Data model for view
	$self->{"checkClass"} = PartCheckClass->new();    # Checking model before panelisation
	
	$self->__SetActiveCreators();

	return $self;
}

#-------------------------------------------------------------------------------------------#
#  Interface method
#-------------------------------------------------------------------------------------------#

# Set part View
# Dock part View into passed View wrapper
sub InitForm {
	my $self        = shift;
	my $partWrapper = shift;
	my $inCAM       = shift;

	my $parent = $partWrapper->GetParentForPart();

	$self->{"form"} = PartFrm->new( $parent, $inCAM, $self->{"jobId"}, $self->{"model"} );

	$self->{"form"}->{"manualPlacementEvt"}->Add( sub { $self->__OnManualPlacementHndl(@_) } );

	$self->SUPER::_InitForm($partWrapper);

}

# Initialize part model by:
# - Restored data from disc
# - Default depanding on panelisation type
sub InitPartModel {
	my $self          = shift;
	my $inCAM         = shift;
	my $restoredModel = shift;

	if ( defined $restoredModel ) {

		# Load settings from restored data

		$self->{"model"} = $restoredModel;
	}
	else {

		# Init default
		my $defCreator = @{ $self->{"model"}->GetCreators() }[0];
		$self->{"model"}->SetSelectedCreator( $defCreator->GetModelKey() );
	}
}

sub __OnManualPlacementHndl {
	my $self      = shift;
	my $pauseText = shift;

	# Check if preview mode is active
	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	unless ( $self->GetPreview() ) {

		my $messMngr = $self->{"partWrapper"}->GetMessMngr();
		my @mess     = ();
		push( @mess, " \"Preview mode\" must be active for manual panel pick/adjust." );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess );

		return 0;
	}

	# Do check of selected creator
	my $creatorKey   = $self->{"form"}->GetSelectedCreator();
	my $creatorModel = $self->{"form"}->GetCreators($creatorKey)->[0];
	$creatorModel->SetManualPlacementJSON(undef);
	$creatorModel->SetManualPlacementStatus( EnumsGeneral->ResultType_NA );

	my $creator = CreatorHelper->GetPnlCreatorByKey( $self->{"jobId"}, $self->{"pnlType"}, $creatorKey );

	$creator->ImportSettings( $creatorModel->ExportCreatorSettings() );

	my $errMess = "";
	my $result  = 0;    # succes / failure od manual step placement

	if ( $creator->Check( $inCAM, \$errMess ) ) {

		
		my $step = $creatorModel->GetStep();
		$inCAM->COM( "set_subsystem", "name" => "Panel-Design" );
		CamHelper->SetStep( $inCAM, $step );

		# Hide form
		$self->{"showPnlWizardFrmEvt"}->Do(0);
		$inCAM->PAUSE($pauseText);
		$self->{"showPnlWizardFrmEvt"}->Do(1);

		# Show form

		my $pnlToJSON = PnlToJSON->new( $inCAM, $jobId, $step );

		my $errMessJSON = "";

		if ( $pnlToJSON->CheckBeforeParse( \$errMessJSON ) ) {

			my $JSON = $pnlToJSON->ParsePnlToJSON(1, 0, 1, 0);

			if ( defined $JSON ) {

				$creatorModel->SetManualPlacementJSON($JSON);
				$creatorModel->SetManualPlacementStatus( EnumsGeneral->ResultType_OK );

				$result = 1;
			}

		}
		else {

			$self->{"showPnlWizardFrmEvt"}->Do(1);

			my $messMngr = $self->{"partWrapper"}->GetMessMngr();
			my @mess     = ();
			push( @mess, "Manual step placement failed. Detail:\n\n" );
			push( @mess, $errMessJSON );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );

		}

	}
	else {

		my $messMngr = $self->{"partWrapper"}->GetMessMngr();
		my @mess     = ();
		push( @mess, "Check before manual panel pick/adjus failed. Detail:\n\n" );
		push( @mess, $errMess );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );

	}

	# Update form
	$self->{"frmHandlersOff"} = 1;

	$self->{"form"}->SetCreators( [$creatorModel] );

	$self->{"frmHandlersOff"} = 0;

	# Call change settings to return panel automatically to former settings if fail
	unless ($result) {

		$self->__OnCreatorSettingsChangedHndl($creatorKey);
	}

}

# Handler which catch change of creatores in other parts
# Reise imidiatelly after slection change, do not wait on asznchrounous task
sub OnOtherPartCreatorSelChangedHndl {
	my $self            = shift;
	my $partId          = shift;
	my $creatorKey      = shift;

	print STDERR "Selection changed part id: $partId, creator key: $creatorKey\n";

}

# Handler which catch change of selected creatores settings in other parts
sub OnOtherPartCreatorSettChangedHndl {
	my $self        = shift;
	my $partId      = shift;
	my $creatorKey  = shift;
	my $creatorSett = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	print STDERR "Setting changed part id: $partId, creator key: $creatorKey\n";

}

#-------------------------------------------------------------------------------------------#
#  Private method
#-------------------------------------------------------------------------------------------#

# Disable creators which are not needed for specific panelisation type
sub __SetActiveCreators {
	my $self = shift;

	my @currCreators   = @{ $self->GetModel(1)->GetCreators() };
	my @activeCreators = ();

	if ( $self->_GetPnlType() eq PnlCreEnums->PnlType_CUSTOMERPNL ) {
 

	}
	elsif ( $self->_GetPnlType() eq PnlCreEnums->PnlType_PRODUCTIONPNL ) {
		foreach my $c (@currCreators) {

			push( @activeCreators, $c ) if ( $c->GetModelKey() eq PnlCreEnums->CpnPnlCreator_SEMIAUTO );

		}
	}

	$self->GetModel(1)->SetCreators( \@activeCreators );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

