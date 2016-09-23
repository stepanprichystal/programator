package Programs::Exporter::ExportUtility::Groups::ETExport::ETExportTmp;

#3th party library
use strict;
use warnings;

use aliased 'Enums::EnumsGeneral';

#use aliased 'Programs::Exporter::ExportChecker::Groups::ETExport::Model::ETDataMngr';
use aliased 'Programs::Exporter::ExportChecker::Groups::NCExport::Model::NCGroupData';
use aliased 'Programs::Exporter::ExportChecker::Groups::ETExport::Presenter::ETUnit';
use aliased 'Managers::MessageMngr::MessageMngr';

use aliased 'Programs::Exporter::ExportUtility::Groups::ETExport::ETExport';
use aliased 'Programs::Exporter::DataTransfer::UnitsDataContracts::ETData';
use aliased 'Programs::Exporter::UnitEnums';

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
	my $stepToTest = shift;


	#GET INPUT NIF INFORMATION

	my $exportData = ETData->new();

$exportData->SetStepToTest($stepToTest);
 my $export = ETExport->new( UnitEnums->UnitId_ET );
$export->Init( $inCAM, $jobId, $exportData );

$export->{"onItemResult"}->Add( sub { Test(@_) } );

$export->Run();

	print "\n========================== E X P O R T: " . UnitEnums->UnitId_ET . " ===============================\n";
	print $resultMess;
	print "\n========================== E X P O R T: "
	  . UnitEnums->UnitId_ET
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
		my @mess1 = ( "== EXPORT FAILURE === GROUP:  ".UnitEnums->UnitId_ET."\n".$resultMess);
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

	use aliased 'Programs::Exporter::ExportUtility::Groups::ETExport::ETExportTmp';

	my $jobId    = "f13610";
	my $stepName = "panel";
	my $inCAM    = InCAM->new();

	#GET INPUT NIF INFORMATION
	my $stepToTest = "panel";

}

1;

