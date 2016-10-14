
#-------------------------------------------------------------------------------------------#
# Description: Data definition for group. This data struct are used  as data transfer
# between ExportChecker and ExportUtility
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::DataTransfer::UnitsDataContracts::PlotData;
 
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
 
# sendtToPlotter
sub SetSendToPlotter {
	my $self  = shift;
	$self->{"data"}->{"sendtToPlotter"} = shift;
}

sub GetSendToPlotter {
	my $self  = shift;
	return $self->{"data"}->{"sendtToPlotter"};
}

# layers
sub SetLayers {
	my $self  = shift;
	$self->{"data"}->{"layers"} = shift;
}

sub GetLayers {
	my $self  = shift;
	return $self->{"data"}->{"layers"};
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

