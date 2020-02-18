
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::SectionBuilders::ISectionBuilder;

#3th party library
use strict;
use warnings;

#use File::Copy;

#local library

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"key"}   = shift;
	$self->{"width"} = shift;

	return $self;
}

sub GetKey {
	my $self = shift;

	return $self->{"key"};

}

sub GetWidth {
	my $self = shift;

	return $self->{"width"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

