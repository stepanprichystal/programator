
#-------------------------------------------------------------------------------------------#
# Description: TifFile - interface for pol mother
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::TifFile::TifPoolMother;
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

	$self->{"key"} = "poolMother";

	return $self;
}

sub GetFormerOuterClass {
	my $self = shift;

	return $self->{"tifData"}->{ $self->{"key"} }->{"outerClass"};

}

sub SetFormerOuterClass {
	my $self  = shift;
	my $class = shift;

	$self->{"tifData"}->{ $self->{"key"} }->{"outerClass"} = $class;

	$self->_Save();
}


sub GetFormerInnerClass {
	my $self = shift;

	return $self->{"tifData"}->{ $self->{"key"} }->{"innerClass"};

}

sub SetFormerInnerClass {
	my $self  = shift;
	my $class = shift;

	$self->{"tifData"}->{ $self->{"key"} }->{"innerClass"} = $class;

	$self->_Save();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

