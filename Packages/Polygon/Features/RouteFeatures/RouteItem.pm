
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
	my $class    = shift;
	my $baseItem = shift;
	my $self     = {};

	$self = { %$self, %$baseItem };

	bless $self;

	#direction of score
	#$self->{"direction"} = undef;

	return $self;
}

# Move while feature
sub Move {
	my $self = shift;
	my $x    = shift;
	my $y    = shift;

	if ( $self->{"type"} eq "P" ) {

		$self->{"x1"} += $x;
		$self->{"y1"} += $y;

	}

	if ( $self->{"type"} eq "L" ) {

		$self->{"x1"} += $x;
		$self->{"y1"} += $y;
		$self->{"x2"} += $x;
		$self->{"y2"} += $y;

	}

	if ( $self->{"type"} eq "A" ) {

		$self->{"x1"}   += $x;
		$self->{"y1"}   += $y;
		$self->{"x2"}   += $x;
		$self->{"y2"}   += $y;
		$self->{"xmid"} += $x;
		$self->{"ymid"} += $y;

	}

	if ( $self->{"type"} eq "T" ) {

		$self->{"x1"} += $x;
		$self->{"y1"} += $y;

	}

	if ( $self->{"type"} eq "A" ) {

		foreach my $surf ( @{ $self->{"surfaces"} } ) {

			foreach my $surfShape ( ( @{ $surf->{"island"} }, @{ $surf->{"holes"} } ) ) {
				$surfShape->{"x"} -= $x;
				$surfShape->{"y"} -= $y;

				# C - point defined by circle, store center point of circle
				if ( $surfShape->{"type"} eq "c" ) {

					$surfShape->{"xmid"} -= $x;
					$surfShape->{"ymid"} -= $y;
				}
			}
		}
	}
	
	
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

