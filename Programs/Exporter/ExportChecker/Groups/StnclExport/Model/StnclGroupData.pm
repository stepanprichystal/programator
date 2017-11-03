
#-------------------------------------------------------------------------------------------#
# Description: Cover merging, spliting and checking before exporting NC files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::StnclExport::Model::StnclGroupData;

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

