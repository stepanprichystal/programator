
#-------------------------------------------------------------------------------------------#
# Description: Cover merging, spliting and checking before exporting NC files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::GerExport::Model::GerGroupData;

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

sub SetPasteInfo {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"pasteInfo"} = $value;
}

sub GetPasteInfo {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"pasteInfo"};
}
 
 
# export layers
sub SetExportLayers {
	my $self  = shift;
	$self->{"data"}->{"exportLayers"} = shift;
} 


sub GetExportLayers {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"exportLayers"};
}
 
# layers to export 
sub SetLayers {
	my $self  = shift;
	$self->{"data"}->{"layers"} = shift;
}

sub GetLayers {
	my $self  = shift;
	return $self->{"data"}->{"layers"};
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

