
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::ExportUtility::ExportUtility;

#3th party library
use threads;
use threads::shared;
use Wx;
use strict;
use warnings;

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';

use aliased 'Programs::Exporter::ExportUtility::Task::Task';
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::Forms::ExportUtilityForm';
use aliased 'Programs::Exporter::DataTransfer::DataTransfer';
use aliased 'Programs::Exporter::DataTransfer::Enums' => 'EnumsTransfer';
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::JobWorkerClass';
use aliased 'Programs::Exporter::ExportUtility::Enums';

#my $THREAD_MESSAGE_EVT : shared;
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

#use constant {
#			   ITEM_RESULT  => "itemResult",
#			   ITEM_ERROR   => "itemError",
#			   GROUP_EXPORT => "groupExport"
#};

sub new {
	my $self = shift;
	$self = {};
	bless($self);

	$self->{"inCAM"} = undef;

	# Main application form
	$self->{"form"} = ExportUtilityForm->new();

	# Keep all references of used groups/units in form
	my @tasks = ();
	$self->{"tasks"} = \@tasks;

	#set base class handlers

	$self->__Init();
	$self->__Run();

	#$self->{'onSetLayout'}->Add( sub { $self->__OnSetLayout(@_)});

	return $self;
}

sub __Init {
	my $self = shift;

	#set handlers for main app form
	$self->__SetHandlers();

	#$self->__RunTimers();
}

sub __Run {
	my $self = shift;
	$self->{"form"}->{"mainFrm"}->Show(1);

	$self->{"form"}->MainLoop();

}

sub __AddNewJob {
	my $self       = shift;
	my $jobId      = shift;
	my $exportData = shift;

	# unique id per each task
	my $guid = GeneralHelper->GetGUID();

	my $task = Task->new( $guid, $jobId, $exportData );
	
	push( @{ $self->{"tasks"} }, $task );

	# prepare gui
	$self->{"form"}->AddNewTaskGUI($task);

	# Add new task to queue
	$self->{"form"}->AddNewTask($task);

	

}

# ========================================================================================== #
#  BASE CLASS HANDLERS
# ========================================================================================== #

sub __OnJobStartRunHandler {
	my $self    = shift;
	my $jobGUID = shift;

	print "Exporter utility: Start job id: $jobGUID\n";

}

sub __OnJobDoneEvtHandler {
	my $self     = shift;
	my $jobGUID  = shift;
	my $exitType = shift;

	print "Exporter utility: Job DONE job id: $jobGUID, exit type: $exitType\n";

}

sub __OnJobProgressEvtHandler {
	my $self    = shift;
	my $jobGUID = shift;
	my $data   = shift;

	#$self->{"gauge"}->SetValue($value);

	#print "Exporter utility:  job progress, job id: " . $jobGUID . " - value: " . $value . "\n";

}

sub __OnJobMessageEvtHandler {
	my $self     = shift;
	my $taskId  = shift;
	my $messType = shift;
	my $data     = shift;
	

	my $task = $self->__GetTaskById($taskId);
	
	print "Exporter utility::  task id: " . $taskId . " - messType: " . $messType. "\n";
	
	if($messType eq Enums->EventType_ITEM_RESULT){
		
		
		$task->ItemMessageEvt($data);
		
		#$self->{"form"}->{"mainFrm"}->Layout();
		#$self->{"form"}->{"mainFrm"}->Refresh();
		
		$self->{"form"}->__GroupContentRefresh($taskId);
		#$self->{"form"}->{"mainFrm"}->Layout();
		#$self->{"form"}->{"mainFrm"}->Refresh();
	}
	
	


	#print "Exporter utility::  job id: " . $jobGUID . " - messType: " . $messType . " - data: " . $data . "\n";
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
	
	 
	#vytvorit nejakou Base class ktera bude obsahovat odesilani zprav prostrednictvim messhandler

	#GetExportClass
	my $task        = $self->__GetTaskById($taskId);
	my %exportClass = $task->{"units"}->GetExportClass();
	my $exportData  = $task->GetExportData();
	
	# TODO udelat base class pro JobWorkerClass nebo to nejak vzresit
	
	my $jobExport = JobWorkerClass->new( \$THREAD_PROGRESS_EVT, \$THREAD_MESSAGE_EVT, $self->{"form"}->{"mainFrm"});
	 $jobExport->Init($pcbId, $taskId, $inCAM, \%exportClass, $exportData);

	$jobExport->RunExport();

	#$jobExport->{'onItemResult'}->Add{  sub    { $self->__OnItemResultHandler(@_) }  };
	#$jobExport->{'onItemError'}->Add{  sub    { $self->__OnItemErrorHandler(@_) }  }
	#$jobExport->{'onGroupExport'}->Add{  sub    { $self->__OnGroupExportHandler(@_) }  }

	#use aliased 'Packages::Export::NCExport::NC_Group';

	#my $jobId    = "F13608";
	#my $stepName = "panel";

	#use aliased 'CamHelpers::CamHelper';

	#CamHelper->OpenJobAndStep( $inCAM, $pcbId, $stepName );

	#my $ncgroup = NC_Group->new( $inCAM, $pcbId );

	#$ncgroup->Run();

	#doExport($pcbId,$inCAM)
	#
	#	my %res : shared = ();
	#	for ( my $i = 0 ; $i < 50 ; $i++ ) {
	#
	#		$res{"jobGUID"} = $jobGUID;
	#		$res{"port"}    = "port";
	#		$res{"value"}   = $i;
	#
	#		my $threvent2 = new Wx::PlThreadEvent( -1, $THREAD_PROGRESS_EVT, \%res );
	#		Wx::PostEvent( $self->{"mainFrm"}, $threvent2 );
	#
	#		sleep(1);
	#	}
	print "TESTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT KONEEEEC";

}

# ========================================================================================== #
#  PRIVATE HELPER METHOD
# ========================================================================================== #

sub __GetTaskById {
	my $self   = shift;
	my $taskId = shift;

	foreach my $task ( @{ $self->{"tasks"} } ) {

		if ( $task->GetTaskId() eq $taskId ) {

			return $task;
		}
	}
}

sub __SetHandlers {
	my $self = shift;

	#Set base handler

	$self->{"form"}->{'onJobStartRun'}->Add( sub    { $self->__OnJobStartRunHandler(@_) } );
	$self->{"form"}->{'onJobDoneEvt'}->Add( sub     { $self->__OnJobDoneEvtHandler(@_) } );
	$self->{"form"}->{'onJobProgressEvt'}->Add( sub { $self->__OnJobProgressEvtHandler(@_) } );
	$self->{"form"}->{'onJobMessageEvt'}->Add( sub  { $self->__OnJobMessageEvtHandler(@_) } );

	$self->{"form"}->{'onClick'}->Add( sub { $self->__OnClick(@_) } );

	# Set worker method
	$self->{"form"}->_SetThreadWorker( sub { $self->JobWorker(@_) } );

}

sub __RunTimers {
	my $self = shift;

	my $formMainFrm = $self->{"form"};

	my $timerFiles = Wx::Timer->new( $formMainFrm, -1, );
	Wx::Event::EVT_TIMER( $formMainFrm, $timerFiles, sub { __CheckFilesHandler( $self, @_ ) } );
	$self->{"timerFiles"} = $timerFiles;

	my $timerRefresh = Wx::Timer->new( $formMainFrm, -1, );
	Wx::Event::EVT_TIMER( $formMainFrm, $timerRefresh, sub { __Refresh( $self, @_ ) } );
	$timerRefresh->Start(200);
}

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

		next unless $file =~ /^[a-z](\d+)\.xml$/i;

		$filePath = EnumsPaths->Client_EXPORTFILES . $file;

		#get file attributes
		my @stats = stat($filePath);

		$fileName = lc($file);
		$fileName =~ s/\.xml//;
		$fileCreated = $stats[9];

		my $cnt = scalar( grep { $_->{"name"} eq $fileName && $_->{"created"} == $fileCreated } @actFiles );

		unless ($cnt) {
			my %newFile = ( "name" => $fileName, "created" => $fileCreated );
			push( @newFiles, \%newFile );

		}
	}

	if ( scalar(@newFiles) ) {
		@newFiles = sort { $a->{"created"} <=> $b->{"created"} } @newFiles;
		push( @{ $self->{"exportFiles"} }, @newFiles );
	}

	my $str = "";
	foreach my $f ( @{ $self->{"exportFiles"} } ) {
		$str .= $f->{"name"} . " - " . localtime( $f->{"created"} ) . "\n";

	}

	$self->{"txt"}->SetLabel($str);
	print "Aktualiyace - " . localtime( time() ) . "\n";
}

sub __Refresh {
	my ( $self, $frame, $event ) = @_;

	#$self->_SetDestroyServerOnDemand(1);

	my $txt2 = $self->_GetInfoServers();
	my $txt  = $self->_GetInfoJobs();

	$self->{"txt"}->SetLabel($txt);
	$self->{"txt2"}->SetLabel($txt2);

}

sub __OnClick {
	my $self = shift;

	my $actualColId = 0;
	my $total       = 0;

	my $jobId = "f13610";

	my $dataTransfer = DataTransfer->new( $jobId, EnumsTransfer->Mode_READ );
	my $exportData = $dataTransfer->GetExportData();

	$self->__AddNewJob( $jobId, $exportData );
}

sub doExport {
	my ( $id, $inCAM ) = @_;

	my $errCode = $inCAM->COM( " clipb_open_job ", job => $id, update_clipboard => " view_job " );

	#
	#	$errCode = $inCAM->COM(
	#		" open_entity ",
	#		job  => " F17116 + 2 ",
	#		type => " step ",
	#		name => " test "
	#	);

	#return 0;
	for ( my $i = 0 ; $i < 5 ; $i++ ) {

		sleep(3);
		$inCAM->COM(
					 'output_layer_set',
					 layer        => " c ",
					 angle        => '0',
					 x_scale      => '1',
					 y_scale      => '1',
					 comp         => '0',
					 polarity     => 'positive',
					 setupfile    => '',
					 setupfiletmp => '',
					 line_units   => 'mm',
					 gscl_file    => ''
		);

		$inCAM->COM(
					 'output',
					 job                  => $id,
					 step                 => 'input',
					 format               => 'Gerber274x',
					 dir_path             => " c : /Perl/site / lib / TpvScripts / Scripts / data ",
					 prefix               => " incam1_ " . $id . " _ $i",
					 suffix               => "",
					 break_sr             => 'no',
					 break_symbols        => 'no',
					 break_arc            => 'no',
					 scale_mode           => 'all',
					 surface_mode         => 'contour',
					 min_brush            => '25.4',
					 units                => 'inch',
					 coordinates          => 'absolute',
					 zeroes               => 'Leading',
					 nf1                  => '6',
					 nf2                  => '6',
					 x_anchor             => '0',
					 y_anchor             => '0',
					 wheel                => '',
					 x_offset             => '0',
					 y_offset             => '0',
					 line_units           => 'mm',
					 override_online      => 'yes',
					 film_size_cross_scan => '0',
					 film_size_along_scan => '0',
					 ds_model             => 'RG6500'
		);

	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Exporter::ExportUtility::ExportUtility::ExportUtility';

	my $exporter = ExportUtility->new();

	#$app->Test();

	$exporter->MainLoop;

}

1;

1;
