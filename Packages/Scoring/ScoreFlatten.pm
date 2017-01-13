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
use aliased 'Managers::MessageMngr::MessageMngr';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Flatten score in given step and delete score data from nested steps
sub FlattenNestedScore {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;
	
	unless(CamHelper->StepExists($inCAM, $jobId, $stepName)){
		return 0;
	}
	
	unless(CamHelper->LayerExists($inCAM, $jobId, "score")){
		return 1;
	}

	CamHelper->SetStep( $inCAM, $stepName );

	my @scoreSteps = ();    # nested steps where is scoring

	# test if exist nested steps
	my @sr = CamStepRepeat->GetStepAndRepeat( $inCAM, $jobId, $stepName );

	if ( scalar(@sr) == 0 ) {
		return 0;
	}

	# Check if any step and repeat contain score

	my $scoreExist  = 0;
	my $customerJum = 0;

	foreach my $srStep (@sr) {

		my $name = $srStep->{"gSRstep"};

		if ( $self->__ScoreExist( $inCAM, $jobId, $name ) ) {

			push( @scoreSteps, $name );

			$scoreExist = 1;

			# test if jumpscoring
			my $checker = ScoreChecker->new( $inCAM, $jobId, $name, "score", 0 );
			$checker->Init();
			if ( $checker->CustomerJumpScoring() ) {

				$customerJum = 1;
			}
		}
	}

	# if jumscoring, no flatten
	unless ($scoreExist) {

		return 0;
	}

	# if jumscoring, no flatten
	if ($customerJum) {

		return 0;
	}

	# Flatten score layer
	CamLayer->FlatternLayer( $inCAM, $jobId, $stepName, "score" );

	# Do optimization
	# pripadna kontrola jestli i v mpanelu neni uzivatelskz jumpscoring !
	
	#my $checker = ScoreChecker->new( $inCAM, $jobId, $stepName, "score", 0 );
	#$checker->Init();
	#unless ( $checker->CustomerJumpScoring() ) {

		$self->__ScoreRepair( $inCAM, $jobId, $stepName );
	#}

	my @uniqSteps = uniq(@scoreSteps);

	# remove score line from nested steps
	foreach my $name (@uniqSteps) {

		CamHelper->SetStep( $inCAM, $name );
		CamLayer->WorkLayer( $inCAM, "score" );
		$inCAM->COM('sel_delete');
	}

	CamHelper->SetStep( $inCAM, $stepName );

	# show inforamtion window
	my @mess =
	  (   "Drážky ze stepu: "
		. join( ", ", @uniqSteps )
		. " byly přesunuty do stepu: $stepName. Zkontroluj jestli je drážkování ve stepu $stepName v pořádku." );

	my $messMngr = MessageMngr->new($jobId);
	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess );

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

	my $dist = 4;                                                               #sit from profile
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

	my $jobId = "f13609";
	my $inCAM = InCAM->new();

	my $step = "mpanel";

	my $max = ScoreFlatten->FlattenNestedScore( $inCAM, $jobId, $step );

}

1;
