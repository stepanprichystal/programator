
#-------------------------------------------------------------------------------------------#
# Description: Data definition for group. This data struct are used  as data transfer
# between ExportChecker and ExportUtility
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::DataTransfer::UnitsDataContracts::NCData;
 
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
 
 
# exportSingle
sub SetExportSingle {
	my $self  = shift;
	$self->{"data"}->{"exportSingle"} = shift;
}

sub GetExportSingle {
	my $self  = shift;
	return $self->{"data"}->{"exportSingle"};
}
 
# Plt layers 
sub SetPltLayers {
	my $self  = shift;
	$self->{"data"}->{"pltLayers"} = shift;
}

sub GetPltLayers {
	my $self  = shift;
	return $self->{"data"}->{"pltLayers"};
} 

# NPlt layers 
sub SetNPltLayers {
	my $self  = shift;
	$self->{"data"}->{"npltLayers"} = shift;
}

sub GetNPltLayers {
	my $self  = shift;
	return $self->{"data"}->{"npltLayers"};
} 
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

