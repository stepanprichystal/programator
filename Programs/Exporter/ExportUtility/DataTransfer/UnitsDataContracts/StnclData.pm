
#-------------------------------------------------------------------------------------------#
# Description: Data definition for group. This data struct are used  as data transfer
# between ExportChecker and ExportUtility
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::DataTransfer::UnitsDataContracts::StnclData;
 
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
 
 # Stencil thickness
sub SetThickness {
	my $self  = shift;

	$self->{"data"}->{"thickness"} = shift;
}

sub GetThickness {
	my $self = shift;
 
	return $self->{"data"}->{"thickness"};
}
 

# Export nif file
sub SetExportNif {
	my $self  = shift;
	 
	$self->{"data"}->{"exportNif"} = shift;
}

sub GetExportNif {
	my $self = shift;

	return $self->{"data"}->{"exportNif"};
}

# Export data files (gerbers, nc programs)
sub SetExportData {
	my $self  = shift;
	
	$self->{"data"}->{"exportData"} = shift;
}

sub GetExportData {
	my $self = shift;

	return $self->{"data"}->{"exportData"};
}

# Export pdf file
sub SetExportPdf {
	my $self  = shift;
	 
	$self->{"data"}->{"exportPdf"} = shift;
}

sub GetExportPdf {
	my $self = shift;

	return $self->{"data"}->{"exportPdf"};
}


# Export measure data
sub SetExportMeasureData {
	my $self  = shift;
	 
	$self->{"data"}->{"exportMeasureData"} = shift;
}

sub GetExportMeasureData {
	my $self = shift;

	return $self->{"data"}->{"exportMeasureData"};
}

# Fiducial info
sub SetFiducialInfo {
	my $self  = shift;
	 
	$self->{"data"}->{"fiducialInfo"} = shift;
}

sub GetFiducialInfo {
	my $self = shift;

	return $self->{"data"}->{"fiducialInfo"};
}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

