
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

	# Integer InCam feature id
	$self->{"id"} = undef;

	# Integer Unique id assigned by Feature parser (counted from 1)
	$self->{"uid"} = undef;

	# feature source step
	$self->{"step"} = undef;

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

	# symbol name
	$self->{"symbol"} = undef;

	# features polarity
	$self->{"polarity"} = undef;

	# features dcode
	$self->{"dcode"} = undef;

	# text value of type text
	$self->{"text"} = undef;

	# array of surface item (holes and ilands)
	$self->{"surfaces"} = undef;

	#attributes of features
	$self->{"att"} = undef;

	# Properties set only if breakSR during parse layer

	# feature source step ancestors in string format: <ancestor>/<ancestor parent>/...
	$self->{"SRAncestors"} = undef;

	return $self;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

