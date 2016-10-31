
#-------------------------------------------------------------------------------------------#
# Description: Class can parse incam layer fetures for score. 
# This is decorator of base Features.pm
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Polygon::Features::ScoreFeatures::ScoreFeatures;

use Class::Interface;

&implements('Packages::Polygon::Features::IFeatures');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Packages::Polygon::Features::ScoreFeatures::ScoreItem';

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
	my $breakSR = shift;

	$self->{"base"}->Parse( $inCAM, $jobId, $step, $layer,  $breakSR);

	my @baseFeats = $self->{"base"}->GetFeatures();
	my @features = ();

	# add extra score information
	
	foreach my $f (@baseFeats) {

		my $newF = ScoreItem->new($f);

		$self->__AddGeometricAtt($newF);
		
		push(@features, $newF);
	}

	$self->{"features"} = \@features;

}

# Return fatures for score layer
sub GetFeatures {
	my $self = shift;

	return @{ $self->{"features"} };
}

# do some computation with score lines
sub __AddGeometricAtt {
	my $self = shift;
	my $f    = shift;

	#direction of score
	$f->{"direction"} = "";

	if ( abs( $f->{"x1"} - $f->{"x2"} ) < abs( $f->{"y1"} - $f->{"y2"} ) ) {
		$f->{"direction"} = "vertical";
	}
	elsif ( abs( $f->{"x1"} - $f->{"x2"} ) > abs( $f->{"y1"} - $f->{"y2"} ) ) {
		$f->{"direction"} = "horizontal";
	}
	elsif ( abs( $f->{"x1"} - $f->{"x2"} ) == abs( $f->{"y1"} - $f->{"y2"} ) ) {

		$f->{"direction"} = "diagonal";
	}
}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Polygon::Features::ScoreFeatures::ScoreFeatures';
	use aliased 'Packages::InCAM::InCAM';
	
	my $score = ScoreFeatures->new();

	my $jobId = "F13608";
	my $inCAM = InCAM->new();

	my $step  = "panel";
	my $layer = "fr";
	
	$score->Parse($inCAM, $jobId, $step, $layer);
	
	my @features = $score->GetFeatures();
	

}

1;

