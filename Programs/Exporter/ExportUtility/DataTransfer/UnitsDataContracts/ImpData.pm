
#-------------------------------------------------------------------------------------------#
# Description: Data definition for group. This data struct are used  as data transfer
# between ExportChecker and ExportUtility
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::DataTransfer::UnitsDataContracts::ImpData;
 
#3th party library
use strict;
use warnings;


#local library
use aliased 'Programs::Exporter::ExportChecker::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $self = shift;
	$self = {};
	bless $self;

	my %exportData = ();
	$self->{"data"} = \%exportData;

	return $self; 
}
 
# Export impedance measurement pdf
sub SetExportMeasurePdf {
	my $self  = shift;
	$self->{"data"}->{"exportMeasurePdf"} = shift;
}

sub GetExportMeasurePdf {
	my $self  = shift;
	return $self->{"data"}->{"exportMeasurePdf"};
}


# Create MultiCall pdf from InStack
sub SetBuildMLStackup {
	my $self  = shift;
	$self->{"data"}->{"buildMLStackup"} = shift;
}

sub GetBuildMLStackup {
	my $self  = shift;
	return $self->{"data"}->{"buildMLStackup"};
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

