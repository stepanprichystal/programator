
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

#-------------------------------------------------------------------------------------------#
#  Package methods, requested by IUnit interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"onCheckEvent"} = Event->new();

	return $self;    # Return the reference to the hash.
}

sub Init {
	my $self = shift;

	#my $parent = shift;
	my @units = @{ shift(@_) };

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

		$unit->SetGroupState($groupState);
	}

}



sub GetExportData {
	my $self = shift;
 
	my %allExportData = ();

	foreach my $unit ( @{ $self->{"units"} } ) {

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

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

