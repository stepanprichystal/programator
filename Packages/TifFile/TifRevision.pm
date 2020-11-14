
#-------------------------------------------------------------------------------------------#
# Description: TifFile - interface for revision - instructions for reorder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::TifFile::TifRevision;
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

	$self->{"key"} = "revision";

	return $self;
}

sub GetRevisionIsActive {
	my $self = shift;

	return  $self->{"tifData"}->{ $self->{"key"} }->{"isActive"};

}

sub SetRevisionIsActive {
	my $self         = shift;
	my $isActive = shift;

	$self->{"tifData"}->{ $self->{"key"} }->{"isActive"} = $isActive;

	$self->_Save();
}

sub GetRevisionText {
	my $self = shift;

	return  $self->{"tifData"}->{ $self->{"key"} }->{"text"};

}

sub SetRevisionText {
	my $self         = shift;
	my $revText = shift;

	$self->{"tifData"}->{ $self->{"key"} }->{"text"} = $revText;

	$self->_Save();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

