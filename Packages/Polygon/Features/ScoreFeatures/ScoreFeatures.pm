
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

	$self->{"microns"}         = shift;
	$self->{"accuracy"}        = shift // ($self->{"microns"} ? 20 : 0.02);   # 20?m is value, which score line could be not strictly ("vertical/horiyontal")
	$self->{"accuracyOverlap"} = shift // ($self->{"microns"} ? 500 : 0.5);    # 500? is min allowed parallel overlap (see existParallelOverlap())
                                                            #instance of  "base" class Features.pm
	$self->{"base"}            = Features->new();

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

	# filter only lines
	@baseFeats = grep { $_->{"type"} =~ /^L$/i } @baseFeats;

	my @features = ();

	# add extra score information

	foreach my $f (@baseFeats) {

		my $newF = ScoreItem->new($f);

		if ( $self->{"microns"} ) {
			$self->__ToMicron($newF);
		}

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

	if ( abs( $f->{"x1"} - $f->{"x2"} ) < abs( $f->{"y1"} - $f->{"y2"} ) && abs( $f->{"x1"} - $f->{"x2"} ) < $self->{"accuracy"} ) {
		$f->{"direction"} = "vertical";

		$f->{"x2"} = $f->{"x1"};    # if score is according accuracy, do it strictly straight

	}
	elsif ( abs( $f->{"x1"} - $f->{"x2"} ) > abs( $f->{"y1"} - $f->{"y2"} ) && abs( $f->{"y1"} - $f->{"y2"} ) < $self->{"accuracy"} ) {
		$f->{"direction"} = "horizontal";

		$f->{"y2"} = $f->{"y1"};    # if score is according accuracy, do it strictly straight

	}
	elsif ( abs( $f->{"x1"} - $f->{"x2"} ) == abs( $f->{"y1"} - $f->{"y2"} ) ) {

		$f->{"direction"} = "diagonal";

	}
	else {

		$f->{"direction"} = undef;
	}

	# Add length of score
	if ( $f->{"direction"} eq "vertical" ) {

		$f->{"length"} = abs( $f->{"y1"} - $f->{"y2"} );

	}
	elsif ( $f->{"direction"} eq "horizontal" ) {

		$f->{"length"} = abs( $f->{"x1"} - $f->{"x2"} );
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

# test overlapping example 2 lines on same position
# L1 start, L2start, L1 end, L2 End
# OR
# L1 start, L2start, L2 end, L1 End
# etc
sub ExistOverlap {
	my $self = shift;

	$self->__ExistOverlap( $self->{"features"} );
}

# test overlapping example 2 lines on same position
# L1 start, L2start, L1 end, L2 End
# OR
# L1 start, L2start, L2 end, L1 End
# etc
sub __ExistOverlap {
	my $self   = shift;
	my @scores = @{ shift(@_) };

	my $exist = 0;

	# this give as point, for each point of score
	foreach my $feat (@scores) {

		my @scoOnPos = ();
		my $dir      = $feat->{"direction"};
		my %point    = ( "x" => $feat->{"x1"}, "y" => $feat->{"y1"} );

		# For specific point
		foreach my $sco (@scores) {

			my %infS;
			my %infE;

			if ( $dir ne $sco->{"direction"} ) {
				next;
			}

			if ( $dir eq "horizontal" ) {

				if ( $sco->{"y1"} == $point{"y"} ) {
					%infS = ( "val" => $sco->{"x1"}, "type" => 1 );
					%infE = ( "val" => $sco->{"x2"}, "type" => -1 );
					push( @scoOnPos, \%infS );
					push( @scoOnPos, \%infE );
				}

			}
			elsif ( $dir eq "vertical" ) {

				if ( $sco->{"x1"} == $point{"x"} ) {
					%infS = ( "val" => $sco->{"y1"}, "type" => 1 );
					%infE = ( "val" => $sco->{"y2"}, "type" => -1 );

					push( @scoOnPos, \%infS );
					push( @scoOnPos, \%infE );
				}
			}
		}

		# potencional duplicate overlapping lines
		# we test, if values in array @scoOnPos, are alternating like : 1, -1, 1, -1
		# Two same values in a row means, overlapping lines
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

# This overlaping mean, score lines are too close each other => too smal gap < 200?m
sub ExistParallelOverlap {
	my $self = shift;

	my @lines = @{ $self->{"features"} };

	my $exist = 0;

	my $tolerance = $self->{"accuracyOverlap"};

	for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {

		my $lineI = $lines[$i];
		my $dirI  = $lineI->{"direction"};

		for ( my $j = 0 ; $j < scalar(@lines) ; $j++ ) {

			my $lineJ = $lines[$j];
			my $dirJ  = $lineJ->{"direction"};

			if ( $dirI ne $dirJ ) {
				next;
			}

			if ( $i == $j ) {
				next;
			}

			my %l1 = %{$lineI};
			my %l2 = %{$lineJ};

			if ( $dirI eq "vertical" ) {
				if ( abs( $l1{"x1"} - $l2{"x1"} ) <= $tolerance ) {

					# lines are parralel overlaping
					# now test, if there exist normal overlaping for this two lines
					$l2{"x1"} = $l1{"x1"};    # same x position, for testin overlpa
					my @lines = ( \%l1, \%l2 );

					$exist = $self->__ExistOverlap( \@lines );

					if ($exist) {
						last;
					}
				}
			}
			elsif ( $dirI eq "horizontal" ) {

				if ( abs( $l1{"y1"} - $l2{"y1"} ) <= $tolerance ) {

					# lines are parralel overlaping
					# now test, if there exist normal overlaping for this two lines
					$l2{"y1"} = $l1{"y1"};    # same y position, for testin overlpa
					my @lines = ( \%l1, \%l2 );

					$exist = $self->__ExistOverlap( \@lines );

					if ($exist) {
						last;
					}
				}
			}
		}

		if ($exist) {
			last;
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

sub __ToMicron {
	my $self = shift;
	my $f    = shift;

	$f->{"x1"} = int( $f->{"x1"} * 1000 + 0.5 );
	$f->{"x2"} = int( $f->{"x2"} * 1000 + 0.5 );
	$f->{"y1"} = int( $f->{"y1"} * 1000 + 0.5 );
	$f->{"y2"} = int( $f->{"y2"} * 1000 + 0.5 );

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

