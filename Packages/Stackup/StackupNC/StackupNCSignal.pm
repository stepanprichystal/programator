
#-------------------------------------------------------------------------------------------#
# Description: Contain inforamtion about Top/bot copper, which is tied with pressing/core
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupNC::StackupNCSignal;

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

	#only if materialType is copper
	$self->{"name"} = shift;

	# c = 1, v2 = 2, v3 = 3, v4 = 4,......, s = order of last layer
	$self->{"number"} = shift;

	return $self;
}

sub GetName {
	my $self = shift;

	return $self->{"name"};

}

sub GetNumber {
	my $self = shift;

	return $self->{"number"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

