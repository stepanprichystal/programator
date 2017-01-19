
#-------------------------------------------------------------------------------------------#
# Description: Data definition for group. This data struct are used  as data transfer
# between ExportChecker and ExportUtility
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::DataTransfer::UnitsDataContracts::PdfData;
 
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
 

sub SetExportControl {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"exportControl"} = $value;
}

sub GetExportControl {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"exportControl"};
}

sub SetControlStep {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"controlStep"} = $value;
}

sub GetControlStep {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"controlStep"};
}

sub SetControlLang {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"controlLang"} = $value;
}

sub GetControlLang {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"controlLang"};
}
 
# Info about tpv technik to pdf

sub GetInfoToPdf {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"infoToPdf"};
}

sub SetInfoToPdf {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"infoToPdf"} = $value;
}
 
 
 
sub SetExportStackup {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"exportStackup"} = $value;
}

sub GetExportStackup {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"exportStackup"};
} 
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

