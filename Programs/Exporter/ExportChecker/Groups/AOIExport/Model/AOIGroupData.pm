
#-------------------------------------------------------------------------------------------#
# Description: Cover merging, spliting and checking before exporting NC files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::AOIExport::Model::AOIGroupData;

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
 
 
# layers to test 
sub SetLayers {
	my $self  = shift;
	$self->{"data"}->{"layers"} = shift;
}

sub GetLayers {
	my $self  = shift;
	return $self->{"data"}->{"layers"};
} 

sub SetSendToServer {
	my $self  = shift;
	$self->{"data"}->{"sendToServer"} = shift;
}

sub GetSendToServer {
	my $self  = shift;
	return $self->{"data"}->{"sendToServer"};
} 

# Include panel frame to testing
sub SetIncldMpanelFrm {
	my $self  = shift;
	$self->{"data"}->{"incldMpanelFrm"} = shift;
}

sub GetIncldMpanelFrm {
	my $self  = shift;
	return $self->{"data"}->{"incldMpanelFrm"};
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

