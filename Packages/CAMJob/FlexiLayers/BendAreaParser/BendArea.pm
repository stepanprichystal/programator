
#-------------------------------------------------------------------------------------------#
# Description: Bend area contains:
# - reference to 2 transition zones
# - features which crates whole bend area
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::FlexiLayers::BendAreaParser::BendArea;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Connectors::TpvConnector::TpvMethods';
use aliased 'Enums::EnumsDrill';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"features"}  = shift;
	$self->{"tranZones"} = shift;
	return $self;
}

sub GetTransitionZones {
	my $self = shift;

	return @{ $self->{"tranZones"} }

}

sub GetFeatures {
	my $self = shift;
	return @{ $self->{"features"} };
}

# Return array of points which form bend area polygon
# Polygon is closed: first point coonrdinate == last point
# Each point is defined by hash:
# - x; y       = coordinate of next point
# - xmid; ymid = coordinate of center of arc
# - dir        = direction of arc (cw/ccw) Enums->Dir_CW;Enums->Dir_CW
sub GetPoints {
	my $self = shift;

	my @polygonPoints = ();
	my @features      = $self->GetFeatures();

	# first point of polygon
	push( @polygonPoints, { "x" => $features[0]->{"x1"}, "y" => $features[0]->{"y1"} } );

	for ( my $i = 0 ; $i < scalar( @{ $self->{"features"} } ) ; $i++ ) {

		my $f = $self->{"features"}->[$i];

		my %p = ();
		$p{"x"} = $f->{"x2"};
		$p{"y"} = $f->{"y2"};
		if ( $f->{"type"} eq "A" ) {

			$p{"xmid"} = $f->{"xmid"};
			$p{"ymid"} = $f->{"ymid"};
			$p{"dir"}  = $f->{"newDir"};
		}
 
		push( @polygonPoints, \%p );
	}

	return @polygonPoints;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

