#-------------------------------------------------------------------------------------------#
# Description: Contain special function, which work with stackup
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupOperation;

#3th party library
use List::Util;

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::StackupBase::StackupBase';
use aliased 'Enums::EnumsIS';
use aliased 'Packages::ProductionPanel::StandardPanel::StandardBase';
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

#Return final thickness of pcb base on Cu layer number
sub GetThickByLayer {
	my $self     = shift;
	my $inCAM    = shift;
	my $pcbId    = shift;    #pcb id
	my $layer    = shift;    #layer of number. Simple c,1,2,s or v1, v2 use ENUMS::Layers
	my $noResist = shift;    #indicate id add resit

	my $thick = 0;           #total thick

	if ( HegMethods->GetBasePcbInfo($pcbId)->{"pocet_vrstev"} > 2 ) {

		my $stackup = Stackup->new( $inCAM, $pcbId );

		$thick = $stackup->GetThickByCuLayer($layer) / 1000;

		my $cuLayer = $stackup->GetCuLayer($layer);

		#test by Mira, add 80um (except cores)
		if ( $cuLayer->GetType() eq EnumsGeneral->Layers_TOP || $cuLayer->GetType() eq EnumsGeneral->Layers_BOT ) {
			$thick += 0.080;
		}

	}
	else {

		$thick = HegMethods->GetPcbMaterialThick($pcbId);

		#test by Mira, add 80um (except cores)
		$thick += 0.080;
	}

	#there are two resist from top and bottom. Top resis 40um + bottom 20um
	if ( !$noResist ) {
		$thick += 0.080;

	}

	return ( sprintf "%3.2f", ($thick) );
}

# Return if Cu layer has orientation TOP/BOT
# Orientation is based on view pcb from top
# Return string "top" or "bot"
sub GetSideByLayer {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $layerName = shift;
	my $stackup   = shift;

	unless ( defined $stackup ) {
		$stackup = Stackup->new( $inCAM, $jobId );
	}

	my $side = "";

	my $product = $stackup->GetProductByLayer($layerName);

	if ( $layerName eq $product->GetTopCopperLayer() ) {

		$side = "top";
	}
	elsif ( $layerName eq $product->GetBotCopperLayer() ) {

		$side = "bot";
	}

	return $side;
}

# If stackup contains core topmost or very bottom (Cu-core-cu-prepreg-Cu-core-cu)
# Return 1, else 0
sub OuterCore {
	my $self          = shift;
	my $inCAM         = shift;
	my $pcbId         = shift;    #pcb id
	my $inputProducts = shift;    # input products which contain outer core

	my $result = 0;

	if ( CamJob->GetSignalLayerCnt( $inCAM, $pcbId ) > 2 ) {

		my $stackup = Stackup->new( $inCAM, $pcbId );

		my @input = grep { $_->GetOuterCoreTop() || $_->GetOuterCoreBot() } $stackup->GetInputProducts();

		if ( scalar(@input) ) {
			$result = 1;
			push( @{$inputProducts}, @input ) if ( defined $inputProducts );
		}
	}

	return $result;
}

# Check if material for multilayer pcb is actually on the store
sub StackupMatInStock {
	my $self    = shift;
	my $inCAM   = shift;
	my $pcbId   = shift;    #pcb id
	my $stackup = shift;    # if not defined, stackup will e loaded
	my $errMess = shift;    # if err, missin materials in stock

	my $result = 1;

	unless ($stackup) {
		$stackup = Stackup->new( $inCAM, $pcbId );
	}

	my $pnl = StandardBase->new( $inCAM, $pcbId );

	# 1) check cores
	foreach my $m ( $stackup->GetAllCores() ) {

		# abs - because copper id can be negative (plated core)
		my @mat = HegMethods->GetCoreStoreInfo( $m->GetQId(), $m->GetId(), abs( $m->GetTopCopperLayer()->GetId() ) );

		if ( $m->GetCoreRigidType() eq StackEnums->CoreType_FLEX ) {

			# Flex material is always cut from dimension 305*456mm, test if panel height is smaller than 456mm
			# (tolerance +-3mm)
			@mat = grep { abs( $_->{"sirka"} - $pnl->W() ) <= 3 && $pnl->H() <= $_->{"hloubka"} } @mat;

		}
		else {

			# Check if material dimension are in tolerance +-2mm
			@mat = grep { abs( $_->{"sirka"} - $pnl->W() ) <= 2 && abs( $_->{"hloubka"} - $pnl->H() ) <= 2 } @mat;

		}

		if ( scalar(@mat) == 0 ) {

			$result = 0;
			$$errMess .=
			    "- Material: "
			  . $m->GetType() . " - "
			  . $m->GetTextType() . ","
			  . $m->GetText() . " - "
			  . $m->GetTopCopperLayer()->GetText() . " ("
			  . $pnl->W() . "mm x "
			  . $pnl->H()
			  . "mm) is not in  IS stock evidence\n";

		}
		else {

			if ( $mat[0]->{"stav_skladu"} == 0 ) {

				$result = 0;
				$$errMess .= "- Material quantity of " . $mat[0]->{"nazev_mat"} . "  is 0m2 in IS stock\n";

			}
		}
	}

	# 2) Check prepregs
	foreach my $m ( map { $_->GetAllPrepregs() } grep { $_->GetType() eq Enums->MaterialType_PREPREG } $stackup->GetAllLayers() ) {

		my $prepregW = undef;
		my $prepregH = undef;

		my @mat = ();

		if ( $pnl->IsStandard() ) {

			$prepregW = $pnl->GetStandard()->PrepregW();
			$prepregH = $pnl->GetStandard()->PrepregH();

			if ( $m->GetTextType() =~ /49np|no.*flow/i ) {

				@mat = HegMethods->GetPrepregStoreInfo( $m->GetQId(), $m->GetId(), undef, undef, 1 );

				# Flex prepreg material is always cut from dimension 305*456mm, test if panel height is smaller than 456mm
				# (tolerance +-3mm)
				@mat = grep { abs( $_->{"sirka"} - $prepregW ) <= 3 && $prepregH <= $_->{"hloubka"} } @mat;

			}
			else {

				@mat = HegMethods->GetPrepregStoreInfo( $m->GetQId(), $m->GetId() );

				# Check if material dimension are in tolerance +-2mm for width
				# Check if material dimension are in tolerance +-10mm for height 
				# (we use sometimes shorter version -10mm of standard prepregs because of stretching prepregs by temperature and pressure)
				@mat = grep { abs( $_->{"sirka"} - $prepregW ) <= 2 && abs( $_->{"hloubka"} - $prepregH ) <= 10 } @mat;

			}

		}

		if ( scalar(@mat) == 0 ) {

			$result = 0;
			$$errMess .=
			    "- Material: "
			  . $m->GetType() . " - "
			  . $m->GetTextType() . ","
			  . $m->GetText() . " ("
			  . $prepregW . "mm x "
			  . $prepregH
			  . "mm) is not in  IS stock evidence\n";

		}
		else {

			if ( $mat[0]->{"stav_skladu"} == 0 ) {

				$result = 0;
				$$errMess .= "- Material quantity of " . $mat[0]->{"nazev_mat"} . "  is 0m2 in IS stock\n";

			}
		}
	}

	return $result;
}

# Return array of packages created from stackup product joined by NoFlwo prepreg
# Couple contain top + bot stackup products + type of cores inside each product
# Each item contain keys:
# - pTop = top stackup product
# - pTopCoreType =  type of cores inside each product
# - pBot = bot stackup product
# - pBotCoreType =  type of cores inside each product
sub GetJoinedFlexRigidProducts {
	my $self    = shift;
	my $inCAM   = shift;
	my $pcbId   = shift;    #pcb id
	my $stackup = shift;    # if not defined, stackup will e loaded

	my $result = 1;

	unless ($stackup) {
		$stackup = Stackup->new($inCAM, $pcbId);
	}

	my @laminatePckgsInf = ();
 
	my $firstCore;
	my $secondCore;

	foreach my $pressP ( $stackup->GetPressProducts(1) ) {

		
		my @layers = $pressP->GetLayers();

		for ( my $i = 1 ; $i < scalar(@layers) - 1 ; $i++ ) {

			my $lTypePrev = $layers[ $i - 1 ]->GetType();
			my $lTypeNext = $layers[ $i + 1 ]->GetType();

			my $lType = $layers[$i]->GetType();
			my $lData = $layers[$i]->GetData();

			# Identify two products between Noflow prepreg
			if (    $lType eq StackEnums->ProductL_MATERIAL
				 && $lData->GetType() eq StackEnums->MaterialType_PREPREG
				 && $lData->GetIsNoFlow()
				 && $lTypePrev eq StackEnums->ProductL_PRODUCT
				 && $lTypeNext eq StackEnums->ProductL_PRODUCT )
			{

				my %infJoin = ();

				# top product
				my $topP = $layers[ $i - 1 ]->GetData();
				$infJoin{"pTop"} = $topP;

				# search for core
				if ( $topP->GetProductType() eq StackEnums->Product_INPUT ) {
					$infJoin{"pTopCoreType"} = $topP->GetCoreRigidType();
				}
				elsif ( $topP->GetProductType() eq StackEnums->Product_PRESS ) {
					my $frstInput = ( $topP->GetLayers( StackEnums->ProductL_PRODUCT ) )[0];
					$infJoin{"pTopCoreType"} = $frstInput->GetCoreRigidType();
				}

				# Bot product
				my $botP = $layers[ $i +1 ]->GetData();
				$infJoin{"pBot"} = $botP;

				# search for core
				if ( $botP->GetProductType() eq StackEnums->Product_INPUT ) {
					$infJoin{"pBotCoreType"} = $botP->GetCoreRigidType();
				}
				elsif ( $botP->GetProductType() eq StackEnums->Product_PRESS ) {
					my $frstInput = ( $botP->GetLayers( StackEnums->ProductL_PRODUCT ) )[0];
					$infJoin{"pBotCoreType"} = $frstInput->GetCoreRigidType();
				}

				push( @laminatePckgsInf, \%infJoin );

			}

		}
	}

	return @laminatePckgsInf;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Stackup::StackupOperation';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $mes   = "";

	#	my $side;
	my @package = StackupOperation->GetJoinedFlexRigidProducts($inCAM, "d266089");
	#
	#	my @package2 = StackupOperation->GetJoinedFlexRigidProducts2("d222777");

	#print StackupOperation->StackupMatInStock( $inCAM, "d251561", undef, \$mes );

	print @package;

}

1;
