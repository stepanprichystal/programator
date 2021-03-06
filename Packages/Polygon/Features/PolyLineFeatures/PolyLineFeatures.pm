
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
	my $self        = shift;
	my $preselected = shift;    # if is request parse only some features

	my @features = @{ $self->{"features"} };

	if ($preselected) {

		@features = @{$preselected};
	}

	my @lines = grep { $_->{"type"} eq "L" || $_->{"type"} eq "A" } @features;
	my @sequences = RoutCyclic->GetRoutSequences( \@lines );

	my @polygons = ();

	foreach my $seq (@sequences) {

		my %result = RoutCyclic->GetSortedRout($seq);

		if ( $result{"result"} ) {
			push( @polygons, $result{"edges"} );
		}
		else {

			die "Polygon features are not cyclic. Feature Ids: " . join( "; ", map { $_->{"id"} } @{$seq} );
		}
	}

	return @polygons;
}

# Return if features are cyclic in layer
sub GetPolygonsAreCyclic {
	my $self        = shift;
	my $preselected = shift;    # if is request parse only some features

	my $cyclic = 1;

	my @features = @{ $self->{"features"} };

	@features = @{$preselected} if ($preselected);

	my @lines = grep { $_->{"type"} eq "L" || $_->{"type"} eq "A" } @features;

	foreach my $seq ( RoutCyclic->GetRoutSequences( \@lines ) ) {

		my %result = RoutCyclic->GetSortedRout($seq);

		unless ( $result{"result"} ) {
			$cyclic = 0;
			last;
		}
	}

	return $cyclic;
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

	use aliased 'Packages::Polygon::Features::PolyLineFeatures::PolyLineFeatures';
	use aliased 'Packages::InCAM::InCAM';

	my $route = PolyLineFeatures->new();

	my $jobId = " d245265";
	my $inCAM = InCAM->new();

	my $step  = " o+1";
	my $layer = " test";

	$route->Parse( $inCAM, $jobId, $step, $layer );

	my @features = $route->GetPolygonsFeatures();

}

1;

