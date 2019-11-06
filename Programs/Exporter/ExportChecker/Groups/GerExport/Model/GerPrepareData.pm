
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for prepare:
# - default "dataset" (groupData) for displaying them in GUI. Handler: OnPrepareGroupData
# - decide, if group will be active in GUI. Handler: OnIsGroupAllowed
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::GerExport::Model::GerPrepareData;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::GerExport::Model::GerGroupData';
use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'CamHelpers::CamHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Gerbers::Mdi::ExportFiles::Helper' => 'MdiHelper';

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

	# 1) Prepare default layer settings
	my @baseLayers = $defaultInfo->GetBoardBaseLayers();
	$defaultInfo->SetDefaultLayersSettings( \@baseLayers );
	my @layers = $self->__GetFinalLayers( \@baseLayers, $defaultInfo );

	$groupData->SetLayers( \@layers );

	if ( scalar(@layers) ) {
		$groupData->SetExportLayers(1);
	}
	else {
		$groupData->SetExportLayers(0);
	}

	# 2) Prepare MDI settings
	my %mdiInfo = $self->__GetMDIInfo( $inCAM, $jobId );
	$groupData->SetMdiInfo( \%mdiInfo );

	# 3) Prepare paste settings
	my %pasteInfo = $self->__GetPasteInfo( $inCAM, $jobId, $defaultInfo );

	$groupData->SetPasteInfo( \%pasteInfo );

	# 4) Prepare jetprint settings

	my %jetInfo = $self->__GetJetprintInfo( $jobId, $defaultInfo );

	$groupData->SetJetprintInfo( \%jetInfo );

	return $groupData;
}

sub __GetFinalLayers {
	my $self        = shift;
	my @layers      = @{ shift(@_) };
	my $defaultInfo = shift;

	my @prepared = ();

	foreach my $l (@layers) {

		my %lInfo = ();

		$lInfo{"plot"}        = 1;
		$lInfo{"name"}        = $l->{"gROWname"};
		$lInfo{"polarity"}    = $l->{"polarity"};
		$lInfo{"mirror"}      = $l->{"mirror"};
		$lInfo{"comp"}        = $l->{"comp"};

		push( @prepared, \%lInfo );
	}

	# remove/not plot layer "c" if no copper pcb
	if ( $defaultInfo->GetTypeOfPcb() eq "Neplatovany" ) {

		foreach (@prepared) {

			if ( $_->{"name"} eq "c" ) {
				$_->{"plot"} = 0;
				last;
			}
		}
	}

	return @prepared;

}

sub __GetPasteInfo {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $defaultInfo = shift;
	my %pasteInfo   = ();

	my $customerNote = $defaultInfo->GetCustomerNote();

	#my @layers = CamJob->GetSignalLayerNames( $inCAM, $jobId );

	my $sa_ori      = $defaultInfo->LayerExist("sa-ori");
	my $sb_ori      = $defaultInfo->LayerExist("sb-ori");
	my $sa_made     = $defaultInfo->LayerExist("sa-made");
	my $sb_made     = $defaultInfo->LayerExist("sb-made");
	my $mpanelExist = $defaultInfo->StepExist("mpanel");

	#my @layers     = ();
	my $pasteExist = 1;

	if ( $sa_ori || $sb_ori ) {

		$pasteInfo{"notOriginal"} = 0;
		$pasteExist = 1;

	}
	elsif ( $sa_made || $sb_made ) {

		$pasteInfo{"notOriginal"} = 1;
		$pasteExist = 1;

	}
	else {

		$pasteInfo{"notOriginal"} = 0;
		$pasteExist = 0;
	}

	if ($mpanelExist) {
		$pasteInfo{"step"} = "mpanel";
	}
	else {
		$pasteInfo{"step"} = "o+1";
	}

	# default if export paste
	if ( $pasteExist && !$defaultInfo->IsPool() ) {

		$pasteInfo{"export"} = 1;

	}
	else {
		$pasteInfo{"export"} = 0;
	}

	# default is not add profile
	if ( defined $customerNote->ProfileToPaste() ) {
		$pasteInfo{"addProfile"} = $customerNote->ProfileToPaste();

	}
	else {

		$pasteInfo{"addProfile"} = 0;
	}

	# default is don't add single profile
	if ( $mpanelExist && defined $customerNote->ProfileToPaste() ) {
		$pasteInfo{"addSingleProfile"} = $customerNote->SingleProfileToPaste();

	}
	else {

		$pasteInfo{"addSingleProfile"} = 0;
	}

	# default is don't add fiducials to paste
	if ( $mpanelExist && defined $customerNote->FiducialToPaste() ) {
		$pasteInfo{"addFiducial"} = $customerNote->FiducialToPaste();

	}
	else {

		$pasteInfo{"addFiducial"} = 0;
	}

	$pasteInfo{"zipFile"} = 1;

	return %pasteInfo;

}

sub __GetMDIInfo {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my %mdiTypes = MdiHelper->GetDefaultLayerTypes( $inCAM, $jobId );

	my %mdi = ();
	$mdi{"exportSignal"} = $mdiTypes{"typeSignal"};
	$mdi{"exportMask"}   = $mdiTypes{"typeMask"};
	$mdi{"exportPlugs"}  = $mdiTypes{"typePlug"};
	$mdi{"exportGold"}   = $mdiTypes{"typeGold"};

	return %mdi;
}

#sub __GetMDIInfo {
#	my $self        = shift;
#	my $jobId       = shift;
#	my $defaultInfo = shift;
#
#	my %mdiInfo = ();
#
#	my $signal = $defaultInfo->LayerExist("c");
#
#	if ( HegMethods->GetTypeOfPcb($jobId) eq "Neplatovany" ) {
#		$signal = 0;
#	}
#
#	$mdiInfo{"exportSignal"} = $signal;
#
#	if ( ( $defaultInfo->LayerExist("mc") || $defaultInfo->LayerExist("ms") ) && $defaultInfo->GetPcbClass() >= 3 ) {
#		$mdiInfo{"exportMask"} = 1;
#	}
#	else {
#		$mdiInfo{"exportMask"} = 0;
#	}
#
#	$mdiInfo{"exportPlugs"} = ( $defaultInfo->LayerExist("plgc") || $defaultInfo->LayerExist("plgs") ) ? 1 : 0;
#
#	$mdiInfo{"exportGold"} = ( $defaultInfo->LayerExist("goldc") || $defaultInfo->LayerExist("golds") ) ? 1 : 0;
#
#
#	return %mdiInfo;
#
#}

sub __GetJetprintInfo {
	my $self = shift;

	my $jobId       = shift;
	my $defaultInfo = shift;

	my %jetInfo = ();

	if ( $defaultInfo->LayerExist("pc") || $defaultInfo->LayerExist("ps") ) {

		$jetInfo{"exportGerbers"} = 1;
	}
	else {
		$jetInfo{"exportGerbers"} = 0;
	}

	$jetInfo{"fiduc3p2"} = 0;

	return %jetInfo;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

