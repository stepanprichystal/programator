
#-------------------------------------------------------------------------------------------#
# Description: Data definition for group. This data struct are used  as data transfer
# between ExportChecker and ExportUtility
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::DataTransfer::UnitsDataContracts::AOIData;
 
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
 
 
# stepToTest
sub SetStepToTest {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"stepToTest"} = $value;
}

sub GetStepToTest {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"stepToTest"};
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

# send opfx data to server
sub SetSendToServer {
	my $self  = shift;
	$self->{"data"}->{"sendToServer"} = shift;
}

sub GetSendToServer {
	my $self  = shift;
	return $self->{"data"}->{"sendToServer"};
} 
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

