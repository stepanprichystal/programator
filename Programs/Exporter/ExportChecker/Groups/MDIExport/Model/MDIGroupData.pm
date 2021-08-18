
#-------------------------------------------------------------------------------------------#
# Description: Cover merging, spliting and checking before exporting NC files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::MDIExport::Model::MDIGroupData;



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

 
# Layer couples
sub SetLayerCouples {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"layerCouples"} = $value;
}

sub GetLayerCouples {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"layerCouples"};
}

# Settings of each layer
sub SetLayersSettings {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"layersSettings"} = $value;
}

sub GetLayersSettings {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"layersSettings"};
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

