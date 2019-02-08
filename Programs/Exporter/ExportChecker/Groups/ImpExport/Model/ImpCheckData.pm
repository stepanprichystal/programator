
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for:
# - Checking group data before final export. Handler: OnCheckGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::ImpExport::Model::ImpCheckData;

#3th party library
use utf8;
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

	my $inCAM    = $dataMngr->{"inCAM"};
	my $jobId    = $dataMngr->{"jobId"};
	my $stepName = "panel";

	my $groupData = $dataMngr->GetGroupData();

	my $defaultInfo = $dataMngr->GetDefaultInfo();

	# If export is not checked, check if
	if ( !$groupData->GetBuildMLStackup() ) {

		$dataMngr->_AddErrorResult( "MultiCal stackup",
						"MultiCal stackup by měl být vždy vygenerován z InStack stackupu, aby bylo do IS načteno aktuální InStack složení." );
	}

	# Error when measurement pdf is not checked
	if ( !$groupData->GetExportMeasurePdf() ) {

		$dataMngr->_AddErrorResult( "Measurement PDF", "Kontrolní PDF soubor pro měření impedancí by měl být vždy pro výrobu vyexportován." );
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

