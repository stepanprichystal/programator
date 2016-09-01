
#-------------------------------------------------------------------------------------------#
# Description: Cover merging, spliting and checking before exporting NC files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::DataTransfer::ExportData;

#3th party library
use strict;
use warnings;
use File::Copy;

#local library
use aliased 'Programs::Exporter::ExportChecker::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $self = shift;
	$self = {};
	bless $self;

	my %units = ();
	$self->{"units"} = \%units;
	
	# EXPORT PROPERTIES
	$self->{"time"} = undef;
	$self->{"mode"} = undef; # synchronousExport/ asynchronousExport
	$self->{"toProduce"} = undef; # sent to produce 0/1
	
	return $self;    # Return the reference to the hash.
}


sub GetExportTime{
		my $self  = shift;
		
		return $self->{"time"};
}

sub GetExportMode{
		my $self  = shift;
		
		return $self->{"mode"};
}

sub GetToProduce{
		my $self  = shift;
		
		return $self->{"toProduce"};
}

sub GetOrderedUnitKeys {
	my $self  = shift;
	my $desc = shift;

	my %unitsData = %{ $self->{"units"} };
	my @keys      = ();
	if ( $desc ) {
		@keys = sort { $unitsData{$b}->{"data"}->{"__UNITORDER__"} <=> $unitsData{$a}->{"data"}->{"__UNITORDER__"} } keys %unitsData;
	}
	else {
		@keys = sort { $unitsData{$a}->{"data"}->{"__UNITORDER__"} <=> $unitsData{$b}->{"data"}->{"__UNITORDER__"} } keys %unitsData;
	}

	return @keys;
}

# Tenting
sub GetUnitData {
	my $self   = shift;
	my $unitId = shift;

	my $exportData = $self->{"units"}->{$unitId};
	return $exportData;
}

sub GetAllUnitData {
	my $self = shift;

	return %{ $self->{"units"} };
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

