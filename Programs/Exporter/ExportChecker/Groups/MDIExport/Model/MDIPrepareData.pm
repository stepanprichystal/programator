
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for prepare:
# - default "dataset" (groupData) for displaying them in GUI. Handler: OnPrepareGroupData
# - decide, if group will be active in GUI. Handler: OnIsGroupAllowed
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::MDIExport::Model::MDIPrepareData;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::MDIExport::Model::MDIGroupData';
use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Gerbers::Mditt::ExportFiles::Helper' => 'MDITTHelper';

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

	my $defaultInfo = $dataMngr->GetDefaultInfo();

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my $state = Enums->GroupState_ACTIVEON;

	return $state;
}

# Default "group data" are prepared in this method
sub OnPrepareGroupData {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	my $groupData = MDIGroupData->new();

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my $defaultInfo = $dataMngr->GetDefaultInfo();

	# 1) Get all possible laye couples

	my @allCouplesInfo = $self->__GetAllCouplesInfo($inCAM, $jobId);
	$groupData->SetLayerCouples( \@allCouplesInfo );

	# 2) Set default layer settings
	my %layerSett = $self->__GetAllLayerSett($inCAM, $jobId,  \@allCouplesInfo, $defaultInfo );
	$groupData->SetLayersSettings( \%layerSett );

	return $groupData;
}

sub __GetAllCouplesInfo {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my @allCouples = MDITTHelper->GetDefaultLayerCouples( $inCAM, $jobId );

	# create structure where is stored if export couple or not (default export all)

	my @allCouplesInfo = ();

	foreach my $couple (@allCouples) {

		my %inf = ( "couple" => $couple, "export" => 1 );
		push( @allCouplesInfo, \%inf );
	}

	return @allCouplesInfo;

}

sub __GetAllLayerSett {
	my $self           = shift;
	my $inCAM          = shift;
	my $jobId          = shift;
	my $allCouplesInfo = shift;
	my $defaultInfo    = shift;

	my %layersSett = ();

	foreach my $coupleInf ( @{$allCouplesInfo} ) {

		foreach my $layer ( @{ $coupleInf->{"couple"} } ) {

			my %sett = MDITTHelper->GetDefaultLayerSett( $inCAM, $jobId, $defaultInfo->GetStep(), $layer );

			$layersSett{$layer} = \%sett;

		}

	}

	return %layersSett;
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

