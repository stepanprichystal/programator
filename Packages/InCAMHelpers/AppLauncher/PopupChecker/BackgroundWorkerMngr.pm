
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::InCAMHelpers::AppLauncher::PopupChecker::BackgroundWorkerMngr;

# Abstract class #

#3th party library
use strict;
use warnings;
use JSON::XS;

#local library
use aliased 'Enums::EnumsGeneral';

#use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'Packages::Events::Event';
use aliased 'Packages::ObjectStorable::JsonStorable::JsonStorable';
use aliased 'Packages::ItemResult::ItemResult';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

use constant MessType_CLASSCHECKERR   => "messType_ClassCheckErr";
use constant MessType_CLASSCHECKSTART => "messType_ClassCheckStart";
use constant MessType_CLASSCHECKEND   => "messType_ClassCheckEnd";

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	# PROPERTIES

	$self->{"jobId"} = shift;

	$self->{"backgroundWorker"} = undef;    # helper background worker class

	$self->{"jsonStorable"} = JsonStorable->new();

	$self->{"asyncWorkerSub"} = "__TaskBackgroundFunc";

	$self->{"checkTaskId"} = "checker";

	# EVENTS

	$self->{"checkStartEvt"}  = Event->new();
	$self->{"checkFinishEvt"} = Event->new();
	$self->{"checkDieEvt"}    = Event->new();    # check task end with error
	$self->{"checkAbortEvt"}  = Event->new();    # aborted thread on purpose

	$self->{"checkClassStartEvt"} = Event->new();
	$self->{"checkClassEndEvt"}   = Event->new();
	$self->{"checkClassErrEvt"}   = Event->new();

	return $self;
}

sub Init {
	my $self   = shift;
	my $worker = shift;

	# Tell to launcher backround woker will be used

	$self->{"backgroundWorker"} = $worker;
	#
	$self->{"backgroundWorker"}->{"thrStartEvt"}->Add( sub       { $self->__OnTaskStartHndl(@_) } );
	$self->{"backgroundWorker"}->{"thrFinishEvt"}->Add( sub      { $self->__OnTaskFinishHndl(@_) } );
	$self->{"backgroundWorker"}->{"thrDieEvt"}->Add( sub         { $self->__OnTaskDieHndl(@_) } );
	$self->{"backgroundWorker"}->{"thrAbortEvt"}->Add( sub       { $self->__OnTaskAbortHndl(@_) } );
	$self->{"backgroundWorker"}->{"thrPogressInfoEvt"}->Add( sub { $self->__OnTaskProgressInfoHndl(@_) } );
	$self->{"backgroundWorker"}->{"thrMessageInfoEvt"}->Add( sub { $self->__OnTaskMessageInfoHndl(@_) } );

}

# Raise "pnlCreatorInitedEvt" event, which will contain Creator Model data
sub CheckClasses {
	my $self         = shift;
	my $checkClasses = shift;

	my @taskParams = ();

	# job Id
	push( @taskParams, $self->{"jobId"} );

	# JSON requested class
	my $checkClassesJSON = $self->{"jsonStorable"}->Encode($checkClasses);
	push( @taskParams, $checkClassesJSON );

	$self->{"backgroundWorker"}->AddTaskSerial( $self->{"checkTaskId"}, \@taskParams, $self->{"asyncWorkerSub"} );

}

sub StopChecking {
	my $self = shift;

	$self->{"backgroundWorker"}->AbortTask( $self->{"checkTaskId"} );
}

#-------------------------------------------------------------------------------------------#
#  Background function (runing in child thread)
#-------------------------------------------------------------------------------------------#

sub __TaskBackgroundFunc {
	my $taskId            = shift;
	my $taskParams        = shift;
	my $inCAM             = shift;
	my $thrPogressInfoEvt = shift;
	my $thrMessageInfoEvt = shift;

	my $jobId            = shift @{$taskParams};
	my $checkClassesJSON = shift @{$taskParams};

	my $jsonStorable = JsonStorable->new();

	my @checkClasses = @{ $jsonStorable->Decode($checkClassesJSON) };

	# Init helper message mngr

	# Init all check classes
	foreach my $classInf (@checkClasses) {

		my $checkClassId              = $classInf->{"checkClassId"};
		my $checkClassPackage         = $classInf->{"checkClassPackage"};
		my $checkClassTitle           = $classInf->{"checkClassTitle"};
		my $checkClassConstrData = $classInf->{"checkClasConstructorData"};
		my $checkClassCheckData       = $classInf->{"checkClassCheckData"};

		# raise start event
		my %infoStart = ();
		$infoStart{"messageType"}  = MessType_CLASSCHECKSTART;
		$infoStart{"checkClassId"} = $checkClassId;
		$thrMessageInfoEvt->Do( $taskId, $jsonStorable->Encode( \%infoStart ) );

		# Do checks
		my $classObj = $checkClassPackage->new( $inCAM, $jobId, @{$checkClassConstrData} );

		$classObj->{'onItemResult'}->Add( sub { __OnItemResultHndl( $taskId, $thrMessageInfoEvt, $checkClassId, @_ ) } );

		eval {

			$classObj->Check( @{$checkClassCheckData} );

		};
		if ( my $e = $@ ) {

			# Catch all die in check script and process as regular errror
			my $itemRes = ItemResult->new("Checkscript unexepected die");
			$itemRes->AddError($e);

			__OnItemResultHndl( $taskId, $thrMessageInfoEvt, $checkClassId, $itemRes );
		}

	}
}

#-------------------------------------------------------------------------------------------#
#  Private method
#-------------------------------------------------------------------------------------------#

sub __OnItemResultHndl {
	my $taskId            = shift;
	my $thrMessageInfoEvt = shift;
	my $checkClassId      = shift;
	my $itemResult        = shift;

	my %res = ();
	$res{"messageType"}  = MessType_CLASSCHECKERR;
	$res{"checkClassId"} = $checkClassId;

	if ( $itemResult->GetWarningCount() ) {

		$res{"errType"} = EnumsGeneral->MessageType_WARNING;
		$res{"errMess"} = $itemResult->GetWarningStr();
	}

	if ( $itemResult->GetErrorCount() ) {

		$res{"errType"} = EnumsGeneral->MessageType_ERROR;
		$res{"errMess"} = $itemResult->GetErrorStr();
	}

	my $jsonStorable = JsonStorable->new();
	my $JSONMess     = $jsonStorable->Encode( \%res );

	$thrMessageInfoEvt->Do( $taskId, $JSONMess );

}

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

	$self->{"checkStartEvt"}->Do($taskId);

}

sub __OnTaskFinishHndl {
	my $self   = shift;
	my $taskId = shift;

	$self->{"checkFinishEvt"}->Do($taskId);

}

sub __OnTaskProgressInfoHndl {
	my $self   = shift;
	my $taskId = shift;

}

sub __OnTaskDieHndl {
	my $self    = shift;
	my $taskId  = shift;
	my $errMess = shift;

	$self->{"checkDieEvt"}->Do( $taskId, $errMess );
}

sub __OnTaskAbortHndl {
	my $self   = shift;
	my $taskId = shift;

	$self->{"checkAbortEvt"}->Do($taskId);
}

sub __OnTaskMessageInfoHndl {
	my $self        = shift;
	my $taskId      = shift;
	my $messageJSON = shift;

	my %message = %{ $self->{"jsonStorable"}->Decode($messageJSON) };

	my $messageType  = $message{"messageType"};
	my $checkClassId = $message{"checkClassId"};

	if ( $messageType eq MessType_CLASSCHECKERR ) {

		my $errType = $message{"errType"};
		my $errMess = $message{"errMess"};

		$self->{"checkClassErrEvt"}->Do( $checkClassId, $errType, $errMess )

	}
	elsif ( $messageType eq MessType_CLASSCHECKSTART ) {

		$self->{"checkClassStartEvt"}->Do($checkClassId);
	}
	elsif ( $messageType eq MessType_CLASSCHECKEND ) {

		$self->{"checkClassEndEvt"}->Do($checkClassId);
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
