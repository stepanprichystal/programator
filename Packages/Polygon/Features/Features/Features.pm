
#-------------------------------------------------------------------------------------------#
# Description: Class can parse incam layer fetures. Parsed features, contain only
# basic info like coordinate, attrubutes etc..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Polygon::Features::Features::Features;

use Class::Interface;

&implements('Packages::Polygon::Features::IFeatures');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::Polygon::Features::Features::Item';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};
	bless $self;

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

	$inCAM->COM("units", "type"=> "mm");

	my $infoFile = $inCAM->INFO(
								 units           => 'mm',
								 angle_direction => 'ccw',
								 entity_type     => 'layer',
								 entity_path     => "$jobId/$step/$layer",
								 data_type       => 'FEATURES',
								 options         => "feat_index+f0",
								 parse           => 'no'
	);
	my $f;
	open( $f, "<" . $infoFile );
	my @feat = <$f>;
	close($f);
	unlink($infoFile);

	my @features = $self->__ParseLines( \@feat );

	$self->{"features"} = \@features;

}

sub GetFeatures {
	my $self = shift;

	return @{ $self->{"features"} };

}

sub __ParseLines {

	my $self  = shift;
	my @lines = @{ shift(@_) };

	my @features = ();

	foreach my $l (@lines) {

		if ( $l =~ /###/ ) { next; }

		my $featInfo = Item->new();
		
		my @attr = ();


		# line, arcs, pads
		if($l =~ m/^#(\d*)\s*#(\w)\s*((-?[0-9]*\.?[0-9]*\s)*)\s*r([0-9]*\.?[0-9]*)\s*([\w\d\s]*);?(.*)/i)
		{
			$featInfo->{"id"}   = $1;
			$featInfo->{"type"} = $2;
			
			my @points = split( /\s/, $3 );
			
			#remove sign from zero value, when after rounding there minus left
 

			$featInfo->{"x1"} = $points[0];
			$featInfo->{"y1"} = $points[1];
			$featInfo->{"x2"} = $points[2];
			$featInfo->{"y2"} = $points[3];

			$featInfo->{"thick"} = $5;
			
			
			if ( $featInfo->{"type"} eq "A" ) {

			#$featInfo->{"xmid"} = sprintf( "%.3f", $points[4] );
			#$featInfo->{"ymid"} = sprintf( "%.3f", $points[5] );
			$featInfo->{"xmid"} = $points[4];
			$featInfo->{"ymid"} = $points[5];

			my $dir = $6;
			$dir =~ m/([YN])/;
			$featInfo->{"oriDir"} = $1 eq "Y" ? "CW" : "CCW";
			}
			
			
			@attr = split( ",", $7 );
		 
			
		}
		# surfaces
		elsif($l =~ m/^#(\d*)\s*#(s)\s*([\w\d\s]*);?(.*)/i){
		
			$featInfo->{"id"}   = $1;
			$featInfo->{"type"} = $2;
			@attr = split( ",", $4 );	
		
		}else{
			
			next;
		}

	 
	 	# parse attributes
		foreach my $at (@attr) {

			my @attValue = split( "=", $at );
			$featInfo->{"att"}{ $attValue[0] } = $attValue[1];
		}

		push( @features, $featInfo );
	}

	return @features;
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

