
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
 
use aliased 'Programs::Exporter::ExportUtility::DataTransfer::Enums' => 'EnumsTransfer';
use aliased 'Managers::AsyncJobMngr::Enums'           => 'EnumsJobMngr';
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::JobWorkerClass';
use aliased 'Programs::Exporter::ExportUtility::Enums';
use aliased 'Packages::InCAM::InCAM';

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

	#GetTaskClass
	my $task        = $self->_GetTaskById($taskId);
	my %exportClass = $task->{"units"}->GetTaskClass();
	my $taskData  = $task->GetTaskData();

	my $jobExport = JobWorkerClass->new( \$THREAD_PROGRESS_EVT, \$THREAD_MESSAGE_EVT, $stopVar, $self->{"form"}->{"mainFrm"} );
	$jobExport->Init( $pcbId, $taskId, $inCAM, \%exportClass, $taskData );

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
	my $taskData = $task->GetTaskData();

	if ( $taskState eq EnumsJobMngr->JobState_DONE ) {

		# Setting to produce if is checked by export settings
		if ( $task->GetJobShouldToProduce() ) {

			# Set values, if job can be sent to produce
			$task->SetToProduceResult();

			# if can eb sent to produce without errror, send it
			if ( $task->GetJobCanToProduce() ) {

				$task->SentToProduce();
			}

			# refresh GUI to produce
			$self->{"form"}->SetJobItemToProduceResult($task);
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

		foreach my $jobFile (@newFiles) {

			my $jobId = $jobFile->{"name"};

			my $dataTransfer = DataTransfer->new( $jobId, EnumsTransfer->Mode_READ );
			my $taskData = $dataTransfer->GetExportData();

			my $f = EnumsPaths->Client_EXPORTFILES . $jobId;

			copy( $f, EnumsPaths->Client_EXPORTFILES . "backup\\" . $jobId );    # do backup

			# TODO odkomentovat abt to mazalo
			#unlink($f);

			$self->__AddNewJob( $jobId, $taskData );

		}
	}

}

# ========================================================================================== #
#  PRIVATE HELPER METHOD
# ========================================================================================== #

sub __AddNewJob {
	my $self       = shift;
	my $jobId      = shift;
	my $taskData = shift;

	my $path = JobHelper->GetJobArchive( $jobId) . "Status_export";

	my $status = TaskStatus->new( $path);

	my $task = Task->new( $jobId, $taskData, $status );

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
