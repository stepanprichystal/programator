
#-------------------------------------------------------------------------------------------#
# Description: Prostrednik mezi formularem jednotky a buildere,
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::PartContainer;

#use Class::Interface;
#&implements('Programs::Exporter::ExportChecker::ExportChecker::Unit::IUnit');

#3th party library
use strict;
use warnings;

#local library
#use aliased "Packages::Events::Event";
#use aliased 'Programs::Exporter::ExportChecker::Enums';
#use aliased 'Programs::Exporter::ExportUtility::UnitEnums';
#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::DefaultInfo::DefaultInfo';
#use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::Presenter::PreUnit';

use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::Control::SizePart';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::Control::StepPart';
use aliased 'Programs::Panelisation::PnlWizard::EnumsStyle';
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods, requested by IUnit interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"asyncPanelCreatedEvt"}   = Event->new();    #
	$self->{"asyncCreatorsInitedEvt"} = Event->new();    #
	                                                     #	$self->{"switchAppEvt"} = Event->new();    # allow to run another app from unitForm

	$self->{"jobId"} = shift;

	$self->{"backgroundTaskMngr"} = shift;
	$self->{"parts"}              = [];

	return $self;                                        # Return the reference to the hash.
}

# Init parts
sub Init {
	my $self  = shift;
	my $inCAM = shift;
	my $pnlType = shift;

	my $jobId = $self->{"jobId"};

	# Each unit contain reference on default info - info with general info about pcb

	my @parts = ();

	# Part 1
	push( @parts, SizePart->new( $jobId, $pnlType, $self->{"backgroundTaskMngr"} ) );
	push( @parts, StepPart->new( $jobId, $pnlType, $self->{"backgroundTaskMngr"} ) );

	#push( @parts, SizePart->new( $jobId, $self->{"backgroundTaskMngr"} ) );

	foreach my $part (@parts) {

		$part->{"previewChangedEvt"}->Add( sub        { $self->__OnPreviewChangedHndl(@_) } );
		$part->{"asyncCreatorProcessedEvt"}->Add( sub { $self->__OnAsyncCreatorProcessedHndl(@_) } );
		$part->{"asyncCreatorInitedEvt"}->Add( sub    { $self->__OnAsyncCreatorInitedHndl(@_) } );

		#$part->{"asyncCreatorProcessedEvt"}->Add( sub { $self->__OnCreatorProcessedHndl(@_) } );

	}

	#push( @parts, SizePart->new($jobId, $self->{"backgroundTaskMngr"}) );
	#	push( @parts, SizePart->new($jobId, $self->{"backgroundTaskMngr"}) );

	#	# Save to each unit->dataMngr default info
	#	foreach my $part (@parts) {
	#
	#		$part->SetWizardModel( $self->{"model"} );
	#	}
	#
	#	# Add handelr to "switchAppEvt" for some events
	#	foreach my $unit (@units) {
	#		if ( defined $unit->{"switchAppEvt"} ) {
	#
	#			$unit->{"switchAppEvt"}->Add( sub { $self->{"switchAppEvt"}->Do(@_) } );
	#		}
	#	}

	$self->{"parts"} = \@parts;

	# Bind part events each other
	foreach my $pi (@parts) {

		foreach my $pj (@parts) {

			if ( $pi != $pj ) {

				#	my $hndlSel = $parts[$j]->can('OnOtherPartCreatorSelChangedHndl');

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

sub GetParts {
	my $self = shift;

	return @{ $self->{"parts"} };
}

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

			$part->InitPartModel( $inCAM, undef );
		}
	}

}

sub AsyncInitSelCreatorModel {
	my $self = shift;

	foreach my $part ( @{ $self->{"parts"} } ) {

		$part->AsyncInitSelCreatorModel();

		print STDERR "cyklus\n";
	}
}

sub RefreshGUI {
	my $self = shift;
	foreach my $part ( @{ $self->{"parts"} } ) {

		$part->RefreshGUI();
	}
}

sub AsyncProcessSelCreatorModel {
	my $self   = shift;
	my $partId = shift;

	my @parts = @{ $self->{"parts"} };

	@parts = grep { $_->GetPartId() eq $partId } @parts if ( defined $partId );

	foreach my $part (@parts) {

		$part->AsyncProcessSelCreatorModel();
	}
}

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

sub GetPreview {
	my $self = shift;

}

#
# ===================================================================
# Helper method not requested by interface IUnit
# ===================================================================

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

# Returl list of parts
sub GetModel {
	my $self = shift;
	my $notUpdate = shift;

	# Set all parts
	my @partModels = ();
	foreach my $part ( @{ $self->{"parts"} } ) {

		push( @partModels, [ $part->GetPartId(), $part->GetModel($notUpdate) ] );

		#$self->{"model"}->SetPartModelById( $part->GetPartId(), $part->GetModel() );
	}

	# Set preview
	#$self->{"model"}->SetPreview( $self->{"partWrapper"}->GetPreview() );

	# Set step name

	return \@partModels;

}

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

sub ClearErrors {
	my $self = shift;

	foreach my $part ( @{ $self->{"parts"} } ) {

		$part->ClearErrors();
	}

}

sub UpdateStep {
	my $self = shift;
	my $step = shift;

	foreach my $part ( @{ $self->{"parts"} } ) {

		$part->UpdateStep($step);
	}
}

##Set handler for catch changing state of each unit
#sub SetGroupChangeHandler {
#	my $self    = shift;
#	my $handler = shift;
#
#	foreach my $unit ( @{ $self->{"units"} } ) {
#
#		$unit->{"onChangeState"}->Add($handler);
#	}
#}
#
## Return number of active units for export
#sub GetActiveUnitsCnt {
#	my $self = shift;
#	my @activeOnUnits =
#	  grep { $_->GetGroupState() eq Enums->GroupState_ACTIVEON || $_->GetGroupState() eq Enums->GroupState_ACTIVEALWAYS } @{ $self->{"units"} };
#
#	return scalar(@activeOnUnits);
#}
#
## Return units and info if group is mansatory
#sub GetUnitsMandatory {
#	my $self      = shift;
#	my $mandatory = shift;
#
#	my @units = @{ $self->{"units"} };
#
#	if ($mandatory) {
#		@units = grep { $_->GetGroupMandatory() eq Enums->GroupMandatory_YES } @units;
#	}
#	else {
#
#		@units = grep { $_->GetGroupMandatory() eq Enums->GroupMandatory_NO } @units;
#	}
#
#	return @units;
#}
#
## ===================================================================
## Handlers
## ===================================================================

sub __OnPreviewChangedHndl {
	my $self    = shift;
	my $partId  = shift;
	my $preview = shift;

	if ($preview) {

		# Set preview + process up to this specific  part
		$self->SetPreviewOnAllPart($partId);

		# Process this specific part
		$self->AsyncProcessSelCreatorModel($partId);

	}

}

sub __OnAsyncCreatorProcessedHndl {
	my $self       = shift;
	my $creatorKey = shift;
	my $result     = shift;
	my $errMess    = shift;

	if ( $self->{"finalProcessing"} ) {

		$self->__OnAsyncProcessSelCreatorModelHndl( $creatorKey, $result, $errMess );
	}

}

sub __OnAsyncCreatorInitedHndl {
	my $self       = shift;
	my $creatorKey = shift;
	my $result     = shift;
	my $errMess    = shift;

	# Check how many init creator task exist
	#
	#	my $taskCnt =  $self->{"backgroundTaskMngr"}->GetInitCreatorTaskCnt();
	#
	#	if($taskCnt == 0){
	#
	#		$self->{"asyncCreatorsInitedEvt"}->Do();
	#	}

}

# Set previwe
sub SetPreviewOnAllPart {
	my $self       = shift;
	my $lastPartId = shift;    # if defined, set preview ON up to this specific partId (this part is excluded). By order from first partId

	for ( my $i = 0 ; $i < scalar( @{ $self->{"parts"} } ) ; $i++ ) {

		last if ( defined $lastPartId && $self->{"parts"}->[$i]->GetPartId() eq $lastPartId );

		if ( !$self->{"parts"}->[$i]->GetPreview() ) {

			$self->{"parts"}->[$i]->SetPreview(1);
			$self->AsyncProcessSelCreatorModel( $self->{"parts"}->[$i]->GetPartId() );

		}

	}

}

sub SetPreviewOffAllPart {
	my $self = shift;

	for ( my $i = scalar( @{ $self->{"parts"} } ) - 1 ; $i >= 0 ; $i-- ) {

		if ( $self->{"parts"}->[$i]->GetPreview() ) {

			$self->{"parts"}->[$i]->SetPreview(0);
		}
	}
}

# Process all parts
sub AsyncCreatePanel {
	my $self = shift;

	# Get creator for every part
	$self->{"finalProcessing"} = 1;

	$self->{"finalCreateParts"} = [ map { $_->GetPartId() } @{ $self->{"parts"} } ];

	my $nextPart = shift @{ $self->{"finalCreateParts"} };

	$self->AsyncProcessSelCreatorModel($nextPart);

}

sub __OnAsyncProcessSelCreatorModelHndl {
	my $self       = shift;
	my $creatorKey = shift;
	my $result     = shift;
	my $errMess    = shift;

	if ($result) {

		my $nextPart = shift @{ $self->{"finalCreateParts"} };

		if ( defined $nextPart ) {

			$self->AsyncProcessSelCreatorModel($nextPart);
		}
		else {

			$self->{"finalProcessing"} = 0;
			$self->{"asyncPanelCreatedEvt"}->Do(1);
		}
	}
	else {
		$self->{"finalProcessing"} = 0;
		$self->{"asyncPanelCreatedEvt"}->Do( 0, $errMess );
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

