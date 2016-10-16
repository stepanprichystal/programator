
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

	print 1;
}

# Return fatures for route layer
sub GetFeatures {
	my $self = shift;

	return @{ $self->{"features"} };
}

sub __GetLineFeatures {
	my $self = shift;

	my @lines = grep { $_->{"type"} eq "L" } @{ $self->{"features"} };

	return @lines;
}

sub GetPolygonsPoints {
	my $self = shift;

	my @polygons = $self->GetClosedPolyLines();

	my @polygonsPoints = ();

	foreach my $polygon (@polygons) {

		my @polygonPoints = ();

	 
		for ( my $i = 0 ; $i < scalar(@{$polygon}); $i++ ) {	

			my $line = ${$polygon}[$i];

			my @arr = ( $line->{"x1"}, $line->{"y1"} );
			push( @polygonPoints, \@arr );
			
			if ($i ==  scalar(@{$polygon}) -1 ) {

				$line = ${$polygon}[0];
				my @arrEnd = ( $line->{"x1"}, $line->{"y1"} );
				push( @polygonPoints, \@arrEnd );
			}
		}

		push( @polygonsPoints, \@polygonPoints );

	}

	return @polygonsPoints;

}

sub GetClosedPolyLines {
	my $self = shift;

	my @lines = $self->__GetLineFeatures();

	my $x;
	my $y;
	my @polygons = ();

	# until we process all lines
	while ( scalar(@lines) ) {

		my @polygon = ();

		#take arbitrary line
		my %actLine = %{ $lines[0] };
		$x = sprintf( "%.2f", $actLine{"x2"} );
		$y = sprintf( "%.2f", $actLine{"y2"} );

		# save start point
		push( @polygon, \%actLine );
		splice @lines, 0, 1;    # dekete from list

		my $polygonFound = 0;

		while ( !$polygonFound ) {

			my $isFind = 0;

			#find next part of chain. Go through all lines
			for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {

				my %searchL = %{ $lines[$i] };
				$isFind = 0;

				# case when we find next polygon line
				if (    ( $x == sprintf( "%.2f", $searchL{"x1"} ) && $y == sprintf( "%.2f", $searchL{"y1"} ) )
					 || ( $x == sprintf( "%.2f", $searchL{"x2"} ) && $y == sprintf( "%.2f", $searchL{"y2"} ) ) )
				{
					$isFind = 1;

					#switch edge points for achieve same-oriented polygon
					if ( ( $x == sprintf( "%.3f", $searchL{"x2"} ) && $y == sprintf( "%.3f", $searchL{"y2"} ) ) ) {
						my $pX = $searchL{"x2"};
						my $pY = $searchL{"y2"};
						$searchL{"x2"} = $searchL{"x1"};
						$searchL{"y2"} = $searchL{"y1"};
						$searchL{"x1"} = $pX;
						$searchL{"y1"} = $pY;

						$searchL{"switchPoints"} = 1;
					}
					else {

						$searchL{"switchPoints"} = 0;
					}

					push( @polygon, \%searchL );

					#%actLine = %searchL;

					$x = sprintf( "%.2f", $searchL{"x2"} );
					$y = sprintf( "%.2f", $searchL{"y2"} );

					splice @lines, $i, 1;

					# go to find next line
					last;

				}
			}

			if ( $isFind == 0 ) {

				$polygonFound = 1;

				# if polygon is closed, save
				if ( scalar(@polygon) > 1 ) {
					my $firstLine = $polygon[0];
					my $lastLine  = $polygon[ scalar(@polygon) - 1 ];

					if ( $lastLine->{"x2"} == $firstLine->{"x1"} && $lastLine->{"y2"} == $firstLine->{"y1"} ) {

						# save searched polygon and search next
						push( @polygons, \@polygon );

					}

				}
			}

		}

	}

	return @polygons;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Polygon::Features::PolyLineFeatures::PolyLineFeatures';
	use aliased 'Packages::InCAM::InCAM';

	my $route = PolyLineFeatures->new();

	my $jobId = "f13609";
	my $inCAM = InCAM->new();

	my $step  = "panel";
	my $layer = "test";

	$route->Parse( $inCAM, $jobId, $step, $layer );

	my @features = $route->GetFeatures();
	my @chains   = $route->GetClosedPolyLines();
	my @points   = $route->GetPolygonsPoints();
	
	use Math::Polygon;
	
	my @areas = ();
	
	foreach my $p (@points){
		
		my $p = Math::Polygon->new(@{$p});
		my $area   = $p->area;
		
		push (@areas, $area);
		
	}
	
	 

	print 1;

}

1;

