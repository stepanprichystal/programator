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
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Packages::ProductionPanel::PanelDimension';

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

# Return array of packages created from stackup product joined by NoFlwo prepreg
# Couple contain top + bot stackup products + type of cores inside each product
# Each item contain keys:
# - pTop = top stackup product
# - pTopCoreType =  type of cores inside each product
# - pBot = bot stackup product
# - pBotCoreType =  type of cores inside each product
# - layersNoflow = layers data of noflow prepregs between packages
sub GetJoinedFlexRigidProducts {
	my $self    = shift;
	my $inCAM   = shift;
	my $pcbId   = shift;    #pcb id
	my $stackup = shift;    # if not defined, stackup will e loaded

	my $result = 1;

	unless ($stackup) {
		$stackup = Stackup->new( $inCAM, $pcbId );
	}

	my @laminatePckgsInf = ();

	my $firstCore;
	my $secondCore;

	foreach my $pressP ( $stackup->GetPressProducts(1) ) {

		my @layers = $pressP->GetLayers();

		for ( my $i = 0 ; $i < scalar(@layers) - 1 ; $i++ ) {

			my $lType = $layers[$i]->GetType();

			next unless ( $lType eq StackEnums->ProductL_PRODUCT );
			
			my $topP = $layers[$i]->GetData();
			my $botP = undef;

			last if ( $i + 1 == scalar(@layers) );
			$i++;

			# 1) Check if next layers up to next product are noflow prepregs

			my $nextProduct = undef;
			my @noFLow      = ();

			for ( ; $i < scalar(@layers) ; $i++ ) {

				if (    $layers[$i]->GetType() eq StackEnums->ProductL_MATERIAL
					 && $layers[$i]->GetData()->GetType() eq StackEnums->MaterialType_PREPREG
					 && $layers[$i]->GetData()->GetIsNoFlow() )
				{
					push( @noFLow, $layers[$i]->GetData() );
				}
				else {
					last;
				}
			}

			# 2) Check if next layer is product
			if ( scalar(@noFLow) > 0 && $layers[$i]->GetType() eq StackEnums->ProductL_PRODUCT ) {
				
				$botP = $layers[$i]->GetData();

				# We found noflow prepregs between two products
				my %infJoin = ();

				# top product
				
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
				
				$infJoin{"pBot"} = $botP;

				# search for core
				if ( $botP->GetProductType() eq StackEnums->Product_INPUT ) {
					$infJoin{"pBotCoreType"} = $botP->GetCoreRigidType();
				}
				elsif ( $botP->GetProductType() eq StackEnums->Product_PRESS ) {
					my $frstInput = ( $botP->GetLayers( StackEnums->ProductL_PRODUCT ) )[0];
					$infJoin{"pBotCoreType"} = $frstInput->GetCoreRigidType();
				}

				# Noflow Material layer
				$infJoin{"layersNoflow"} = \@noFLow;

				push( @laminatePckgsInf, \%infJoin );
				
				$i--;

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
	use aliased 'Packages::CAMJob::Dim::JobDim';

	my $inCAM = InCAM->new();
	my $mes   = "";

	my $side;
	my @packages = StackupOperation->GetJoinedFlexRigidProducts( $inCAM, "d321505" );

	#	my $orderId       = "d272796-01";
	#	my $inf           = HegMethods->GetInfoAfterStartProduce($orderId);
	#	my %dimsPanelHash = JobDim->GetDimension( $inCAM, "d272796" );
	#	my %lim           = CamJob->GetProfileLimits2( $inCAM, "d272796", "panel" );
	#
	#	my $pArea = ( $lim{"xMax"} - $lim{"xMin"} ) * ( $lim{"yMax"} - $lim{"yMin"} ) / 1000000;
	#	my $area = $inf->{"kusy_pozadavek"} / $dimsPanelHash{"nasobnost"} * $pArea;
	#
	#	 MaterialInfo->StackupMatInStock( $inCAM, "d272796", undef,$area, \$mes );

	print @packages;

}

1;
