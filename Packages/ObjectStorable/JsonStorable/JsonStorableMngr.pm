
#-------------------------------------------------------------------------------------------#
# Description: Is responsible for saving/loading JSON serialized file to/from disc
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ObjectStorable::JsonStorable::JsonStorableMngr;

#3th party library
use strict;
use warnings;
use utf8;
use JSON;

#local library

use aliased "Helpers::FileHelper";
use aliased 'Packages::ObjectStorable::JsonStorable::JsonStorable';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"filePath"} = shift;

	$self->{"jsonStorable"} = JsonStorable->new();

	return $self;
}

# Return 1 if serialized file exist
sub SerializedDataExist{
	my $self = shift;
	
	return (-e $self->{"filePath"}) ? 1 : 0;
}


# Load serialized data
sub LoadData {
	my $self = shift;

	unless ( -e $self->{"filePath"} ) {
		die "Serialized data file doesn't exist: " . $self->{"filePath"};
	}

	my $serializeData = FileHelper->ReadAsString( $self->{"filePath"} );
	my $data          = $self->{"jsonStorable"}->Decode($serializeData);

	return $data;
}

# Serialize class "ExportData"
# Data has to be reference type and implement  Packages::ObjectStorable::JsonStorable::IJsonStorable
sub StoreData {
	my $self = shift;
	my $data = shift;    # data ref

	my $serialized = $self->{"jsonStorable"}->Encode($data);

	#delete old file

	unlink $self->{"filePath"};
	open( my $f, '>', $self->{"filePath"} ) or die "Unable create serialized data file: " . $self->{"filePath"};
	print $f $serialized;
	close $f;
	
	return 1;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::StorageMngr';

	#my $id

	#my $form = StorageMngr->new();

}

1;

