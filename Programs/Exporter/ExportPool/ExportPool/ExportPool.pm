
#-------------------------------------------------------------------------------------------#
# Description: Core of Export utility program. Manage whole process of exporting.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportPool::ExportPool::ExportPool;
use base("Managers::AbstractQueue::AbstractQueue::AbstractQueue");

#3th party library
use threads;
use threads::shared;
use Wx;
use strict;
use warnings;
use File::Copy;

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::FileHelper';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Managers::AbstractQueue::AbstractQueue::ExportStatus::ExportStatus';
use aliased 'Programs::Exporter::ExportPool::Task::Task';
use aliased 'Programs::Exporter::ExportPool::ExportPool::Forms::ExportPoolForm';
use aliased 'Programs::Exporter::DataTransfer::DataTransfer';
use aliased 'Managers::AbstractQueue::ExportData::Enums' => 'EnumsExportData';
use aliased 'Managers::AbstractQueue::ExportData::Enums' => 'EnumsTransfer';
use aliased 'Managers::AsyncJobMngr::Enums'           => 'EnumsMngr';
use aliased 'Programs::Exporter::ExportPool::ExportPool::JobWorkerClass';
use aliased 'Programs::Exporter::ExportPool::Enums';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::Exporter::ExportPool::ExportData::DataParser';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	# Tray or window mode
	my $runMode = shift;

	# Main application form
	my $form = ExportPoolForm->new( $runMode, undef );

	my $self = $class->SUPER::new($form);
	bless $self;

	my @exportFiles = ();
	$self->{"exportFiles"} = \@exportFiles;

	#set base class handlers

	$self->__SetHandlers();

	$self->__RunTimers();

	$self->_Run();

	return $self;
}

# ========================================================================================== #
# WORER METHOD - THIS METHOD IS PROCESS ASYNCHRONOUSLY IN CHILD THREAD
# ========================================================================================== #

#this handler run, when new job thread is created
sub JobWorker {
	my $self                         = shift;
	my $pcbId                        = shift;
	my $taskId                       = shift;
	my $inCAM                        = shift;
	my $THREAD_PROGRESS_EVT : shared = ${ shift(@_) };
	my $THREAD_MESSAGE_EVT : shared  = ${ shift(@_) };
	my $stopVar                      = shift;

	#GetExportClass
	my $task        = $self->_GetTaskById($taskId);
	my %exportClass = $task->{"units"}->GetExportClass();
	my $exportData  = $task->GetExportData();

	my $jobExport = JobWorkerClass->new( \$THREAD_PROGRESS_EVT, \$THREAD_MESSAGE_EVT, $stopVar, $self->{"form"}->{"mainFrm"} );
	$jobExport->Init( $pcbId, $taskId, $inCAM, \%exportClass, $exportData );

	$jobExport->RunExport();

}

# ========================================================================================== #
#  BASE CLASS HANDLERS
# ========================================================================================== #

# First is called this function in base class, then is called this handler
sub __OnJobStateChanged {
	my $self            = shift;
	my $taskId          = shift;
	my $taskState       = shift;
	my $taskStateDetail = shift;

	my $task       = $self->_GetTaskById($taskId);
	my $exportData = $task->GetExportData();

	if ( $taskState eq EnumsMngr->JobState_DONE ) {

		# Setting to Export if is checked by export settings
		if ( $task->GetJobShouldToExport() ) {

			# Set values, if job can be send to export
			$task->SetToExportResult();

			# if can eb send to export without errror, send it
			if ( $task->GetJobCanToExport() ) {

				$task->SendToExport();
			}

			# refresh GUI to Export
			$self->{"form"}->SetJobItemToExportResult($task);
		}
	}
}

# First is called this function in base class, then is called this handler
sub __OnJobProgressEvtHandler {
	my $self   = shift;
	my $taskId = shift;
	my $data   = shift;

}

# First is called this function in base class, then is called this handler
sub __OnJobMessageEvtHandler {
	my $self     = shift;
	my $taskId   = shift;
	my $messType = shift;
	my $data     = shift;

}

# First is called this function in base class, then is called this handler
sub __OnCloseExporter {
	my $self = shift;

	# All jobs should be DONE in this time

	# find if some jobs (in synchronous mode) are in queue
	# if so remove them in order do incam editor free
	foreach my $task ( @{ $self->{"tasks"} } ) {

		my $exportData = $task->GetExportData();

		if ( $exportData->GetExportMode() eq EnumsExportData->ExportMode_SYNC ) {

			$self->__OnRemoveJobClick( $task->GetTaskId() );
		}
	}

}

sub __OnToExportClick {
	my $self   = shift;
	my $taskId = shift;

	my $task = $self->_GetTaskById($taskId);

	my $messMngr = $self->{"form"}->{"messageMngr"};
	my @mess     = ();

	$task->SetToExportResult();
	$self->{"form"}->SetJobItemToExportResult($task);

	#update gui

	# Can send to export but show errors
	if ( $task->GetJobCanToExport() && $task->ResultToExport() eq EnumsGeneral->ResultType_FAIL ) {

		push( @mess, "You can send job to product, but first check errors." );
		my @btns = ( "Cancel", "send to export" );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess, \@btns );

		if ( $messMngr->Result() == 1 ) {
			$task->SendToExport();
			$self->{"form"}->SetJobItemToExportResult($task);

		}
	}

	# Can send to export, sent directly
	elsif ( $task->GetJobCanToExport() && $task->ResultToExport() eq EnumsGeneral->ResultType_OK ) {

		$task->SendToExport();
		$self->{"form"}->SetJobItemToExportResult($task);

	}
	elsif ( !$task->GetJobCanToExport() ) {

		push( @mess, "You CAN'T send job to product, check \"to Export\" errors." );
		my @btns = ("Ok");
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess, \@btns );
	}

	#update gui
	# get results, set gui
}

#update gui

# Handler responsible for reading DIR which contain files with export settings
# Take every file only once, then delete it
sub __CheckFilesHandler {
	my ( $self, $mainFrm, $event ) = @_;

	my @actFiles = @{ $self->{"exportFiles"} };
	my @newFiles = ();

	#get all files from path
	opendir( DIR, EnumsPaths->Client_EXPORTFILES ) or die $!;

	my $fileCreated;
	my $fileName;
	my $filePath;

	while ( my $file = readdir(DIR) ) {

		next unless $file =~ /^[a-z](\d+)$/i;

		$filePath = EnumsPaths->Client_EXPORTFILES . $file;

		#get file attributes
		my @stats = stat($filePath);

		$fileName = lc($file);
		$fileName =~ s/\.xml//;
		$fileCreated = $stats[9];

		my $cnt = scalar( grep { $_->{"name"} eq $fileName && $_->{"created"} == $fileCreated } @actFiles );

		unless ($cnt) {

			my %newFile = ( "name" => $fileName, "path" => $filePath, "created" => $fileCreated );
			push( @newFiles, \%newFile );
		}
	}

	if ( scalar(@newFiles) ) {
		@newFiles = sort { $a->{"created"} <=> $b->{"created"} } @newFiles;
		push( @{ $self->{"exportFiles"} }, @newFiles );

		foreach my $poolFile (@newFiles) {

			my $fileName = $poolFile->{"name"};
			my $path = $poolFile->{"path"};
			
			my $f = EnumsPaths->Client_EXPORTFILESPOOL . $fileName;

			my $dataParser = DataParser->new( );
			my $exportData = $dataParser->GetExportData($f);
 
			copy( $f, EnumsPaths->Client_EXPORTFILESPOOL . "backup\\" . $fileName );    # do backup

			# TODO odkomentovat abt to mazalo
			#unlink($f);

			$self->__AddNewJob( $jobId, $exportData );

		}
	}

}

# ========================================================================================== #
#  PRIVATE HELPER METHOD
# ========================================================================================== #

sub __AddNewJob {
	my $self       = shift;
	my $jobId      = shift;
	my $exportData = shift;

	my $status = ExportStatus->new( $jobId, "Pcb" );

	my $task = Task->new( $jobId, $exportData, $status );

	$self->_AddNewJob($task);
}

sub __SetHandlers {
	my $self = shift;

	#Set base handler
	$self->{"form"}->{'onJobStateChanged'}->Add( sub { $self->__OnJobStateChanged(@_) } );
	$self->{"form"}->{'onJobProgressEvt'}->Add( sub  { $self->__OnJobProgressEvtHandler(@_) } );
	$self->{"form"}->{'onJobMessageEvt'}->Add( sub   { $self->__OnJobMessageEvtHandler(@_) } );

	$self->{"form"}->{'onClick'}->Add( sub     { $self->__OnClick(@_) } );
	$self->{"form"}->{'onToExport'}->Add( sub { $self->__OnToExportClick(@_) } );

	# Set worker method
	$self->{"form"}->_SetThreadWorker( sub { $self->JobWorker(@_) } );

}

# Times are in milisecond
sub __RunTimers {
	my $self = shift;

	my $formMainFrm = $self->{"form"}->{"mainFrm"};

	my $timerFiles = Wx::Timer->new( $formMainFrm, -1, );
	Wx::Event::EVT_TIMER( $formMainFrm, $timerFiles, sub { $self->__CheckFilesHandler(@_) } );
	$self->{"timerFiles"} = $timerFiles;
	$timerFiles->Start(200);

}

#
#sub __Refresh {
#	my ( $self, $frame, $event ) = @_;
#
#	#$self->_SetDestroyServerOnDemand(1);
#
#	my $txt2 = $self->_GetInfoServers();
#	my $txt  = $self->_GetInfoJobs();
#
#	$self->{"txt"}->SetLabel($txt);
#	$self->{"txt2"}->SetLabel($txt2);
#
#}

# necessery for running RunALone library

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Exporter::ExportPool::ExportPool::ExportPool';
	use aliased 'Widgets::Forms::MyTaskBarIcon';

	my $exporter = ExportPool->new( EnumsMngr->RUNMODE_WINDOW );

	#my $form = $exporter->{"form"}->{"mainFrm"};

	#my $trayicon = MyTaskBarIcon->new( "Exporter", $form);

	#$trayicon->AddMenuItem("Exit Exporter", sub {  $exporter->{"form"}->OnClose() });
	#$trayicon->AddMenuItem("Open", sub { print "Open"; });

	#	sub __OnLeftClick {
	#	my $self = shift;
	#
	#	print "left click\n";
	#
	#	}

	#$trayicon->IsOk() || die;

	#$app->Test();

}

1;
