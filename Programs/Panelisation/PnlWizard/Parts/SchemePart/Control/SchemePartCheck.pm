
#-------------------------------------------------------------------------------------------#
# Description: Check class for checking before processing panel creator
# Class should contain OnItemResult event
# Class must implement ICheckClass
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::SchemePart::Control::SchemePartCheck;
use base 'Programs::Panelisation::PnlWizard::Parts::PartCheckBase';

use Class::Interface;

&implements('Packages::InCAMHelpers::AppLauncher::PopupChecker::ICheckClass');

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'Helpers::JobHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Packages::Stackup::StackupBase::StackupBase';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::CAMJob::Scheme::SchemeCheck';
use aliased 'Packages::Other::CustomerNote';
use aliased 'Enums::EnumsCAM';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $self  = {};

	$self = $class->SUPER::new(@_);
	bless $self;

	# PROPERTIES

	$self->{"inCAM"} = $inCAM;
	$self->{"jobId"} = $jobId;

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

	my $scheme        = $creatorModel->GetScheme();                 # All model should have GetScheme Method
	my $specLayerFill = $creatorModel->GetSignalLayerSpecFill();    #

	# Scheme name check
	{
		my $custInfo = HegMethods->GetCustomerInfo($jobId);
		my $custNote = CustomerNote->new( $custInfo->{"reference_subjektu"} );

		unless ( SchemeCheck->CustPanelSchemeOk( $inCAM, $jobId, $scheme, $custNote ) ) {

			my @custSchemas = $custNote->RequiredSchemas();
			my $custTxt = join( "; ", @custSchemas );

			$self->_AddError( "Zákaznické schéma",
							  "Zákazník požaduje ve stepu: \"mpanel\" vlastní schéma: \"$custTxt\", ale je vybrané schéma: \"$scheme\"." );
		}
	}

	# More customer schemas
	{
		my $custInfo    = HegMethods->GetCustomerInfo($jobId);
		my $custNote    = CustomerNote->new( $custInfo->{"reference_subjektu"} );
		my @custSchemas = $custNote->RequiredSchemas();

		if ( scalar(@custSchemas) ) {

			my $schTxt = join( "; ", @custSchemas );
			$self->_AddWarning( "Zákaznické schéma",
								"Zákazník má uloženo více vlastních schémat (${schTxt}). Je vybrané scháma ($scheme) to správné?." )
			  ;
		}
	}

	# If stiffener, check if special fill is empty

	my @stiff = grep { $_->{"gROWlayer_type"} eq "stiffener" } CamJob->GetBoardBaseLayers( $inCAM, $jobId );
	foreach my $stiffL (@stiff) {

		my $sigL = ( $stiffL->{"gROWname"} =~ /^\w+([csv]\d*)$/ )[0];

		if ( defined $specLayerFill->{$sigL} && $specLayerFill->{$sigL} ne EnumsCAM->AttSpecLayerFill_EMPTY ) {

			$self->_AddError(
							  "Mpanel - výplň",
							  "Pokud DPS obsauje stiffner, mpanel nesmí obsahovat ze strany stiffeneru v signálové vrstvě ("
								. $sigL
								. ") šrafování."
								. " Nastav speciální vylití pro vrstvu ${sigL} na \""
								. EnumsCAM->AttSpecLayerFill_EMPTY . "\"."
			);

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

	my $scheme = $creatorModel->GetScheme();    # All model should have GetScheme Method

	# X) Check if semihybrid, if proper scheme is selected
	{

		my $errMess = "";

		unless ( SchemeCheck->ProducPanelSchemeOk( $inCAM, $jobId, $scheme, undef, \$errMess ) ) {
			my $extarInfo = "";

			$self->_AddError( "Špatné schéma", "Je vybrané špatné schéma: $scheme" . ( $errMess ne "" ? "Detail chyby:\n$errMess" : "" ) );

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

	# X) Check proper pattern fill at inenr layers
	my $specLayerFill = $creatorModel->GetSignalLayerSpecFill();
	my @inner = CamJob->GetSignalLayerNames( $inCAM, $jobId, 1, 0 );

	if ( scalar(@inner) ) {

		my $stackup = Stackup->new( $inCAM, $jobId );

		my @inner =
		  grep { $_->GetType() eq StackEnums->MaterialType_COPPER && !$_->GetIsFoil() && $_->GetCopperName() =~ /^v\d+/ } $stackup->GetAllLayers();

		foreach my $cuLayer (@inner) {

			my $cuLayerName = $cuLayer->GetCopperName();
			my $specFill    = $specLayerFill->{$cuLayerName};

			my $core     = $stackup->GetCoreByCuLayer( $cuLayer->GetCopperName() );
			my %lPars    = JobHelper->ParseSignalLayerName( $cuLayer->GetCopperName() );
			my $IProduct = $stackup->GetProductByLayer( $lPars{"sourceName"}, $lPars{"outerCore"}, $lPars{"plugging"} );

			if ( $cuLayer->GetUssage() == 0 && $specFill ne EnumsCAM->AttSpecLayerFill_EMPTY ) {

				$self->_AddError(
								  "Špatná výplň okolí",
								  "Pokud vnitřní vrstva ($cuLayerName) má 0% využití, musí být typ vylití nastaven na: "
									. EnumsCAM->AttSpecLayerFill_EMPTY
				);

			}
			elsif ( $cuLayer->GetUssage() < 0.05 && $specFill ne EnumsCAM->AttSpecLayerFill_EMPTY ) {

				$self->_AddWarning(
					"Špatná výplň okolí",
					"Není vnitšní vrstva: $cuLayerName prázdná? "
					  . "Pokud neobsahuje motiv, nastav využití vrstvy ve stackupu na 0% (značky v okolí do využití nepočítáme) a typ vylití na: "
					  . EnumsCAM->AttSpecLayerFill_EMPTY
				);

			}
			elsif ( $cuLayer->GetUssage() > 0 && $specFill eq EnumsCAM->AttSpecLayerFill_EMPTY ) {

				$self->_AddWarning(
									"Špatná výplň okolí",
									"Pokud vnitřní vrstva ($cuLayerName) má  využití větší jak 0%, neměl by být typ vylití nastaven na: "
									  . EnumsCAM->AttSpecLayerFill_EMPTY
									  . ". Pokud jsou v okolí jen naváděcí značky atd, tak ty zanedbáváme a ve stackupu by "
				);

			}
			elsif (    $cuLayer->GetUssage() > 0
					&& $core->GetCoreRigidType() eq StackEnums->CoreType_FLEX
					&& $specFill ne EnumsCAM->AttSpecLayerFill_SOLID100PCT )
			{
				$self->_AddError(
								  "Špatná výplň okolí",
								  "Pokud vnitřní vrstva ($cuLayerName) je na flex jádře, musí být typ vylití nastaveno na: "
									. EnumsCAM->AttSpecLayerFill_SOLID100PCT
									. ". Důvodem je, že je jádro rozměrově stabilnější a prepreg lépe vyplní mezery v Cu."
				);
			}
			elsif ( ( ( $cuLayer->GetThick() >= 35 && $IProduct->GetIsPlated() ) || $cuLayer->GetThick() >= 70 )
					&& $specFill ne EnumsCAM->AttSpecLayerFill_CIRCLE80PCT )
			{
				$self->_AddError(
						  "Špatná výplň okolí",
						  "Pokud vnitřní vrstva ($cuLayerName) včetně nakovení má Cu vyšší než 70µm, musí být typ vylití nastaveno na: "
							. EnumsCAM->AttSpecLayerFill_CIRCLE80PCT
				);
			}

		}
	}

}

