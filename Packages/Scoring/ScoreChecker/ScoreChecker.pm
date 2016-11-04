
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
use aliased 'Packages::Scoring::ScoreChecker::OriginConvert';

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

	$self->{"dec"} = 2;    # tell precision of compering score position. 1 decimal place

	$self->{"convertor"} = OriginConvert->new( $self->{"dec"} );

	$self->{"pcbPlace"} =
	  PcbPlace->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, $self->{"layer"}, $self->{"SR"}, $self->{"convertor"}, $self->{"dec"} );

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

sub GetConvertor {
	my $self = shift;

	return $self->{"convertor"};
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
	
	if($self->GetReduceDist() == -1){
		
		$distOk = 0ù
	}

	return $distOk;
}

sub GetReduceDist {
	my $self = shift;

	my $dist = undef;

	my $gap = $self->__GetMinPcbGap();

	# test if pcb are not too close each other
	if ( $gap && $gap > 2 && $gap < 6 ) {

		my $passDist    = 10;    # distance, which score machine pass end of line
		my $maxProfDist = 8;     # max dist, where score can start/end from profile

		if ( $passDist - $gap < $maxProfDist ) {
			$dist = $passDist - $gap; 
	
		}else{
			
			$dist = -1;
		}
		
	}else{
		
		$dist = 4; # standard reduce of scorin 4mm
	}

	return $dist;
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

