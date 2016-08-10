package Programs::Exporter::ExportUtility::Groups::NCExport::NCExportTmp;

#3th party library
use strict;
use warnings;

use PackagesLib;

use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Export::NCExport::ExportMngr';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsMachines';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Export::NCExport::FileHelper::Parser';
use aliased 'Packages::Events::Event';
use aliased 'Programs::Exporter::ExportUtility::Groups::NCExport::NCGroup';
 use aliased 'Programs::Exporter::ExportChecker::Groups::NCExport::Model::NCGroupData';
use aliased 'Programs::Exporter::ExportChecker::Groups::NCExport::Presenter::NCUnit';

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

	my $exportAll  = shift;
	my $pltLayers  = shift;
	my $npltLayers = shift;

	my $stepName = "panel";

	#GET INPUT NIF INFORMATION

	my $groupData = NCGroupData->new();
	$groupData->SetExportAll($exportAll);
	$groupData->SetPltLayers($pltLayers);
	$groupData->SetNPltLayers($npltLayers);

	my $unit = NCUnit->new($jobId);
	
	$unit->InitDataMngr($inCAM, $groupData);
	
	my $resultMngr = -1;
	my $succ = $unit->CheckBeforeExport( $inCAM, \$resultMngr );

	# Check export data for errors
	unless ( $succ) {

		my @errors   = $resultMngr->GetErrors();
		my @warnings = $resultMngr->GetWarnings();

		#my @fail = $nifPreGroup->GetFailResults();
		my @fail = (@errors, @warnings);

		my $messMngr = MessageMngr->new($jobId);

		foreach my $resItem (@fail) {

			my @mess1 = ( $resItem->GetErrorStr() );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess1 );
		}

		return 0;
	}

	my %exportData = $unit->GetExportData($inCAM);

	my $group = NCGroup->new( $inCAM, $jobId );
	$group->SetData( \%exportData );
	my $itemsCnt = $group->GetItemsCount();

	#my $builder = $group->GetResultBuilder();
	$group->{"onItemResult"}->Add( sub { Test(@_) } );

	# run export
	$group->Run();
	
	print "\n========================== E X P O R T: ".$group->GetGroupId()." ===============================\n";
	print $resultMess;
	print "\n========================== E X P O R T: ".$group->GetGroupId()." - F I N I S H: ".( $succes ? "SUCCES" : "FAILURE" )." ===============================\n";

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

		my @mess1 = ( "== EXPORT FAILURE === GROUP:  ".$group->GetGroupId()."\n".$resultMess);
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

	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Programs::Exporter::ExportUtility::Groups::NCExport::NCExportTmp';

	#input parameters
	my $jobId = "f13610";

	my $exportSingle = 0;
	my @pltLayers    = ();
	my @npltLayers   = ();

	my $inCAM  = InCAM->new();
	my $export = NCExportTmp->new();

	#return 1 if OK, else 0
	$export->Run($inCAM, $jobId, $exportSingle, \@pltLayers, \@npltLayers );

	#	my @pltLayers = CamDrilling->GetPltNCLayers( $inCAM, $jobId );
	#	my @pltLayers1 = ();
	#	foreach (@pltLayers) {
	#		push( @pltLayers1, $_->{"name"} );
	#	}
	#
	#	my @npltLayers = CamDrilling->GetNPltNCLayers( $inCAM, $jobId );
	#	my @npltLayers1 = ();
	#	foreach (@npltLayers) {
	#		push( @npltLayers1, $_->{"name"} );
	#	}

}

1;

