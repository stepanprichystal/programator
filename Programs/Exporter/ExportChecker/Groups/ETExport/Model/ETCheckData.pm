
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for:
# - Checking group data before final export. Handler: OnCheckGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::ETExport::Model::ETCheckData;

#3th party library
use utf8;
use strict;
use warnings;
use File::Copy;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'Packages::ETesting::BasicHelper::Helper' => 'ETHelper';
use aliased 'Packages::CAM::Netlist::NetlistCompare';

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

	my $defaultInfo = $dataMngr->GetDefaultInfo();
	my $groupData   = $dataMngr->GetGroupData();

	# 1) check attribute .n_electric (it can appear in odb data)

	my @steps = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueDeepestSR( $inCAM, $jobId );

	my @l = CamJob->GetSignalLayerNames( $inCAM, $jobId );

	my $impPresent = 0;
	foreach my $step (@steps) {

		foreach my $l (@l) {
			my %attHist = CamHistogram->GetAttHistogram( $inCAM, $jobId, $step, $l, 1 );

			if ( $attHist{".n_electric"} ) {

				$dataMngr->_AddWarningResult(
											  "Attribute",
											  "Ve stepu: $step, vrstvě: \"$l\" některé features obsahují atribut \".n_electric\"."
												. "Plošky s tímto atributem se nebudou elektricky testovat a tester je vyhodnotí jako nevodivé, je to ok?"
				);
				next;
			}
		}
	}

	# 2) If use custom et step, check if step is not empty
	if ( $groupData->GetCreateEtStep() == 0 ) {

		my $s = $groupData->GetStepToTest();
		if ( !defined $s || $s eq "" ) {

			$dataMngr->_AddErrorResult( "Empty step",
									 "Není vybrán žádný step ze kterého se vytvoří IPC soubor. Step musí mít název \"et_<jmeno stepu>\"" );
		}
	}


	# 3) Check place of storeing IPC file
	if ( $groupData->GetLocalCopy() == 0 && $groupData->GetServerCopy() == 0 ) {

		$dataMngr->_AddErrorResult( "IPC file placement", "Není vybráno umístění, kam se má IPC soubor zkopírovat (Server copy; Local copy)" );

	}

	# 4) Check if keep rpofile is possible
	if ( $groupData->GetKeepProfiles() && !ETHelper->KeepProfilesAllowed( $inCAM, $jobId, $groupData->GetStepToTest() ) ) {

		$dataMngr->_AddErrorResult( "Keep profiles",
									"Pro ET step: " . $groupData->GetStepToTest() . " není možné ponechat SR profily desek v IPC souboru." );
	}

	# 5) Check if coverlay on outer signal layers are properly prepared (are not empty)
	my @cvrl = grep { $_->{"gROWname"} =~ /^coverlay[cs]$/ } $defaultInfo->GetBoardBaseLayers();
	if ( scalar(@cvrl) ) {
		
		my @steps = CamStepRepeatPnl->GetUniqueDeepestSR( $inCAM, $jobId );

		foreach my $l (@cvrl) {

			foreach my $s (@steps) {

				my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $s->{"stepName"}, $l->{"gROWname"} );
				
				if ( $hist{"total"} == 0 ) {

					$dataMngr->_AddErrorResult(
						"Empty coverlay layers",
						"Vrstva: "
						  . $l->{"gROWname"}
						  . "; ve stepu: "
						  . $s->{"stepName"}
						  . " nesmí být prázdná kvůli správnému vytvoření elektrického testu."
					);
				}
			}
		}
	}
	
	# 15) Check if all netlist control was succes in past
	my @reports = NetlistCompare->new( $inCAM, $jobId )->GetStoredReports();

	@reports = grep { !$_->Result() } @reports;

	if ( scalar(@reports) ) {

		my $m = "Byly nalezeny Netlist reporty, které skončily neúspěšně. Zjisti proč, popř. proveď novou kontrolu netlistů. Reporty:";

		foreach my $r (@reports) {

			$m .=
			    "\n- report: "
			  . $r->GetShorts()
			  . " shorts, "
			  . $r->GetBrokens()
			  . " brokens, "
			  . "Stepy: \""
			  . $r->GetStep()
			  . "\", \""
			  . $r->GetStepRef()
			  . "\", Adresa: "
			  . $r->GetReportPath();
		}

		$dataMngr->_AddErrorResult( "Netlist kontrola", $m );
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

