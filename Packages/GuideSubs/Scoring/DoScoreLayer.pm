#-------------------------------------------------------------------------------------------#
# Description: Create default score layer after panelisation before export
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Scoring::DoScoreLayer;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Packages::Scoring::ScoreFlatten';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Scoring::ScoreChecker::ScoreChecker';
use aliased 'Packages::Scoring::ScoreOptimize::ScoreOptimize';
use aliased 'Packages::Export::ScoExport::ProgCreator::ProgCreator';
use aliased 'Packages::Scoring::ScoreChecker::ScoreChecker';
use aliased 'Packages::Scoring::ScoreOptimize::ScoreOptimize';
use aliased 'Packages::Export::ScoExport::ProgCreator::ProgCreator';
use aliased 'Packages::Export::ScoExport::Enums';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::Scoring::ScoreChecker::Enums' => "ScoEnums";
use aliased 'Packages::ItemResult::Enums'            => "ResEnums";



#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#
my @messHead = ();
push( @messHead, "<g>=====================================</g>" );
push( @messHead, "<g>Průvodce vytvořením vrstvy score_layer</g>" );
push( @messHead, "<g>=====================================</g>\n" );

# Check if there is outline layer, if all other layer (inner, right etc) are in this outline layer
sub CreateScoreLayer {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $messMngr = MessageMngr->new($jobId);

	my $step = "panel";

	my $scoreL = "score";

	unless ( CamHelper->LayerExists( $inCAM, $jobId, $scoreL ) ) {

		return 0;
	}

	my $scoreOptL = "score_layer";

	my $precision = 2;    # number of decimal, used when compering score position etc ()

	my $scoreCheck = ScoreChecker->new( $inCAM, $jobId, $step, $scoreL, 1 );
	my $scoreOptimize = ScoreOptimize->new( $inCAM, $jobId, $scoreCheck );

	# Do check before create score layer
 

	# 2) Parse layer, check if data score data are ok

	$scoreCheck->Init();
 

	my $errMess = "";
	unless ( $scoreCheck->ScoreIsOk( \$errMess ) ) {

		my @mess = (@messHead);
		push( @mess, "Chaba v drážkovací vrstvě: ${scoreL}\n" );
		push( @mess, $errMess );

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );

		return 0;
	}

	 

	# 3) Optimize  and get score data

	$scoreOptimize->Run(1);

	my $optimizeData = $scoreOptimize->GetScoreData();

	# 4) Check result of optimalization

	$scoreOptimize->CreateScoreLayer();

	my $errMess2 = "";
	unless ( $scoreOptimize->ReCheck( \$errMess2 ) ) {

		my @mess = (@messHead);
		push( @mess, "Chaba v drážkovac vrstvě: ${$scoreOptL} při zpětné kontrole\n" );
		push( @mess, $errMess2 );

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );

		return 0;
	}
	
	CamLayer->ClearLayers($inCAM);

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::Scoring::DoScoreLayer';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';

	my $inCAM = InCAM->new();

	my $jobId = "d319756";

	my $notClose = 0;
	if ( CamHelper->LayerExists( $inCAM, $jobId, "score" ) ) {

		my $res = DoScoreLayer->CreateScoreLayer( $inCAM, $jobId );
	}

	

}

1;

