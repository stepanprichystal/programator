
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

#-------------------------------------------------------------------------------------------#
#  Package methods, requested by IUnit interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	#	$self->{"onCheckEvent"} = Event->new();
	#	$self->{"switchAppEvt"} = Event->new();    # allow to run another app from unitForm

	$self->{"jobId"}       = shift;
	$self->{"wizardModel"} = shift;
	$self->{"parts"}       = [];

	return $self;    # Return the reference to the hash.
}

sub Init {
	my $self  = shift;
	my $inCAM = shift;

	my $jobId = $self->{"jobId"};

	# Each unit contain reference on default info - info with general info about pcb

	my @parts = ();

	# Part 1
	push( @parts, SizePart->new($jobId) );
	push( @parts, SizePart->new($jobId) );
	push( @parts, SizePart->new($jobId) );

	#	# Save to each unit->dataMngr default info
	#	foreach my $part (@parts) {
	#
	#		$part->SetWizardModel( $self->{"wizardModel"} );
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

}

sub GetParts {
	my $self = shift;

	return @{ $self->{"parts"} };
}

sub InitModel {
	my $self            = shift;
	my $inCAM           = shift;
	my $storedModelMngr = shift;

	#case when group data are taken from disc
	if ($storedModelMngr) {

		unless ( $storedModelMngr->ExistModelData() ) {
			return 0;
		}

		foreach my $part ( @{ $self->{"parts"} } ) {

			my $storedData = $storedModelMngr->GetDataByPart($part);
			$part->InitModel( $inCAM, $storedData );
		}
	}

	#case, when "default" data for group are loaded
	else {

		foreach my $part ( @{ $self->{"parts"} } ) {

			$part->InitModel();
		}
	}
}

sub RefreshGUI {
	my $self = shift;
	foreach my $part ( @{ $self->{"parts"} } ) {

		$part->RefreshGUI();
	}

}
#
#sub RefreshWrapper {
#	my $self = shift;
#
#	foreach my $unit ( @{ $self->{"units"} } ) {
#
#		$unit->RefreshWrapper();
#	}
#
#}
#
#sub CheckBeforeExport {
#	my $self  = shift;
#	my $inCAM = shift;
#	my $mode  = shift;    # EnumsJobMngr->TaskMode_SYNC /  EnumsJobMngr->TaskMode_ASYNC
#
#	#my $totalRes = 1;
#
#	# Check only units, which are in ACTIVEON state
#	my @activeOnUnits =
#	  grep { $_->GetGroupState() eq Enums->GroupState_ACTIVEON || $_->GetGroupState() eq Enums->GroupState_ACTIVEALWAYS } @{ $self->{"units"} };
#
#	foreach my $unit (@activeOnUnits) {
#
#		#$totalRes = 0;
#		my %info = ();
#		$info{"unit"} = $unit;
#
#		my $resultMngr = -1;
#
#		# Start checking
#		$self->{"onCheckEvent"}->Do( "start", \%info );
#
#		my $succes = $unit->CheckBeforeExport( $inCAM, \$resultMngr, $mode );
#
#		#unless ($succes) {
#		#	$totalRes = 0;
#		#}
#
#		$info{"resultMngr"} = $resultMngr;
#
#		# End checking
#		$self->{"onCheckEvent"}->Do( "end", \%info );
#	}
#
#	#return $totalRes;
#}
#
## Return numbers of each state
#sub GetGroupState {
#	my $self = shift;
#
#	my $unitsCnt = scalar( @{ $self->{"units"} } );
#
#	my %unitState;
#
#	$unitState{ Enums->GroupState_ACTIVEALWAYS } = scalar( grep { $_->GetGroupState() eq Enums->GroupState_ACTIVEALWAYS } @{ $self->{"units"} } );
#	$unitState{ Enums->GroupState_DISABLE }      = scalar( grep { $_->GetGroupState() eq Enums->GroupState_DISABLE } @{ $self->{"units"} } );
#	$unitState{ Enums->GroupState_ACTIVEOFF }    = scalar( grep { $_->GetGroupState() eq Enums->GroupState_ACTIVEOFF } @{ $self->{"units"} } );
#	$unitState{ Enums->GroupState_ACTIVEON }     = scalar( grep { $_->GetGroupState() eq Enums->GroupState_ACTIVEON } @{ $self->{"units"} } );
#
#	return %unitState;
#
#}
#
#sub SetGroupState {
#	my $self       = shift;
#	my $groupState = shift;
#
#	foreach my $unit ( @{ $self->{"units"} } ) {
#
#		# dnot set state, if group is disabled
#
#		if ( $unit->GetGroupState() eq Enums->GroupState_DISABLE || $unit->GetGroupState() eq Enums->GroupState_ACTIVEALWAYS ) {
#			next;
#		}
#
#		$unit->SetGroupState($groupState);
#	}
#
#}
#
## Return current group data
#sub GetGroupData {
#	my $self = shift;
#
#	die "group is Not implemented";
#}
#
#sub GetExportData {
#	my $self         = shift;
#	my $activeGroups = shift;
#
#	my %allExportData = ();
#
#	my @units = @{ $self->{"units"} };
#
#	if ($activeGroups) {
#		@units = grep { $_->GetGroupState() eq Enums->GroupState_ACTIVEON || $_->GetGroupState() eq Enums->GroupState_ACTIVEALWAYS } @units;
#	}
#
#	foreach my $unit (@units) {
#
#		my $exportData = $unit->GetExportData();
#		$allExportData{ $unit->{"unitId"} } = $exportData;
#	}
#
#	return %allExportData;
#}
#
## Update group data from GUI
#sub UpdateGroupData {
#	my $self = shift;
#
#	foreach my $unit ( @{ $self->{"units"} } ) {
#
#		$unit->UpdateGroupData();
#	}
#}

# ===================================================================
# Helper method not requested by interface IUnit
# ===================================================================
#
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
## Other methods
## ===================================================================
#
#sub GetUnitById {
#	my $self   = shift;
#	my $unitId = shift;
#
#	foreach my $unit ( @{ $self->{"units"} } ) {
#
#		if ( $unitId eq $unit->{"unitId"} ) {
#			return $unit;
#		}
#	}
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

