
#-------------------------------------------------------------------------------------------#
# Description: Keep all units, and do same operation for all units
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AbstractQueue::Unit::Units;

use Class::Interface;
&implements('Managers::AbstractQueue::Unit::IUnit');

#3th party library
use strict;
use warnings;

#local library
use aliased "Packages::Events::Event";
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::ItemResult::ItemResultMngr';

 


#-------------------------------------------------------------------------------------------#
#  Package methods, requested by IUnit interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"jobId"} = shift;
	
	# 1- when some group finish only with warning (no error), whole units result is:
	# ignoreWarn = 1 => succes
	# ignoreWarn = 0 => failed
	$self->{"ignoreWarn"} = shift; 

	$self->{"units"} = undef;
	
	

	#$self->{"onCheckEvent"} = Event->new();

	return $self;    # Return the reference to the hash.
}

sub Init {
	my $self = shift;
	my @keys = @{ shift(@_) };

	my @allUnits = ();

	foreach my $key (@keys) {

		my $unit = $self->__GetUnitClass($key);
		push( @allUnits, $unit );
	}

	$self->{"units"} = \@allUnits;

}
# Return initialized "unit" object by unitId
sub __GetUnitClass {
	my $self   = shift;
	my $unitId = shift;

	my $unit;
	my $jobId = $self->{"jobId"};
	
	

	if ( $unitId eq UnitEnums->UnitId_NIF ) {

		$unit = NifUnit->new($unitId, $jobId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_NC ) {

		$unit = NCUnit->new($unitId, $jobId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_AOI ) {

		$unit = AOIUnit->new($unitId, $jobId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_ET ) {

		$unit = ETUnit->new($unitId, $jobId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_PLOT ) {

		$unit = PlotUnit->new($unitId, $jobId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_PRE ) {

		$unit = PreUnit->new($unitId, $jobId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_SCO ) {

		$unit = ScoUnit->new($unitId, $jobId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_GER ) {

		$unit = GerUnit->new($unitId, $jobId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_PDF ) {

		$unit = PdfUnit->new($unitId, $jobId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_OUT ) {

		$unit = OutUnit->new($unitId, $jobId);

	}
	
 

	return $unit;
}

# ===================================================================
# Method requested by interface IUnit
# ===================================================================

sub ProcessItemResult {
	my $self = shift;
	my $data = shift;

	my $unitId = $data->{"unitId"};

	my $unit = $self->GetUnitById($unitId);

	my $itemId       = $data->{"itemId"};
	my $itemResult   = $data->{"result"};
	my $itemErrors   = $data->{"errors"};
	my $itemWarnings = $data->{"warnings"};
	my $itemGroup    = $data->{"group"};

	$unit->ProcessItemResult( $itemId, $itemResult, $itemGroup, $itemErrors, $itemWarnings );

}

sub ProcessGroupResult {
	my $self = shift;
	my $data = shift;

	my $unitId = $data->{"unitId"};

	my $unit = $self->GetUnitById($unitId);

	my $groupResult   = $data->{"result"};
	my $groupErrors   = $data->{"errors"};
	my $groupWarnings = $data->{"warnings"};

	$unit->ProcessGroupResult( $groupResult, $groupErrors, $groupWarnings );

}

sub Result {
	my $self = shift;
 
	my $result = EnumsGeneral->ResultType_OK;

	foreach my $unit ( @{ $self->{"units"} } ) {

		if ( $unit->Result($self->{"ignoreWarn"}) eq EnumsGeneral->ResultType_FAIL ) {

			$result = EnumsGeneral->ResultType_FAIL;
		}

	}

	return $result;
}

sub GetErrorsCnt {
	my $self = shift;

	my $cnt = 0;

	foreach my $unit ( @{ $self->{"units"} } ) {
		$cnt += $unit->GetErrorsCnt();
	}

	return $cnt;
}

sub GetWarningsCnt {
	my $self = shift;

	my $cnt = 0;

	foreach my $unit ( @{ $self->{"units"} } ) {
		$cnt += $unit->GetWarningsCnt();
	}

	return $cnt;
}

sub GetProgress {
	my $self = shift;

	my $total = 0;

	foreach my $unit ( @{ $self->{"units"} } ) {

		$total += $unit->GetProgress();

	}

	$total = int( $total / scalar( @{ $self->{"units"} } ) );

	return $total;

}

sub GetGroupItemResultMngr {
	my $self = shift;

	my $resultMngr = ItemResultMngr->new();

	foreach my $unit ( @{ $self->{"units"} } ) {

		my @allItems = $unit->GetGroupItemResultMngr()->GetAllItems();
		$resultMngr->AddItems( \@allItems );

	}

	return $resultMngr;
}

sub GetGroupResultMngr {
	my $self = shift;

	my $resultMngr = ItemResultMngr->new();

	foreach my $unit ( @{ $self->{"units"} } ) {

		my @allItems = $unit->GetGroupResultMngr()->GetAllItems();
		$resultMngr->AddItems( \@allItems );

	}

	return $resultMngr;
}

sub GetTaskClass {
	my $self = shift;

	my %taskClasses = ();

	foreach my $unit ( @{ $self->{"units"} } ) {

		my $class = $unit->GetTaskClass();
		$taskClasses{ $unit->{"unitId"} } = $class;
	}

	return %taskClasses;
}

# ===================================================================
# Other methods
# ===================================================================



sub SetUnits {
	my $self   = shift;
	my $units = shift;

	 $self->{"units"} = $units;
}

sub GetUnits {
	my $self   = shift;

	 return @{$self->{"units"}};
}

sub GetUnitById {
	my $self   = shift;
	my $unitId = shift;

	foreach my $unit ( @{ $self->{"units"} } ) {

		if ( $unitId eq $unit->{"unitId"} ) {
			return $unit;
		}
	}
}

# Return number of active units for task
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

