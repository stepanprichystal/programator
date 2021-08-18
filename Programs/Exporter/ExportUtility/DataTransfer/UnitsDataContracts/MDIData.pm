
#-------------------------------------------------------------------------------------------#
# Description: Data definition for group. This data struct are used  as data transfer
# between ExportChecker and ExportUtility
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::DataTransfer::UnitsDataContracts::MDIData;
 
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
 
 
# Layer couples
sub SetLayerCouples {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"layerCouples"} = $value;
}

sub GetLayerCouples {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"layerCouples"};
}

# Settings of each layer
sub SetLayersSettings {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"layersSettings"} = $value;
}

sub GetLayersSettings {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"layersSettings"};
}
  
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

