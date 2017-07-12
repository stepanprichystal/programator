
#-------------------------------------------------------------------------------------------#
# Description: Contain basic property of layer feature
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Polygon::Features::Features::Item;

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	# Id of features
	$self->{"id"} = undef;

	# type of features - L, A, etc..
	$self->{"type"} = undef;

	#first x
	$self->{"x1"} = undef;
	
	#second  x, if line or arc
	$self->{"x2"} = undef;

	#first y
	$self->{"y1"} = undef;

	#second y, if line or arc
	$self->{"y2"} = undef;

	#thick of symbol
	$self->{"thick"} = undef;

	#x center of arc
	$self->{"xmid"} = undef;

	#y center of arc
	$self->{"ymid"} = undef;

	$self->{"oriDir"} = undef;
	
	# text value of type text
	$self->{"text"} = undef;

	#attributes of features
	$self->{"att"} = undef;
	
	# surface envelop
	my @points = ();
	$self->{"envelop"} = \@points; # start and end points are not equal

	return $self;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

