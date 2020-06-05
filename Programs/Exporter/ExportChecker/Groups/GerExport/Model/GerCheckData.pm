
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for:
# - Checking group data before final export. Handler: OnCheckGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::GerExport::Model::GerCheckData;

#3th party library
use utf8;
use strict;
use warnings;
use File::Copy;
use List::MoreUtils qw(uniq);

#local library
use aliased 'CamHelpers::CamLayer';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::CAMJob::SilkScreen::SilkScreenCheck';

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

	my $groupData    = $dataMngr->GetGroupData();
	my $defaultInfo  = $dataMngr->GetDefaultInfo();
	my $customerNote = $defaultInfo->GetCustomerNote();

	my $pasteInfo    = $groupData->GetPasteInfo();
	my $jetprintInfo = $groupData->GetJetprintInfo();
	my $mpanelExist  = $defaultInfo->StepExist("mpanel");

	# 1) check if customer request paste files

	if ( defined $customerNote->ExportPaste() && !$defaultInfo->IsPool() ) {

		if ( $pasteInfo->{"export"} != $customerNote->ExportPaste() ) {

			$dataMngr->_AddWarningResult(
										  "Export paste",
										  "Zákazník si "
											. ( $customerNote->ExportPaste() ? "přeje" : "nepřeje" )
											. " exportovat paste files. Zaškrtni volbu 'Export'.\n"
			);
		}
	}

	# 2) Check when export is checked,

	if ( $pasteInfo->{"export"} ) {

		#if paste layers exist
		if ( !$self->__PasteLayersExist($defaultInfo) ) {
			$dataMngr->_AddErrorResult( "Paste data", "Nelze exportovat data na pastu. Vrstvy sa-ori, sb-ori ani sa-made, sb-made neexistují.\n" );
		}

		# check customer request to profile
		if ( defined $customerNote->ProfileToPaste() ) {

			if ( $pasteInfo->{"addProfile"} != $customerNote->ProfileToPaste() ) {
				$dataMngr->_AddErrorResult(
											"Profile to paste",
											"Zákazník si "
											  . ( $customerNote->ProfileToPaste() ? "přeje" : "nepřeje" )
											  . " vkládat profil do šablon pasty. Oprav volbu 'Add profile'.\n"
				);
			}
		}

		# check customer request to single profile
		if ( $mpanelExist && defined $customerNote->SingleProfileToPaste() ) {

			if ( $pasteInfo->{"addSingleProfile"} != $customerNote->SingleProfileToPaste() ) {
				$dataMngr->_AddErrorResult(
											"Single profile to paste",
											"Zákazník si "
											  . ( $customerNote->SingleProfileToPaste() ? "přeje" : "nepřeje" )
											  . " vkládat profil vnitřních stepů do šablon pasty. Oprav volbu 'Add single profile'.\n"
				);
			}
		}

		# check customer request add fiduc
		if ( $mpanelExist && defined $customerNote->FiducialToPaste() ) {

			if ( $pasteInfo->{"addFiducial"} != $customerNote->FiducialToPaste() ) {
				$dataMngr->_AddErrorResult(
											"Fiducials to paste",
											"Zákazník si "
											  . ( $customerNote->FiducialToPaste() ? "přeje" : "nepřeje" )
											  . " vkládat fiduciální značky do šablon pasty. Oprav volbu 'Add fiducials'.\n"
				);
			}
		}

		# If there is option add fiducials, check if there are fiduc in step
		if ( $pasteInfo->{"addFiducial"} ) {

			if ( $defaultInfo->LayerExist("c") ) {
				my %attHist = CamHistogram->GetAttHistogram( $inCAM, $jobId, $pasteInfo->{"step"}, "c", 0 );

				unless ( $attHist{".fiducial_name"} ) {
					$dataMngr->_AddErrorResult(
												"Fiducials to paste",
												"Fiduciální značky chybí ve vrstvě 'c' ve stepu '"
												  . $pasteInfo->{"step"}
												  . "'. Pokud je chceš přidat do šablony, vlož fiduciální značky do vrstvy 'c'. Značky musí mít atribut .fiducial_name.\n"
					);
				}
			}
		}

	}

	# 4) When wound old format of paste file - with underscore, warning
	my $sa_ori  = $defaultInfo->LayerExist("sa_ori");
	my $sb_ori  = $defaultInfo->LayerExist("sb_ori");
	my $sa_made = $defaultInfo->LayerExist("sa_made");
	my $sb_made = $defaultInfo->LayerExist("sb_made");

	if ( $sa_ori || $sb_ori || $sa_made || $sb_made ) {

		my @layers = ();
		push( @layers, "sa_ori" )  if ($sa_ori);
		push( @layers, "sb_ori" )  if ($sb_ori);
		push( @layers, "sa_made" ) if ($sa_made);
		push( @layers, "sb_made" ) if ($sb_made);

		my $str = join( ", ", @layers );

		$dataMngr->_AddWarningResult( "Paste data",
			  "Byl nalezen starý formát názvu pasty s podtržítkem ($str). Pokud chceš pastu vyexportovat použij nový název s pomlčkou.\n" );
	}

	# 5) Check if some layers are not empty
	if ( $pasteInfo->{"export"} && !$defaultInfo->IsPool() ) {

		foreach my $l ( ( "sa-ori", "sb-ori", "sa-made", "sb-made" ) ) {

			if ( $defaultInfo->LayerExist($l) ) {

				my %fHist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $pasteInfo->{"step"}, $l );

				if ( $fHist{"total"} == 0 ) {
					$dataMngr->_AddWarningResult( "Paste data",
												  "Vrstva pasty: \"$l\" je prázdná, zkontroluj, jestli v ní nechybí data, jinak ji smaž.\n" );
				}
			}
		}
	}

	# 6) Jet print, check if featues are no to thin
	if ( $jetprintInfo->{"exportGerbers"} ) {

		my $mess = "";
		unless ( SilkScreenCheck->FeatsWidthOkAllLayers( $inCAM, $jobId, "panel", \$mess ) ) {

			$dataMngr->_AddErrorResult( "Jetprint data", $mess );
		}
	}
 
}

sub __PasteLayersExist {
	my $self        = shift;
	my $defaultInfo = shift;

	#my @layers = CamJob->GetSignalLayerNames( $inCAM, $jobId );
	my $sa_ori  = $defaultInfo->LayerExist("sa-ori");
	my $sb_ori  = $defaultInfo->LayerExist("sb-ori");
	my $sa_made = $defaultInfo->LayerExist("sa-made");
	my $sb_made = $defaultInfo->LayerExist("sb-made");

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

