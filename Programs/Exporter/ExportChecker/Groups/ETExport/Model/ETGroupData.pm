
#-------------------------------------------------------------------------------------------#
# Description: Cover merging, spliting and checking before exporting NC files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::ETExport::Model::ETGroupData;



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

# If create et step
sub SetCreateEtStep {
	my $self  = shift;
	$self->{"data"}->{"createEtStep"} = shift;
}

sub GetCreateEtStep {
	my $self  = shift;
	return $self->{"data"}->{"createEtStep"};
}
 
 
# Keep sr profile of nested steps
sub SetKeepProfiles {
	my $self  = shift;
	$self->{"data"}->{"keepProfiles"} = shift;
}

sub GetKeepProfiles {
	my $self  = shift;
	return $self->{"data"}->{"keepProfiles"};
} 

# Copy local ipc to file
sub SetLocalCopy {
	my $self  = shift;
	$self->{"data"}->{"localCopy"} = shift;
}

sub GetLocalCopy {
	my $self  = shift;
	return $self->{"data"}->{"localCopy"};
}

# Copy server ipc to file
sub SetServerCopy {
	my $self  = shift;
	$self->{"data"}->{"serverCopy"} = shift;
}

sub GetServerCopy {
	my $self  = shift;
	return $self->{"data"}->{"serverCopy"};
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

