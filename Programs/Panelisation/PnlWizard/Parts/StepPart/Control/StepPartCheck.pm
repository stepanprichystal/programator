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
use aliased 'Helpers::JobHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamJob';


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

	my $creator      = $partModel->GetSelectedCreator();
	my $creatorModel = $partModel->GetCreatorModelByKey($creator);

	{
		# X) Check proper step distance base on material and PCB type
		if (    $creator eq PnlCreEnums->StepPnlCreator_CLASSUSER
			 || $creator eq PnlCreEnums->StepPnlCreator_CLASSHEG
			 || $creator eq PnlCreEnums->SizePnlCreator_MATRIX )
		{

			my $matKind      = HegMethods->GetMaterialKind($jobId);
			my $isSemiHybrid = 0;
			my $isHybrid     = JobHelper->GetIsHybridMat( $jobId, $matKind, [], \$isSemiHybrid );
			my $pcbType      = JobHelper->GetPcbType($jobId);
			my @boardLayers  = CamJob->GetBoardBaseLayers( $inCAM, $jobId );

			my $spaceX = undef;
			my $spaceY = undef;

			if (    $creator eq PnlCreEnums->StepPnlCreator_CLASSUSER
				 || $creator eq PnlCreEnums->StepPnlCreator_CLASSHEG )
			{
				$spaceX = $creatorModel->GetSpaceX();
				$spaceY = $creatorModel->GetSpaceY();
			}
			elsif ( $creator eq PnlCreEnums->SizePnlCreator_MATRIX ) {
				$spaceX = $creatorModel->GetStepSpaceX();
				$spaceY = $creatorModel->GetStepSpaceY();
			}

			if (    ( $pcbType eq EnumsGeneral->PcbType_1VFLEX || $pcbType eq EnumsGeneral->PcbType_2VFLEX )
				 && scalar( grep { $_->{"gROWlayer_type"} eq "stiffener" } @boardLayers ) == 0
				 && scalar( grep { $_->{"gROWlayer_type"} eq "coverlay" } @boardLayers ) == 0
				 && ( $spaceX < 10 || $spaceY < 10 ) )
			{

				# Flex without stiffener, space at least 6.5

				$self->_AddError( "Malý rozestup mezi stepy",
						  "Pokud je DPS typu Flex a neobsahuje stiffener ani coverlay, je třeba dodržet minimální rozestupy mezi stepy >= 10mm" );
			}
			elsif (
					(
					     $pcbType eq EnumsGeneral->PcbType_1VFLEX
					  || $pcbType eq EnumsGeneral->PcbType_2VFLEX
					  || $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXI
					  || $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXO
					)
					&& ( $spaceX < 2.5 || $spaceY < 2.5 )
			  )
			{

				# space at least 2,5 because of 1flut rout
				$self->_AddError(
								  "Malý rozestup mezi stepy",
								  "Pokud je DPS typu Flex nebo RigidFlex, je třeba dodržet minimální rozestupy mezi stepy >= 2,5mm"
									. "Dúvodem je použití 1-břitých fréz (pouze jedna strana pojezdu je kvalitní)"
				);

			}
			elsif (    ( $isSemiHybrid || $isHybrid )
					&& ( $spaceX < 2.5 || $spaceY < 2.5 ) )
			{
				# space 2.5 (at least 2,5 because of 1flut rout)

				$self->_AddError(
								 "Malý rozestup mezi stepy",
								 "Pokud je DPS typu hybrid/semi-hybrid (DPS s coverlay), je třeba dodržet minimální rozestupy mezi stepy >= 2,5mm"
								   . "Dúvodem je použití 1-břitých fréz (pouze jedna strana pojezdu je kvalitní)"
				);

			}

		}
	}

}

# Check only production panel errors
sub __CheckProductionPanel {
	my $self      = shift;
	my $partModel = shift;    # Part model

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $creator      = $partModel->GetSelectedCreator();
	my $creatorModel = $partModel->GetCreatorModelByKey($creator);

	# X) Check proper step distance base on material and PCB type
	{
		
		if (    $creator eq PnlCreEnums->StepPnlCreator_CLASSUSER
			 || $creator eq PnlCreEnums->StepPnlCreator_CLASSHEG )
		{

			if ( $creatorModel->GetPCBStep() ne "mpanel" ) {

				my $spaceX      = $creatorModel->GetSpaceX();
				my $spaceY      = $creatorModel->GetSpaceY();
				my $pcbThick    = CamJob->GetFinalPcbThick( $inCAM, $jobId, 1 );
				my $pcbType     = JobHelper->GetPcbType($jobId);
				my @boardLayers = CamJob->GetBoardBaseLayers( $inCAM, $jobId );

				use constant MINTHICK1      => 1100;                                # Use 10 mm space if less than 1100
				use constant MINTHICK2      => 600;                                 # Use 15 mm space if less than 600
				use constant SPACEMINTHICK1 => 10;                                  # Use 10 mm space if less than 1100
				use constant SPACEMINTHICK2 => 15;                                  # Use 15 mm space if less than 600

				if ( $pcbThick <= MINTHICK2 && ( $spaceX < SPACEMINTHICK2 || $spaceY < SPACEMINTHICK2 ) ) {

					# min space 15

					$self->_AddError(
									  "Malý rozestup mezi stepy",
									  "Pokud je tloušťka DPS (${pcbThick}µm) < "
										. sprintf( "%.2f", MINTHICK2 / 1000 )
										. "mm, musí být rozestup minimálně: "
										. SPACEMINTHICK2 . "mm"
					);

				}
				elsif ( $pcbThick <= MINTHICK1 && ( $spaceX < SPACEMINTHICK1 || $spaceY < SPACEMINTHICK1 ) ) {

					# min space 10

					$self->_AddError(
									  "Malý rozestup mezi stepy",
									  "Pokud je tloušťka DPS (${pcbThick}µm) < "
										. sprintf( "%.2f", MINTHICK1 / 1000 )
										. "mm, musí být rozestup minimálně: "
										. SPACEMINTHICK1 . "mm"
					);

				}
				elsif (    ( $pcbType eq EnumsGeneral->PcbType_1VFLEX || $pcbType eq EnumsGeneral->PcbType_2VFLEX )
						&& scalar( grep { $_->{"gROWlayer_type"} eq "stiffener" } @boardLayers ) == 0
						&& scalar( grep { $_->{"gROWlayer_type"} eq "coverlay" } @boardLayers ) == 0
						&& ( $spaceX < 6.5 || $spaceY < 6.5 ) )
				{

					# min space 6.5  Flex without stiffener, coveraly
					$self->_AddError( "Malý rozestup mezi stepy",
						 "Pokud je DPS typu Flex a neobsahuje stiffener ani coverlay, je třeba dodržet minimální rozestupy mezi stepy >= 6.5mm" );
				}

			}

		}
	}

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

