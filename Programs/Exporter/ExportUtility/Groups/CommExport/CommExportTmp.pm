package Programs::Exporter::ExportUtility::Groups::CommExport::CommExportTmp;

#3th party library
use strict;
use warnings;

use aliased 'Enums::EnumsGeneral';

#use aliased 'Programs::Exporter::ExportChecker::Groups::CommExport::Model::CommDataMngr';
use aliased 'Programs::Exporter::ExportChecker::Groups::NCExport::Model::NCGroupData';
#use aliased 'Programs::Exporter::ExportChecker::Groups::CommExport::Presenter::CommUnit';
use aliased 'Managers::MessageMngr::MessageMngr';



use aliased "Programs::Exporter::ExportChecker::Groups::CommExport::Presenter::CommUnit"  => "Unit";
use aliased "Programs::Exporter::ExportUtility::Groups::CommExport::CommWorkUnit" => "UnitExport";
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::DefaultInfo::DefaultInfo';
use aliased 'Packages::ItemResult::ItemResultMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Connectors::HeliosConnector::HegMethods';

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

	$self->{"defaultInfo"} = DefaultInfo->new($jobId );
	$self->{"defaultInfo"}->Init($inCAM);

	# Check data

	my $resultMngr = ItemResultMngr->new();

	my $unit = Unit->new($jobId);
	$unit->SetDefaultInfo( $self->{"defaultInfo"} );
	$unit->InitDataMngr($inCAM);
	$unit->CheckBeforeExport( $inCAM, \$resultMngr );

	unless ( $resultMngr->Succes() ) {

		my $str = "";
		$str .= $resultMngr->GetErrorsStr();
		$str .= $resultMngr->GetWarningsStr();

		my $messMngr = MessageMngr->new( $self->{"jobId"} );

		my @mess1 = ( "Kontrola pred exportem", $str );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess1 );

		#return 0;
	}

	my $taskData = $unit->GetExportData($inCAM);
	my $exportClass = UnitExport->new( $self->{"id"} );
	$exportClass->SetTaskData($taskData);
 

	$exportClass->Init( $inCAM, $jobId, $taskData );
	$exportClass->{"onItemResult"}->Add( sub { Test(@_) } );
	$exportClass->Run();

	print "\n========================== E X P O R T: " . UnitEnums->UnitId_Comm . " ===============================\n";
	print $resultMess;
	print "\n========================== E X P O R T: "
	  . UnitEnums->UnitId_Comm
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
		my @mess1 = ( "== EXPORT FAILURE === GROUP:  ".UnitEnums->UnitId_Comm."\n".$resultMess);
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

	use aliased 'Programs::Exporter::ExportUtility::Groups::CommExport::CommExportTmp';

	my $jobId    = "f13610";
	my $stepName = "panel";
	my $inCAM    = InCAM->new();

	#GComm INPUT NIF INFORMATION
	my $stepToTest = "panel";

}

1;

