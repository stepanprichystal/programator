
#-------------------------------------------------------------------------------------------#
# Description: Class provide function for loading / saving tif file
# TIF - technical info file - contain onformation important for produce, for technical list,
# another support script use this file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::TifFile::TifFile::TifFile;

#3th party library
use strict;
use warnings;
use JSON;

#local library
use aliased 'Helpers::JobHelper';
use aliased "Helpers::FileHelper";

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"jobId"} = shift;

	$self->{"filePath"} = JobHelper->GetJobArchive( $self->{"jobId"} ) . $self->{"jobId"} . ".dif";

	my %tifData = ();
	$self->{"tifData"} = \%tifData;

	$self->__LoadTifFile();

	return $self;
}

sub TifFileExist {
	my $self = shift;

	if (-e $self->{"filePath"} ) {
		return 1;
	}
	else {
		return 0;
	}

}

sub __LoadTifFile {
	my $self = shift;

	if ( -e $self->{"filePath"} ) {

		# read from disc
		# Load data from file
		my $serializeData = FileHelper->ReadAsString( $self->{"filePath"} );

		my $json = JSON->new();

		my $hashData = $json->decode($serializeData);

		$self->{"tifData"} = $hashData;
	}
}

sub _Save {
	my $self = shift;

	my $json = JSON->new();

	my $serialized = $json->pretty->encode( $self->{"tifData"} );

	#delete old file
	if ( -e $self->{"filePath"} ) {
		unlink $self->{"filePath"};
	}

	open( my $f, '>', $self->{"filePath"} );
	print $f $serialized;
	close $f;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

