
#-------------------------------------------------------------------------------------------#
# Description: Optimiye score data for scorin machines
# - shortens lines, links lines, etc..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreOptimize::Optimizator;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::Scoring::ScoreOptimize::ScoreLayer::ScoreSet';
use aliased 'Packages::Scoring::ScoreOptimize::ScoreLayer::ScoreLine';
use aliased 'Packages::Scoring::ScoreOptimize::ScoreLayer::ScoreLayer';
use aliased 'Packages::Scoring::ScoreChecker::OriginConvert' => "Convertor";
use aliased 'Packages::Scoring::ScoreChecker::Enums'         => "ScoEnums";

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

	$self->{"scoreLayer"} = undef;

	$self->{"reduce"} = undef;    # reduce score from profile by 4mm

	return $self;
}

sub Run {
	my $self     = shift;
	my $optimize = shift;

	my $checker    = $self->{"scoreChecker"};
	my $isStraight = $checker->IsStraight();

	# if jumpscoring "is not needed", dont shortens lines
	if ($isStraight) {

		$self->{"reduce"} = 0;
	}
	else {
		
		# get distance which is necessary in order score doesn't cut next pcb
		$self->{"reduce"} = $checker->GetReduceDist();

	}

	my $scoreLayer = ScoreLayer->new();

	if ($optimize) {

		$self->__PrepareOptimizeScoreData($scoreLayer);
	}
	else {

		$self->__PrepareScoreData($scoreLayer);
	}

	$self->{"scoreLayer"} = $scoreLayer;

}

sub GetScoreData {
	my $self = shift;

	return $self->{"scoreLayer"};

}
 

# -------------------------------------------------------
# Methods, create final score layer
# -------------------------------------------------------

# prepare score data , do NOT optimize
sub __PrepareScoreData {
	my $self       = shift;
	my $scoreLayer = shift;

	my $checker  = $self->{"scoreChecker"};
	my $pcbPlace = $checker->GetPcbPlace();

	# all verticall and horiyontall score positions

	my @h = $pcbPlace->GetScorePos( ScoEnums->Dir_HSCORE );
	my @v = $pcbPlace->GetScorePos( ScoEnums->Dir_VSCORE );

	my @scorePos = ( @h, @v );

	foreach my $posInfo (@scorePos) {

		my $pos = $posInfo->GetPosition();
		my $dir = $posInfo->GetDirection();

		my @pcbOnPos = $pcbPlace->GetPcbOnScorePos($posInfo);

		# create set of optimiyed score lines on this position
		my $scoreSet = $self->__CreateSet( $posInfo, \@pcbOnPos );

		$scoreLayer->AddScoreSet($scoreSet);
	}

}

sub __CreateSet {
	my $self   = shift;
	my $posPnl = shift;             # score through by this position (position has coordiante relative to panel origin)
	my @pcbs   = @{ shift(@_) };    # pcb which are intersect by score

	my $dir   = $posPnl->GetDirection();
	my $point = $posPnl->GetPosition();

	# new info struct about score position and all score lines
	my $scoreSet = ScoreSet->new( $point, $dir );
	my $line     = ScoreLine->new($dir);             # Init new lajn
	                                                 #my $lstPoint = undef;
	                                                 # Go through all pcb which are potential intersect  by score
	foreach my $pcb (@pcbs) {

		my @score = $self->__GetScore( $posPnl, $pcb );
		my @allPoints = $self->__GetPoints( $posPnl, $pcb );    # get all points, where score start or end. Sorted

		foreach my $sco (@score) {

			my $line = ScoreLine->new($dir);                    # Init new lajn

			my $sPoint = Convertor->DoPoint( $sco->GetStartP(), $pcb );
			$line->SetStartP($sPoint);

			my $ePoint = Convertor->DoPoint( $sco->GetEndP(), $pcb );
			$line->SetEndP($ePoint);

			$scoreSet->AddScoreLine($line);
		}
	}

	return $scoreSet;

}

# prepare score data , DO optimize
sub __PrepareOptimizeScoreData {
	my $self       = shift;
	my $scoreLayer = shift;

	my $checker  = $self->{"scoreChecker"};
	my $pcbPlace = $checker->GetPcbPlace();

	# all verticall and horiyontall score positions
	my @h = $pcbPlace->GetScorePos( ScoEnums->Dir_HSCORE );
	my @v = $pcbPlace->GetScorePos( ScoEnums->Dir_VSCORE );

	my @scorePos = ( @h, @v );

	foreach my $posInfo (@scorePos) {

		my $pos = $posInfo->GetPosition();
		my $dir = $posInfo->GetDirection();

		my @pcbOnPos = $pcbPlace->GetPcbOnScorePos($posInfo);

		# create set of optimiyed score lines on this position
		my $scoreSet = $self->__CreateOptimizeSet( $posInfo, \@pcbOnPos );

		$scoreLayer->AddScoreSet($scoreSet);
	}

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
			
			
			# First check, if there is not complete line
			# if so, end this line
			if ( $line->StartPExist() ) {
				
					$self->__EndLineOfLastPcb( $line,  $lstPcb, $posPnl);
					$scoreSet->AddScoreLine($line);
					$line = ScoreLine->new($dir);
			}
			
 
			# Go through points
			for(my $j = 0; $j < scalar(@allPoints); $j++) {

				my $pointInf = $allPoints[$j];

				# get gap between profile and start of score line

				my $reduce = 0;

 
				if ( defined $pointInf->GetDist() && $pointInf->GetDist() < $self->{"reduce"} ) {
					$reduce = 1;
				}

				unless ( $line->StartPExist() ) {

					$self->__StartLine( $line, $pointInf, $pcb, $reduce );

				}
				else {
					
					
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

#				@allPoints = $self->__GetPoints( $posPnl, $lstPcb );
#				$noOptimize = $self->__NoOptimize( $posPnl, $lstPcb );
#
#				my $point = $allPoints[ scalar(@allPoints) - 1 ];
#
#				# ukonci lajnu
#				#$line->SetEndP( $allPoints[ scalar(@allPoints) - 1 ] );
#
#				# Dont recuce lines, when pcb should not be optimized
#				my $reduce = 1;
#				if ( $noOptimize && $point->GetDist() > $self->{"reduce"} ) {
#					$reduce = 0;
#				}
#				$self->__EndLine( $line, $point, $lstPcb, $reduce );

				$self->__EndLineOfLastPcb( $line,  $lstPcb, $posPnl);

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
#		my @allPoints = $self->__GetPoints( $posPnl, $lstPcb );
#		my $noOptimize = $self->__NoOptimize( $posPnl, $lstPcb );
#
#		my $point = $allPoints[ scalar(@allPoints) - 1 ];
#
#		# ukonci lajnu
#		#$line->SetEndP( $allPoints[ scalar(@allPoints) - 1 ] );
#		my $reduce = 1;
#		if ( $noOptimize && $point->GetDist() > $self->{"reduce"} ) {
#			$reduce = 0;
#		}
#
#		$self->__EndLine( $line, $point, $lstPcb, $reduce );

		$self->__EndLineOfLastPcb( $line,  $lstPcb, $posPnl);

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

	my $finalPoint = Convertor->DoPoint( \%newPoint, $pcb );

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

	my $finalPoint = Convertor->DoPoint( \%newPoint, $pcb );

	$line->SetEndP($finalPoint);
}

sub __EndLineOfLastPcb{
	my $self     = shift;
	my $line     = shift;
	my $lstPcb     = shift;
	my $posPnl     = shift;
	
		my @allPoints = $self->__GetPoints( $posPnl, $lstPcb );
		my $noOptimize = $self->__NoOptimize( $posPnl, $lstPcb );

		my $point = $allPoints[ scalar(@allPoints) - 1 ];

		# ukonci lajnu
		#$line->SetEndP( $allPoints[ scalar(@allPoints) - 1 ] );
		my $reduce = 1;
		if ( $noOptimize && $point->GetDist() > $self->{"reduce"} ) {
			$reduce = 0;
		}

		$self->__EndLine( $line, $point, $lstPcb, $reduce );
	
	
}

# For specific pcb, get all points, where score start or end.
# point are sorted according lines
# Consider new origin of whole "panel" (pcb are placed in panel)
sub __GetPoints {
	my $self = shift;
	my $pos  = shift;
	my $pcb  = shift;

	my $dir = $pos->GetDirection();

	my $posPcb = Convertor->DoPosInfo( $pos, $pcb, 1 );    # origin relative to pcb

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

	my $posPcb = Convertor->DoPosInfo( $pos, $pcb, 1 );

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

	my $posPcb = Convertor->DoPosInfo( $pos, $pcb, 1 );    # consider origin of pcb

	my @allSco = $pcb->GetScoresOnPos($posPcb);            # get all score lines, on this pcb

	return @allSco;
}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::ScoreExport::Optimizator::Optimizator';
	 
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

