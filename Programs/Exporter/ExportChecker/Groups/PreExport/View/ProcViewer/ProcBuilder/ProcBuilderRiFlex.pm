
#-------------------------------------------------------------------------------------------#
# Description: Builder of procedure for 1v +2v PCB
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcBuilder::ProcBuilderRiFlex;
use base('Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcBuilder::ProcBuilderBase');

use Class::Interface;
&implements('Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcBuilder::IProcBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Enums';
use aliased 'Packages::Stackup::StackupOperation';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;
}

sub Build {
	my $self          = shift;
	my $procViewerFrm = shift;
	my $signalLayers  = shift;
	my $stackup       = shift;

	$self->__BuildPressProducts( $procViewerFrm, $stackup );

	$self->__BuildInputProducts( $procViewerFrm, $stackup );

	$procViewerFrm->HideControls();

}

sub __BuildPressProducts {
	my $self          = shift;
	my $procViewerFrm = shift;
	my $stackup       = shift;

	$procViewerFrm->AddCategoryTitle( StackEnums->Product_PRESS, "Pressing" );

	my @products = reverse( $stackup->GetPressProducts(1) );

	foreach my $p (@products) {

		my $plugging     = $p->GetPlugging();
		my $outerCoreTop = $p->GetOuterCoreTop();
		my $outerCoreBot = $p->GetOuterCoreBot();

		# Create group
		my $g = $procViewerFrm->AddGroup( $p->GetId(), StackEnums->Product_PRESS );

		# Create sub group
		my $subG = $g->AddSubGroup( $p->GetId(), StackEnums->Product_PRESS );

		foreach my $productL ( $p->GetLayers() ) {

			my $lType      = $productL->GetType();
			my $lData      = $productL->GetData();
			my $extraPress = scalar( grep { $_ eq $productL } $p->GetExtraPressLayers() ) ? 1 : 0;

			if ( $lType eq StackEnums->ProductL_PRODUCT ) {

				# If product has outer core TOP/BOT and copper layer
				

				if ( $lData->GetOuterCoreTop() ) {
					
					 my $topCuThick = $stackup->GetCuLayer($p->GetTopCopperLayer())->GetThick();
					
					$subG->AddCopperRow( $p->GetTopCopperLayer(), $outerCoreTop, 0, 0, $topCuThick );
					$subG->AddCopperRow( $p->GetTopCopperLayer(), $outerCoreTop, $plugging, 0, $topCuThick ) if ($plugging);
				}

				$subG->AddProductRow( $lData->GetId(), $lData->GetProductType() );

				if ( $lData->GetOuterCoreBot() ) {
					
					 my $botCuThick = $stackup->GetCuLayer($p->GetBotCopperLayer())->GetThick();
					
					$subG->AddCopperRow( $p->GetBotCopperLayer(), $outerCoreBot, $plugging, 0, $botCuThick ) if ($plugging);
					$subG->AddCopperRow( $p->GetBotCopperLayer(), $outerCoreBot, 0, 0, $botCuThick );

				}

			}
			elsif ( $lType eq StackEnums->ProductL_MATERIAL ) {

				if ( $lData->GetType() eq StackEnums->MaterialType_COPPER ) {

				
					my $cuThick = $lData->GetThick();

					if ( $lData->GetCopperName() eq $p->GetTopCopperLayer() ) {

						$subG->AddCopperRow( $lData->GetCopperName(), $outerCoreTop, 0, 0, $cuThick );
						$subG->AddCopperRow( $lData->GetCopperName(), $outerCoreTop, 1, 0, $cuThick ) if ($plugging);

					}
					elsif ( $lData->GetCopperName() eq $p->GetBotCopperLayer() ) {

						$subG->AddCopperRow( $lData->GetCopperName(), $outerCoreBot, 1, 0, $cuThick ) if ($plugging);
						$subG->AddCopperRow( $lData->GetCopperName(), $outerCoreBot, 0, 0, $cuThick );
					}
				}
				elsif ( $lData->GetType() eq StackEnums->MaterialType_PREPREG ) {

					if ( $lData->GetIsNoFlow() && $lData->GetIsCoverlayIncl() ) {
						$subG->AddPrepregCoverlayRow($extraPress);
					}
					else {
						$subG->AddPrepregRow($extraPress);
					}

				}
				elsif ( $lData->GetType() eq StackEnums->MaterialType_CORE ) {
					$subG->AddCoreRow();

				}
				elsif ( $lData->GetType() eq StackEnums->MaterialType_COVERLAY ) {
					$subG->AddCoverlayRow($extraPress);
				}
			}
		}
	}

}

sub __BuildInputProducts {
	my $self          = shift;
	my $procViewerFrm = shift;
	my $stackup       = shift;

	$procViewerFrm->AddCategoryTitle( StackEnums->Product_INPUT, "Input semi-products" );

	my @products = $stackup->GetInputProducts();

	foreach my $p (@products) {

		# Create group
		my $g = $procViewerFrm->AddGroup( $p->GetId(), StackEnums->Product_INPUT );

		# Add sub groups for this gorup
		my @nestProducts = ( map { $_->GetData() } $p->GetChildProducts() );

		# If parent product has Product layer type of material, add it to list
		if ( grep { $_->GetType() eq StackEnums->ProductL_MATERIAL } $p->GetLayers() ) {

			unshift( @nestProducts, $p );
		}

		foreach my $nestP (@nestProducts) {

			my $plugging     = $nestP->GetPlugging();
			my $outerCoreTop = $nestP->GetOuterCoreTop();
			my $outerCoreBot = $nestP->GetOuterCoreBot();

			my $subG = $g->AddSubGroup( $nestP->GetId(), StackEnums->Product_INPUT );

			foreach my $productL ( $nestP->GetLayers() ) {

				my $lType = $productL->GetType();
				my $lData = $productL->GetData();

				if ( $lType eq StackEnums->ProductL_PRODUCT ) {

					$subG->AddProductRow( $lData->GetId(), $lData->GetProductType() );

				}
				elsif ( $lType eq StackEnums->ProductL_MATERIAL ) {

					if ( $lData->GetType() eq StackEnums->MaterialType_COPPER ) {

						my $cuFoil  = $lData->GetIsFoil();
						my $cuThick = $lData->GetThick();

						if ( $lData->GetCopperName() eq $nestP->GetTopCopperLayer() ) {

							$subG->AddCopperRow( $lData->GetCopperName(), $outerCoreTop, $plugging, $cuFoil, $cuThick );
							$subG->AddCopperRow( $lData->GetCopperName(), $outerCoreTop, $plugging, $cuFoil, $cuThick ) if ($plugging);

						}
						elsif ( $lData->GetCopperName() eq $nestP->GetBotCopperLayer() ) {

							$subG->AddCopperRow( $lData->GetCopperName(), $outerCoreBot, $plugging, $cuFoil, $cuThick ) if ($plugging);
							$subG->AddCopperRow( $lData->GetCopperName(), $outerCoreBot, $plugging, $cuFoil, $cuThick );
						}
					}
					elsif ( $lData->GetType() eq StackEnums->MaterialType_PREPREG ) {

						if ( $lData->GetIsNoFlow() && $lData->GetIsCoverlayIncl() ) {
							$subG->AddPrepregCoverlayRow();
						}
						else {
							$subG->AddPrepregRow();
						}

					}
					elsif ( $lData->GetType() eq StackEnums->MaterialType_CORE ) {
						$subG->AddCoreRow();

					}
					elsif ( $lData->GetType() eq StackEnums->MaterialType_COVERLAY ) {
						$subG->AddCoverlayRow();
					}
				}
			}
		}
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

