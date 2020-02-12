package Programs::Exporter::ExportUtility::Groups::NCExport::NCExportTmp;

#3th party library
use strict;
use warnings;
use Wx;

use PackagesLib;

 
use aliased 'Packages::Export::NCExport::ExportMngr';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsMachines';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Export::NCExport::FileHelper::Parser';
use aliased 'Packages::Events::Event';


use aliased "Programs::Exporter::ExportChecker::Groups::NCExport::Presenter::NCUnit"  => "Unit";
use aliased "Programs::Exporter::ExportUtility::Groups::NCExport::NCWorkUnit" => "UnitExport";

 
use aliased 'Programs::Exporter::ExportUtility::DataTransfer::UnitsDataContracts::NCData';
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';

use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::DefaultInfo::DefaultInfo';
use aliased 'Packages::ItemResult::ItemResultMngr';
use aliased 'Enums::EnumsGeneral';

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
	my $exportSingle = shift;
	my $plt = shift;
	my $nplt = shift;

	$self->{"defaultInfo"} = DefaultInfo->new($jobId );
	$self->{"defaultInfo"}->Init($inCAM);

	# Check data

	my $resultMngr = ItemResultMngr->new();

	my $unit = Unit->new($jobId);
	$unit->SetDefaultInfo( $self->{"defaultInfo"} );
	$unit->InitDataMngr($inCAM);
	#$unit->CheckBeforeExport( $inCAM, \$resultMngr );

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

	print "\n========================== E X P O R T: " . UnitEnums->UnitId_NC . " ===============================\n";
	print $resultMess;
	print "\n========================== E X P O R T: "
	  . UnitEnums->UnitId_NC
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

		my @mess1 = ( "== EXPORT FAILURE === GROUP:  " . UnitEnums->UnitId_NC . "\n" . $resultMess );
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
	$export->Run( $inCAM, $jobId, $exportSingle, \@pltLayers, \@npltLayers );

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

