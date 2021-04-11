
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Core::BackgroundTaskMngr;

# Abstract class #

#3th party library
use strict;
use warnings;
use JSON::XS;

#local library
#use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'Packages::Events::Event';
use aliased 'Programs::Panelisation::PnlCreator::SchemePnlCreator::LibraryScheme';
use aliased 'Packages::ObjectStorable::JsonStorable::JsonStorable';
use aliased 'Programs::Panelisation::PnlCreator::Helpers::Helper' => "CreatorHelper";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

use constant TaskType_INITCREATOR    => "INIT_CREATOR";
use constant TaskType_PROCESSCREATOR => "PROCESS_CREATOR";

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	# PROPERTIES

	$self->{"jobId"} = shift;

	$self->{"pnlType"} = shift;

	$self->{"backgroundWorker"} = undef;    # helper background worker class

	$self->{"jsonStorable"} = JsonStorable->new();

	$self->{"asyncWorkerSub"} = "__TaskBackgroundFunc";

	# EVENTS

	$self->{"pnlCreatorInitedEvt"}   = Event->new();
	$self->{"pnlCreatorProcesedEvt"} = Event->new();
	$self->{"asyncTaskDieEvt"}       = Event->new();
	$self->{"taskCntChangedEvt"}     = Event->new();

	return $self;
}

sub Init {
	my $self   = shift;
	my $worker = shift;

	# Tell to launcher backround woker will be used

	$self->{"backgroundWorker"} = $worker;

	$self->{"backgroundWorker"}->{"thrStartEvt"}->Add( sub       { $self->__OnTaskStartHndl(@_) } );
	$self->{"backgroundWorker"}->{"thrFinishEvt"}->Add( sub      { $self->__OnTaskFinishHndl(@_) } );
	$self->{"backgroundWorker"}->{"thrDieEvt"}->Add( sub         { $self->__OnTaskDieHndl(@_) } );
	$self->{"backgroundWorker"}->{"thrAbortEvt"}->Add( sub       { $self->__OnTaskDieHndl(@_) } );
	$self->{"backgroundWorker"}->{"thrPogressInfoEvt"}->Add( sub { $self->__OnTaskProgressInfoHndl(@_) } );
	$self->{"backgroundWorker"}->{"thrMessageInfoEvt"}->Add( sub { $self->__OnTaskMessageInfoHndl(@_) } );

	$self->{"backgroundWorker"}->{"taskCntChangedEvt"}->Add( sub { $self->{"taskCntChangedEvt"}->Do(@_) } );

}

# Raise "pnlCreatorInitedEvt" event, which will contain Creator Model data
sub AsyncInitPnlCreator {
	my $self       = shift;
	my $partId     = shift;
	my $creatorKey = shift;
	my $initParams = shift;    # array ref

	my $taskId     = $creatorKey . "_" . TaskType_INITCREATOR;
	my @taskParams = ();
	push( @taskParams, TaskType_INITCREATOR );
	push( @taskParams, $self->{"jobId"} );
	push( @taskParams, $self->{"pnlType"} );
	push( @taskParams, $partId );
	push( @taskParams, $creatorKey );
	push( @taskParams, $initParams );

	$self->{"backgroundWorker"}->AddTaskSerial( $taskId, \@taskParams, $self->{"asyncWorkerSub"} );

}

# Raise "pnlCreatorProcesedEvt" event, which will contain result succes/failed
sub AsyncProcessPnlCreator {
	my $self        = shift;
	my $partId      = shift;
	my $creatorKey  = shift;
	my $JSONSett    = shift;    # hash of model properties
	my $callReason = shift;    # optional text info - reason of calling  AsyncProcessPnlCreator

	my $taskId     = $creatorKey . "_" . TaskType_PROCESSCREATOR;
	my @taskParams = ();

	push( @taskParams, TaskType_PROCESSCREATOR );
	push( @taskParams, $self->{"jobId"} );
	push( @taskParams, $self->{"pnlType"} );
	push( @taskParams, $partId );
	push( @taskParams, $creatorKey );
	push( @taskParams, $JSONSett );
	push( @taskParams, $callReason );

	$self->{"backgroundWorker"}->AddTaskSerial( $taskId, \@taskParams, $self->{"asyncWorkerSub"} );

}

sub GetCurrentTasksCnt {
	my $self = shift;

	return $self->{"backgroundWorker"}->GetCurrentTasks();

}

#sub GetInitCreatorTaskCnt {
#	my $self = shift;
#	GetInitCreatorTaskCnt
#
#	  my $t = TaskType_INITCREATOR;
#
#	my @tasks = grep { $_ =~ /$t/ } $self->{"backgroundWorker"}->GetCurrentTasks();
#
#	return scalar(@tasks);
#
#}

#-------------------------------------------------------------------------------------------#
#  Background function (runing in child thread)
#-------------------------------------------------------------------------------------------#

sub __TaskBackgroundFunc {
	my $taskId            = shift;
	my $taskParams        = shift;
	my $inCAM             = shift;
	my $thrPogressInfoEvt = shift;
	my $thrMessageInfoEvt = shift;

	my $jsonStorable = JsonStorable->new();

	my $taskType   = shift @{$taskParams};
	my $jobId      = shift @{$taskParams};
	my $pnlType    = shift @{$taskParams};
	my $partId     = shift @{$taskParams};
	my $creatorKey = shift @{$taskParams};

	my $creator = CreatorHelper->GetPnlCreatorByKey( $jobId, $pnlType, $creatorKey );

	if ( $taskType eq TaskType_INITCREATOR ) {

		my @creatorInitParams = @{ shift @{$taskParams} };

		my $result = $creator->Init( $inCAM, @creatorInitParams );

		my $JSONSett = $creator->ExportSettings();

		# Create JSON message
		my %res = ();
		$res{"taskType"}     = $taskType;
		$res{"partId"}       = $partId;
		$res{"creatorKey"}   = $creatorKey;
		$res{"JSONSettings"} = $JSONSett;
		$res{"result"}       = $result;

		my $JSONMess = $jsonStorable->Encode( \%res );

		$thrMessageInfoEvt->Do( $taskId, $JSONMess );

	}
	elsif ( $taskType eq TaskType_PROCESSCREATOR ) {

		my $creatorJSONSett = shift @{$taskParams};
		my $callReason     = shift @{$taskParams};

		$creator->ImportSettings($creatorJSONSett);

		my $errMess = "";
		my $result  = 0;

		if ( $creator->Check( $inCAM, \$errMess ) ) {

			$result = $creator->Process( $inCAM, \$errMess );

			# Zoom
			$inCAM->COM('zoom_home');

		}
		else {
			$result = 0;
		}

		# Create JSON message
		my %res = ();
		$res{"taskType"}    = $taskType;
		$res{"partId"}      = $partId;
		$res{"creatorKey"}  = $creatorKey;
		$res{"result"}      = $result;
		$res{"errMess"}     = $errMess;
		$res{"callReason"} = $callReason;

		my $JSONMess = $jsonStorable->Encode( \%res );

		$thrMessageInfoEvt->Do( $taskId, $JSONMess );

	}

}

#-------------------------------------------------------------------------------------------#
#  Private method
#-------------------------------------------------------------------------------------------#

#sub __ModelSettings2CreatorSettings {
#	my $self       = shift;
#	my $creatorKey = shift;
#	my $JSONSettings  = shift;
#
#	# Get creator object
#	my $creator = $self->__GetPnlCreatorByKey( $creatorKey);
#
#	# CHeck if model data and creatod settings has same "keys"
#
#	$creator->ImportSettings($JSONSettings);
#
#	my $JSONSett = $creator->ExportSettings();
#
#	return $JSONSett;
#}
#
#sub __CreatorSettings2ModelSettings {
#	my $self       = shift;
#	my $creatorKey = shift;
#	my $JSONSett   = shift;
#
#	# Get creator object
#	my $creator = $self->__GetPnlCreatorByKey( $creatorKey);
#
#	# CHeck if model data and creatod settings has same "keys"
#
#	$creator->ImportSettings($JSONSett);
#
#	my $modelData = $creator->{"settings"};
#
#	return $modelData;
#}

#-------------------------------------------------------------------------------------------#
#  Background woker handlers
#-------------------------------------------------------------------------------------------#

sub __OnTaskStartHndl {
	my $self   = shift;
	my $taskId = shift;

	print STDERR "Asynchronous task ($taskId) START. Handler in BackroundTaskMngr.\n";

}

sub __OnTaskFinishHndl {
	my $self   = shift;
	my $taskId = shift;

	print STDERR "Asynchronous task ($taskId) FINISH. Handler in BackroundTaskMngr.\n";

}

sub __OnTaskProgressInfoHndl {
	my $self   = shift;
	my $taskId = shift;

	print STDERR "Asynchronous task ($taskId) PROGRESS. Handler in BackroundTaskMngr.\n";

}

sub __OnTaskDieHndl {
	my $self    = shift;
	my $taskId  = shift;
	my $errMess = shift;

	$self->{"asyncTaskDieEvt"}->Do( $taskId, $errMess );

	print STDERR "Asynchronous task ($taskId) END with error: $errMess. Handler in BackroundTaskMngr.\n";

}

sub __OnTaskMessageInfoHndl {
	my $self        = shift;
	my $taskId      = shift;
	my $messageJSON = shift;

	print STDERR "Asynchronous task ($taskId) SEND MESSAGE. Handler in BackroundTaskMngr.\n";

	my %message = %{ $self->{"jsonStorable"}->Decode($messageJSON) };

	my $taskType   = $message{"taskType"};
	my $partId     = $message{"partId"};
	my $creatorKey = $message{"creatorKey"};

	if ( $taskType eq TaskType_INITCREATOR ) {
		my $result   = $message{"result"};
		my $JSONSett = $message{"JSONSettings"};

		#		my $modelData = $self->__CreatorSettings2ModelSettings( $creatorKey, $JSONSett );

		$self->{"pnlCreatorInitedEvt"}->Do( $partId, $creatorKey, $result, $JSONSett )

	}
	elsif ( $taskType eq TaskType_PROCESSCREATOR ) {

		my $result      = $message{"result"};
		my $errMess     = $message{"errMess"};
		my $callReason = $message{"callReason"};

		$self->{"pnlCreatorProcesedEvt"}->Do( $partId, $creatorKey, $result, $errMess, $callReason )

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
