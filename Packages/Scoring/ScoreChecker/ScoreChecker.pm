
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers as gerber274x
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreChecker::ScoreChecker;

#3th party library
use strict;
use warnings;
use Math::Trig;

#local library
#use aliased 'Helpers::GeneralHelper';
#use aliased 'Packages::ItemResult::ItemResult';
#use aliased 'Enums::EnumsPaths';
#use aliased 'Helpers::JobHelper';
#use aliased 'Helpers::FileHelper';
#use aliased 'CamHelpers::CamHelper';
#use aliased 'Packages::Export::GerExport::Helper';
#
#use aliased 'CamHelpers::CamJob';
#use aliased 'CamHelpers::CamStepRepeat';
#use aliased 'Packages::Polygon::Features::ScoreFeatures::ScoreFeatures';

use aliased 'Packages::Scoring::ScoreChecker::Enums';
use aliased 'Packages::Scoring::ScoreChecker::InfoClasses::ScoreInfo';
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
	$self->{"SR"}    = shift;

	$self->{"accuracy"} = 50;    # tell precision of compering score position. 1 decimal place

	$self->{"pcbPlace"} = PcbPlace->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, $self->{"layer"}, $self->{"SR"}, $self->{"accuracy"} );

	#$self->__Init();

	#my @hscore = $self->{"pcbPlace"}->GetScorePos(Enums->Dir_HSCORE);
	#my @vscore = $self->{"pcbPlace"}->GetScorePos( Enums->Dir_VSCORE );

	#my @pcb1 = $self->{"pcbPlace"}->GetPcbOnScorePos( $vscore[0] );

	#my @pcb2 = $self->{"pcbPlace"}->GetPcbOnScorePos( $vscore[1] );

	#print "jump = " . $self->IsJumScoring() . " \n\n";

	return $self;
}

sub Init {
	my $self = shift;

	$self->{"pcbPlace"}->Init();

}

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

#
sub ScoreIsOk {
	my $self = shift;
	my $mess = shift;

	my $res = $self->{"pcbPlace"}->ScoreIsOk( \$mess );

	return $res;
}

#sub __Init {
#	my $self = shift;
#	my $mess = "";
#
#	# check if all line strictly horizontal or verticall
#	unless ( $self->{"pcbPlace"}->ScoreIsOk( \$mess ) ) {
#
#		die $mess . " Repair it first. \n";
#
#	}
#
#}

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

sub PcbDistanceOk {
	my $self = shift;

	my $distOk = 1;

	if ( $self->GetReduceDist() == -1 ) {

		$distOk = 0;
	}

	return $distOk;
}

sub GetReduceDist {
	my $self = shift;

	my $dist         = undef;
	my $standardDist = 4000;
	my $minPcbDist = 4500;

	my $gap = $self->{"pcbPlace"}->__GetMinPcbGap();
	print STDERR "Mezera min bude  o = ".$gap."\n";
	
	
	unless ( defined $gap ) {
		return $standardDist;
	}

	# test if pcb are not too close each other
	if ( $gap < $minPcbDist ) {

		return -1;
	}

	my $passDist = 10000;    # distance, which score machine pass end of line

	# minus 1000, is for insurence. Machine pass 10mm, but ofr insurence, count with 11mm
	my $tmp = ($passDist - $gap  + 1000);
	print STDERR "Drayka bude ykracena o = ".$tmp."\n";
	
	
	return $passDist - $gap  + 1000;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Scoring::ScoreChecker::ScoreChecker';
	use aliased 'Packages::InCAM::InCAM';

	my $jobId = "f52456";

	my $inCAM = InCAM->new();

	my $checker = ScoreChecker->new( $inCAM, $jobId, "panel" );

	print 1;

}

1;

