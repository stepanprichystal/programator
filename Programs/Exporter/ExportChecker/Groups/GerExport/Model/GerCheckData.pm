
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for:
# - Checking group data before final export. Handler: OnCheckGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::GerExport::Model::GerCheckData;

#3th party library
use strict;
use warnings;
use File::Copy;

#local library
use aliased 'CamHelpers::CamLayer';
use aliased 'Connectors::HeliosConnector::HegMethods';
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

sub OnCheckGroupData {
	my $self     = shift;
	my $dataMngr = shift;

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my $groupData   = $dataMngr->GetGroupData();
	my $defaultInfo = $dataMngr->GetDefaultInfo();

	# 1) Check when export is checked, if paste layers exist

	my $pasteInfo = $groupData->GetPasteInfo();

	if ( $pasteInfo->{"export"} && !$self->__PasteLayersExist($defaultInfo) ) {

		$dataMngr->_AddErrorResult( "Paste data", "Nelze exportovat data na pastu. Vrstvy sa_ori, sb_ori ani sa_made, sb_made neexistují.\n" );
	}

}

sub __PasteLayersExist {
	my $self        = shift;
	my $defaultInfo = shift;

	#my @layers = CamJob->GetSignalLayerNames( $inCAM, $jobId );

	my $sa_ori  = $defaultInfo->LayerExist("sa_ori");
	my $sb_ori  = $defaultInfo->LayerExist("sb_ori");
	my $sa_made = $defaultInfo->LayerExist("sa_made");
	my $sb_made = $defaultInfo->LayerExist("sb_made");

	if ( !$sa_ori && !$sb_ori && !$sa_made && !$sb_made ) {

		return 0;
	}
	else {

		return 1;
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

