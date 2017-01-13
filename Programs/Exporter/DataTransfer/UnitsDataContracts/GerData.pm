
#-------------------------------------------------------------------------------------------#
# Description: Data definition for group. This data struct are used  as data transfer
# between ExportChecker and ExportUtility
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::DataTransfer::UnitsDataContracts::GerData;
 
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
 
 
# paste info
sub SetPasteInfo {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"pasteInfo"} = $value;
}

sub GetPasteInfo {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"pasteInfo"};
}
 
# mdi info, hash with info if mask, signal, plug layers are exported
 
sub SetMdiInfo {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"mdiInfo"} = $value;
}

sub GetMdiInfo {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"mdiInfo"};
}

# export layers
sub SetExportLayers {
	my $self  = shift;
	$self->{"data"}->{"exportLayers"} = shift;
} 


sub GetExportLayers {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"exportLayers"};
} 
 
# layers to test 
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

