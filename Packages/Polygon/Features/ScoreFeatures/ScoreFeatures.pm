
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
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $layer   = shift;
	my $breakSR = shift;

	$self->{"base"}->Parse( $inCAM, $jobId, $step, $layer, $breakSR );

	my @baseFeats = $self->{"base"}->GetFeatures();
	my @features  = ();

	# add extra score information

	foreach my $f (@baseFeats) {

		my $newF = ScoreItem->new($f);

		$self->__AddGeometricAtt($newF);
		$self->__SetCourse($newF);

		push( @features, $newF );
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

	if ( abs( $f->{"x1"} - $f->{"x2"} ) < abs( $f->{"y1"} - $f->{"y2"} ) && $f->{"x1"} == $f->{"x2"} ) {
		$f->{"direction"} = "vertical";
	}
	elsif ( abs( $f->{"x1"} - $f->{"x2"} ) > abs( $f->{"y1"} - $f->{"y2"} ) && $f->{"y1"} == $f->{"y2"} ) {
		$f->{"direction"} = "horizontal";
	}
	elsif ( abs( $f->{"x1"} - $f->{"x2"} ) == abs( $f->{"y1"} - $f->{"y2"} ) ) {

		$f->{"direction"} = "diagonal";

	}
	else {

		$f->{"direction"} = undef;
	}
}

sub IsStraight {
	my $self = shift;

	# test on strictly verticall/horizontal dir
	my @undefDir = grep { $_->{"direction"} ne "vertical" && $_->{"direction"} ne "horizontal" } @{ $self->{"features"} };

	if ( scalar(@undefDir) ) {

		return 0;

	}
	else {

		return 1;
	}
}

sub ExistOverlap {
	my $self = shift;

	my @scores = @{ $self->{"features"} };

	my $exist = 0;

	# this give as point, for each point of score
	foreach my $feat (@scores) {

		my @scoOnPos = ();

		# get all scores on this point
		foreach my $sco (@scores) {

			my %infS;
			my %infE;

			if ( $feat->{"direction"} eq "horizontal" && $sco->{"y1"} == $feat->{"y1"} ) {

				%infS = ( "val" => $sco->{"x1"}, "type" => 1 );
				%infE = ( "val" => $sco->{"x2"}, "type" => -1 );
				push( @scoOnPos, \%infS );
				push( @scoOnPos, \%infE );

			}
			elsif ( $feat->{"direction"} eq "vertical" && $sco->{"x1"} == $feat->{"x1"} ) {
				%infS = ( "val" => $sco->{"y1"}, "type" => 1 );
				%infE = ( "val" => $sco->{"y2"}, "type" => -1 );

				push( @scoOnPos, \%infS );
				push( @scoOnPos, \%infE );

			}
		}

		# potencional duplicate overlapping lines
		if ( scalar(@scoOnPos) > 1 ) {

			@scoOnPos = sort { $b->{"val"} <=> $a->{"val"} } @scoOnPos;
			@scoOnPos = map  { $_->{"type"} } @scoOnPos;

			my $last = $scoOnPos[0];

			for ( my $i = 1 ; $i < scalar(@scoOnPos) ; $i++ ) {

				if ( $scoOnPos[$i] == $last ) {

					#two score ends OR score start points behind => overlap
					$exist = 1;
					last;
				}
				
				$last = $scoOnPos[$i];

			}

			if ($exist) {
				last;
			}

		}

	}

	return $exist;
}

# set direction of score from top, and from left
sub __SetCourse {
	my $self = shift;
	my $f    = shift;

	if ( $f->{"direction"} eq "horizontal" ) {

		# test x points
		if ( $f->{"x1"} > $f->{"x2"} ) {

			my $val = $f->{"x1"};
			$f->{"x1"} = $f->{"x2"};
			$f->{"x2"} = $val;
		}
	}
	elsif ( $f->{"direction"} eq "vertical" ) {

		# test y points

		if ( $f->{"y1"} < $f->{"y2"} ) {

			my $val = $f->{"y1"};
			$f->{"y1"} = $f->{"y2"};
			$f->{"y2"} = $val;

		}
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

	my $jobId = "f52456";
	my $inCAM = InCAM->new();

	my $step  = "o+2";
	my $layer = "score";

	$score->Parse( $inCAM, $jobId, $step, $layer );

	my $streit  = $score->IsStraight();
	my $overlap = $score->ExistOverlap();

	print "Overlap = " . $overlap . ".\n\n";

	my @features = $score->GetFeatures();

}

1;

