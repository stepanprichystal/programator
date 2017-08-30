#-------------------------------------------------------------------------------------------#
# Description: Flatten score from nested step to given step and optimize it. uniq (
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreFlatten;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library

use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::Scoring::ScoreChecker::ScoreChecker';
use aliased 'Packages::Polygon::Features::ScoreFeatures::ScoreFeatures';
use aliased 'Packages::Scoring::Optimalization::Enums';
use aliased 'Packages::Scoring::Optimalization::Helper';


#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;

	return $self;

}

sub NeedFlatten {
	my $self    = shift;
	my $scoreSR = shift;    # nested steps where is scoring

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $stepName = $self->{"step"};

	if ( !CamHelper->StepExists( $inCAM, $jobId, $stepName ) || !CamHelper->LayerExists( $inCAM, $jobId, "score" ) ) {
		return 0;
	}

	CamHelper->SetStep( $inCAM, $stepName );

	# test if exist nested steps
	my @sr = CamStepRepeat->GetStepAndRepeat( $inCAM, $jobId, $stepName );

	if ( scalar(@sr) == 0 ) {
		return 0;
	}

	# Check if any step and repeat contain score

	my $scoreExist       = 0;
	my $customerJum      = 0;
	my @customerJumSteps = ();

	foreach my $srStep (@sr) {

		my $name = $srStep->{"gSRstep"};

		if ( $self->__ScoreExist( $inCAM, $jobId, $name ) ) {

			if ( defined $scoreSR ) {
				push( @{$scoreSR}, $name );
			}

			$scoreExist = 1;
		}
	}

	return $scoreExist;
}

sub JumpScoringExist {
	my $self             = shift;
	my $customerJumSteps = shift;

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $stepName = $self->{"step"};

	my $customerJum = 0;

	my @scoreStep = ();

	$self->NeedFlatten( \@scoreStep );

	foreach my $s (@scoreStep) {

		# test if jumpscoring
		my $checker = ScoreChecker->new( $inCAM, $jobId, $s, "score", 0 );
		$checker->Init();
		if ( $checker->CustomerJumpScoring() ) {

			$customerJum = 1;

			if ( defined $customerJumSteps ) {

				push( @{$customerJumSteps}, $s );
			}
		}
	}

	return $customerJum;
}

# Flatten score in given step and delete score data from nested steps
sub FlattenNestedScore {
	my $self     = shift;
	my $repairScore = shift;
	
	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $stepName = $self->{"step"};
	
	my @scoreSteps = ();

	unless($self->NeedFlatten( \@scoreSteps )){
	
		return 0;
	}

 
	# Flatten score layer
	CamLayer->FlatternLayer( $inCAM, $jobId, $stepName, "score" );

	# Do optimization
	# pripadna kontrola jestli i v mpanelu neni uzivatelskz jumpscoring !

	#my $checker = ScoreChecker->new( $inCAM, $jobId, $stepName, "score", 0 );
	#$checker->Init();
	#unless ( $checker->CustomerJumpScoring() ) {

	if ($repairScore) {
		$self->__ScoreRepair( $inCAM, $jobId, $stepName );
	}

	my @uniqSteps = uniq(@scoreSteps);

	# remove score line from nested steps
	foreach my $name (@uniqSteps) {

		CamHelper->SetStep( $inCAM, $name );
		CamLayer->WorkLayer( $inCAM, "score" );
		$inCAM->COM('sel_delete');
	}

	CamHelper->SetStep( $inCAM, $stepName );
 
}

sub __ScoreRepair {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;

	my %errors  = ( "errors" => undef, "warrings" => undef );
	my $changes = 0;                                            # tell if some changes was done
	                                                            # parse score in step
	my $score   = ScoreFeatures->new(0);

	$score->Parse( $inCAM, $jobId, $stepName, "score", 0 );
	my @scoreFeatures = $score->GetFeatures();

	my $dist = 0;                                                               #sit from profile
	my %profileLimts = CamJob->GetProfileLimits( $inCAM, $jobId, $stepName );

	# 1) do score streight
	Helper->GetStraightScore( \@scoreFeatures, \$changes, \%errors );

	# 2) Remove duplication
	@scoreFeatures = Helper->RemoveDuplication( \@scoreFeatures, \$changes, \%errors );

	# 3) Adapt score line to profile
	my $checkProf = Helper->CheckProfileDistance( \@scoreFeatures, \%profileLimts, $dist, \%errors );

	if ( $checkProf ne Enums->ScoreLength_OK ) {
		@scoreFeatures = Helper->AdaptScoreToProfile( \@scoreFeatures, \%profileLimts, $dist, \%errors );
	}

	CamLayer->WorkLayer( $inCAM, "score" );

	$inCAM->COM('sel_delete');

	$self->__DrawScoreLines( $inCAM, \@scoreFeatures );

}

sub __DrawScoreLines {

	my $self     = shift;
	my $inCAM    = shift;
	my @features = @{ shift(@_) };
	my $lastIdx;

	for ( my $i = 0 ; $i < scalar(@features) ; $i++ ) {

		if ( $features[$i]{"type"} eq "L" ) {

			$lastIdx = $inCAM->COM(
									'add_line',
									attributes => 'no',
									xs         => $features[$i]{"x1"},
									ys         => $features[$i]{"y1"},
									xe         => $features[$i]{"x2"},
									ye         => $features[$i]{"y2"},
									"symbol"   => "r400"
			);
		}

		$features[$i]{"id"} = $lastIdx;
	}
}

sub __ScoreExist {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;

	my $score = ScoreFeatures->new(1);

	$score->Parse( $inCAM, $jobId, $stepName, "score", 1 );
	my @lines = $score->GetFeatures();

	if ( scalar(@lines) ) {
		return 1;
	}
	else {
		return 0;
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Scoring::ScoreFlatten';
	use aliased 'Packages::InCAM::InCAM';

	my $jobId = "f52457";
	my $inCAM = InCAM->new();

	my $step = "mpanel";

	my $max = ScoreFlatten->FlattenNestedScore( $inCAM, $jobId, $step );

}

1;
