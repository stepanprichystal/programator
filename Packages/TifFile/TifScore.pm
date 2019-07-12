
#-------------------------------------------------------------------------------------------#
# Description: TifFile - interface for score programs
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::TifFile::TifScore;
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

	$self->{"key"} = "score";

	return $self;
}

sub GetScoreThick {
	my $self = shift;

	return  $self->{"tifData"}->{ $self->{"key"} }->{"materialThickness"};

}

sub SetScoreThick {
	my $self         = shift;
	my $matThickness = shift;

	$self->{"tifData"}->{ $self->{"key"} }->{"materialThickness"} = $matThickness;

	$self->_Save();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

