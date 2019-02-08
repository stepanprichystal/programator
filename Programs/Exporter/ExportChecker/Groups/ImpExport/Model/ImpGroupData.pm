
#-------------------------------------------------------------------------------------------#
# Description: Cover merging, spliting and checking before exporting NC files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::ImpExport::Model::ImpGroupData;



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

sub GetData {
	my $self = shift;
	return %{ $self->{"data"} };
}

# Export impedance measurement pdf
sub SetExportMeasurePdf {
	my $self  = shift;
	$self->{"data"}->{"exportMeasurePdf"} = shift;
}

sub GetExportMeasurePdf {
	my $self  = shift;
	return $self->{"data"}->{"exportMeasurePdf"};
}


# Create MultiCall pdf from InStack
sub SetBuildMLStackup {
	my $self  = shift;
	$self->{"data"}->{"buildMLStackup"} = shift;
}

sub GetBuildMLStackup {
	my $self  = shift;
	return $self->{"data"}->{"buildMLStackup"};
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

