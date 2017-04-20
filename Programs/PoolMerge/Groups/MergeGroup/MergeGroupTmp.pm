package Programs::PoolMerge::Groups::MergeGroup::MergeGroupTmp;

#3th party library
use strict;
use warnings;

use aliased 'Enums::EnumsGeneral';

 
use aliased 'Programs::PoolMerge::UnitEnums';
use aliased 'Managers::AbstractQueue::AbstractQueue::JobWorkerUnit';

#use aliased 'Programs::Exporter::ExportChecker::Groups::MergeGroup::Presenter::AOIUnit';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased "Programs::PoolMerge::Task::TaskData::DataParser";
use aliased "Programs::PoolMerge::Groups::MergeGroup::MergeWorkUnit" => "Unit";

#-------------------------------------------------------------------------------------------#
#  NC export, all layers, all machines..
#-------------------------------------------------------------------------------------------#

my $resultMess = "";
my $succes     = 1;

sub new {

	my $self = shift;
	$self = {};
	bless $self;
	
	$self->{"id"} =  UnitEnums->UnitId_MERGE;
	
	return $self;
}

sub Run {
	my $self       = shift;
	my $inCAM      = shift;

	#PARSE INPUT DATA

	my $path = "c:\\Export\\ExportFiles\\Pool\\backup\\pan2_4-18-1500-Imersnizlato_17-09-58.xml";
 
	my $dataParser = DataParser->new();
	my $taskDataAll = $dataParser->GetTaskDataByPath( $path);
 
	my $worker = Unit->new( $self->{"id"} );
	
	my $taskData = $taskDataAll->GetUnitData($self->{"id"} );
	$worker->SetTaskData($taskData);
	
	$worker->Init( $inCAM, "");
	$worker->{"onItemResult"}->Add( sub { Test(@_) } );
	$worker->Run();
	
	$inCAM->VOF();

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
		my $messMngr = MessageMngr->new("");

		my @mess1 = ( "== EXPORT FAILURE === GROUP:  " . $self->{"id"} . "\n" . $resultMess );
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

 
	#GET INPUT NIF INFORMATION
	 

}

1;

