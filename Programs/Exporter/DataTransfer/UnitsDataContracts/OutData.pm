
#-------------------------------------------------------------------------------------------#
# Description: Data definition for group. This data struct are used  as data transfer
# between ExportChecker and ExportUtility
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::DataTransfer::UnitsDataContracts::OutData;
 
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
 
 
# export data kooperace
sub SetExportCooper {
	my $self  = shift;
	$self->{"data"}->{"exportCooper"} = shift;
} 


sub GetExportCooper {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"exportCooper"};
}

# export electric test for cooper
sub SetExportET {
	my $self  = shift;
	$self->{"data"}->{"exportET"} = shift;
} 

sub GetExportET {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"exportET"};
}

# Electric step
sub SetExportETStep {
	my $self  = shift;
	$self->{"data"}->{"exportETStep"} = shift;
} 

sub GetExportETStep {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"exportETStep"};
}
 
# export data control
sub SetExportControl {
	my $self  = shift;
	$self->{"data"}->{"exportControl"} = shift;
} 


sub GetExportControl {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"exportControl"};
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

