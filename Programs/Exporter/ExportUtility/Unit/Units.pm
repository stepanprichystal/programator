
#-------------------------------------------------------------------------------------------#
# Description: Keep all units, and do same operation for all units
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Unit::Units;

use Class::Interface;
&implements('Programs::Exporter::ExportUtility::Unit::IUnit');

#3th party library
use strict;
use warnings;

#local library
use aliased "Packages::Events::Event";
use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::ItemResult::ItemResultMngr';

#-------------------------------------------------------------------------------------------#
#  Package methods, requested by IUnit interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"units"} = undef;

	#$self->{"onCheckEvent"} = Event->new();

	return $self;    # Return the reference to the hash.
}

sub Init {
	my $self = shift;

	#my $parent = shift;
	my @units = @{ shift(@_) };

	$self->{"units"} = \@units;

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

	my $unit = $self->__GetUnit($unitId);

	my $groupResult   = $data->{"result"};
	my $groupErrors   = $data->{"errors"};
	my $groupWarnings = $data->{"warnings"};

	$unit->ProcessGroupResult( $groupResult, $groupErrors, $groupWarnings );

}

sub Result {
	my $self = shift;

	my $result = EnumsGeneral->ResultType_OK;

	foreach my $unit ( @{ $self->{"units"} } ) {

		if ( $unit->Result() eq EnumsGeneral->ResultType_FAIL ) {

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

sub GetExportClass {
	my $self = shift;

	my %exportClasses = ();

	foreach my $unit ( @{ $self->{"units"} } ) {

		my $class = $unit->GetExportClass();
		$exportClasses{ $unit->{"unitId"} } = $class;
	}

	return %exportClasses;
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

