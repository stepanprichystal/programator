
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
use aliased 'Packages::Scoring::ScoreChecker::InfoClasses::ScorePosInfo';
use aliased 'Packages::Scoring::ScoreChecker::InfoClasses::PcbInfo';
use aliased 'Packages::Scoring::ScoreChecker::InfoClasses::ScoreInfo';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = {};
	bless $self;

	$self->{"inCAM"}     = shift;
	$self->{"jobId"}     = shift;
	$self->{"step"}      = shift;
	$self->{"layer"}     = shift;    # score layer, whic will be parsed
	$self->{"SR"}        = shift;    # if yes, only child steps are consider
	                                 # if no, only data in given step are consider
	$self->{"convertor"} = shift;
	$self->{"dec"}       = shift;    # tell precision of compering score position

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

sub GetScorePos {
	my $self = shift;
	my $dir  = shift;

	my @score  = ();
	my @points = ();

	foreach my $pcb ( @{ $self->{"pcbs"} } ) {

		my @scoPos = $pcb->GetScorePos($dir);

		foreach my $pInfo (@scoPos) {

			push( @points, $self->{"convertor"}->DoPosInfo( $pInfo, $pcb ) );
		}

	}

	# Reduce points, which has same location
	my %seen;
	@points = grep { !$seen{ $_->GetPosition() }++ } @points;

	return @points;

}

sub IsScoreOnPos {
	my $self    = shift;
	my $posInfo = shift;
	my $pcb     = shift;

	my $relPos = $self->{"convertor"}->DoPosInfo( $posInfo, $pcb, 1 );

	return $pcb->IsScoreOnPos($relPos);

}

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

		$uStep->{"lim"} = \%lim;

		$uStep->{"width"}  = abs( $lim{"xmax"} - $lim{"xmin"} );
		$uStep->{"height"} = abs( $lim{"ymax"} - $lim{"ymin"} );

	}

	foreach my $uStep (@uniqueSR) {
 

		my $score = ScoreFeatures->new();

		$score->Parse( $inCAM, $jobId, $uStep->{"stepName"}, $self->{"layer"}, 1 );

		unless ( $score->IsStraight() ) {
			$self->{"errorMess"} .= "Score in step: " . $uStep->{"stepName"} . " is not strictly horizontal or vertical.";
			$self->{"initSucc"} = 0;
		}

		if ( $score->ExistOverlap() ) {
			$self->{"errorMess"} .= "Some scorelines in step: " . $uStep->{"stepName"} . " are overlapping.";
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
		
		my %origin = ( "x" => $rep->{"originXNew"} , "y" => $rep->{"originYNew"} );
		
		

		# switch height/width, by rotation
		my $rotCnt = $rep->{"angle"} / 90;
 
		my $repW =  $step->{"width"} ;
		my $repH =  $step->{"height"} ;

		if ( $rotCnt % 2 != 0 ) {
			$repW = $step->{"height"};
			$repH = $step->{"width"};
		}

		# Create new pcb info
		my $pcbInfo = PcbInfo->new( $rep->{"stepName"}, \%origin, $repW, $repH, $self->{"dec"} );

		# add score lines, according original score lines in step

		my @score = @{ $step->{"score"} };

		foreach my $l (@score) {

			#my %startP = ( "x" => $self->__Round( $l->{"x1"} ), "y" => $self->__Round( $l->{"y1"} ) );
			#my %endP   = ( "x" => $self->__Round( $l->{"x2"} ), "y" => $self->__Round( $l->{"y2"} ) );
			
			my %startP = ( "x" =>  $l->{"x1"} , "y" =>  $l->{"y1"}  );
			my %endP   = ( "x" =>  $l->{"x2"} , "y" =>  $l->{"y2"}  );

 


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

			my $scoLine = ScoreInfo->new( \%startP, \%endP, $dir, $l->{"length"}, $self->{"dec"} );

			$pcbInfo->AddScoreLine($scoLine);
		}




		push( @{ $self->{"pcbs"} }, $pcbInfo );

	}
}

sub __LoadStep {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	$self->{"initSucc"}  = 1;
	$self->{"errorMess"} = "";

	my $score = ScoreFeatures->new();

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

	my %origin = ( "x" => 0, "y" => 0 );
	my $w      = abs( $lim{"xmin"} - $lim{"xmax"} );
	my $h      = abs( $lim{"ymin"} - $lim{"ymax"} );

	my $pcbInfo = PcbInfo->new( $self->{"step"}, \%origin, $w, $h, $self->{"dec"} );

	# add score lines, according original score lines in step
	foreach my $l (@lines) {

		my %startP = ( "x" => $l->{"x1"}, "y" => $l->{"y1"} );
		my %endP   = ( "x" => $l->{"x2"}, "y" => $l->{"y2"} );
		my $dir    = $l->{"direction"};

		my $scoLine = ScoreInfo->new( \%startP, \%endP, $dir, $l->{"length"}, $self->{"dec"} );
		$pcbInfo->AddScoreLine($scoLine);
	}

	push( @{ $self->{"pcbs"} }, $pcbInfo );
}

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

			$new{"x"} = $point->{"x"} * cos($angle90) - $point->{"y"} * sin($angle90);
			$new{"y"} = $point->{"y"} * cos($angle90) + $point->{"x"} * sin($angle90);


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

	$point->{"x"} = sprintf( "%." . $dec . "f", $point->{"x"} );
	$point->{"y"} = sprintf( "%." . $dec . "f", $point->{"y"} );

}

sub __GetMinPcbGap{
	my $self = shift;
	
	my $minGap = 0;
	
	
	
}

sub __Round {
	my $self = shift;
	my $num  = shift;
	return sprintf( "%." . $self->{"dec"} . "f", $num );
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

