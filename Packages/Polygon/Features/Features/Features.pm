
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
use aliased 'Packages::Polygon::PolygonPoints';

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
	my $breakSR = shift;
	
	
	my $breakSRVal;
	if($breakSR){
		$breakSRVal = "break_sr+";
	}else{
		
		$breakSRVal = "";
	}
 

	$inCAM->COM("units", "type"=> "mm");

	my $infoFile = $inCAM->INFO(
								 units           => 'mm',
								 angle_direction => 'ccw',
								 entity_type     => 'layer',
								 entity_path     => "$jobId/$step/$layer",
								 data_type       => 'FEATURES',
								 options         => $breakSRVal."feat_index+f0",
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

# Return features by feature id (unique per layer)
sub GetFeatureById {
	my $self = shift;
	my $id = shift;

	my @features = grep { $_->{"id"} eq $id }  @{ $self->{"features"} };
	
	# feature id are unique per layer, but when BreakSR, more feature can have same id
	if(scalar(@features)){
		return @features
	}else{
		
		return 0;
	}

}

# Return features by feature id (unique per layer)
sub GetFeatureByGroupGUID {
	my $self = shift;
	my $groupGuid = shift;

	my @features = grep { $_->{"att"}->{"feat_group_id"} eq $groupGuid }  @{ $self->{"features"} };
	
	# feature id are unique per layer, but when BreakSR, more feature can have same id
	if(scalar(@features)){
		return @features
	}else{
		
		return 0;
	}

}

sub __ParseLines {

	my $self  = shift;
	my @lines = @{ shift(@_) };

	my @features = ();

	for(my $i = 0; $i < scalar(@lines); $i++) {
		
		my $l = $lines[$i];

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
			
			my $l = $lines[$i];
			
			$i++;
			my @envelop = ();
			while ( $lines[$i] =~ m/^#\s*#o[besc]\s*((-?[0-9]*\.?[0-9]*\s)*)/i ){
				
				my $lll = $lines[$i];
				my $lll2 = $1;
				
				my @points = split( /\s/, $1 );
				
				for(my $ip = 0;  $ip <scalar(@points); $ip +=2){
					
					my @p = ( sprintf("%.2f",$points[$ip]),  sprintf("%.2f",$points[$ip+1]) ); # x and y
					push(@envelop, \@p);
				}
 
				$i++;
			}
			
			$i--;

			# 1) Reduce same point from surface
			my @envReduced = ();
			foreach my $e (@envelop){
				
				unless(grep { @{$_}[0] == @{$e}[0]  &&    @{$_}[1] == @{$e}[1]} @envReduced ){

					push(@envReduced, $e);
				} 
			}
			
			# 2 ) If points cnt is smaller than 3, do not envelop
			my @envelopFinal = ();
			if(scalar(@envReduced) < 3){
				push(@envelopFinal, $envReduced[0]);
			}else{
				@envelopFinal = PolygonPoints->GetConvexHull(\@envelop);
			 
			}
			
			my @envelopFinalHash = ();
			foreach my $p (@envelopFinal){
				my %pInf = ("x" => @{$p}[0], "y" => @{$p}[1]);
 				push(@envelopFinalHash, \%pInf);
			}
	 
			$featInfo->{"envelop"} = \@envelopFinalHash;
			
			# 3) Set center point of surface
			my $centroid = PolygonPoints->GetCentroid(\@envelopFinal);
 	
		
		}else{
			
			next;
		}

	 
	 	# parse attributes
		foreach my $at (@attr) {

			my @attValue = split( "=", $at );
			
			my $attVal = $attValue[1]; 
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

