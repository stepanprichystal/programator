package Programs::Exporter::ExportPool::Groups::AOIExport::AOIExportTmp;

#3th party library
use strict;
use warnings;

use aliased 'Enums::EnumsGeneral';

use aliased 'Programs::Exporter::ExportPool::Groups::AOIExport::AOIExport';
use aliased 'Programs::Exporter::DataTransfer::UnitsDataContracts::AOIData';
use aliased 'Programs::Exporter::ExportPool::UnitEnums';

#use aliased 'Programs::Exporter::ExportChecker::Groups::AOIExport::Presenter::AOIUnit';
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
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $stepToTest = shift;

	#GET INPUT NIF INFORMATION

	my $exportData = AOIData->new();

	$exportData->SetStepToTest("panel");

	my $export = AOIExport->new( UnitEnums->UnitId_AOI );
	$export->Init( $inCAM, $jobId, $exportData );

	$export->{"onItemResult"}->Add( sub { Test(@_) } );

	 $inCAM->VOF();
	
	$export->Run();
	
	$inCAM->VOF();

	print "\n========================== E X P O R T: " . UnitEnums->UnitId_AOI . " ===============================\n";
	print $resultMess;
	print "\n========================== E X P O R T: "
	  . UnitEnums->UnitId_AOI
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
		my @mess1    = ( "== EXPORT FAILURE === GROUP:  " . UnitEnums->UnitId_AOI . "\n" . $resultMess );
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

	use aliased 'Programs::Exporter::ExportPool::Groups::ETExport::ETExportTmp';

	my $jobId    = "f13610";
	my $stepName = "panel";
	my $inCAM    = InCAM->new();

	#GET INPUT NIF INFORMATION
	my $stepToTest = "panel";

}

1;

