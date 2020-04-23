#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::ProcessStackup::LamItemBuilders::LamItemBuilderBase;

#3th party library
use strict;
use warnings;
use Time::localtime;
use Storable qw(dclone);
use List::Util qw(first);

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::CAMJob::Stackup::ProcessStackup::Enums';
use aliased 'Packages::CAMJob::Stackup::ProcessStackup::EnumsStyle';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	return $self;
}

# Build stackup product layer for Multilayer PCB
sub _ProcessStckpProduct {
	my $self      = shift;
	my $lam       = shift;
	my $stckpMngr = shift;
	my $IProduct  = shift;

	my $itemType = undef;
	my $itemId   = undef;

	if ( $IProduct->GetProductType() eq StackEnums->Product_INPUT ) {

		$itemType = Enums->ItemType_MATPRODUCTCORE;
		$itemId   = "P" . $IProduct->GetId();

	}
	elsif ( $IProduct->GetProductType() eq StackEnums->Product_PRESS ) {

		$itemType = Enums->ItemType_MATPRODUCTDPS;
		$itemId   = $IProduct->GetId() . "xLis";
	}

	# LAYER: product
	my $curProducNum = ( $lam->GetProductId() =~ /^P(\d+)$/i )[0];
	my $product = ( $curProducNum - 1 ) < 1 ? "" : "P" . ( $curProducNum - 1 );

	my $item = $lam->AddItem( $itemId, $itemType, EnumsStyle->GetItemTitle($itemType), $itemId, undef, undef, $IProduct->GetThick() );

	$lam->AddChildItem( $item, "top", $itemId . "productTop", Enums->$itemType, "TOP", undef, undef, undef, undef );
	$lam->AddChildItem( $item, "bot", $itemId . "productBot", Enums->$itemType, "BOT", undef, undef, undef, undef );

}

# Build stackup material layer for Multilayer PCB
sub _ProcessStckpMatLayer {
	my $self       = shift;
	my $lam        = shift;
	my $stckpMngr  = shift;
	my $stckpLayer = shift;

	if ( $stckpLayer->GetType() eq StackEnums->MaterialType_COPPER ) {

		my $itemType = undef;

		if ( $stckpLayer->GetIsFoil() ) {
			$itemType = Enums->ItemType_MATCUFOIL;
		}
		else {
			$itemType = Enums->ItemType_MATCUCORE;
		}

		my $layerISRef = $stckpMngr->GetCuFoilISRef($stckpLayer);
		my $item       = $lam->AddItem( $layerISRef, $itemType,
								  EnumsStyle->GetItemTitle($itemType),
								  $stckpLayer->GetCopperName(),
								  $stckpLayer->GetTextType(),
								  $stckpLayer->GetText(),
								  $stckpLayer->GetThick() );

	}
	elsif ( $stckpLayer->GetType() eq StackEnums->MaterialType_PREPREG ) {

		foreach my $prpgLayer ( $stckpLayer->GetAllPrepregs() ) {

			my $itemType   = undef;
			my $valExtraId = undef;

			if ( $stckpLayer->GetIsNoFlow() ) {

				$itemType = Enums->ItemType_MATFLEXPREPREG;
				if ( $stckpLayer->GetNoFlowType() eq StackEnums->NoFlowPrepreg_P1 ) {
					$valExtraId = "P1";
				}
				elsif ( $stckpLayer->GetNoFlowType() eq StackEnums->NoFlowPrepreg_P2 ) {
					$valExtraId = "P2";
				}
			}
			else {
				$itemType = Enums->ItemType_MATPREPREG;
			}

			my $layerISRef = $stckpMngr->GetPrpgISRef($prpgLayer);
			my $item = $lam->AddItem(
									  $layerISRef,           $itemType, EnumsStyle->GetItemTitle($itemType),
									  $valExtraId,           $prpgLayer->GetTextType(),
									  $prpgLayer->GetText(), $prpgLayer->GetThick()
			);
		}

	}
	elsif ( $stckpLayer->GetType() eq StackEnums->MaterialType_CORE ) {

		my $layerISRef = $stckpMngr->GetCoreISRef($stckpLayer);
		my $topCuLayer = $stckpLayer->GetTopCopperLayer();
		my $botCuLayer = $stckpLayer->GetBotCopperLayer();

		my $itemType = undef;

		if ( $stckpLayer->GetCoreRigidType() eq StackEnums->CoreType_RIGID ) {
			$itemType = Enums->ItemType_MATCORE;
		}
		elsif ( $stckpLayer->GetCoreRigidType() eq StackEnums->CoreType_FLEX ) {
			$itemType = Enums->ItemType_MATFLEXCORE;
		}

		my $item = $lam->AddItem( $layerISRef, $itemType,
								  EnumsStyle->GetItemTitle($itemType),
								  "J" . $stckpLayer->GetCoreNumber(),
								  $stckpLayer->GetTextType(),
								  $stckpLayer->GetText(),
								  $stckpLayer->GetThick() );

		$lam->AddChildItem( $item, $layerISRef, Enums->ItemType_MATCUCORE, $topCuLayer->GetCopperName(), undef, undef, undef, undef );
		$lam->AddChildItem( $item, $layerISRef, Enums->ItemType_MATCUCORE, $botCuLayer->GetCopperName(), undef, undef, undef, undef );

	}
	elsif ( $stckpLayer->GetType() eq StackEnums->MaterialType_COVERLAY ) {

		my $cuLayer     = $stckpLayer->GetCoveredCopperName();
		my %lPars       = JobHelper->ParseSignalLayerName($cuLayer);
		my $cuLayerSide = $stckpMngr->GetStackup()->GetSideByCuLayer( $lPars{"sourceName"}, $lPars{"outerCore"}, $lPars{"plugging"} );

		my $cvrlInfo = $stckpMngr->GetCvrlInfo($stckpLayer);

		my $item = $lam->AddItem( $cvrlInfo->{"cvrlISRef"},
								  Enums->ItemType_MATCOVERLAY,
								  EnumsStyle->GetItemTitle( Enums->ItemType_MATCOVERLAY ),
								  $cuLayer,
								  $cvrlInfo->{"cvrlKind"},
								  $cvrlInfo->{"cvrlText"},
								  $cvrlInfo->{"cvrlThick"} );
		$lam->AddChildItem(
							$item, ( $cuLayerSide eq "top" ? "bot" : "top" ),
							$cvrlInfo->{"cvrlISRef"},                                    Enums->ItemType_MATCVRLADHESIVE,
							EnumsStyle->GetItemTitle( Enums->ItemType_MATCVRLADHESIVE ), undef,
							$cvrlInfo->{"adhesiveKind"},                                 $cvrlInfo->{"adhesiveText"},
							$cvrlInfo->{"adhesiveThick"}
		);

	}
	else {

		die "Layer type: " . $stckpLayer->GetType() . " is not implemented";
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

