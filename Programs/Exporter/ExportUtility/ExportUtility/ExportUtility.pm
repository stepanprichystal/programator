
#-------------------------------------------------------------------------------------------#
# Description: Core of Export utility program. Manage whole process of exporting.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::ExportUtility::ExportUtility;
use base("Managers::AbstractQueue::AbstractQueue::AbstractQueue");

#3th party library
use threads;
use threads::shared;
use Wx;
use strict;
use warnings;
use File::Copy;
use File::Basename;
use Log::Log4perl qw(get_logger :levels);

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::FileHelper';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Managers::AbstractQueue::Task::TaskStatus::TaskStatus';
use aliased 'Programs::Exporter::ExportUtility::Task::Task';
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::Forms::ExportUtilityForm';
use aliased 'Programs::Exporter::ExportUtility::DataTransfer::DataTransfer';
use aliased 'Managers::AsyncJobMngr::Helper'                         => "AsyncJobHelber";
use aliased 'Programs::Exporter::ExportUtility::DataTransfer::Enums' => 'EnumsTransfer';
use aliased 'Managers::AsyncJobMngr::Enums'                          => 'EnumsJobMngr';
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::JobWorkerClass';
use aliased 'Programs::Exporter::ExportUtility::Enums';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::UnitBuilder';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	# Tray or window mode
	my $runMode = shift;

	# Main application form
	my $form = ExportUtilityForm->new( $runMode, undef );

	my $self = $class->SUPER::new($form);
	bless $self;

	my @exportFiles = ();
	$self->{"exportFiles"} = \@exportFiles;

	#set base class handlers

	$self->__SetHandlers();

	$self->__RunTimers();

	#$self->_Run();
	return $self;
}

# ========================================================================================== #
# WORER METHOD - THIS METHOD IS PROCESS ASYNCHRONOUSLY IN CHILD THREAD
# ========================================================================================== #

#this handler run, when new job thread is created
sub JobWorker {
	my $self                         = shift;
	my $pcbIdShare                   = shift;
	my $taskId                       = shift;
	my $jobStrData                   = shift;
	my $inCAM                        = shift;
	my $THREAD_PROGRESS_EVT : shared = ${ shift(@_) };
	my $THREAD_MESSAGE_EVT : shared  = ${ shift(@_) };
	my $stopVarShare                 = shift;

	#GetTaskClass
	my $task = $self->_GetTaskById($taskId);

	my $unitBuilder = UnitBuilder->new( $inCAM, $$pcbIdShare, $jobStrData );

	my $workerClass = JobWorkerClass->new( \$THREAD_PROGRESS_EVT, \$THREAD_MESSAGE_EVT, $stopVarShare, $self->{"form"}->{"mainFrm"} );
	$workerClass->Init( $pcbIdShare, $taskId, $unitBuilder, $inCAM, );

	$workerClass->RunTask();

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

	my $task     = $self->_GetTaskById($taskId);
	my $taskData = $task->GetTaskData();

	if ( $taskState eq EnumsJobMngr->JobState_DONE ) {

		# Set values, if job can be sent to produce
		$task->SetToProduceResult();

		# Setting to produce if is checked by export settings
		if ( $task->GetJobShouldToProduce() ) {

			# if can eb sent to produce without errror, send it
			if ( $task->GetJobCanToProduce() && $task->GetTaskWarningCnt() == 0 ) {

				my $sent = $task->SentToProduce();

				# remove job automaticaly form queue if sent to export
				if ($sent) {

					$self->_AddJobToAutoRemove( $task->GetTaskId() );
				}
			}

			# refresh GUI to produce
			$self->{"form"}->SetJobItemToProduceResult($task);

		}
		else {

			if ( $task->Result() eq EnumsGeneral->ResultType_OK ) {

				$self->_AddJobToAutoRemove( $task->GetTaskId() );
			}
		}

		# if task done, check if thera are errors or note
		if ( $taskStateDetail eq EnumsJobMngr->ExitType_SUCCES ) {

			# if job cant to produce, it means, there are errors
			# send error state
			unless ( $task->GetJobCanToProduce() ) {

				$task->SetErrorState();
			}
		}

		# if export is ruiunning on server and export is background, remove from queue always
		if ( AsyncJobHelber->ServerVersion() && $task->GetTaskData()->GetTaskMode() eq EnumsJobMngr->TaskMode_ASYNC ) {

			$self->_AddJobToAutoRemove( $task->GetTaskId() );
		}
	}

	$self->{"form"}->GetNotifyMngr()->JobStateChanged( $task, $taskState, $taskStateDetail );

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

}

sub __OnToProduceClick {
	my $self   = shift;
	my $taskId = shift;

	my $task = $self->_GetTaskById($taskId);

	my $messMngr = $self->{"form"}->{"messageMngr"};
	my @mess     = ();

	$task->SetToProduceResult();
	$self->{"form"}->SetJobItemToProduceResult($task);

	#update gui

	# Can sent to produce but show errors
	if ( $task->GetJobCanToProduce() && $task->ResultToProduce() eq EnumsGeneral->ResultType_FAIL ) {

		push( @mess, "You can send job to product, but first check errors." );
		my @btns = ( "Cancel", "Sent to produce" );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess, \@btns );

		if ( $messMngr->Result() == 1 ) {
			$task->SentToProduce();
			$self->{"form"}->SetJobItemToProduceResult($task);

		}
	}

	# Can sent to produce, sent directly
	elsif ( $task->GetJobCanToProduce() && $task->ResultToProduce() eq EnumsGeneral->ResultType_OK ) {

		$task->SentToProduce();
		$self->{"form"}->SetJobItemToProduceResult($task);

	}
	elsif ( !$task->GetJobCanToProduce() ) {

		push( @mess, "You CAN'T send job to product, check \"to produce\" errors." );
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

	# If dir for export files doesn't exist, create it
	unless ( -e EnumsPaths->Client_EXPORTFILES ) {
		mkdir( EnumsPaths->Client_EXPORTFILES ) or die "Can't create dir: " . EnumsPaths->Client_EXPORTFILES . $_;
	}

	my @files = ();

	#get all files from path
	my $dir;
	opendir( $dir, EnumsPaths->Client_EXPORTFILES ) or die $!;
	while ( my $file = readdir($dir) ) {

		push( @files, EnumsPaths->Client_EXPORTFILES . $file );
	}
	closedir($dir);

	# Check files for export on server
	my $dirSrv;
	if ( AsyncJobHelber->ServerVersion() ) {
		opendir( $dirSrv, EnumsPaths->Jobs_EXPORTFILESPCB ) or die $!;
		while ( my $file = readdir($dirSrv) ) {

			push( @files, EnumsPaths->Jobs_EXPORTFILESPCB . $file );
		}
		closedir($dirSrv);
	}

	my @actFiles = @{ $self->{"exportFiles"} };
	my @newFiles = ();

	my $fileCreated;
	my $fileName;
	my $filePath;

	foreach my $filePath (@files) {

		my $fileName = basename($filePath);
		my $fileDir  = dirname($filePath) . "\\";

		next unless $fileName =~ /^[a-z](\d+)$/i;

		$filePath = $fileDir . $fileName;

		#get file attributes
		my @stats = stat($filePath);

		$fileName = lc($fileName);
		$fileName =~ s/\.xml//;
		$fileCreated = $stats[9];

		# if file is empty, next
		next if ( $stats[7] == 0 );

		my $cnt = scalar( grep { $_->{"name"} eq $fileName && $_->{"created"} == $fileCreated } @actFiles );

		unless ($cnt) {

			my %newFile = ( "name" => $fileName, "dirName" => $fileDir, "created" => $fileCreated );
			push( @newFiles, \%newFile );
		}
	}

	if ( scalar(@newFiles) ) {
		@newFiles = sort { $a->{"created"} <=> $b->{"created"} } @newFiles;
		push( @{ $self->{"exportFiles"} }, @newFiles );

		foreach my $jobFile (@newFiles) {

			my $jobId = $jobFile->{"name"};

			my $pathExportFile = $jobFile->{"dirName"} . $jobId;
			my $dataTransfer   = DataTransfer->new( $jobId, EnumsTransfer->Mode_READ, undef, undef, $pathExportFile );
			my $taskData       = $dataTransfer->GetExportData();

			my $f          = $jobFile->{"dirName"} . $jobId;
			my $jsonString = FileHelper->ReadAsString($f);

			copy( $f, $jobFile->{"dirName"} . "backup\\" . $jobId );    # do backup

			# TODO odkomentovat abt to mazalo
			unlink($f);

			# serialize job data to string (use hash in order serialize via JSON)
			#my %hashData = ();
			#$hashData{"jsonData"} = $jsonString;

			#my $json = JSON->new();

			#my $taskStrData = $json->pretty->encode( \%hashData );

			$self->__AddNewJob( $jobId, $taskData, $jsonString );
		}
	}

}

# ========================================================================================== #
#  PRIVATE HELPER METHOD
# ========================================================================================== #

sub __AddNewJob {
	my $self        = shift;
	my $jobId       = shift;
	my $taskData    = shift;
	my $taskStrData = shift;

	my $path = undef;
	if ( !JobHelper->GetJobIsOffer($jobId) ) {
		$path = JobHelper->GetJobArchive($jobId) . "Status_export";
	}

	my $status = TaskStatus->new($path);

	my $task = Task->new( $jobId, $taskData, $taskStrData, $status, 1 );

	$self->_AddNewJob($task);
}

sub __SetHandlers {
	my $self = shift;

	#Set base handler
	$self->{"form"}->{'onJobStateChanged'}->Add( sub { $self->__OnJobStateChanged(@_) } );
	$self->{"form"}->{'onJobProgressEvt'}->Add( sub  { $self->__OnJobProgressEvtHandler(@_) } );
	$self->{"form"}->{'onJobMessageEvt'}->Add( sub   { $self->__OnJobMessageEvtHandler(@_) } );

	$self->{"form"}->{'onClick'}->Add( sub     { $self->__OnClick(@_) } );
	$self->{"form"}->{'onToProduce'}->Add( sub { $self->__OnToProduceClick(@_) } );

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
	$timerFiles->Start(500);
	$self->_AddTimers($timerFiles);

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

	use aliased 'Programs::Exporter::ExportUtility::ExportUtility::ExportUtility';
	use aliased 'Widgets::Forms::MyTaskBarIcon';

	my $exporter = ExportUtility->new( EnumsJobMngr->RUNMODE_WINDOW );

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
