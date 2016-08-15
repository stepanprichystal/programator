
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
	
 
	return $self;    # Return the reference to the hash.
}
 

# Tenting
sub GetUnitData {
	my $self  = shift;
	my $unitId  = shift;
	
	my $exportData = $self->{"units"}->{$unitId};
	return $exportData;
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

