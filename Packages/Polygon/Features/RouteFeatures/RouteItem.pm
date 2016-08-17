
#-------------------------------------------------------------------------------------------#
# Description: Contain score property of layer feature
# Author:SPR
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Polygon::Features::RouteFeatures::RouteItem;
use base('Packages::Polygon::Features::Features::Item');

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $baseItem = shift;
	my $self  = {};

	$self = { %$self, %$baseItem };
	
	bless $self;
 

	#direction of score
	#$self->{"direction"} = undef;
 
	return $self;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

