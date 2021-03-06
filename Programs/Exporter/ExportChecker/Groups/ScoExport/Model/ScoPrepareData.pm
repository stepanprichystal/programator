
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for prepare:
# - default "dataset" (groupData) for displaying them in GUI. Handler: OnPrepareGroupData
# - decide, if group will be active in GUI. Handler: OnIsGroupAllowed
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::ScoExport::Model::ScoPrepareData;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::ScoExport::Model::ScoGroupData';
use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'Packages::Export::ScoExport::Enums' => "ScoEnums";
use aliased 'CamHelpers::CamHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Packages::TifFile::TifScore';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;    # Return the reference to the hash.
}

# This method decide, if group will be "active" or "passive"
# If active, decide if group will be switched ON/OFF
# Return enum: Enums->GroupState_xxx
sub OnGetGroupState {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my $scoExist = CamHelper->LayerExists( $inCAM, $jobId, "score" );

	if ($scoExist) {
		return Enums->GroupState_ACTIVEON;
	}
	else {

		return Enums->GroupState_DISABLE;
	}

}

# Default "group data" are prepared in this method
sub OnPrepareGroupData {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	my $groupData = ScoGroupData->new();

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my $defaultInfo        = $dataMngr->GetDefaultInfo();
	my $customerNote       = $defaultInfo->GetCustomerNote();
	my $custScoreCoreThick = $customerNote->ScoreCoreThick();
	my $tifSco             = TifScore->new($jobId);

	# 1 ) Score thickness

	if ( defined $tifSco->GetScoreThick() ) {

		$groupData->SetCoreThick( $tifSco->GetScoreThick() );
	}
	elsif ( defined $custScoreCoreThick ) {

		$groupData->SetCoreThick($custScoreCoreThick);

	}
	else {
		$groupData->SetCoreThick(0.3);           # default material rest is 0.3mm
	}

	
	# 2) scoring mode

	my $scoringType = ScoEnums->Type_CLASSIC;

	# If AL or pcbthick is smaller than 600
	if ( $defaultInfo->GetMaterialKind() =~ /al/i || $defaultInfo->GetPcbThick() < 600 ) {

		$scoringType = ScoEnums->Type_ONEDIR;
	}

	$groupData->SetScoringType($scoringType);


	# 3) Customer jumpscoring
	 
	my $scoreChecker = $defaultInfo->GetScoreChecker();
	my $jumpscoring         = 0;
	if ($scoreChecker) {
		$jumpscoring = $scoreChecker->CustomerJumpScoring();
	}
	$groupData->SetCustomerJump($jumpscoring);
	
	
	# 4) Score optimization
	
	if($jumpscoring){
		$groupData->SetOptimize( ScoEnums->Optimize_NO );
		
	}else{
		
		$groupData->SetOptimize( ScoEnums->Optimize_YES );
	}

	return $groupData;
}

# Default "group data" for REORDER are prepared in this method
sub OnPrepareReorderGroupData {
	my $self      = shift;
	my $dataMngr  = shift;    #instance of GroupDataMngr
	my $groupData = shift;    # default group data

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my $defaultInfo = $dataMngr->GetDefaultInfo();
	my $tifSco             = TifScore->new($jobId);
	
	# Load optimiyation from former export settings
		
	if ( defined $tifSco->GetScoreOptimize() ) {
		$groupData->SetOptimize( $tifSco->GetScoreOptimize() );
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

