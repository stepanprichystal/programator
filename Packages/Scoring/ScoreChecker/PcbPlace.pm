
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers for particular machine, which can procces given nc file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreChecker::PcbPlace;

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use Math::Trig;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::Polygon::Features::ScoreFeatures::ScoreFeatures';

use aliased 'Packages::Scoring::ScoreChecker::Enums';
use aliased 'Packages::Scoring::ScoreChecker::ScorePosInfo';
use aliased 'Packages::Scoring::ScoreChecker::PcbInfo';
use aliased 'Packages::Scoring::ScoreChecker::ScoreInfo';

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

	my @pcbs = ();
	$self->{"pcbs"} = \@pcbs;

	$self->__LoadStepsInfo();

	return $self;
}

sub GetScorePos {
	my $self = shift;
	my $dir  = shift;

	my @score  = ();
	my @points = ();

	foreach my $pcb ( @{ $self->{"pcbs"} } ) {

		my @sco = $pcb->GetScore($dir);

		foreach my $sInfo (@sco) {

			my $pVal = $sInfo->GetScorePoint();

			# consider origin of "panel" and location of pcb
			if ( $sInfo->GetDirection() eq Enums->Dir_HSCORE ) {

				$pVal += $pcb->GetOrigin()->{"y"};

			}
			elsif ( $sInfo->GetDirection() eq Enums->Dir_VSCORE ) {

				$pVal += $pcb->GetOrigin()->{"x"};
			}

			my $pInfo = ScorePosInfo->new( $pVal, $sInfo->GetDirection() );

			push( @points, $pInfo );

		}

	}

	# Reduce points, which has same location
	my %seen;
	@points = grep { !$seen{ $_->GetPosition() }++ } @points;

}

sub GetPcbOnScorePos {
	my $self    = shift;
	my $posInfo = shift;

	my $dir = $posInfo->GetDirection();
	my $pos = $posInfo->GetPosition();

	my @pcb = ();

	foreach my $pcb ( @{ $self->{"pcbs"} } ) {

		my $oriX = $pcb->GetOrigin()->{"x"};
		my $oriY = $pcb->GetOrigin()->{"y"};

		my $h = $pcb->GetHeight();
		my $w = $pcb->GetHeight();

		if ( $dir eq Enums->Dir_HSCORE ) {

			if ( $pos >= $oriY && $pos <= $oriY + $h ) {

				push( @pcb, $pos );
			}

		}
		elsif ( $dir eq Enums->Dir_VSCORE ) {

			if ( $pos >= $oriX && $pos <= $oriX + $w ) {

				push( @pcb, $pos );
			}
		}
	}

	return @pcb;

}

sub __LoadStepsInfo {
	my $self  = shift;
	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my @repeats = CamStepRepeat->GetRepeatStep( $inCAM, $jobId, $step );

	my @uniqueSR = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $step );

	# Set width/height
	foreach my $uStep (@uniqueSR) {

		my %lim = CamJob->GetProfileLimits( $inCAM, $jobId, $uStep->{"stepName"} );

		$uStep->{"lim"} = \%lim;

		$uStep->{"width"}  = abs( $lim{"xmax"} - $lim{"xmin"} );
		$uStep->{"height"} = abs( $lim{"ymax"} - $lim{"ymin"} );

	}

	foreach my $uStep (@uniqueSR) {

		my $score = ScoreFeatures->new();

		$score->Parse( $inCAM, $jobId, $uStep->{"stepName"}, "score", 1 );

		my @lines = $score->GetFeatures();

		# register lines to zero, if origin is not in left lower corner

		if ( $uStep->{"lim"}->{"xmin"} < 0 ) {

			foreach my $l (@lines) {

				$l->{"x1"} -= $uStep->{"lim"}->{"xmin"};
				$l->{"x2"} -= $uStep->{"lim"}->{"xmin"};
				$l->{"y1"} -= $uStep->{"lim"}->{"ymin"};
				$l->{"y2"} -= $uStep->{"lim"}->{"ymin"};
			}

		}

		$uStep->{"score"} = \@lines;
	}

	# Created pcbInfo objects

	foreach my $rep (@repeats) {

		my @steps = grep { $_->{"stepName"} eq $rep->{"stepName"} } @uniqueSR;

		my $step = $steps[0];

		my %origin = ( "x" => $rep->{"originXNew"}, "y" => $rep->{"originYNew"} );

		# switch height/width, by rotation
		my $rotCnt = $rep->{"angle"} / 90;

		my $repW = $step->{"width"};
		my $repH = $step->{"height"};

		if ( $rotCnt % 2 != 0 ) {
			$repW = $step->{"height"};
			$repH = $step->{"width"};
		}

		my $pcbInfo = PcbInfo->new( \%origin, $repW, $repH );

		# add score lines, according original score lines in step

		my @score = @{ $step->{"score"} };

		foreach my $l (@score) {

			my %startP = ( "x" => $l->{"x1"}, "y" => $l->{"y1"} );
			my %endP   = ( "x" => $l->{"x2"}, "y" => $l->{"y2"} );

			$self->__RotateAndMovePoint( \%startP, $rep->{"angle"}, $step->{"width"}, $step->{"height"} );
			$self->__RotateAndMovePoint( \%endP,   $rep->{"angle"}, $step->{"width"}, $step->{"height"} );

			# change direction by angle
			my $rotCnt = $rep->{"angle"} / 90;
			my $dir    = $l->{"direction"};

			if ( $rotCnt % 2 != 0 ) {

				if ( $dir eq Enums->Dir_HSCORE ) {
					$dir = Enums->Dir_VSCORE;
				}
				else {
					$dir = Enums->Dir_HSCORE;
				}
			}

			my $scoLine = ScoreInfo->new( \%startP, \%endP, $dir );

			$pcbInfo->AddScoreLine($scoLine);
		}

		push( @{ $self->{"pcbs"} }, $pcbInfo );

	}
}

sub __RotateAndMovePoint {
	my $self   = shift;
	my $point  = shift;
	my $angle  = shift;
	my $width  = shift;
	my $height = shift;

	my $num = $angle / 90;

	my $angle90 = pi / 2;

	for ( my $i = 0 ; $i < $num ; $i++ ) {

		my %new = ();

		$new{"x"} = $point->{"x"} * cos($angle90) - $point->{"y"} * sin($angle90);
		$new{"y"} = $point->{"y"} * cos($angle90) + $point->{"x"} * sin($angle90);

		$point->{"x"} = sprintf( "%.2f", $new{"x"} );
		$point->{"y"} = sprintf( "%.2f", $new{"y"} );

		if ( $i % 2 == 0 ) {

			$point->{"x"} += $height;
		}
		else {

			$point->{"x"} += $width;
		}

	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Packages::Export::NCExport::NCExportGroup';

	#print $test;

}

1;

