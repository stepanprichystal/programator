
#-------------------------------------------------------------------------------------------#
# Description: TifFile - interface for score programs
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::TifFile::TifET;
use base ('Packages::TifFile::TifFile::TifFile');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"key"} = "et";

	return $self;
}

sub GetTotalTestPoint {
	my $self = shift;

	return  $self->{"tifData"}->{ $self->{"key"} }->{"totalTestPointCnt"};

}

sub SetTotalTestPoint {
	my $self         = shift;
	my $TPCount = shift;

	$self->{"tifData"}->{ $self->{"key"} }->{"totalTestPointCnt"} = $TPCount;

	$self->_Save();
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

