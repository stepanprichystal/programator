
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

	my $defaultInfo  = $dataMngr->GetDefaultInfo();
	my $customerNote = $defaultInfo->GetCustomerNote();

	my $custScoreCoreThick = $customerNote->ScoreCoreThick();

	if ( defined $custScoreCoreThick ) {
		$groupData->SetCoreThick($custScoreCoreThick);
	}
	else {
		$groupData->SetCoreThick(0.3);
	}

	$groupData->SetOptimize( ScoEnums->Optimize_YES );

	my $scoringType = ScoEnums->Type_CLASSIC;

	# If AL or pcbthick is smaller than 600
	if ( $defaultInfo->GetMaterialKind() =~ /al/i || $defaultInfo->GetPcbThick() < 600) {

		$scoringType = ScoEnums->Type_ONEDIR;
	}

	$groupData->SetScoringType($scoringType);

	my $scoreChecker = $defaultInfo->GetScoreChecker();
	my $jump         = 0;
	if ($scoreChecker) {
		$jump = $scoreChecker->CustomerJumpScoring();
	}

	$groupData->SetCustomerJump($jump);

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

	# check if exist score file, and get core thick
	my $path = JobHelper->GetJobArchive($jobId);

	my @scoreFilesJum = FileHelper->GetFilesNameByPattern( $path, ".jum" );
	my @scoreFilesCut = FileHelper->GetFilesNameByPattern( $path, ".cut" ); #old format of score file

	my @scoreFiles = (@scoreFilesJum, @scoreFilesCut);

	my $coreThick = undef;

	if ( scalar(@scoreFiles) > 0 ) {

		my @lines = @{ FileHelper->ReadAsLines( $scoreFiles[0] ) };

		foreach (@lines) {

			if ( $_ =~ /core\s*:\s*(\d+.\d+)/i ) {
				$coreThick = $1;
				last;
			}
		}
	}
	
	if(defined $coreThick && $coreThick > 0){
		
		$groupData->SetCoreThick($coreThick);
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

