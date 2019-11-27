
#-------------------------------------------------------------------------------------------#
# Description: Data definition for group. This data struct are used  as data transfer
# between ExportChecker and ExportUtility
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::DataTransfer::UnitsDataContracts::PreData;
 
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
 
 
 
# signal layers
sub SetSignalLayers {
	my $self  = shift;
	$self->{"data"}->{"signalLayers"} = shift;
}

sub GetSignalLayers {
	my $self  = shift;
	return $self->{"data"}->{"signalLayers"};
}

# other layers
sub SetOtherLayers {
	my $self  = shift;
	$self->{"data"}->{"otherLayers"} = shift;
}

sub GetOtherLayers {
	my $self  = shift;
	return $self->{"data"}->{"otherLayers"};
}

## Tenting
#sub SetTentingCS {
#	my $self  = shift;
#	$self->{"data"}->{"tentingCS"} = shift;
#}
#
#sub GetTentingCS {
#	my $self  = shift;
#	return $self->{"data"}->{"tentingCS"};
#}
#
#
## Technology
#sub SetTechnologyCS {
#	my $self  = shift;
#	
#	$self->{"data"}->{"technologyCS"} = shift;
#}
#
#sub GetTechnologyCS {
#	my $self  = shift;
#	
#	return $self->{"data"}->{"technologyCS"};
#}
# 
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

