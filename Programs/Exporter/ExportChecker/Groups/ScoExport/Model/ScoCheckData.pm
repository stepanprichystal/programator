
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for:
# - Checking group data before final export. Handler: OnCheckGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::ScoExport::Model::ScoCheckData;

#3th party library
use utf8;
use strict;
use warnings;
use File::Copy;
use List::MoreUtils qw(uniq);

#local library
#use aliased 'CamHelpers::CamLayer';
#use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';

use aliased 'Packages::Export::ScoExport::Enums' => "ScoEnums";
use aliased 'Packages::Polygon::Features::ScoreFeatures::ScoreFeatures';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;    # Return the reference to the hash.
}

sub OnCheckGroupData {
	my $self     = shift;
	my $dataMngr = shift;

	my $inCAM     = $dataMngr->{"inCAM"};
	my $jobId     = $dataMngr->{"jobId"};
	my $groupData = $dataMngr->GetGroupData();

	my $defaultInfo  = $dataMngr->GetDefaultInfo();
	my $customerNote = $defaultInfo->GetCustomerNote();

	# 1) Check of core thick

	my $thick = $groupData->GetCoreThick();

	$thick = sprintf( "%2.2f", $thick );

	if ( !defined $thick || $thick <= 0 || $thick > 3 ) {

		$dataMngr->_AddErrorResult( "Tloušťka zůstatku", "Tloušťka zůstatku dps po drážkování je nulová nebo není definovaná." );
	}

	# Check if core thick match with customer request
	my $custScoreCoreThick = $customerNote->ScoreCoreThick();

	if ( defined $custScoreCoreThick && $custScoreCoreThick != $thick ) {

		$dataMngr->_AddErrorResult( "Tloušťka zůstatku",
			   "Tloušťka zůstatku dps po drážkování (" . $thick . "mm) neodpovídá požadavku zákazníka (" . $custScoreCoreThick . "mm)." );
	}

	# Check small rest of material after scoring
	my $minScoreDepth = 100;                                                      # 100µm minimal score depth fro mone side
	my $scoringDepth = ( ( $defaultInfo->GetPcbThick() - $thick * 1000 ) / 2 );
	if ( ( ( $defaultInfo->GetPcbThick() - $thick * 1000 ) / 2 ) <= $minScoreDepth ) {

		$dataMngr->_AddWarningResult(
									  "Malá hloubka drážkování",
									  "Hloubka drážkování z každé strany bude: "
										. $scoringDepth
										. "µm. (tloušťka DPS: "
										. $defaultInfo->GetPcbThick()
										. "µm). Zmenši zůstatek materiálu po drážkování."
		);
	}

	my $opt = $groupData->GetOptimize();

	# 2) if manual, check if layer score_layer exist
	if ( $opt eq ScoEnums->Optimize_MANUAL ) {

		my $scoExist = CamHelper->LayerExists( $inCAM, $jobId, "score_layer" );

		unless ($scoExist) {

			my $m = "Pokud je zvolena oprimalizace manual, musí existovat vrstva 'score_layer', podle které se drážka vyexportuje.";

			$dataMngr->_AddErrorResult( "Optimalizace manual", $m );
		}
	}

	# 3) if score is ok

	my $scoreChecker = $defaultInfo->GetScoreChecker();
	my $errMess      = "";
	unless ( $scoreChecker->ScoreIsOk( \$errMess ) ) {

		$dataMngr->_AddErrorResult( "Score data", $errMess );
	}

	# 4) check if mpanel exist, if some nested steps in panel contain score

	if ( $defaultInfo->LayerExist("score") && $defaultInfo->StepExist("mpanel") ) {

		my @sr = CamStepRepeat->GetStepAndRepeat( $inCAM, $jobId, "mpanel" );

		# Check if any step and repeat contain score
		my $scoreExist = 0;
		my @scoreSteps = ();

		foreach my $srStep (@sr) {

			my $name = $srStep->{"gSRstep"};

			if ( $self->__ScoreExist( $inCAM, $jobId, $name ) ) {
				push( @scoreSteps, $name );
			}
		}

		if ( scalar(@scoreSteps) ) {
			my $strSteps = join( ", ", uniq(@scoreSteps) );

			$dataMngr->_AddErrorResult(
				"Score data",
"Step 'mpanel' obsahuje stepy ($strSteps), které obsahují drážku. Přesuň tuto drážku do stepu 'mpanel'. Použij script: FlattenScoreScript.pl"
			);
		}

	}

	# 5) If customer jumscoring, optimize must be NO or Manual

	if ( $groupData->GetCustomerJump() && $groupData->GetOptimize() ne ScoEnums->Optimize_NO ) {

		$dataMngr->_AddErrorResult( "Jump-scoring zákazníka",
			   "Pokud má zákazník na DPS vlastní jums-coring, nelze použít omptimalizaci drážky." . " Změň optimalizaci na: Manual nebo No" );
	}

}

# check if in given step score exist
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

	#	use aliased 'Packages::Export::NCExport::NCExportGroup';
	#
	#	my $jobId    = "F13608";
	#	my $stepName = "panel";
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $ncgroup = NCExportGroup->new( $inCAM, $jobId );
	#
	#	$ncgroup->Run();

	#print $test;

}

1;

