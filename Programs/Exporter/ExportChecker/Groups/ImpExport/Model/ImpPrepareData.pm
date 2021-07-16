
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for prepare:
# - default "dataset" (groupData) for displaying them in GUI. Handler: OnPrepareGroupData
# - decide, if group will be active in GUI. Handler: OnIsGroupAllowed
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::ImpExport::Model::ImpPrepareData;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::ImpExport::Model::ImpGroupData';
use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Enums::EnumsGeneral';

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

	my $state = Enums->GroupState_DISABLE;

	# Active only ifexist impedance steps
	my @step = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $defaultInfo->GetStep() );

	# Impedance coupon default settings
	my $impCpnBaseName = EnumsGeneral->Coupon_IMPEDANCE;
	my @impSteps = grep { $_ =~ /$impCpnBaseName/i } map { $_->{"stepName"} } @step;

	if ( scalar(@impSteps) ) {

		$state = Enums->GroupState_ACTIVEON;

	}

	return $state;
}

# Default "group data" are prepared in this method
sub OnPrepareGroupData {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	my $groupData = ImpGroupData->new();

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my $defaultInfo = $dataMngr->GetDefaultInfo();

	$groupData->SetExportMeasurePdf(1);

	if ( $defaultInfo->GetLayerCnt() > 2 ) {
		$groupData->SetBuildMLStackup(1);
	}
	else {
		$groupData->SetBuildMLStackup(0);
	}

	return $groupData;
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

