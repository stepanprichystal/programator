
#-------------------------------------------------------------------------------------------#
# Description: Prostrednik mezi formularem jednotky a buildere,
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::ExportChecker::Unit::Units;

use Class::Interface;
&implements('Programs::Exporter::ExportChecker::ExportChecker::Unit::IUnit');

#3th party library
use strict;
use warnings;

#local library
use aliased "Packages::Events::Event";
use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::DefaultInfo::DefaultInfo';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::Presenter::PreUnit';
#-------------------------------------------------------------------------------------------#
#  Package methods, requested by IUnit interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;
 
  
	$self->{"onCheckEvent"} = Event->new();

	$self->{"defaultInfo"} = undef;

	return $self;    # Return the reference to the hash.
}

sub Init {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my @units = @{ shift(@_) };
	
	
	## each export has to contai special group "PreGroup"
	#my $preUnit1 = PreUnit->new( $jobId);	
	#push(@units, $preUnit1);

	$self->{"defaultInfo"} = DefaultInfo->new( $inCAM, $jobId );

	# Save to each unit->dataMngr default info
	foreach my $unit (@units) {
		
		$unit->SetDefaultInfo( $self->{"defaultInfo"} );
	}


#	# Do conenction between units events/handlers
#	 
#
#	foreach my $unitA (@units) {
#
#		my @unitEvents = $unitA->GetEventClass()->GetEvents();
#
#		# search handler for this event type in all units
#		foreach my $unitB (@units) {
#
#			$unitB->GetEventClass()->ConnectEvents( \@unitEvents );
#		}
#	}

	$self->{"units"} = \@units;

}

sub InitDataMngr {
	my $self           = shift;
	my $inCAM          = shift;
	my $storedDataMngr = shift;

	#case when group data are taken from disc
	if ($storedDataMngr) {

		unless ( $storedDataMngr->ExistGroupData() ) {
			return 0;
		}

		foreach my $unit ( @{ $self->{"units"} } ) {

			my $storedData = $storedDataMngr->GetDataByUnit($unit);
			$unit->InitDataMngr( $inCAM, $storedData );
		}
	}

	#case, when "default" data for group are loaded
	else {

		foreach my $unit ( @{ $self->{"units"} } ) {

			$unit->InitDataMngr($inCAM);
		}
	}
}

sub RefreshGUI {
	my $self = shift;

	#my $inCAM = shift;

	foreach my $unit ( @{ $self->{"units"} } ) {

		$unit->RefreshGUI();
	}

}

sub CheckBeforeExport {
	my $self  = shift;
	my $inCAM = shift;

	#my $totalRes = 1;

	# Check only units, which are in ACTIVEON state
	my @activeOnUnits = grep { $_->GetGroupState() eq Enums->GroupState_ACTIVEON } @{ $self->{"units"} };

	foreach my $unit (@activeOnUnits) {

		#$totalRes = 0;
		my %info = ();
		$info{"unit"} = $unit;

		my $resultMngr = -1;

		# Start checking
		$self->{"onCheckEvent"}->Do( "start", \%info );

		my $succes = $unit->CheckBeforeExport( $inCAM, \$resultMngr );

		#unless ($succes) {
		#	$totalRes = 0;
		#}

		$info{"resultMngr"} = $resultMngr;

		# End checking
		$self->{"onCheckEvent"}->Do( "end", \%info );
	}

	#return $totalRes;
}

sub GetGroupState {
	my $self = shift;

	my $unitsCnt = scalar( @{ $self->{"units"} } );

	my $result;

	my @allDisable   = grep { $_->GetGroupState() eq Enums->GroupState_DISABLE } @{ $self->{"units"} };
	my @allActiveOff = grep { $_->GetGroupState() eq Enums->GroupState_ACTIVEOFF } @{ $self->{"units"} };

	if ( scalar(@allDisable) == $unitsCnt ) {

		# if all are disabled return  disable

		$result = Enums->GroupState_DISABLE;
	}
	elsif ( scalar(@allActiveOff) == $unitsCnt ) {

		# if all are active off return  Active off

		$result = Enums->GroupState_ACTIVEOFF;
	}
	else {

		# if exist some active ON, return Active on

		$result = Enums->GroupState_ACTIVEON;
	}

}

sub SetGroupState {
	my $self       = shift;
	my $groupState = shift;

	foreach my $unit ( @{ $self->{"units"} } ) {
		
		if($unit->GetGroupState() eq Enums->GroupState_DISABLE){
			next;
		}

		$unit->SetGroupState($groupState);
	}

}

sub GetExportData {
	my $self         = shift;
	my $activeGroups = shift;

	my %allExportData = ();

	my @units = @{ $self->{"units"} };

	if ($activeGroups) {
		@units = grep { $_->GetGroupState() eq Enums->GroupState_ACTIVEON } @units;
	}

	foreach my $unit (@units) {

		my $exportData = $unit->GetExportData();
		$allExportData{ $unit->{"unitId"} } = $exportData;
	}

	return %allExportData;
}

sub GetGroupData {
	my $self = shift;

	die "GetGroupData is not implemented ";

	#	my %groupData = ();
	#
	#	foreach my $unit ( @{ $self->{"units"} } ) {
	#
	#		my $groupData = $unit->GetGroupData();
	#		my %hashData  = %{ $groupData->{"data"} };
	#		$groupData{ $unit->{"unitId"} } = \%hashData;
	#	}
	#
	#	return %groupData;
}

# ===================================================================
# Helper method not requested by interface IUnit
# ===================================================================

#Set handler for catch changing state of each unit
sub SetGroupChangeHandler {
	my $self    = shift;
	my $handler = shift;

	foreach my $unit ( @{ $self->{"units"} } ) {

		$unit->{"onChangeState"}->Add($handler);
	}
}

# Return number of active units for export
sub GetActiveUnitsCnt {
	my $self = shift;
	my @activeOnUnits = grep { $_->GetGroupState() eq Enums->GroupState_ACTIVEON } @{ $self->{"units"} };

	return scalar(@activeOnUnits);
}






# ===================================================================
# Other methods
# ===================================================================

sub GetUnitById {
	my $self   = shift;
	my $unitId = shift;

	foreach my $unit ( @{ $self->{"units"} } ) {

		if ( $unitId eq $unit->{"unitId"} ) {
			return $unit;
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

