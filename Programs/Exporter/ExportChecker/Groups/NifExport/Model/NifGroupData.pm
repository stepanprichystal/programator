
#-------------------------------------------------------------------------------------------#
# Description: Cover merging, spliting and checking before exporting NC files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifGroupData;

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

sub SetTenting {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"tenting"} = $value;
}

sub SetMaska01 {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"maska01"} = $value;
}

sub SetPressfit {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"pressfit"} = $value;
}

sub SetNotes {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"notes"} = $value;
}

sub SetDatacode {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"datacode"} = $value;
}

sub SetUlLogo {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"ul_logo"} = $value;
}

sub SetJumpScoring {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"prerusovana_drazka"} = $value;
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

