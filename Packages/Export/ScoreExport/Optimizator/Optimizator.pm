
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers for particular machine, which can procces given nc file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::ScoreExport::Optimizator;
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
use aliased 'Packages::Export::ScoreExport::ScoreLayer::ScoreSet';
use aliased 'Packages::Export::ScoreExport::ScoreLayer::ScoreLine';
use aliased 'Packages::Export::ScoreExport::ScoreLayer::ScoreLayer';

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

	return $self;
}

sub Optimize {
	my $self = shift;

	my $checker = $self->{"scoreChecker"};

	if ( $checker->IsJumScoring() ) {

		$self->__OptimizeJumpScoring();

	}
	else {

		$self->__OptimizeStandard();
	}

}

sub __OptimizeStandard {
	my $self = shift;

}

sub __OptimizeJumpScoring {
	my $self = shift;

	my $checker  = $self->{"scoreChecker"};
	my $pcbPlace = $checker->GetPcbPlace();

	my $scoreLayer = ScoreLayer->new();

	# all verticall and horiyontall score positions
	my @scorePos = $self->{"pcbPlace"}->GetScorePos();

	foreach my $posInfo (@scorePos) {

		my $pos = $posInfo->GetPosition();
		my $dir = $posInfo->GetDirection();

		my @pcbOnPos = $self->{"pcbPlace"}->GetPcbOnScorePos($pos);

		# create set of optimiyed score lines on this position
		my $scoreSet = $self->__OptimizeScoreLines( $posInfo, @pcbOnPos );

		$scoreLayer->AddScoreSet($scoreSet);
	}
	return $scoreLayer
}

sub __OptimizeScoreLines {
	my $self    = shift;
	my $posInfo = shift;             # score through by this position
	my @pcbs    = @{ shift(@_) };    # pcb which are intersect by score

	# new info struct about score position and all score lines
	my $scoreSet = ScoreSet->new( $posInfo->GetPosition(), $posInfo->GetDirection() );

	my $line   = ScoreLine->new( $posInfo->GetDirection() );    # Init new lajn
	                                                            #my $lstPoint = undef;
	my $lstPcb = undef;

	# Go through all pcb which are potential intersect  by score
	for ( my $i = 0 ; $i < scalar(@pcbs) ; $i++ ) {

		my $pcb = $pcbs[$i];                                    # investigate pcb

		my @allSco    = $pcb->GetScoresOnPos($posInfo);         # get all score lines, on this pcb
		my @allPoints = $self->__GetPoints($posInfo, $pcb);;    # get all points, where score start or end. Sorted

		# Exist 3 cases: 1) more lines, 2) one line, 3) no lines

		# 1) more lines
		# This line has not to be optimized (connected together on this pcb,
		# but can be connected with another board)
		if ( scalar(@allSco) > 1 ) {

			# Go through points
			foreach my $point (@allPoints) {

				unless ( $line->StartPExist() ) {

					# zacni novou
					$line->SetStartP($point);

				}
				else {

					# always end lines, except this is last point
					unless ( $point = $allSco[ scalar(@allSco) - 1 ] ) {

						$line->SetEndP($point);
					}
				}
			}

		}

		# 2) one line,
		# never end line here.
		# start line only if it hasn't started yet
		elsif ( scalar(@allSco) == 1 ) {

			unless ( $line->StartPExist() ) {

				# Start new line
				$line->SetStartP( $allPoints[0] );

			}
			else {

				# dont end line
			}

		}

		# 3) no lines
		# always end line. End point is end point of last line in last pcb
		else {

			if ( $line->StartPExist() ) {

				@allPoints = $self->__GetPoints($posInfo, $lstPcb);

				# ukonci lajnu
				$line->SetEndP( $allPoints[ scalar(@allPoints) - 1 ] );

			}
		}

		# if line is complete (contain start and end point)
		# store it and create new line
		if ( $line->Complete() ) {

			$scoreSet->AddScoreLine($line);
			$line = ScoreLine->new( $posInfo->GetDirection() );
		}

		$lstPcb = $pcbs[$i];

	}

	# Finally, if some last is not ended ( case when last step contain score)
	# end this line
	if ( $line->StartPExist() ) {
		my @allPoints =  $self->__GetPoints($posInfo, $lstPcb);

		# ukonci lajnu
		$line->SetEndP( $allPoints[ scalar(@allPoints) - 1 ] );
	}

	return $scoreSet;

}

# For specific pcb, get all points, where score start or end.
# point are sorted according lines
# Consider new origin of whole "panel" (pcb are placed in panel)
sub __GetPoints{
	my $self     = shift;
	my $pos      = shift;
	my $pcb      = shift;
	
	my $dir = $pos->GetDierection();
	my @allPoints = $pcb->GetScorePointsOnPos($pos);
	
	@allPoints = map { $self->__ConsiderOrigin($dir, $_, $pcb)} @allPoints;
	
	return @allPoints;
	
}

# Do conversion of position value (inside a step), between "panel" origin and step origin
sub __ConsiderOrigin {
	my $self     = shift;
	my $dir      = shift;
	my $point      = shift;
	my $pcb      = shift;
	 

	my $sign = 1;
  

	# consider origin of "panel" and location of pcb
	if ($dir eq ScoEnums->Dir_HSCORE ) {

		$point->{"y"} += $sign * $pcb->GetOrigin()->{"y"};

	}
	elsif ( $dir eq ScoEnums->Dir_VSCORE ) {

		$point->{"x"} += $sign * $pcb->GetOrigin()->{"x"};
	}
	
	return $point;
 
}


sub GetOptimizeLayer {
	my $self = shift;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::ScoreExport::Optimizator';
	 use aliased 'Packages::Scoring::ScoreChecker::ScoreChecker';
	use aliased 'Packages::InCAM::InCAM';

	my $jobId = "f52456";

	my $inCAM = InCAM->new();

	my $checker = ScoreChecker->new( $inCAM, $jobId, "panel" );
	
	my $optim = Optimizator->new($checker);
	$optim->Optimize();

	print 1;

}

1;

