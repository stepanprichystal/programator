
#-------------------------------------------------------------------------------------------#
# Description: Data definition for group. This data struct are used  as data transfer
# between ExportChecker and ExportUtility
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::DataTransfer::UnitsDataContracts::PdfData;

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

sub SetControlInclNested {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"controlInclNested"} = $value;
}

sub GetControlInclNested {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"controlInclNested"};
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

sub SetExportPressfit {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"exportPressfit"} = $value;
}

sub GetExportPressfit {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"exportPressfit"};
}

sub SetExportToleranceHole {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"exportToleranceHole"} = $value;
}

sub GetExportToleranceHole {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"exportToleranceHole"};
}

sub SetExportNCSpecial {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"exportNCSpecial"} = $value;
}

sub GetExportNCSpecial {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"exportNCSpecial"};
}

sub SetExportCustCpnIPC3Map {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"exportCustCpnIPC3Map"} = $value;
}

sub GetExportCustCpnIPC3Map {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"exportCustCpnIPC3Map"};
}

sub SetExportDrillCpnIPC3Map {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"exportDrillCpnIPC3Map"} = $value;
}

sub GetExportDrillCpnIPC3Map {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"exportDrillCpnIPC3Map"};
}

sub SetExportPeelStencil {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"exportPeelStencil"} = $value;
}

sub GetExportPeelStencil {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"exportPeelStencil"};
}

sub SetExportCvrlStencil {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"exportCvrlStencil"} = $value;
}

sub GetExportCvrlStencil {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"exportCvrlStencil"};
}

sub SetExportPCBThick {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"exportStiffThick"} = $value;
}

sub GetExportPCBThick {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"exportStiffThick"};
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

