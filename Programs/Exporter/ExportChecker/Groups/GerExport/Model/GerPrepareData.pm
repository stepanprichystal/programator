
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for prepare:
# - default "dataset" (groupData) for displaying them in GUI. Handler: OnPrepareGroupData
# - decide, if group will be active in GUI. Handler: OnIsGroupAllowed
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::GerExport::Model::GerPrepareData;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::GerExport::Model::GerGroupData';
use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'CamHelpers::CamHelper';

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

	#we want nif group allow always, so return ACTIVE ON
	return Enums->GroupState_ACTIVEON;

}

# Default "group data" are prepared in this method
sub OnPrepareGroupData {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	my $groupData = GerGroupData->new();

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};
	
	my $defaultInfo = $dataMngr->GetDefaultInfo();

	my @layers =  $self->__GetLayers($defaultInfo);
	my %pasteInfo = $self->__GetPasteInfo($inCAM, $jobId);

	$groupData->SetLayers(\@layers);
	$groupData->SetPasteInfo(\%pasteInfo);
	
	
	return $groupData;
}


sub __GetLayers {
	my $self      = shift;
	my $defaultInfo = shift;
	
	my @baseLayers = $defaultInfo->GetBoardBaseLayers();

	my @layers = ();
	
	foreach my $baseL (@baseLayers){
		
		my %info = ();
		
		$info{"name"} =  $baseL->{"gROWname"};
		$info{"comp"} =  $defaultInfo->GetCompByLayer($baseL->{"gROWname"});
		
		push(@layers, \%info);
	}
	
	return @layers;
}


sub __GetPasteInfo {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my %pasteInfo = ();

	#my @layers = CamJob->GetSignalLayerNames( $inCAM, $jobId );

	my $sa_ori  = CamHelper->LayerExists( $inCAM, $jobId, "sa_ori" );
	my $sb_ori  = CamHelper->LayerExists( $inCAM, $jobId, "sa_ori" );
	my $sa_made = CamHelper->LayerExists( $inCAM, $jobId, "sa_made" );
	my $sb_made = CamHelper->LayerExists( $inCAM, $jobId, "sa_made" );
	my $mpanelExist = CamHelper->StepExists( $inCAM, $jobId, "mapnel" );

	my $pasteExist = 1;

	if ( $sa_ori || $sb_ori ) {

		$pasteInfo{"notOriginal"} = 0;
		$pasteInfo{"export"}      = 1;

	}
	elsif ( $sa_made || $sb_made ) {

		$pasteInfo{"notOriginal"} = 1;
		$pasteInfo{"export"}      = 1;
	}
	else {

		$pasteInfo{"notOriginal"} = 0;
		$pasteInfo{"export"}      = 0;
	}

	if ($mpanelExist) {
		$pasteInfo{"step"} = "mpanel";
	}
	else {
		$pasteInfo{"step"} = "o+1";
	}

	$pasteInfo{"addProfile"} = 0;
	$pasteInfo{"zipFile"}    = 1;

	return %pasteInfo;

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

