package Programs::Exporter::ExportUtility::Groups::NifExport::NifExportTmp;

#3th party library
use strict;
use warnings;
use Wx;
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';

use aliased 'CamHelpers::CamDrilling';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Enums::EnumsMachines';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Events::Event';
use aliased 'Connectors::HeliosConnector::HegMethods';

#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifDataMngr';
#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::NifPreGroup';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifGroupData';
use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifGroup';

use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifUnit';
use aliased 'Managers::MessageMngr::MessageMngr';

#-------------------------------------------------------------------------------------------#
#  NC export, all layers, all machines..
#-------------------------------------------------------------------------------------------#

my $resultMess = "";
my $succes     = 1;

sub new {

	my $self = shift;
	$self = {};
	bless $self;
	return $self;
}

sub Run {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $poznamka  = shift;
	my $tenting   = shift;
	my $pressfit  = shift;
	my $maska01   = shift;
	my $datacode  = shift;
	my $ulLogo    = shift;
	my $jumpScore = shift;

	my $stepName = "panel";

	#GET INPUT NIF INFORMATION

	my $groupData = NifGroupData->new();
	$groupData->SetNotes($poznamka);
	$groupData->SetTenting($tenting);
	$groupData->SetPressfit($pressfit);
	$groupData->SetMaska01($maska01);
	$groupData->SetDatacode($datacode);
	$groupData->SetUlLogo($ulLogo);
	$groupData->SetJumpScoring($jumpScore);

	#my $nifPreGroup = NifDataMngr->new( $inCAM, $jobId );
	#$nifPreGroup->SetStoredGroupData($groupData);

	my $unit = NifUnit->new($jobId);

	$unit->InitDataMngr( $inCAM, $groupData );

	my $resultMngr = -1;
	my $succ = $unit->CheckBeforeExport( $inCAM, \$resultMngr );

	# Check export data for errors
	unless ($succ) {

		#unless ( $nifPreGroup->CheckGroupData() ) {

		#my @errors   = $resultMngr->GetErrors();
		#my @warnings = $resultMngr->GetWarnings();

		#my @fail = $nifPreGroup->GetFailResults();
		my @fail = $resultMngr->GetFailResults();

		my $messMngr = MessageMngr->new($jobId);

		foreach my $resItem (@fail) {

			my @mess1 = ( $resItem->GetErrorStr() );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess1 );
		}

		return 0;
	}

	my %inputPar = $unit->GetExportData($inCAM);

	my %exportData = ();

	foreach my $key ( keys %inputPar ) {
		my $value = $inputPar{$key};
		$exportData{"nifdata"}{$key} = $value;
	}

	my $group = NifGroup->new( $inCAM, $jobId );
	$group->SetData( \%exportData );
	my $itemsCnt = $group->GetItemsCount();

	#my $builder = $group->GetResultBuilder();
	$group->{"onItemResult"}->Add( sub { Test(@_) } );

	$group->Run();

	print "\n========================== E X P O R T: " . $group->GetGroupId() . " ===============================\n";
	print $resultMess;
	print "\n========================== E X P O R T: "
	  . $group->GetGroupId()
	  . " - F I N I S H: "
	  . ( $succes ? "SUCCES" : "FAILURE" )
	  . " ===============================\n";

	sub Test {
		my $itemResult = shift;

		if ( $itemResult->Result() eq "failure" ) {
			$succes = 0;
		}

		$resultMess .= " \n=============== Export task result: ==============\n";
		$resultMess .= "Task: " . $itemResult->ItemId() . "\n";
		$resultMess .= "Task result: " . $itemResult->Result() . "\n";
		$resultMess .= "Task errors: \n" . $itemResult->GetErrorStr() . "\n";
		$resultMess .= "Task warnings: \n" . $itemResult->GetWarningStr() . "\n";

	}

	unless ($succes) {
		my $messMngr = MessageMngr->new($jobId);

		my @mess1 = ( "== EXPORT FAILURE === GROUP:  " . $group->GetGroupId() . "\n" . $resultMess );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess1 );
	}

	return $succes;

}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifExportTmp';
	my $checkOk  = 1;
	my $jobId    = "f13610";
	my $stepName = "panel";
	my $inCAM    = InCAM->new();

	#GET INPUT NIF INFORMATION

	my $nifPreGroup = NifPreGroup->new( $inCAM, $jobId );

	my $tenting  = 1;
	my $pressfit = 0;
	my $maska01  = 0;

	my $prepareOk = 1;
	my %exportData = $nifPreGroup->__GetExportData( \$prepareOk, $tenting, $pressfit, $maska01 );

	# Vytvoøení nifu, pokud vstupní parametry jsou OK
	if ($prepareOk) {

		my $export = NifExportTmp->new();
		$export->Run( $inCAM, $jobId, $stepName, \%exportData );

	}

}

1;

