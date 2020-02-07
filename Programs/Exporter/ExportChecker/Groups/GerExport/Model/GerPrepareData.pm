
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
use aliased "Packages::Polygon::PolygonFeatures";
use aliased 'Packages::Polygon::Features::Features::Features';

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
	my @layers = ();
	push( @layers, $self->__GetSignalLayersSett($defaultInfo) );
	push( @layers, $self->__GetOtherLayersSett($defaultInfo) );

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

	my %jetInfo = $self->__GetJetprintInfo( $inCAM, $jobId, $defaultInfo );

	$groupData->SetJetprintInfo( \%jetInfo );

	return $groupData;
}

sub __GetSignalLayersSett {
	my $self        = shift;
	my $defaultInfo = shift;

	my @signalLayers = ();
	push( @signalLayers, $defaultInfo->GetSignalLayers() );
	push( @signalLayers, $defaultInfo->GetSignalExtLayers() );

	# if No copper, remove layer C

	@signalLayers = () if ( $defaultInfo->GetPcbType() eq EnumsGeneral->PcbType_NOCOPPER );

	my @prepared = ();

	foreach my $l (@signalLayers) {

		my %lInfo = $defaultInfo->GetDefSignalLSett($l);

		push( @prepared, \%lInfo );
	}

	return @prepared;
}

sub __GetOtherLayersSett {
	my $self        = shift;
	my $defaultInfo = shift;

	my @otherLayer = $defaultInfo->GetBoardBaseLayers();

	@otherLayer =
	  grep { $_->{"gROWlayer_type"} eq "solder_mask" || $_->{"gROWname"} =~ /^(gold)[cs]$/ } @otherLayer;

	my @prepared = ();

	foreach my $l (@otherLayer) {

		my %lInfo = $defaultInfo->GetNonSignalLSett($l);

		push( @prepared, \%lInfo );
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
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $defaultInfo = shift;

	my %jetInfo = ();

	# Export data

	if ( $defaultInfo->LayerExist("pc") || $defaultInfo->LayerExist("ps") ) {

		$jetInfo{"exportGerbers"} = 1;
	}
	else {
		$jetInfo{"exportGerbers"} = 0;
	}

	# Special fiduc

	$jetInfo{"fiduc3p2"} = 0;

	# Rotate data 90° if PCB is too long
	$jetInfo{"rotation"} = 0;
	my %lim = ();

	if ( $defaultInfo->GetLayerCnt() > 2 ) {

		my $route = Features->new();
		$route->Parse( $inCAM, $jobId, "panel", "fr" );
		my @features = $route->GetFeatures();
		%lim = PolygonFeatures->GetLimByRectangle( \@features );

	}
	else {

		%lim = $defaultInfo->GetProfileLimits();
	}

	my $maxJetprintLen = 500;    # 500 mm height panel
	$jetInfo{"rotation"} = 1 if ( ($lim{"yMax"} - $lim{"yMin"} ) > $maxJetprintLen );

	return %jetInfo;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

