
#-------------------------------------------------------------------------------------------#
# Description: Data definition for group. This data struct are used  as data transfer
# between ExportChecker and ExportUtility
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::DataTransfer::UnitsDataContracts::NCData;
 
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
 

# All mode NC layers
sub SetAllModeLayers {
	my $self  = shift;
	$self->{"data"}->{"allModeLayers"} = shift;
}

sub GetAllModeLayers {
	my $self  = shift;
	return $self->{"data"}->{"allModeLayers"};
} 

	 

# Plt layers 
sub SetSingleModePltLayers {
	my $self  = shift;
	$self->{"data"}->{"singleModePltLayers"} = shift;
}

sub GetSingleModePltLayers {
	my $self  = shift;
	return $self->{"data"}->{"singleModePltLayers"};
} 

# NPlt layers 
sub SetSingleModeNPltLayers {
	my $self  = shift;
	$self->{"data"}->{"singleModeNpltLayers"} = shift;
}

sub GetSingleModeNPltLayers {
	my $self  = shift;
	return $self->{"data"}->{"singleModeNpltLayers"};
} 
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

