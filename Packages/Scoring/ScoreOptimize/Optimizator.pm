
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers for particular machine, which can procces given nc file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreOptimize::Optimizator;
use base('Packages::Export::MngrBase');

#3th party library
use strict;
use warnings;

#local library
#use aliased 'Helpers::GeneralHelper';
#use aliased 'Packages::ItemResult::ItemResult';
#use aliased 'Enums::EnumsPaths';
#use aliased 'Helpers::JobHelper';
#use aliased 'CamHelpers::CamHelper';
#use aliased 'CamHelpers::CamStepRepeat';
#use aliased 'Helpers::FileHelper';
#use aliased 'Packages::Export::GerExport::Helper';
use aliased 'Packages::Scoring::ScoreOptimize::ScoreLayer::ScoreSet';
use aliased 'Packages::Scoring::ScoreOptimize::ScoreLayer::ScoreLine';
use aliased 'Packages::Scoring::ScoreOptimize::ScoreLayer::ScoreLayer';

use aliased 'Packages::Scoring::ScoreChecker::Enums' => "ScoEnums";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"}        = shift;
	$self->{"jobId"}        = shift;
	$self->{"scoreChecker"} = shift;

	$self->{"convertor"}  = $self->{"scoreChecker"}->GetConvertor();
	$self->{"scoreLayer"} = undef;

	$self->{"reduce"} = 4;    # reduce score from profile by 4mm

	return $self;
}

sub Run {
	my $self     = shift;
	my $optimize = shift;

	my $checker    = $self->{"scoreChecker"};
	my $isStraight = $checker->IsStraight();

	if ($isStraight) {

		#$self->{"scoreLayer"} = $self->__OptimizeJumpScoring();

		$self->{"reduce"} = 0;
	}
	else {
		
	 	$self->{"reduce"} = $checker->GetReduceDist();
 
	}

	print STDERR "Score is Straight = " . $isStraight . "\n.";

	if ($optimize) {

		$self->{"scoreLayer"} = $self->__PrepareOptimizeScoreData();
	}
	else {

		$self->{"scoreLayer"} = $self->__PrepareScoreData();
	}

}

#sub __OptimizeStandard {
#	my $self = shift;
#
#}

# -------------------------------------------------------
# Methods, create final score layer
# -------------------------------------------------------

sub __PrepareScoreData {
	my $self = shift;

	my $checker  = $self->{"scoreChecker"};
	my $pcbPlace = $checker->GetPcbPlace();

	my $scoreLayer = ScoreLayer->new();

	# all verticall and horiyontall score positions
	my @scorePos = $pcbPlace->GetScorePos();

	foreach my $posInfo (@scorePos) {

		my $pos = $posInfo->GetPosition();
		my $dir = $posInfo->GetDirection();

		my @pcbOnPos = $pcbPlace->GetPcbOnScorePos($posInfo);

		# create set of optimiyed score lines on this position
		my $scoreSet = $self->__CreateSet( $posInfo, \@pcbOnPos );

		$scoreLayer->AddScoreSet($scoreSet);
	}

	return $scoreLayer;
}

sub __CreateSet {
	my $self   = shift;
	my $posPnl = shift;             # score through by this position (position has coordiante relative to panel origin)
	my @pcbs   = @{ shift(@_) };    # pcb which are intersect by score

	my $dir   = $posPnl->GetDirection();
	my $point = $posPnl->GetPosition();

	# new info struct about score position and all score lines
	my $scoreSet = ScoreSet->new( $point, $dir );
	my $line     = ScoreLine->new($dir);            # Init new lajn
	                                                #my $lstPoint = undef;
	                                                # Go through all pcb which are potential intersect  by score
	foreach my $pcb (@pcbs) {

		my @score = $self->__GetScore( $posPnl, $pcb );

		foreach my $sco (@score) {

			my $line = ScoreLine->new($dir);        # Init new lajn

			my $start = $sco->GetStartP();
			my $end   = $sco->GetEndP();

			$self->__StartLine( $line, $start, $pcb );
			$self->__EndLine( $line, $end, $pcb );

			$scoreSet->AddScoreLine($line);
		}
	}

	return $scoreSet;

}

sub __PrepareOptimizeScoreData {
	my $self = shift;

	my $checker  = $self->{"scoreChecker"};
	my $pcbPlace = $checker->GetPcbPlace();

	my $scoreLayer = ScoreLayer->new();

	# all verticall and horiyontall score positions
	my @scorePos = $pcbPlace->GetScorePos();

	foreach my $posInfo (@scorePos) {

		my $pos = $posInfo->GetPosition();
		my $dir = $posInfo->GetDirection();

		my @pcbOnPos = $pcbPlace->GetPcbOnScorePos($posInfo);

		# create set of optimiyed score lines on this position
		my $scoreSet = $self->__CreateOptimizeSet( $posInfo, \@pcbOnPos );

		$scoreLayer->AddScoreSet($scoreSet);
	}
	return $scoreLayer;
}

sub __CreateOptimizeSet {
	my $self   = shift;
	my $posPnl = shift;             # score through by this position (position has coordiante relative to panel origin)
	my @pcbs   = @{ shift(@_) };    # pcb which are intersect by score

	my $dir   = $posPnl->GetDirection();
	my $point = $posPnl->GetPosition();

	# new info struct about score position and all score lines
	my $scoreSet = ScoreSet->new( $point, $dir );
	my $line     = ScoreLine->new($dir);            # Init new lajn
	                                                #my $lstPoint = undef;
	my $lstPcb   = undef;

	# Go through all pcb which are potential intersect  by score
	for ( my $i = 0 ; $i < scalar(@pcbs) ; $i++ ) {

		my $pcb = $pcbs[$i];                        # investigate pcb

		my $scoreCnt = $self->__GetScoreCnt( $posPnl, $pcb );    # get all score lines, on this pcb
		my $noOptimize = $self->__NoOptimize( $posPnl, $pcb );
		my @allPoints = $self->__GetPoints( $posPnl, $pcb );     # get all points, where score start or end. Sorted

		# Exist 3 cases: 1) more lines, 2) one line, 3) no lines

		# 1) more lines
		# This line has not to be optimized (connected together on this pcb,
		# but can be connected with another board)
		if ($noOptimize) {

			# Go through points
			foreach my $pointInf (@allPoints) {

				# get gap between profile and start of score line

				my $reduce = 0;

				#
				#				# reduce line, if poin is first point OR last poin of score on this pcb
				#				# AND from profile is less than 4 mm
				#				if ( ( $point == $allPoints[0] || $point == $allPoints[ scalar(@allPoints) - 1 ] ) ) {
				#
				#						my $dist = $pcb->GetProfileDist( $point, $dir );
				#
				#						if($dist < 4 ){
				#							  $reduce = 1;
				#						}
				#
				#				}

				if ( $pointInf->GetDist() < 4 ) {
					$reduce = 1;
				}

				unless ( $line->StartPExist() ) {

					# zacni novou
					#$line->SetStartP($point);
					$self->__StartLine( $line, $pointInf, $pcb, $reduce );

				}
				else {

					#$line->SetEndP($point);
					$self->__EndLine( $line, $pointInf, $pcb, $reduce );

				}

				# if line is complete (contain start and end point)
				# store it and create new line
				if ( $line->Complete() ) {

					$scoreSet->AddScoreLine($line);
					$line = ScoreLine->new($dir);
				}

			}

		}

		# 2) one line,
		# never end line here.
		# start line only if it hasn't started yet
		elsif ( $scoreCnt == 1 ) {

			unless ( $line->StartPExist() ) {

				# Start new line
				#$line->SetStartP( $allPoints[0] );
				$self->__StartLine( $line, $allPoints[0], $pcb, 1 );

			}
			else {

				# dont end line
			}

		}

		# 3) no lines
		# always end line. End point is end point of last line in last pcb
		else {

			if ( $line->StartPExist() ) {

				@allPoints = $self->__GetPoints( $posPnl, $lstPcb );
				$noOptimize = $self->__NoOptimize( $posPnl, $lstPcb );

				my $point = $allPoints[ scalar(@allPoints) - 1 ];

				# ukonci lajnu
				#$line->SetEndP( $allPoints[ scalar(@allPoints) - 1 ] );

				# Dont recuce lines, when pcb should not be optimized
				my $reduce = 1;
				if ( $noOptimize && $point->GetDist() > 4 ) {
					$reduce = 0;
				}
				$self->__EndLine( $line, $point, $lstPcb, $reduce );

			}
		}

		# if line is complete (contain start and end point)
		# store it and create new line
		if ( $line->Complete() ) {

			$scoreSet->AddScoreLine($line);
			$line = ScoreLine->new($dir);
		}

		$lstPcb = $pcbs[$i];

	}

	# Finally, if some last is not ended ( case when last step contain score)
	# end this line
	if ( $line->StartPExist() ) {
		my @allPoints = $self->__GetPoints( $posPnl, $lstPcb );
		my $noOptimize = $self->__NoOptimize( $posPnl, $lstPcb );

		my $point = $allPoints[ scalar(@allPoints) - 1 ];

		# ukonci lajnu
		#$line->SetEndP( $allPoints[ scalar(@allPoints) - 1 ] );
		my $reduce = 1;
		if ( $noOptimize && $point->GetDist() > 4 ) {
			$reduce = 0;
		}

		$self->__EndLine( $line, $point, $lstPcb, $reduce );

		$scoreSet->AddScoreLine($line);
	}

	return $scoreSet;

}

# -------------------------------------------------------
# Helper private methods
# -------------------------------------------------------
sub __StartLine {
	my $self     = shift;
	my $line     = shift;
	my $pointInf = shift;
	my $pcb      = shift;
	my $reduce   = shift;

	my $point = $pointInf->GetPoint();
	my %newPoint = ( "x" => 0, "y" => 0 );

	if ( $reduce && $pointInf->GetType() eq "first" ) {
		my $dir = $line->GetDirection();

		if ( $dir eq ScoEnums->Dir_HSCORE ) {

			$newPoint{"x"} = $self->{"reduce"};
			$newPoint{"y"} = $point->{"y"};
		}
		elsif ( $dir eq ScoEnums->Dir_VSCORE ) {

			$newPoint{"x"} = $point->{"x"};
			$newPoint{"y"} = $pcb->GetHeight() - $self->{"reduce"};
		}
	}
	else {

		$newPoint{"x"} = $point->{"x"};
		$newPoint{"y"} = $point->{"y"};
	}

	my $finalPoint = $self->{"convertor"}->DoPoint( \%newPoint, $pcb, $line->GetDirection() );

	$line->SetStartP($finalPoint);
}

sub __EndLine {
	my $self     = shift;
	my $line     = shift;
	my $pointInf = shift;
	my $pcb      = shift;
	my $reduce   = shift;

	my $point = $pointInf->GetPoint();
	my %newPoint = ( "x" => 0, "y" => 0 );

	if ( $reduce && $pointInf->GetType() eq "last" ) {
		my $dir = $line->GetDirection();

		if ( $dir eq ScoEnums->Dir_HSCORE ) {

			$newPoint{"x"} = $pcb->GetWidth() - $self->{"reduce"};
			$newPoint{"y"} = $point->{"y"};
		}
		elsif ( $dir eq ScoEnums->Dir_VSCORE ) {

			$newPoint{"x"} = $point->{"x"};
			$newPoint{"y"} = $self->{"reduce"};
		}
	}
	else {
		$newPoint{"x"} = $point->{"x"};
		$newPoint{"y"} = $point->{"y"};

	}

	my $finalPoint = $self->{"convertor"}->DoPoint( \%newPoint, $pcb, $line->GetDirection() );

	$line->SetEndP($finalPoint);
}

# For specific pcb, get all points, where score start or end.
# point are sorted according lines
# Consider new origin of whole "panel" (pcb are placed in panel)
sub __GetPoints {
	my $self = shift;
	my $pos  = shift;
	my $pcb  = shift;

	my $dir = $pos->GetDirection();

	my $posPcb = $self->{"convertor"}->DoPosInfo( $pos, $pcb, 1 );    # origin relative to pcb

	my @allPoints = $pcb->GetScorePointsOnPos($posPcb);

	#@allPoints = map { Convertor->DoPoint( $_, $pcb, $dir ) } @allPoints;    # origin relative to panel

	return @allPoints;
}

sub __GetScoreCnt {
	my $self = shift;
	my $pos  = shift;
	my $pcb  = shift;

	my @allSco = $self->__GetScore( $pos, $pcb );    # get all score lines, on this pcb

	return scalar(@allSco);
}

# Some pcb scores we don't want to optimize
# Exist 2 cases
# Case 1) if customer has more then one score on same position
# Case 2) if score is too short, it could mean, customer don't want to score all pcb
sub __NoOptimize {
	my $self = shift;
	my $pos  = shift;
	my $pcb  = shift;

	my $posPcb = $self->{"convertor"}->DoPosInfo( $pos, $pcb, 1 );

	my $noOptimize = $pcb->NoOptimize($posPcb);

	return $noOptimize;
}

# For specific pcb, get all score lines
# score is sorted, start TOP/LEFT
# Consider new origin of whole "panel" (pcb are placed in panel)
sub __GetScore {
	my $self = shift;
	my $pos  = shift;
	my $pcb  = shift;

	my $dir = $pos->GetDirection();

	my $posPcb = $self->{"convertor"}->DoPosInfo( $pos, $pcb, 1 );    # consider origin of pcb

	my @allSco = $pcb->GetScoresOnPos($posPcb);                       # get all score lines, on this pcb

	return @allSco;
}

sub GetScoreData {
	my $self = shift;

	return $self->{"scoreLayer"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::ScoreExport::Optimizator::Optimizator';
	#	use aliased 'Packages::Scoring::ScoreChecker::ScoreChecker';
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $jobId = "f52456";
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $checker = ScoreChecker->new( $inCAM, $jobId, "panel" );
	#
	#	my $optim = Optimizator->new( $inCAM, $jobId, $checker );
	#	$optim->Optimize();
	#
	#	print 1;

}

1;

