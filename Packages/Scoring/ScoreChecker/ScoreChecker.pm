
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
use aliased 'Packages::Scoring::ScoreChecker::ScoreInfo';
use aliased 'Packages::Scoring::ScoreChecker::PcbPlace';

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

	$self->{"dec "} = 1;    # tell precision of compering score position. 1 decimal place

	$self->{"pcbPlace"} = PcbPlace->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, $self->{"dec "} );

	$self->__Init();

	#my @hscore = $self->{"pcbPlace"}->GetScorePos(Enums->Dir_HSCORE);
	my @vscore = $self->{"pcbPlace"}->GetScorePos( Enums->Dir_VSCORE );

	my @pcb1 = $self->{"pcbPlace"}->GetPcbOnScorePos( $vscore[0] );
	#my @pcb2 = $self->{"pcbPlace"}->GetPcbOnScorePos( $vscore[1] );

	print "jump = " . $self->IsJumScoring() . " \n\n";

	return $self;
}

# check if all line strictly horizontal or verticall
sub ScoreIsOk{
	my $self = shift;
	
	
	return $self->{"pcbPlace"}->ScoreIsOk();
}


sub __Init {
	my $self = shift;

	# check if all line strictly horizontal or verticall
	unless ( $self->{"pcbPlace"}->ScoreIsOk() ) {

		die "Some score lines are not strictly horrizontal or verticall. Repair it first. \n";

	}

}

sub __LoadPcb {
	my $self = shift;

	# get step and repeat, break!

	# if rotated, switch dimension etc

	# for each, parse score if is present

	# save score line to new pcb object

}

sub IsJumScoring {
	my $self        = shift;
	my $jumpScoring = 0;

	# 1) Test if some pcb has more then on score on same postition
	# This is case, when pcb is "multipanel" and customer wants jumpscoring on them

	my @allPcb = $self->{"pcbPlace"}->GetPcbs();
	foreach my $pcb (@allPcb) {

		if ( $pcb->ScoreOnSamePos() ) {

			# jumpscoring is necessary
			$jumpScoring = 1;
			last;
		}
	}

	# 2) all pcb which are intersect by specific "position" has to has score on this position
	# for each position, test if all pcb contains score on same postition
	unless ($jumpScoring) {

		# all verticall and horiyontall score positions
		my @posInfos = $self->{"pcbPlace"}->GetScorePos();

		foreach my $pos (@posInfos) {

			my @pcbOnPos = $self->{"pcbPlace"}->GetPcbOnScorePos($pos);

			foreach my $pcb (@pcbOnPos) {

				unless ( $self->{"pcbPlace"}->IsScoreOnPos( $pos, $pcb ) ) {

					$jumpScoring = 1;
					last;
				}
			}
		}
	}

	return $jumpScoring;
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

