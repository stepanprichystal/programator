
#-------------------------------------------------------------------------------------------#
# Description: Prostrednik mezi formularem jednotky a buildere,
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Unit::Units;

#use Class::Interface;
#&implements('Programs::Exporter::ExportChecker::ExportChecker::Unit::IUnit');

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
 
 
 sub GetUnitById {
	my $self = shift;
	my $unitId = shift;

	foreach my $unit ( @{ $self->{"units"} } ) {

		if( $unitId eq $unit->{"unitId"}){
			return $unit;
		} 
	}
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

