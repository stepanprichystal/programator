
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
use aliased 'CamHelpers::CamStep';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Packages::Stackup::StackupBase::StackupBase';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::CAMJob::Scheme::SchemeCheck';
use aliased 'Packages::Other::CustomerNote';
use aliased 'Enums::EnumsCAM';
use aliased 'Programs::Panelisation::PnlWizard::Enums';

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
	my $PnlType   = shift;    # Panelisation type
	my $partModel = shift;    # Part model

	if ( $PnlType eq PnlCreEnums->PnlType_CUSTOMERPNL ) {

		$self->__CheckCustomerPanel($partModel);

	}
	elsif ( $PnlType eq PnlCreEnums->PnlType_PRODUCTIONPNL ) {

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

			$self->_AddError( "Z??kaznick?? sch??ma",
							  "Z??kazn??k po??aduje ve stepu: \"mpanel\" vlastn?? sch??ma: \"$custTxt\", ale je vybran?? sch??ma: \"$scheme\"." );
		}
	}

	# More customer schemas
	{
		my $custInfo    = HegMethods->GetCustomerInfo($jobId);
		my $custNote    = CustomerNote->new( $custInfo->{"reference_subjektu"} );
		my @custSchemas = $custNote->RequiredSchemas();

		if ( scalar(@custSchemas) > 1 ) {

			my $schTxt = join( "; ", @custSchemas );
			$self->_AddWarning( "Z??kaznick?? sch??ma",
								"Z??kazn??k m?? ulo??eno v??ce vlastn??ch sch??mat (${schTxt}). Je vybran?? sch??ma ($scheme) to spr??vn???." );
		}
	}

	# If stiffener, check if special fill is empty

	my @stiff = grep { $_->{"gROWlayer_type"} eq "stiffener" } CamJob->GetBoardBaseLayers( $inCAM, $jobId );
	foreach my $stiffL (@stiff) {

		my $sigL = ( $stiffL->{"gROWname"} =~ /^\w+([csv]\d*)$/ )[0];

		if ( defined $specLayerFill->{$sigL} && $specLayerFill->{$sigL} ne EnumsCAM->AttSpecLayerFill_EMPTY ) {

			$self->_AddError(
							  "Mpanel - v??pl??",
							  "Pokud DPS obsauje stiffner, mpanel nesm?? obsahovat ze strany stiffeneru v sign??lov?? vrstv?? ("
								. $sigL
								. ") ??rafov??n??."
								. " Nastav speci??ln?? vylit?? pro vrstvu ${sigL} na \""
								. EnumsCAM->AttSpecLayerFill_EMPTY . "\"."
			);

		}
	}

	# X) Check if schema match with frame width (only if scheme name contain number which indicate frame border width)
	{
		my $scheme = $creatorModel->GetScheme();    # All model should have GetScheme Method
#		if ( $scheme =~ m/_(\d+)/ ) {

#			my $schFrameW = $1;
# 
# 			my $sizeCreatorModel = $self->_GetSelCreatorModelByPartId(Enums->Part_PNLSIZE);
# 
#			my $BL = $sizeCreatorModel->GetBorderLeft();
#			my $BR = $sizeCreatorModel->GetBorderRight();
#			my $BT = $sizeCreatorModel->GetBorderTop();
#			my $BB = $sizeCreatorModel->GetBorderBot();
#
#			if ( $schFrameW != $BL && $schFrameW != $BR && $schFrameW != $BT && $schFrameW != $BB ) {
#
#				$self->_AddWarning(
#									"Sch??ma",
#									"Je sch??ma: ${scheme} spr??vn??? "
#									  . "Obsahuje v n??zvu: ${schFrameW} co?? indikuje ??????ku okol?? panelu, kter?? v??ak nebyla v panelu dohled??na"
#				);
#			}
#
#		}

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

			$self->_AddError( "??patn?? sch??ma", "Je vybran?? ??patn?? sch??ma: $scheme" . ( $errMess ne "" ? "Detail chyby:\n$errMess" : "" ) );

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

	# X) Check if schema is not empty
	my $scheme = $creatorModel->GetScheme();    # All model should have GetScheme Method

	if ( !defined $scheme || $scheme eq "" ) {

		$self->_AddError(
						  "Chb??j??c?? sch??ma",
						  "Nen?? vybran?? ????dn?? sch??ma. "
							. "Pokud je pot??eba panel bez sch??matu, aktivuj volbu \"Preview\" v??ude krom?? sch??matu pro vytvo??en?? panelu a pak tl. \"Leave as it is\""
		);
	}

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
								  "??patn?? v??pl?? okol??",
								  "Pokud vnit??n?? vrstva ($cuLayerName) m?? 0% vyu??it??, mus?? b??t typ vylit?? nastaven na: "
									. EnumsCAM->AttSpecLayerFill_EMPTY
				);

			}
			elsif ( $cuLayer->GetUssage() < 0.05 && $specFill ne EnumsCAM->AttSpecLayerFill_EMPTY ) {

				$self->_AddWarning(
					"??patn?? v??pl?? okol??",
					"Nen?? vnit??n?? vrstva: $cuLayerName pr??zdn??? "
					  . "Pokud neobsahuje motiv, nastav vyu??it?? vrstvy ve stackupu na 0% (zna??ky v okol?? do vyu??it?? nepo????t??me) a typ vylit?? na: "
					  . EnumsCAM->AttSpecLayerFill_EMPTY
				);

			}
			elsif ( $cuLayer->GetUssage() > 0 && $specFill eq EnumsCAM->AttSpecLayerFill_EMPTY ) {

				$self->_AddWarning(
									"??patn?? v??pl?? okol??",
									"Pokud vnit??n?? vrstva ($cuLayerName) m??  vyu??it?? v??t???? jak 0%, nem??l by b??t typ vylit?? nastaven na: "
									  . EnumsCAM->AttSpecLayerFill_EMPTY
									  . ". Pokud jsou v okol?? jen nav??d??c?? zna??ky atd, tak ty zanedb??v??me a ve stackupu by "
				);

			}
			elsif (    $cuLayer->GetUssage() > 0
					&& $core->GetCoreRigidType() eq StackEnums->CoreType_FLEX
					&& $specFill ne EnumsCAM->AttSpecLayerFill_SOLID100PCT )
			{
				$self->_AddError(
								  "??patn?? v??pl?? okol??",
								  "Pokud vnit??n?? vrstva ($cuLayerName) je na flex j??d??e, mus?? b??t typ vylit?? nastaveno na: "
									. EnumsCAM->AttSpecLayerFill_SOLID100PCT
									. ". D??vodem je, ??e je j??dro rozm??rov?? stabiln??j???? a prepreg l??pe vypln?? mezery v Cu."
				);
			}
			elsif ( ( ( $cuLayer->GetThick() >= 35 && $IProduct->GetIsPlated() ) || $cuLayer->GetThick() >= 70 )
					&& $specFill ne EnumsCAM->AttSpecLayerFill_CIRCLE80PCT )
			{
				$self->_AddError(
						  "??patn?? v??pl?? okol??",
						  "Pokud vnit??n?? vrstva ($cuLayerName) v??etn?? nakoven?? m?? Cu vy?????? ne?? 70??m, mus?? b??t typ vylit?? nastaveno na: "
							. EnumsCAM->AttSpecLayerFill_CIRCLE80PCT
				);
			}

		}
	}

}

