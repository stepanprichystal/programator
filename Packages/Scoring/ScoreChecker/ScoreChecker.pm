
#-------------------------------------------------------------------------------------------#
# Description: Class can parse score layer in step and prepare suitable structure for
# score optimiyation.
# Can fin out, if step has "customer" jumpscoring etc.
# All values are in µm in int
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreChecker::ScoreChecker;

#3th party library
use strict;
use warnings;
use Math::Trig;

#local library
use aliased 'Packages::Scoring::ScoreChecker::Enums';
use aliased 'Packages::Scoring::ScoreChecker::PcbPlace';
use aliased 'Packages::Scoring::ScoreChecker::OriginConvert' => "Convertor";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;
	$self->{"layer"} = shift;
	$self->{"SR"}    = shift;    # break step and repeat

	# tell precision of compering score position in µm
	# thus, if two scoreliones are  spaced less than 50µm we consider it, they are on the same position
	$self->{"accuracy"} = 50;

	$self->{"pcbPlace"} = PcbPlace->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, $self->{"layer"}, $self->{"SR"}, $self->{"accuracy"} );
	return $self;
}

sub Init {
	my $self = shift;

	$self->{"pcbPlace"}->Init();
}

# Return parsed step and score lines, sturcture is suitable for score optimiyation
sub GetPcbPlace {
	my $self = shift;
	my $mess = "";

	if ( $self->{"pcbPlace"}->ScoreIsOk( \$mess ) ) {

		return $self->{"pcbPlace"};
	}
	else {

		return 0;
	}
}


sub GetStep {
	my $self = shift;

	return $self->{"step"};
}


sub GetAccuracy {
	my $self = shift;

	return $self->{"accuracy"};

}

# Return, idf parsed score is traight, and not duplicate
sub ScoreIsOk {
	my $self = shift;
	my $mess = shift;

	my $res = $self->{"pcbPlace"}->ScoreIsOk($mess);

	return $res;
}

# tell if in some steps, score is customer jumpscoring
sub CustomerJumpScoring {
	my $self = shift;

	my $customerJump = 0;

	my @allPcb = $self->{"pcbPlace"}->GetPcbs();
	foreach my $pcb (@allPcb) {

		my @scoPos = $pcb->GetScorePos();

		foreach my $pos (@scoPos) {
			if ( $pcb->NoOptimize($pos) ) {

				# jumpscoring is necessary
				$customerJump = 1;
				last;
			}
		}
	}

	return $customerJump;
}

# If steps and scores are arranged such that, ther is no need of jumpscoring,
# return 1
sub IsStraight {
	my $self       = shift;
	my $isStraight = 1;

	# 1) Test if some pcb has more then on score on same postition
	# This is case, when pcb is "multipanel" and customer wants jumpscoring on them

	my @allPcb = $self->{"pcbPlace"}->GetPcbs();
	foreach my $pcb (@allPcb) {

		my @scoPos = $pcb->GetScorePos();

		foreach my $pos (@scoPos) {
			if ( $pcb->NoOptimize($pos) ) {

				# jumpscoring is necessary
				$isStraight = 0;
				last;
			}
		}
	}

	# 2) all pcb which are intersect by specific "position" has to has score on this position
	# for each position, test if all pcb contains score on same postition
	if ($isStraight) {

		# all verticall and horiyontall score positions
		my @posInfos = $self->{"pcbPlace"}->GetScorePos();

		foreach my $pos (@posInfos) {

			my @pcbOnPos = $self->{"pcbPlace"}->GetPcbOnScorePos($pos);

			foreach my $pcb (@pcbOnPos) {

				unless ( $self->{"pcbPlace"}->IsScoreOnPos( $pos, $pcb ) ) {

					$isStraight = 0;
					last;
				}
			}
		}
	}

	return $isStraight;
}

# Tell if there at least minimal space 4.5mm
sub PcbDistanceOk {
	my $self = shift;

	my $distOk = 1;

	if ( $self->GetReduceDist() == -1 ) {

		$distOk = 0;
	}

	return $distOk;
}

# Return length, which score has to be cutted in each step from profile
sub GetReduceDist {
	my $self = shift;

	my $dist         = undef;
	my $standardDist = 4000;
	my $minPcbDist   = 4500;
	my $passDist     = 11000;    # distance, which score machine pass end of line 11 mm

	my $gap = $self->{"pcbPlace"}->__GetMinPcbGap();
	 

	unless ( defined $gap ) {
		return $standardDist;
	}

	# test if pcb are not too close each other
	if ( $gap < $minPcbDist ) {

		return -1;
	}

	#  Machine pass 11mm, but for insurence, count with 11mm
	if ( $gap > $passDist ) {

		return 0;    # don't reduce
	}

	my $reduceScore = ( $passDist - $gap );

	return $reduceScore;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Scoring::ScoreChecker::ScoreChecker';
	use aliased 'Packages::InCAM::InCAM';
#
	my $jobId = "f13609";
#
	my $inCAM = InCAM->new();
#
	my $checker = ScoreChecker->new( $inCAM, $jobId, "panel", "score", 1 );
	$checker->Init();
#
#	print 1;

}

1;

