
#-------------------------------------------------------------------------------------------#
# Description: Class which manage export checker popup form
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::ExportChecker::ExportPopup;

#3th party library
#use strict;
use warnings;
use threads;
use threads::shared;
use Wx;
use Try::Tiny;

#use strict;

#local library

use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Forms::ExportPopupForm';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';
use aliased 'Packages::Events::Event';
use aliased 'Packages::Exceptions::BaseException';
use aliased 'Packages::ItemResult::ItemResultMngr';
use aliased 'Packages::ItemResult::Enums' => "ItemResEnums";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
my $CHECKER_START_EVT : shared;
my $CHECKER_END_EVT : shared;
my $CHECKER_ERROR_EVT : shared;

#my $CHECKER_FINISH_EVT : shared;
my $THREAD_FORCEEXIT_EVT : shared;

# ================================================================================
# PUBLIC METHOD
# ================================================================================

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"jobId"} = shift;

	$self->{"inCAM"} = undef;

	$self->{"units"} = undef;

	$self->{"parentForm"} = undef;

	#Events
	$self->{"onResultEvt"} = Event->new();
	$self->{'onClose'}     = Event->new();

	return $self;
}

sub Init {
	my $self = shift;

	# Synchronous/Asznchronous mode
	$self->{"mode"} = shift;

	# 1 = client send export to TPV server
	$self->{"onServer"} = shift;

	$self->{"units"} = shift;

	$self->{"parentForm"} = shift;

	# Main application form
	$self->{"popup"} = ExportPopupForm->new( $self->{"parentForm"}->{"mainFrm"}, $self->{"jobId"}, $self->{"onServer"} );

	#set group count for popup form
	$self->{"popup"}->SetGroupCnt( $self->{"units"}->GetActiveUnitsCnt() );

	$self->__SetHandlers();

}

sub CheckBeforeExport {
	my $self       = shift;
	my $serverPort = shift;

	my $inCAM = $self->{"inCAM"};
	$self->{"popup"}->ShowPopup();

	#start new process, where check job before export
	my $worker = threads->create( sub { $self->__CheckAsyncWorker( $self->{"jobId"}, $serverPort, $self->{"units"}, $self->{"mode"} ) } );
	$worker->set_thread_exit_only(1);
	$self->{"threadId"} = $worker->tid();

	# 	for(my $i = 0; $i < 5; $i++){
	# 		sleep(1);
	# 			my $worker1 = threads->create( sub { $self->__CheckAsyncWorker( $self->{"jobId"}, $serverPort, $self->{"units"} ) } );
	#	$worker1->set_thread_exit_only(1);
	#
	# 	}

	#$self->{"threadId"} = $worker->tid();

}

# ================================================================================
# PUBLIC METHOD
# ================================================================================

sub __CheckAsyncWorker {
	my $self = shift;

	my $jobId = shift;
	my $port  = shift;
	my $units = shift;
	my $mode  = shift;

	$export_thread = 1;

	#require ::OLE;
	#import Win32::OLE qw(in);

	my $inCAM = InCAM->new( "remote" => 'localhost', "port" => $port );
	$inCAM->ServerReady();
	
	$SIG{'KILL'} = sub {

		$self->__CleanUpAndExitThread( 1, $inCAM );
		exit;    #exit only this thread, not whole app

	};

	$units->{"onCheckEvent"}->Add( sub { $self->__OnCheckHandler(@_) } );

	try {

		$units->CheckBeforeExport( $inCAM, $mode );

	}
	catch {

		my $eMess = "Export checker thread was unexpectedly exited\n\n";
		my $e = BaseException->new( $eMess, $_ );

		print STDERR $e;

		$self->__OnCheckErrorHandler( $e->Error() );

		$self->__CleanUpAndExitThread( 0, $inCAM );
	};

	$self->__CleanUpAndExitThread( 0, $inCAM );

}

sub __CleanUpAndExitThread {
	my $self  = shift;
	my $force = shift;
	my $inCAM = shift;

	#this is necessary do, when thread exit, because Win32::OLE is not thread safe
	#Win32::OLE->Uninitialize();

	$inCAM->ClientFinish();

	# if process was exited force, let it know
	if ($force) {
		print "Thread killed force\n";
		my %res : shared = ();
		my $threvent = new Wx::PlThreadEvent( -1, $THREAD_FORCEEXIT_EVT, \%res );

		Wx::PostEvent( $self->{"popup"}->{"mainFrm"}, $threvent );

	}
}

# ================================================================================
#  HANDLERS
# ================================================================================

sub __OnStopPopupHandler {
	my $self = shift;

	#stop process
	my $thrObj = threads->object( $self->{"threadId"} );

	print "Print thread object: $thrObj is runing : " . $thrObj->is_running() . " \n";

	if ( defined $thrObj ) {

		if ( $thrObj->is_running() ) {
			$thrObj->kill('KILL');
		}
	}

}

sub __OnClosePopupHandler {
	my $self = shift;

	$self->{'onClose'}->Do();

}

sub __OnResultPopupHandler {
	my $self       = shift;
	my $resultType = shift;

	if (    $resultType eq Enums->PopupResult_EXPORTFORCE
		 || $resultType eq Enums->PopupResult_SUCCES )
	{

		#start exporting

	}
	elsif ( $resultType eq Enums->PopupResult_CHANGE ) {

		#do nothing

	}

	$self->{"onResultEvt"}->Do( $resultType, $self->{"mode"}, $self->{"onServer"} );

}

sub __CheckerForceExitHandler {
	my ( $self, $frame, $event ) = @_;

	#my %d = %{ $event->GetData };
	print "Thread killed succ\n";

	$self->{"popup"}->ThreadExited();

}

# this is controlled by main process
sub __CheckerStartMessageHandler {
	my ( $self, $frame, $event ) = @_;

	my %d = %{ $event->GetData };

	$self->{"popup"}->StartChecking( $d{"group"} );

}

# this is controlled by main process
sub __CheckerEndMessageHandler {
	my ( $self, $frame, $event ) = @_;

	my %d = %{ $event->GetData };

	# fill data - errors
	my @errors    = ();
	my @e         = ();
	my @errTxt    = @{ $d{"errors"} };
	my @errItemId = @{ $d{"errorsItemId"} };

	for ( my $i = 0 ; $i < scalar(@errTxt) ; $i++ ) {

		my %info = ();

		$info{"itemId"} = $errItemId[$i];
		$info{"value"}  = $errTxt[$i];
		push( @e, \%info );
	}

	my %errorsInfo = ();
	$errorsInfo{"group"}  = $d{"group"};
	$errorsInfo{"errors"} = \@e;

	# fill data - warnings
	my @warnings   = ();
	my @w          = ();
	my @warnTxt    = @{ $d{"warnings"} };
	my @warnItemId = @{ $d{"warningsItemId"} };

	for ( my $i = 0 ; $i < scalar(@warnTxt) ; $i++ ) {
		my %info = ();
		$info{"itemId"} = $warnItemId[$i];
		$info{"value"}  = $warnTxt[$i];
		push( @w, \%info );
	}

	my %warningInfo = ();
	$warningInfo{"group"}    = $d{"group"};
	$warningInfo{"warnings"} = \@w;

	$self->{"popup"}->EndChecking( \%errorsInfo, \%warningInfo );

}

# this is controlled by main process
sub __CheckerErrorMessageHandler {
	my ( $self, $frame, $event ) = @_;

	my %d = %{ $event->GetData };

	$self->{"popup"}->ErrorChecking( $d{"mess"} );
}

## this is controlled by main process
#sub __CheckerFinishHandler {
#	my ( $self, $frame, $event ) = @_;
#
#
#
#	my %d = %{ $event->GetData };
#
#	my $succes = $d{"result"};
#
#	print "\n\n HEREEE FINISH Checker: $succes\n\n";
#
#	if ($succes) {
#
#	}
#}

#this is raised by child process
sub __OnCheckHandler {
	my $self = shift;
	my $type = shift;            # start/end
	my %info = %{ shift(@_) };

	my $unit = $info{"unit"};

	my %res : shared = ();

	$res{"group"} = UnitEnums->GetTitle( $unit->GetUnitId() );

	if ( $type eq "start" ) {

		my $threvent = new Wx::PlThreadEvent( -1, $CHECKER_START_EVT, \%res );
		Wx::PostEvent( $self->{"popup"}->{"mainFrm"}, $threvent );
	}
	elsif ( $type eq "end" ) {

		my $resultMngr = $info{"resultMngr"};

		my @errors   = $resultMngr->GetErrors();
		my @warnings = $resultMngr->GetWarnings();

		# fill errors data
		my @err : shared       = ();
		my @errItemId : shared = ();
		$res{"errors"}       = \@err;
		$res{"errorsItemId"} = \@errItemId;

		foreach my $e (@errors) {
			push( @{ $res{"errorsItemId"} }, $e->{"itemId"} );
			push( @{ $res{"errors"} },       $e->{"value"} );
		}

		# fill warnings data
		my @warn : shared       = ();
		my @warnItemId : shared = ();
		$res{"warnings"}       = \@warn;
		$res{"warningsItemId"} = \@warnItemId;

		foreach my $w (@warnings) {
			push( @{ $res{"warningsItemId"} }, $w->{"itemId"} );
			push( @{ $res{"warnings"} },       $w->{"value"} );
		}

		my $threvent = new Wx::PlThreadEvent( -1, $CHECKER_END_EVT, \%res );
		Wx::PostEvent( $self->{"popup"}->{"mainFrm"}, $threvent );
	}

}

sub __OnCheckErrorHandler {
	my $self    = shift;
	my $errMess = shift;    # start/end

	my %res : shared = ();
	$res{"mess"} = $errMess;

	my $threvent = new Wx::PlThreadEvent( -1, $CHECKER_ERROR_EVT, \%res );
	Wx::PostEvent( $self->{"popup"}->{"mainFrm"}, $threvent );
}

# ================================================================================
# PRIVATE METHODS
# ================================================================================

sub __SetHandlers {
	my $self = shift;

	$self->{"popup"}->{"onStopClickEvt"}->Add( sub { $self->__OnStopPopupHandler(@_) } );
	$self->{"popup"}->{"onResultEvt"}->Add( sub    { $self->__OnResultPopupHandler(@_) } );
	$self->{"popup"}->{'onClose'}->Add( sub        { $self->__OnClosePopupHandler(@_) } );

	# Events when group is in the end of checking
	$CHECKER_END_EVT = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"popup"}->{"mainFrm"}, -1, $CHECKER_END_EVT, sub { $self->__CheckerEndMessageHandler(@_) } );

	# Events when group is on the start of checking
	$CHECKER_START_EVT = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"popup"}->{"mainFrm"}, -1, $CHECKER_START_EVT, sub { $self->__CheckerStartMessageHandler(@_) } );

	# Events when export checker fail
	$CHECKER_ERROR_EVT = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"popup"}->{"mainFrm"}, -1, $CHECKER_ERROR_EVT, sub { $self->__CheckerErrorMessageHandler(@_) } );

	# Events when user stop checking force
	$THREAD_FORCEEXIT_EVT = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"popup"}->{"mainFrm"}, -1, $THREAD_FORCEEXIT_EVT, sub { $self->__CheckerForceExitHandler(@_) } );

	# Events when checking of all groups is finished
	#$CHECKER_FINISH_EVT = Wx::NewEventType;
	#Wx::Event::EVT_COMMAND( $self->{"popup"}->{"mainFrm"}, -1, $CHECKER_FINISH_EVT, sub { $self->__CheckerFinishHandler(@_) } );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::ExportChecker';

	#my $form = ExportChecker->new();

}

1;

