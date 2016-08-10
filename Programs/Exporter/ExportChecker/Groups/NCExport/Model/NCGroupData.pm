
#-------------------------------------------------------------------------------------------#
# Description: Cover merging, spliting and checking before exporting NC files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NCExport::Model::NCGroupData;

use Class::Interface;
&implements('Programs::Exporter::ExportChecker::Groups::IGroupData');


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
	#my %data = %{ $self->{"data"} };
	return %{ $self->{"data"} };
}

sub SetExportAll {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"exportSingle"} = $value;
}

sub SetPltLayers {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"pltLayers"} = $value;
}

sub SetNPltLayers {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"npltLayers"} = $value;
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

