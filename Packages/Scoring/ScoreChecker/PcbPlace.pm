
#-------------------------------------------------------------------------------------------#
# Description: Class parse score in steps and create suitable structure for score optimiyation
# All values are in µm in int
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreChecker::PcbPlace;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use Math::Trig ':pi';
use Math::Geometry::Planar;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::Polygon::Features::ScoreFeatures::ScoreFeatures';
use aliased 'Packages::Scoring::ScoreChecker::Enums';
use aliased 'Packages::Scoring::ScoreChecker::InfoClasses::ScorePosInfo';
use aliased 'Packages::Scoring::ScoreChecker::InfoClasses::PcbInfo';
use aliased 'Packages::Scoring::ScoreChecker::InfoClasses::ScoreInfo';
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
	$self->{"layer"} = shift;    # score layer, whic will be parsed
	$self->{"SR"}    = shift;    # if yes, only child steps are consider
	                             # if no, only data in given step are consider

	$self->{"accuracy"} = shift; # tell precision of compering score position

	my @pcbs = ();
	$self->{"pcbs"} = \@pcbs;

	$self->{"initSucc"}  = undef;
	$self->{"errorMess"} = undef;

	return $self;
}

sub Init {
	my $self = shift;

	if ( $self->{"SR"} ) {
		$self->__LoadNestedSteps();
	}
	else {
		$self->__LoadStep();
	}

}
# Return, idf parsed score is traight, and not duplicate
sub ScoreIsOk {
	my $self = shift;
	my $mess = shift;

	unless ( $self->{"initSucc"} ) {
		$$mess = $self->{"errorMess"};
		return 0;
	}
	else {

		return 1;
	}
}

sub GetPcbs {
	my $self = shift;

	return @{ $self->{"pcbs"} };
}

# return all position, where score is situated
# Example for verticall score: 2 lines lying on same position x=10 mm
# - position will be contain point = 10mm and direction verticall
sub GetScorePos {
	my $self = shift;
	my $dir  = shift;

	my @score  = ();
	my @points = ();

	foreach my $pcb ( @{ $self->{"pcbs"} } ) {

		my @scoPos = $pcb->GetScorePos($dir);

		foreach my $pInfo (@scoPos) {

			push( @points, Convertor->DoPosInfo( $pInfo, $pcb ) );
		}

	}

	# Reduce (merge) points, which has same location +- accuracy
	my @merged = ();
	foreach my $posInf (@points) {

		my $pos = $posInf->GetPosition();

		# merge lines, which has spacinf less than 100µm
		my $exist = scalar( grep { abs( $_->GetPosition() - $posInf->GetPosition() ) < $self->{"accuracy"} } @merged );

		unless ($exist) {
			push( @merged, $posInf );

		}
	}

	return @merged;

}

# return if score with specific direction is lying on specific position +- accuracy
sub IsScoreOnPos {
	my $self    = shift;
	my $posInfo = shift;
	my $pcb     = shift;

	my $relPos = Convertor->DoPosInfo( $posInfo, $pcb, 1 );

	return $pcb->IsScoreOnPos($relPos);

}

# Return all pcb, which are intersect by this position
sub GetPcbOnScorePos {
	my $self    = shift;
	my $posInfo = shift;

	my $dir = $posInfo->GetDirection();
	my $pos = $posInfo->GetPosition();

	my @pcbOnPos = ();

	foreach my $pcb ( @{ $self->{"pcbs"} } ) {

		my $oriX = $pcb->GetOrigin()->{"x"};
		my $oriY = $pcb->GetOrigin()->{"y"};

		my $h = $pcb->GetHeight();
		my $w = $pcb->GetWidth();

		if ( $dir eq Enums->Dir_HSCORE ) {

			if ( $pos >= $oriY && $pos <= $oriY + $h ) {

				push( @pcbOnPos, $pcb );
			}

		}
		elsif ( $dir eq Enums->Dir_VSCORE ) {

			if ( $pos >= $oriX && $pos <= $oriX + $w ) {

				push( @pcbOnPos, $pcb );
			}
		}
	}

	# sort by pcb by origin depand on direction. Sort FROM LEFT, TOP
	if ( $dir eq Enums->Dir_HSCORE ) {

		@pcbOnPos = sort { $a->GetOrigin()->{"x"} <=> $b->GetOrigin()->{"x"} } @pcbOnPos;

	}
	elsif ( $dir eq Enums->Dir_VSCORE ) {

		@pcbOnPos = sort { $b->GetOrigin()->{"y"} <=> $a->GetOrigin()->{"y"} } @pcbOnPos;

	}

	return @pcbOnPos;

}

# Load score lines in step, which contain S&R. This steps are breaked
sub __LoadNestedSteps {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	$self->{"initSucc"}  = 1;
	$self->{"errorMess"} = "";

	my @repeats = CamStepRepeat->GetRepeatStep( $inCAM, $jobId, $step );

	my @uniqueSR = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $step );

	# Set width/height
	foreach my $uStep (@uniqueSR) {

		my %lim = CamJob->GetProfileLimits( $inCAM, $jobId, $uStep->{"stepName"} );

		foreach my $k (keys %lim){
			$lim{$k} = int($lim{$k} * 1000 +0.5);
		}

		$uStep->{"lim"} = \%lim;

		$uStep->{"width"}  =  abs( $lim{"xmax"} - $lim{"xmin"} ) ;
		$uStep->{"height"} =  abs( $lim{"ymax"} - $lim{"ymin"} ) ;

	}

	foreach my $uStep (@uniqueSR) {

		my $score = ScoreFeatures->new(1);

		$score->Parse( $inCAM, $jobId, $uStep->{"stepName"}, $self->{"layer"}, 1, 1 );

		unless ( $score->IsStraight() ) {
			$self->{"errorMess"} .= "Některé drážky ve stepu: " . $uStep->{"stepName"} . " nejsou zcela rovné. Nejsou striktně horzontální nebo vertikální.\n";
			$self->{"initSucc"} = 0;
		}

		if ( $score->ExistOverlap() ) {
			$self->{"errorMess"} .= "Některé drážky ve stepu : " . $uStep->{"stepName"} ." se překrývají po své délce (leží na sobě v podélném směru).";
			$self->{"errorMess"} .= " Oprav ať se nepřekrývají.\n";
			$self->{"initSucc"} = 0;
		}

		if ( $score->ExistParallelOverlap() ) {
			$self->{"errorMess"} .= "Některé drážky ve stepu: " . $uStep->{"stepName"} ." se překrývají po své šířce. (leží na sobě)";
			$self->{"errorMess"} .= " Oprav ať se nepřekrývají.\n";
			$self->{"initSucc"} = 0;
		}

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

		#my %origin = ( "x" => $self->__Round( $rep->{"originXNew"} ), "y" => $self->__Round( $rep->{"originYNew"} ) );

		my %origin = ( "x" => $self->__ToMicron( $rep->{"originXNew"} ), "y" => $self->__ToMicron( $rep->{"originYNew"} ) );

		# switch height/width, by rotation
		my $rotCnt = $rep->{"angle"} / 90;

		my $repW = $step->{"width"};
		my $repH = $step->{"height"};

		if ( $rotCnt % 2 != 0 ) {
			$repW = $step->{"height"};
			$repH = $step->{"width"};
		}

		# Create new pcb info
		my $pcbInfo = PcbInfo->new( $rep->{"stepName"}, \%origin, $repW, $repH, $self->{"accuracy"} );

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
				elsif ( $dir eq Enums->Dir_VSCORE ) {
					$dir = Enums->Dir_HSCORE;
				}
			}

			if ( $dir eq Enums->Dir_HSCORE ) {

				if ( $startP{"y"} != $endP{"y"} ) {

					print STDERR sprintf( "%10.20f", $startP{"y"} ) . "\n";
					print STDERR sprintf( "%10.20f", $endP{"y"} ) . "\n";

					print STDERR "uuuu\n";
				}

			}

			if ( $dir eq Enums->Dir_VSCORE ) {

				if ( $startP{"x"} != $endP{"x"} ) {

					print STDERR sprintf( "%10.20f", $startP{"x"} ) . "\n";
					print STDERR sprintf( "%10.20f", $endP{"x"} ) . "\n";

					print STDERR "uuuuxxxxx\n";
				}

			}

			my $scoLine = ScoreInfo->new( \%startP, \%endP, $dir, $l->{"length"}, $self->{"dec"} );

			$pcbInfo->AddScoreLine($scoLine);
		}

		push( @{ $self->{"pcbs"} }, $pcbInfo );

	}
}


# Load score lines in step, S&R is not considered
sub __LoadStep {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	$self->{"initSucc"}  = 1;
	$self->{"errorMess"} = "";

	my $score = ScoreFeatures->new(1);

	$score->Parse( $inCAM, $jobId, $self->{"step"}, $self->{"layer"} );

	unless ( $score->IsStraight() ) {
		$self->{"errorMess"} .= "Score in step: " . $self->{"step"} . " is not strictly horizontal or vertical.";
		$self->{"initSucc"} = 0;
	}

	if ( $score->ExistOverlap() ) {
		$self->{"errorMess"} .= "Some scorelines in step: " . $self->{"step"} . " are overlapping.";
		$self->{"initSucc"} = 0;
	}

	my @lines = $score->GetFeatures();

	# register lines to zero, if origin is not in left lower corner

	my %lim = CamJob->GetProfileLimits( $inCAM, $jobId, $self->{"step"} );

	foreach my $k (keys %lim){
			$lim{$k} = int($lim{$k} * 1000 +0.5);
	}

	my %origin = ( "x" => 0, "y" => 0 );
	my $w      = abs( $lim{"xmin"} - $lim{"xmax"} );
	my $h      = abs( $lim{"ymin"} - $lim{"ymax"} );

	my $pcbInfo = PcbInfo->new( $self->{"step"}, \%origin, $w, $h, $self->{"accuracy"} );

	# add score lines, according original score lines in step
	foreach my $l (@lines) {

		my %startP = ( "x" => $l->{"x1"}, "y" => $l->{"y1"} );
		my %endP   = ( "x" => $l->{"x2"}, "y" => $l->{"y2"} );
		my $dir    = $l->{"direction"};

		my $scoLine = ScoreInfo->new( \%startP, \%endP, $dir, $l->{"length"} );
		$pcbInfo->AddScoreLine($scoLine);
	}

	push( @{ $self->{"pcbs"} }, $pcbInfo );
}

# Ruction rotate point by specific angle
# Process is:
# 1) Rotate point by 90deg
# 2) Set orifgin left down corner of pcb
# 3) Rotate point by 90deg
# 4) Set orifgin left down corner of pcb
# 5) et cetera....
sub __RotateAndMovePoint {
	my $self   = shift;
	my $point  = shift;
	my $angle  = shift;
	my $width  = shift;
	my $height = shift;

	my $dec = $self->{"dec"};

	my $num = $angle / 90;

	my $angle90 = pi / 2;

	# only if angel is not 360
	if ( $num < 4 ) {
		for ( my $i = 0 ; $i < $num ; $i++ ) {

			my %new = ();

			$new{"x"} = $point->{"x"} * cos(pip2) - $point->{"y"} * sin(pip2);
			$new{"y"} = $point->{"y"} * cos(pip2) + $point->{"x"} * sin(pip2);

			$point->{"x"} = $new{"x"};
			$point->{"y"} = $new{"y"};

			if ( $i % 2 == 0 ) {

				$point->{"x"} += $height;
			}
			else {

				$point->{"x"} += $width;
			}

		}

	}

	$point->{"x"} = int( $point->{"x"} + 0.5 ); # round on whole numbers
	$point->{"y"} = int( $point->{"y"} + 0.5 );

}


# Return minimal gap between all pcbs in step
sub __GetMinPcbGap {
	my $self = shift;

	my @pcbs = @{ $self->{"pcbs"} };

	my @rectangles = ();

	for ( my $i = 0 ; $i < scalar(@pcbs) ; $i++ ) {

		my $pcb = $pcbs[$i];

		my @pcbPoints = ();
		my %p1        = ( "x" => 0, "y" => 0 );
		my %p2        = ( "x" => 0, "y" => $pcb->GetHeight() );
		my %p3        = ( "x" => $pcb->GetWidth(), "y" => $pcb->GetHeight() );
		my %p4        = ( "x" => $pcb->GetWidth(), "y" => 0 );

		push( @pcbPoints, Convertor->DoPoint( \%p1, $pcb ) );
		push( @pcbPoints, Convertor->DoPoint( \%p2, $pcb ) );
		push( @pcbPoints, Convertor->DoPoint( \%p3, $pcb ) );
		push( @pcbPoints, Convertor->DoPoint( \%p4, $pcb ) );

		push( @rectangles, \@pcbPoints );

	}

	# find min gap
	my $minGap = undef;

	for ( my $i = 0 ; $i < scalar(@rectangles) ; $i++ ) {

		my $recti   = $rectangles[$i];
		my @pointsI = @{$recti};

		# for each point of rectangle, test distance between all edges of all rect
		foreach my $pointI (@pointsI) {

			for ( my $j = 0 ; $j < scalar(@rectangles) ; $j++ ) {

				my $rectj   = $rectangles[$j];
				my @pointsJ = @{$rectj};

				if ( $i == $j ) {
					next;
				}

				my %e1 = ( "start" => $pointsJ[0], "end" => $pointsJ[1] );
				my %e2 = ( "start" => $pointsJ[1], "end" => $pointsJ[2] );
				my %e3 = ( "start" => $pointsJ[2], "end" => $pointsJ[3] );
				my %e4 = ( "start" => $pointsJ[3], "end" => $pointsJ[0] );

				my @e = ( \%e1, \%e2, \%e3, \%e4 );

				my $minGapTmp = $self->__Pont2LineDist( $pointI, \@e );

				if ( !defined $minGap || $minGapTmp < $minGap ) {
					$minGap = $minGapTmp;
				}

			}
		}

	}

	return $minGap;
}

sub __Pont2LineDist {
	my $self  = shift;
	my $point = shift;
	my @lines = @{ shift(@_) };

	my $min = undef;
	foreach my $l (@lines) {

		my @p = ( $point->{"x"}, $point->{"y"} );
		my @lStart = ( $l->{"start"}->{"x"}, $l->{"start"}->{"y"} );
		my @lEnd   = ( $l->{"end"}->{"x"},   $l->{"end"}->{"y"} );
		my @pointsRef = ( \@lStart, \@lEnd, \@p );
		my $dist = abs( DistanceToSegment( \@pointsRef ) );

		if ( !defined $min || $dist < $min ) {
			$min = $dist;

		}
	}

	return $min;
}

sub __ToMicron {
	my $self = shift;
	my $num  = shift;
	return int( $num * 1000 + 0.5 ); # 0.5, 
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

