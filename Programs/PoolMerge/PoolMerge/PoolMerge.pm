
#-------------------------------------------------------------------------------------------#
# Description: Core of Pool merge program. Manage whole process of merging.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::PoolMerge::PoolMerge::PoolMerge;
use base("Managers::AbstractQueue::AbstractQueue::AbstractQueue");

#3th party library
use threads;
use threads::shared;
use Wx;
use strict;
use warnings;
use File::Copy;
use JSON;
use File::Basename;

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';

#use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::FileHelper';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Managers::AbstractQueue::Task::TaskStatus::TaskStatus';
use aliased 'Programs::PoolMerge::Task::Task';
use aliased 'Programs::PoolMerge::PoolMerge::Forms::PoolMergeForm';
use aliased 'Programs::PoolMerge::Task::TaskData::DataParser';
use aliased 'Managers::AsyncJobMngr::Enums'  => 'EnumsJobMngr';
use aliased 'Managers::AbstractQueue::Enums' => "EnumsAbstrQ";
use aliased 'Programs::PoolMerge::PoolMerge::JobWorkerClass';
use aliased 'Programs::PoolMerge::Enums';
use aliased 'Programs::PoolMerge::PoolMerge::UnitBuilder';
use aliased 'Packages::InCAM::InCAM';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	# Tray or window mode
	my $runMode = shift;

	
	# Main application form
	my $form = PoolMergeForm->new( $runMode, undef );

	my $self = $class->SUPER::new($form);
	bless $self;

	my @taskFiles = ();
	$self->{"taskFiles"} = \@taskFiles;

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
	my $pcbIdShare                        = shift;
	my $taskId                       = shift;
	my $jobStrData                   = shift;
	my $inCAM                        = shift;
	my $THREAD_PROGRESS_EVT : shared = ${ shift(@_) };
	my $THREAD_MESSAGE_EVT : shared  = ${ shift(@_) };
	my $stopVarShare                      = shift;

	#GetTaskClass
	my $task      = $self->_GetTaskById($taskId);
 
	my $unitBuilder = UnitBuilder->new($inCAM, $$pcbIdShare, $jobStrData);
	 

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

	if ( defined $taskStateDetail
		 && ( $taskStateDetail eq EnumsJobMngr->ExitType_FORCE || $taskStateDetail eq EnumsJobMngr->ExitType_FORCERESTART ) )
	{
		return;
	}

	if ( $taskState eq EnumsJobMngr->JobState_DONE ) {

		# Send to export if

		# Set values, if job can be sent to toExport
		$task->SetSentToExportResult();

		# if can eb sent to toExport without errror, send it
		if ( $task->GetJobCanSentToExport() ) {

			$task->SentToExport();
		}

		# refresh GUI to toExport
		$self->{"form"}->SetJobItemSentToExportResult($task);

		$self->{"form"}->SetJobItemResult($task);
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

	my $task = $self->_GetTaskById($taskId);

	# CATCH SPECIAL ITEM MESSAGE

	if ( $messType eq EnumsAbstrQ->EventType_SPECIAL ) {

		if ( $data->{"itemId"} eq EnumsAbstrQ->EventItemType_STOP ) {

			$self->{"form"}->SetJobItemStatus( $taskId, "Pool merging is paused ..." );
			$self->{"form"}->SetJobItemStopped($task);

		}
		elsif ( $data->{"itemId"} eq EnumsAbstrQ->EventItemType_CONTINUE ) {

			$self->{"form"}->SetJobItemStatus( $taskId, "Running ..." );
			$self->{"form"}->SetJobItemContinue($task);

		}
		elsif ( $data->{"itemId"} eq Enums->EventItemType_MASTER ) {

			$self->{"form"}->SetMasterJob( $task, $data->{"data"} );

		}
	}

}

# First is called this function in base class, then is called this handler
sub __OnCloseExporter {
	my $self = shift;

}

sub __OnSentToExportClick {
	my $self   = shift;
	my $taskId = shift;

	my $task = $self->_GetTaskById($taskId);

	my $messMngr = $self->{"form"}->{"messageMngr"};
	my @mess     = ();

	$task->SetSentToExportResult();
	$self->{"form"}->SetJobItemSentToExportResult($task);

	#update gui

	# Can sent to toExport but show errors
	if ( $task->GetJobCanSentToExport() && $task->ResultSentToExport() eq EnumsGeneral->ResultType_FAIL ) {

		push( @mess, "You can send job to product, but first check errors." );
		my @btns = ( "Cancel", "Sent to toExport" );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess, \@btns );

		if ( $messMngr->Result() == 1 ) {
			$task->SentToExport();
			$self->{"form"}->SetJobItemSentToExportResult($task);

		}
	}

	# Can sent to toExport, sent directly
	elsif ( $task->GetJobCanSentToExport() && $task->ResultSentToExport() eq EnumsGeneral->ResultType_OK ) {

		$task->SentToExport();
		$self->{"form"}->SetJobItemSentToExportResult($task);

	}
	elsif ( !$task->GetJobCanSentToExport() ) {

		push( @mess, "You CAN'T send job to product, check \"to toExport\" errors." );
		my @btns = ("Ok");
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess, \@btns );
	}

	#update gui
	# get results, set gui
}

# When job item is restarted, we need set task object, for creating new job item
sub __OnSetNewTaskHandler {
	my $self     = shift;
	my $jobId    = shift;
	my $taskData = shift;
	my $taskStrData = shift;
	my $task     = shift;

	my $status = TaskStatus->new(undef);

	$$task = Task->new( $jobId, $taskData, $taskStrData, $status );
}

#update gui

# Handler responsible for reading DIR which contain files with export settings
# Take every file only once, then delete it
sub __CheckFilesHandler {
	my ( $self, $mainFrm, $event ) = @_;

	# If dir for export files doesn't exist, create it
	unless ( -e EnumsPaths->Client_EXPORTFILESPOOL ) {
		mkdir( EnumsPaths->Client_EXPORTFILESPOOL ) or die "Can't create dir: " . EnumsPaths->Client_EXPORTFILESPOOL . $_;
	}

	my @actFiles = @{ $self->{"taskFiles"} };
	my @newFiles = ();

	#get all files from path
	opendir( DIR, EnumsPaths->Client_EXPORTFILESPOOL ) or die $!;

	my $fileCreated;
	my $fileName;
	my $filePath;

	while ( my $file = readdir(DIR) ) {

		next unless $file =~ /^pan\d+.*\.xml/i;

		$filePath = EnumsPaths->Client_EXPORTFILESPOOL . $file;

		#get file attributes
		my @stats = stat($filePath);

		$fileName = lc($file);

		$fileCreated = $stats[9];

		my $cnt = scalar( grep { $_->{"name"} eq $fileName && $_->{"created"} == $fileCreated } @actFiles );

		unless ($cnt) {

			my %newFile = ( "name" => $fileName, "path" => $filePath, "created" => $fileCreated );
			push( @newFiles, \%newFile );

		}
	}

	if ( scalar(@newFiles) ) {
		@newFiles = sort { $a->{"created"} <=> $b->{"created"} } @newFiles;
		push( @{ $self->{"taskFiles"} }, @newFiles );

		foreach my $jobFile (@newFiles) {

			my $path     = $jobFile->{"path"};
			my $taskName = $jobFile->{"name"};

			my $xmlString = FileHelper->ReadAsString($path);
			my $xmlName   = basename($path);

			my $dataParser = DataParser->new();
			my $taskData = $dataParser->GetTaskDataByString( $xmlString, $xmlName );

			copy( $path, EnumsPaths->Client_EXPORTFILESPOOL . "backup\\" . $taskName );    # do backup

			# TODO odkomentovat abt to mazalo
			#unlink($f);

			# serialize job data to strin
			my %hashData = ();
			$hashData{"fileName"} = $xmlName;
			$hashData{"xmlData"}  = $xmlString;

			my $json = JSON->new();

			my $taskStrData = $json->pretty->encode(\%hashData);

			$self->__AddNewJob( $taskData->GetPanelName(), $taskData, $taskStrData );

		}
	}

}

# ========================================================================================== #
#  PRIVATE HELPER METHOD
# ========================================================================================== #

sub __AddNewJob {
	my $self     = shift;
	my $jobId    = shift;
	my $taskData = shift;
	my $taskStrData = shift;

	my $status = TaskStatus->new(undef);

	my $task = Task->new( $jobId, $taskData, $taskStrData,  $status );

	$self->_AddNewJob($task);
}

sub __SetHandlers {
	my $self = shift;

	#Set base handler
	$self->{"form"}->{'onJobStateChanged'}->Add( sub { $self->__OnJobStateChanged(@_) } );
	$self->{"form"}->{'onJobProgressEvt'}->Add( sub  { $self->__OnJobProgressEvtHandler(@_) } );
	$self->{"form"}->{'onJobMessageEvt'}->Add( sub   { $self->__OnJobMessageEvtHandler(@_) } );

	$self->{"form"}->{'onClick'}->Add( sub        { $self->__OnClick(@_) } );
	$self->{"form"}->{'onSentToExport'}->Add( sub { $self->__OnSentToExportClick(@_) } );

	$self->{'onSetNewTask'}->Add( sub { $self->__OnSetNewTaskHandler(@_) } );

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

	use aliased 'Programs::PoolMerge::PoolMerge::PoolMerge';
	use aliased 'Widgets::Forms::MyTaskBarIcon';

	my $merger = PoolMerge->new( EnumsJobMngr->RUNMODE_WINDOW );

}

1;
