package Programs::Exporter::ExportPool::Groups::PlotExport::PlotExportTmp;

#3th party library
use strict;
use warnings;
use Wx;

use aliased 'Enums::EnumsPaths';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Events::Event';
use aliased 'Programs::Exporter::ExportPool::UnitEnums';
use aliased 'Managers::MessageMngr::MessageMngr';

use aliased "Programs::Exporter::ExportPool::Groups::PlotExport::PlotUnit"  => "UnitExport";
use aliased "Programs::Exporter::ExportChecker::Groups::PlotExport::Presenter::PlotUnit" => "Unit";

use aliased 'Programs::Exporter::ExportChecker::ExportChecker::DefaultInfo::DefaultInfo';
use aliased 'Packages::ItemResult::ItemResultMngr';

#-------------------------------------------------------------------------------------------#
#  NC export, all layers, all machines..
#-------------------------------------------------------------------------------------------#
my $resultMess = "";
my $succes     = 1;
sub new {

	my $self = shift;
	$self = {};
	bless $self;
	
	$self->{"id"} =  UnitEnums->UnitId_PLOT;
	
	return $self;
}

sub Run {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	$self->{"defaultInfo"} = DefaultInfo->new( $inCAM, $jobId );

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

		return 0;
	}

	my $taskData = $unit->GetTaskData($inCAM);

	my $exportUnit = UnitExport->new( $self->{"id"} );

	my $exportClass = $exportUnit->GetExportClass();

	$exportClass->Init( $inCAM, $jobId, $taskData );
	$exportClass->{"onItemResult"}->Add( sub { Test(@_) } );
	
 
	$exportClass->Run();
	
 

	print "\n========================== E X P O R T: " . $self->{"id"} . " ===============================\n";
	print $resultMess;
	print "\n========================== E X P O R T: "
	  . $self->{"id"}
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

		my @mess1 = ( "== EXPORT FAILURE === GROUP:  " . $self->{"id"} . "\n" . $resultMess );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess1 );
	}

	return $succes;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

#	use aliased 'Programs::Exporter::ExportPool::Groups::PlotExport::PlotExportTmp';
#	my $checkOk  = 1;
#	my $jobId    = "f13610";
#	my $stepName = "panel";
#	my $inCAM    = InCAM->new();

	#GET INPUT NIF INFORMATION

	 

}

1;

