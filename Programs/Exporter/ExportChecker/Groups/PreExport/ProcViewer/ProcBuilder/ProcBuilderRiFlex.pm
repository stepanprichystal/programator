
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

	$self->__BuildInputProducts( $procViewerFrm, $signalLayers, $stackup );

	$self->__BuildPressProducts( $procViewerFrm, $signalLayers, $stackup );

}

sub __BuildInputProducts {
	my $self          = shift;
	my $procViewerFrm = shift;
	my $signalLayers  = shift;
	my $stackup       = shift;

	#$procViewerFrm->AddCategoryTitle( Enums->Group_PRODUCTINPUT );

	my @products = $stackup->GetInputProducts();

	foreach my $p (@products) {

		# Create group
		my $g = $procViewerFrm->AddGroup( $p->GetId(), Enums->Group_PRODUCTINPUT, $p );

		# Add sub groups for this gorup
		my @nestProducts = ( $p, map { $_->GetData() } $p->GetChildProducts() );

		foreach my $nestP (@nestProducts) {

			# Add separator if at least one sub group exist
			#$g->AddSeparator() if ( scalar( $g->GetSubGroups() ) );

			my $plugging     = $nestP->GetPlugging();
			my $outerCoreTop = $nestP->GetOuterCoreTop();
			my $outerCoreBot = $nestP->GetOuterCoreBot();

	 

			my $subG = $g->AddSubGroup( $nestP->GetId(), Enums->Group_PRODUCTINPUT, $nestP );
				 
			foreach my $productL ( $nestP->GetLayers() ) {

				my $lType = $productL->GetType();
				my $lData = $productL->GetData();

				if ( $lType eq StackEnums->ProductL_PRODUCT ) {

					$subG->AddProductRow( $lData->GetId(), $lData->GetProductType() );

				}
				elsif ( $lType eq StackEnums->ProductL_MATERIAL ) {

					if ( $lData->GetType() eq StackEnums->MaterialType_COPPER ) {

						if ( $lData->GetCopperName() eq $nestP->GetTopCopperLayer() ) {

							$subG->AddCopperRow( $lData->GetCopperName(), $outerCoreTop );
							$subG->AddCopperRow( $lData->GetCopperName(), $outerCoreTop, 1 ) if ($plugging);

						}
						elsif ( $lData->GetCopperName() eq $nestP->GetBotCopperLayer() ) {

							$subG->AddCopperRow( $lData->GetCopperName(), $outerCoreBot, 1 ) if ($plugging);
							$subG->AddCopperRow( $lData->GetCopperName(), $outerCoreBot );
						}
					}
					elsif ( $lData->GetType() eq StackEnums->MaterialType_PREPREG ) {

						$subG->AddPrepregRow( Enums->RowSeparator_PRPG );

					}
					elsif ( $lData->GetType() eq StackEnums->MaterialType_CORE ) {
						$subG->AddCoreRow( Enums->RowSeparator_CORE );

					}
					elsif ( $lData->GetType() eq StackEnums->MaterialType_COVERLAY ) {
						$subG->AddCoverlayRow( Enums->RowSeparator_COVERLAY );
					}
				}
			}
		}
	}
	
	$procViewerFrm->HideSubGroup();
	
#	$procViewerFrm->{"szGroups"}->Layout();
#	#$procViewerFrm->{"szGroups"}->Refresh();
#	$procViewerFrm->Refresh()
#	#$procViewerFrm->FitInside();
#	#$procViewerFrm->Refresh();
	
}

sub __BuildPressProducts {
	my $self          = shift;
	my $procViewerFrm = shift;
	my $signalLayers  = shift;
	my $stackup       = shift;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

