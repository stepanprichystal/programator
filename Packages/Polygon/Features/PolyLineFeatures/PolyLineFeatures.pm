
#-------------------------------------------------------------------------------------------#
# Description: Class can parse incam layer fetures for route.
# This is decorator of base Features.pm
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Polygon::Features::PolyLineFeatures::PolyLineFeatures;

use Class::Interface;

&implements('Packages::Polygon::Features::IFeatures');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Packages::Routing::RoutLayer::RoutParser::RoutCyclic';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	#instance of  "base" class Features.pm
	$self->{"base"} = Features->new();

	my @features = ();
	$self->{"features"} = \@features;

	return $self;
}

#parse features layer
sub Parse {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;

	$self->{"base"}->Parse( $inCAM, $jobId, $step, $layer );

	$self->{"features"} = $self->{"base"}->{"features"};

	#print 1;
}

# Return fatures for route layer
sub GetFeatures {
	my $self = shift;

	return @{ $self->{"features"} };
}

 
sub GetPolygonsFeatures {
	my $self = shift;

	my @lines     = grep { $_->{"type"} eq "L"  ||  $_->{"type"} eq "A"} @{ $self->{"features"} };
	my @sequences = RoutCyclic->GetRoutSequences( \@lines );

	my @polygons = ();

	foreach my $seq (@sequences) {

		my %result = RoutCyclic->GetSortedRout($seq);

		if ( $result{"result"} ) {
			push(@polygons, $result{"edges"});
		}
		else {

			die "Polygon features are not cyclic";
		}
	} 
	
	return @polygons;
}
 
sub GetPolygonsPoints {
	my $self = shift;

	my @polygons = $self->GetPolygonsFeatures();

	my @polygonsPoints = ();

	foreach my $polygon (@polygons) {

		my @polygonPoints = ();

		for ( my $i = 0 ; $i < scalar( @{$polygon} ) ; $i++ ) {

			my $line = ${$polygon}[$i];

			my @arr = ( $line->{"x1"}, $line->{"y1"} );
			push( @polygonPoints, \@arr );

			if ( $i == scalar( @{$polygon} ) - 1 ) {

				$line = ${$polygon}[0];
				my @arrEnd = ( $line->{"x1"}, $line->{"y1"} );
				push( @polygonPoints, \@arrEnd );
			}
		}

		push( @polygonsPoints, \@polygonPoints );

	}

	return @polygonsPoints;

}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {
#
#	use aliased 'Packages::Polygon::Features::PolyLineFeatures::PolyLineFeatures';
#	use aliased 'Packages::InCAM::InCAM';
#
#	my $route = PolyLineFeatures->new();
#
#	my $jobId = "f13609";
#	my $inCAM = InCAM->new();
#
#	my $step  = "panel";
#	my $layer = "test";
#
#	$route->Parse( $inCAM, $jobId, $step, $layer );
#
#	my @features = $route->GetFeatures();
#	my @chains   = $route->GetClosedPolyLines();
#	my @points   = $route->GetPolygonsPoints();
#
#	use Math::Polygon;
#
#	my @areas = ();
#
#	foreach my $p (@points) {
#
#		my $p    = Math::Polygon->new( @{$p} );
#		my $area = $p->area;
#
#		push( @areas, $area );
#
#	}

	#print 1;

}

1;

