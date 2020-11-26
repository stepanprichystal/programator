#-------------------------------------------------------------------------------------------#
# Description: Group data
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PdfExport::Model::PdfGroupData;

#use Class::Interface;
#&implements('Programs::Exporter::ExportChecker::Groups::IGroupData');

#3th party library
use strict;
use warnings;
use File::Copy;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $self = shift;
	$self = {};
	bless $self;

	my %exportData = ();
	$self->{"data"} = \%exportData;

	return $self;    # Return the reference to the hash.
}

# paste info, hash with info

sub GetData {
	my $self = shift;
	return %{ $self->{"data"} };
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

sub GetControlLang {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"controlLang"};
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

sub SetExportStiffThick {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"exportStiffThick"} = $value;
}

sub GetExportStiffThick {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"exportStiffThick"};
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::NCExport::NCExportGroup';
	#
	#	my $jobId    = "F13608";
	#	my $stepName = "panel";
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $ncgroup = NCExportGroup->new( $inCAM, $jobId );
	#
	#	$ncgroup->Run();

	#print $test;

}

1;

