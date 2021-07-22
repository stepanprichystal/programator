
#-------------------------------------------------------------------------------------------#
# Description: Collection of all parts
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::PartContainer;

use Class::Interface;
&implements('Programs::Panelisation::PnlWizard::Parts::IPart');

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamStep';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::Control::SizePart';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::Control::StepPart';
use aliased 'Programs::Panelisation::PnlWizard::Parts::CpnPart::Control::CpnPart';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SchemePart::Control::SchemePart';
use aliased 'Programs::Panelisation::PnlWizard::EnumsStyle';
use aliased 'Packages::Events::Event';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"asyncPanelCreatedEvt"}   = Event->new();
	$self->{"asyncCreatorsInitedEvt"} = Event->new();
	$self->{"previewChangedEvt"}      = Event->new();
	$self->{"showPnlWizardFrmEvt"}    = Event->new();

	$self->{"jobId"} = shift;

	$self->{"backgroundTaskMngr"} = shift;

	# PROPERTIES

	$self->{"parts"} = [];

	$self->{"previewOnAllPartsProcessing"} = 0;     # Helper indicator if preview all parts is running
	$self->{"finalCreatePanelProcessing"}  = 0;     # Helper indicator if final panel create
	$self->{"partsInProcessing"}           = [];    # helper array wjhere are parts to processing

	return $self;
}

# Init parts
sub Init {
	my $self    = shift;
	my $inCAM   = shift;
	my $pnlType = shift;

	my $jobId = $self->{"jobId"};

	my @parts = ();

	# Select suitable parts

	push( @parts, SizePart->new( $inCAM, $jobId, $pnlType, $self->{"backgroundTaskMngr"} ) );
	push( @parts, StepPart->new( $inCAM, $jobId, $pnlType, $self->{"backgroundTaskMngr"} ) );

	# Only production panel and onlz if contain  coupons
	if ( $pnlType eq PnlCreEnums->PnlType_PRODUCTIONPNL ) {

		# if there are specific coupon
		my @step = CamStep->GetAllStepNames( $inCAM, $jobId );

		# Impedance coupon default settings
		my $impCpnBaseName   = EnumsGeneral->Coupon_IMPEDANCE;
		my $ipc3CpnBaseName  = EnumsGeneral->Coupon_IPC3MAIN;
		my $zAxisCpnBaseName = EnumsGeneral->Coupon_ZAXIS;

		my @cpnSteps =
		  grep { $_ =~ /$impCpnBaseName/i || $_ =~ /$ipc3CpnBaseName/i || $_ =~ /$zAxisCpnBaseName/i } @step;

		if ( scalar(@cpnSteps) > 0 ) {
			push( @parts, CpnPart->new( $inCAM, $jobId, $pnlType, $self->{"backgroundTaskMngr"} ) );
		}
	}

	push( @parts, SchemePart->new( $inCAM, $jobId, $pnlType, $self->{"backgroundTaskMngr"} ) );

	foreach my $part (@parts) {

		$part->{"previewChangedEvt"}->Add( sub        { $self->__OnPreviewChangedHndl(@_) } );
		$part->{"asyncCreatorProcessedEvt"}->Add( sub { $self->__OnAsyncCreatorProcessedHndl(@_) } );
		$part->{"asyncCreatorInitedEvt"}->Add( sub    { $self->__OnAsyncCreatorInitedHndl(@_) } );
		$part->{"showPnlWizardFrmEvt"}->Add( sub      { $self->{"showPnlWizardFrmEvt"}->Do(@_) } );

	}

	$self->{"parts"} = \@parts;

	# Bind part events each other
	foreach my $pi (@parts) {

		foreach my $pj (@parts) {

			if ( $pi != $pj ) {

				my $hndlSel = sub { $pj->OnOtherPartCreatorSelChangedHndl(@_) };
				if ( defined $hndlSel ) {
					$pi->{"creatorSelectionChangedEvt"}->Add( sub { $hndlSel->(@_) } );
				}

				my $hndlSett = sub { $pj->OnOtherPartCreatorSettChangedHndl(@_) };
				if ( defined $hndlSett ) {
					$pi->{"creatorSettingsChangedEvt"}->Add( sub { $hndlSett->(@_) } );
				}

			}

		}
	}

}

#-------------------------------------------------------------------------------------------#
#  Interface methods
#-------------------------------------------------------------------------------------------#

# Initialize part model by:
# - Restored data from disc
# - Default depanding on panelisation type
sub InitPartModel {
	my $self          = shift;
	my $inCAM         = shift;
	my $restoredModel = shift;

	#case when group data are taken from disc
	if ($restoredModel) {

		foreach my $part ( @{ $self->{"parts"} } ) {

			my $partModel = $restoredModel->GetPartModelById( $part->GetPartId() );
			$part->InitPartModel( $inCAM, $partModel );

		}

	}
	else {

		foreach my $part ( @{ $self->{"parts"} } ) {

			$part->SetPartNotInited();
			$part->InitPartModel( $inCAM, undef );
		}
	}

}

# Set values from model to all parts View
sub RefreshGUI {
	my $self = shift;
	foreach my $part ( @{ $self->{"parts"} } ) {

		$part->RefreshGUI();
	}
}

# Return updated model by values from parts View
sub GetModel {
	my $self      = shift;
	my $notUpdate = shift;

	# Set all parts
	my @partModels = ();
	foreach my $part ( @{ $self->{"parts"} } ) {

		push( @partModels, [ $part->GetPartId(), $part->GetModel($notUpdate) ] );

	}

	return \@partModels;

}

# Asynchronously process selected creator for all parts
sub AsyncProcessSelCreatorModel {
	my $self   = shift;
	my $partId = shift;

	foreach my $part ( @{ $self->{"parts"} } ) {

		next if ( defined $partId && $part->GetPartId() ne $partId );

		$part->AsyncProcessSelCreatorModel();
	}
}

# Asynchronously initialize selected creator for this part
sub AsyncInitSelCreatorModel {
	my $self   = shift;
	my $partId = shift;

	foreach my $part ( @{ $self->{"parts"} } ) {

		next if ( defined $partId && $part->GetPartId() ne $partId );

		$part->AsyncInitSelCreatorModel();

		print STDERR "cyklus\n";
	}
}

# Set directly preview option for all parts
sub SetPreview {
	my $self    = shift;
	my $preview = shift;

	my @parts = @{ $self->{"parts"} };

	foreach my $part (@parts) {

		$part->SetPreview($preview);
	}

	if ($preview) {
		$self->AsyncProcessSelCreatorModel();
	}

}

# Return if at least one part has preview activce
sub GetPreview {
	my $self = shift;

	my $preview = 0;

	foreach my $part ( @{ $self->{"parts"} } ) {

		if ( $part->GetPreview() ) {
			$preview = 1;
			last;
		}
	}

	return $preview;
}

# If all asynchronous init calling are done for all parts, return 1
sub IsPartFullyInited {
	my $self = shift;

	my $inited = 1;

	foreach my $part ( @{ $self->{"parts"} } ) {

		unless ( $part->IsPartFullyInited() ) {
			$inited = 0;
			last;
		}
	}

	return $inited;

}

# ===================================================================
# Helper method not requested by interface IUnit
# ===================================================================

sub GetParts {
	my $self = shift;

	return @{ $self->{"parts"} };
}

# Return array of information needed for check specific part
# - part package name
# - part title
# - part data
sub GetPartsCheckClass {
	my $self  = shift;
	my @parts = ();

	foreach my $part ( @{ $self->{"parts"} } ) {

		my %inf = ();

		$inf{"checkClassId"}      = $part->GetPartId();
		$inf{"checkClassPackage"} = $part->GetCheckClass();
		$inf{"checkClassTitle"}   = EnumsStyle->GetPartTitle( $part->GetPartId() );
		$inf{"checkClassData"}    = $part->GetModel();

		push( @parts, \%inf );
	}

	return @parts;

}

# Clear current errros for all parts
sub ClearErrors {
	my $self = shift;

	foreach my $part ( @{ $self->{"parts"} } ) {

		$part->ClearErrors();
	}

}

sub HideLoading {
	my $self = shift;

	foreach my $part ( @{ $self->{"parts"} } ) {

		$part->HideLoading();
	}

}



# Update step in parts/creators models if changed in main form
sub UpdateStep {
	my $self = shift;
	my $step = shift;

	foreach my $part ( @{ $self->{"parts"} } ) {

		$part->UpdateStep($step);
	}
}

# Set previwe
sub SetPreviewOnAllPart {
	my $self       = shift;
	my $lastPartId = shift;    # if defined, set preview ON up to this specific partId (this part is excluded). By order from first partId

	$self->{"previewOnAllPartsProcessing"} = 1;

	my @parts = ();

	for ( my $i = 0 ; $i < scalar( @{ $self->{"parts"} } ) ; $i++ ) {

		push( @parts, $self->{"parts"}->[$i] );
		last if ( defined $lastPartId && $self->{"parts"}->[$i]->GetPartId() eq $lastPartId );

	}

	$self->{"partsInProcessing"} = \@parts;

	for ( my $i = 0 ; $i < scalar(@parts) ; $i++ ) {

		if ( !$parts[$i]->GetPreview() ) {

			$parts[$i]->SetPreview(1);
		}
	}

	$self->AsyncProcessSelCreatorModel( $parts[0]->GetPartId() );

}

sub SetPreviewOffAllPart {
	my $self        = shift;
	my $firstPartId = shift;

	for ( my $i = scalar( @{ $self->{"parts"} } ) - 1 ; $i >= 0 ; $i-- ) {

		if ( $self->{"parts"}->[$i]->GetPreview() ) {

			$self->{"parts"}->[$i]->SetPreview(0);
		}

		last if ( defined $firstPartId && $self->{"parts"}->[$i]->GetPartId() eq $firstPartId );
	}
}

# Final asynchrounous process of all parts
# if preview ppart processing fail, do not continue
sub AsyncCreatePanel {
	my $self = shift;

	# Get creator for every part
	$self->{"finalCreatePanelProcessing"} = 1;

	$self->{"partsInProcessing"} = [ @{ $self->{"parts"} } ];

	my $nextPart = shift @{ $self->{"partsInProcessing"} };

	$nextPart->AsyncProcessSelCreatorModel();

}

# ===================================================================
# Handlers
# ===================================================================

sub __OnPreviewChangedHndl {
	my $self    = shift;
	my $partId  = shift;
	my $preview = shift;

	if ($preview) {

		# Set preview ON (+ process part) from first to this specific  part
		$self->SetPreviewOnAllPart($partId);

	}
	else {

		# Set preview OFF from  this specific to last part
		$self->SetPreviewOffAllPart($partId);

	}

	$self->{"previewChangedEvt"}->Do( $partId, $preview );

}

sub __OnAsyncCreatorProcessedHndl {
	my $self       = shift;
	my $creatorKey = shift;
	my $result     = shift;
	my $errMess    = shift;

	if ( $self->{"finalCreatePanelProcessing"} || $self->{"previewOnAllPartsProcessing"} ) {

		$self->__OnAsyncProcessSelCreatorModelHndl( $creatorKey, $result, $errMess );
	}

}

sub __OnAsyncCreatorInitedHndl {
	my $self       = shift;
	my $creatorKey = shift;
	my $result     = shift;
	my $errMess    = shift;

}

# Handler for final process all parts
# if preview ppart processing fail, do not continue
sub __OnAsyncProcessSelCreatorModelHndl {
	my $self       = shift;
	my $creatorKey = shift;
	my $result     = shift;
	my $errMess    = shift;

	if ( $self->{"previewOnAllPartsProcessing"} ) {

		if ($result) {

			my $nextPart = shift @{ $self->{"partsInProcessing"} };

			if ( defined $nextPart ) {

				$nextPart->AsyncProcessSelCreatorModel();
			}
			else {

				$self->{"previewOnAllPartsProcessing"} = 0;

			}
		}
		else {
			$self->{"previewOnAllPartsProcessing"} = 0;
		}

	}
	elsif ( $self->{"finalCreatePanelProcessing"} ) {

		if ($result) {

			my $nextPart = shift @{ $self->{"partsInProcessing"} };

			if ( defined $nextPart ) {

				$nextPart->AsyncProcessSelCreatorModel();
			}
			else {

				$self->{"finalCreatePanelProcessing"} = 0;
				$self->{"asyncPanelCreatedEvt"}->Do(1);
			}
		}
		else {
			$self->{"finalCreatePanelProcessing"} = 0;
			$self->{"asyncPanelCreatedEvt"}->Do( 0, $errMess );
		}

	}

	return 1;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

