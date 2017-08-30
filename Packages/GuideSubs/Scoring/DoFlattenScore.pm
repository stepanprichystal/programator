#-------------------------------------------------------------------------------------------#
# Description: Floatten score in SR steps to mpanel
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Scoring::DoFlattenScore;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Packages::Scoring::ScoreFlatten';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

# Check if there is outline layer, if all other layer (inner, right etc) are in this outline layer
sub FlattenMpanelScore {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $messMngr = MessageMngr->new($jobId);

	my $stepName = "mpanel";

	my $sf = ScoreFlatten->new( $inCAM, $jobId, $stepName );

	my @scoreSteps = ();

	# 1) Check if flatten is needed
	unless ( $sf->NeedFlatten( \@scoreSteps ) ) {

		return 0;
	}

	# 2) Check if there is jump scoring
	my $repairScore = 1;

	my @scoreStepsJump = ();
	my $jumpScoring    = $sf->JumpScoringExist( \@scoreStepsJump );

	if ($jumpScoring) {

		my $strStep = join( ", ", @scoreStepsJump );

		my $userResultJump = 2;

		while ( $userResultJump == 2 ) {
			my @mess = (
				  "Problém při přesunu drážky do stepu '$stepName'. Vypadá to, že ve vnořeném stepu ($strStep) má zákazník jump-scoring.",
				  "Je to opravdu uživatelský jump-scoring?"
			);

			my @btn = ( "Ano", "Ne", "Zkontrolovat drážku" );

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess, \@btn );

			$userResultJump = $messMngr->Result();

			if ( $userResultJump == 2 ) {
				$inCAM->PAUSE("Zkontroluj, zda stepy uvnitr stepu '$stepName' obsahuji uzivatelsky jump-scoring");
			}
			else {

				# Customer jumpscoring, do not repair score after flatten
				if ( $userResultJump == 0 ) {
					$repairScore = 0;
				}

				last;
			}
		}
	}
	
	# 3) Flatten score
	$sf->FlattenNestedScore($repairScore);

	# show inforamtion window
	my @mess =
	  (   "Drážky ze stepu: "
		. join( ", ", uniq(@scoreSteps) )
		. " byly přesunuty do stepu: '$stepName'. Zkontroluj jestli je drážkování ve stepu '$stepName' v pořádku." );

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

