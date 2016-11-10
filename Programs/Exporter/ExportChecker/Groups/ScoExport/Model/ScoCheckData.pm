
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for:
# - Checking group data before final export. Handler: OnCheckGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::ScoExport::Model::ScoCheckData;

#3th party library
use strict;
use warnings;
use File::Copy;

#local library
#use aliased 'CamHelpers::CamLayer';
#use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::Export::ScoExport::Enums' => "ScoEnums";

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

	my $defaultInfo = $dataMngr->GetDefaultInfo();

	# Check of coe thick

	my $thick = $groupData->GetCoreThick();

	$thick = sprintf( "%2.2f", $thick );

	if ( !defined $thick || $thick <= 0 || $thick > 3 ) {

		$dataMngr->_AddErrorResult( "Tlouška zùstatku", "Tlouška zùstatku dps po drážkování je nulová nebo není definovaná." );
	}

	my $opt = $groupData->GetOptimize();

	# if manual, check if layer score_layer exist
	if ( $opt eq ScoEnums->Optimize_MANUAL ) {

		my $scoExist = CamHelper->LayerExists( $inCAM, $jobId, "score_layer" );

		unless ($scoExist) {

			my $m = "Pokud je zvolena oprimalizace manual, musí existovat vrstva 'score_layer', podle které se drážka vyexportuje.";

			$dataMngr->_AddErrorResult( "Optimalizace manual", $m );
		}
	}

	# if score is ok

	my $scoreChecker = $defaultInfo->GetScoreChecker();
	my $errMess      = "";
	unless ( $scoreChecker->ScoreIsOk( \$errMess ) ) {

		$dataMngr->_AddErrorResult( "Score data", $errMess );
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

