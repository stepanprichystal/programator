
#-------------------------------------------------------------------------------------------#
# Description: Manager for threads. Keep list of running threads
# Responsilbe for start new, force kill etc..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AsyncJobMngr::ThreadMngr::ThreadMngr;

use threads;
use threads::shared;
use Wx;
use Time::HiRes qw (sleep);

#3th party library
use strict;
use aliased 'Managers::AsyncJobMngr::Enums';
use aliased 'Managers::AsyncJobMngr::Helper';
use aliased 'Packages::Events::Event';

#local library
use aliased 'Packages::InCAM::InCAM';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

my $THREAD_PROGRESS_EVT : shared;
my $THREAD_MESSAGE_EVT : shared;
my $THREAD_DONE_EVT : shared;
my $THREAD_END_EVT : shared;

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	my @threads = ();

	$self->{"threads"} = \@threads;

	#raise when new thread start
	$self->{"onThreadWorker"} = Event->new();

	return $self;
}

sub Init {
	my $self = shift;

	$self->{"exporterFrm"} = shift;

	$THREAD_PROGRESS_EVT = ${ shift(@_) };
	$THREAD_MESSAGE_EVT  = ${ shift(@_) };
	$THREAD_DONE_EVT     = ${ shift(@_) };

	$THREAD_END_EVT = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"exporterFrm"}, -1, $THREAD_END_EVT, sub { $self->__ThreadEndedHandler(@_) } );

}

# Processrequest for starting new thread
sub RunNewExport {
	my $self    = shift;
	my $jobGUID = shift;
	my $port    = shift;
	my $pcbId   = shift;

	my $thrId = $self->__CreateThread( $jobGUID, $port, $pcbId );

	my %thrInfo = (
					"jobGUID" => $jobGUID,
					"thrId"   => $thrId,
					"port"    => $port,
					"pcbId"   => $pcbId
	);

	push( @{ $self->{"threads"} }, \%thrInfo );

	if ($thrId) {
		return 1;
	}
	else {
		return 0;
	}

}

# Process request for force exit of thread
# Responsible for proper aborting
sub ExitThread {
	my $self    = shift;
	my $jobGUID = shift;

	my $thr = ( grep { $_->{"jobGUID"} eq $jobGUID } @{ $self->{"threads"} } )[0];

	if ( defined $thr ) {

		#print $thr->{"thrId"};

		my $thrObj = threads->object( $thr->{"thrId"} );

		if ( defined $thrObj ) {

			my $thrId = $thrObj->tid();

			if ( $thrObj->is_running() ) {

				#$thrObj->detach();

				$thrObj->kill('KILL');

				Helper->Print( "Thread:   port:" . $thr->{"port"} . "...........................try to end thread\n" );

			}
			else {

				#In case, thread already finished
				# This can happend in time, when user abort thread when was running, or thread broke down
				# But in time of this place, thread is alreadz finished
				$self->__ThreadEnded( $jobGUID, Enums->ExitType_FORCE );
			}

			return 1;
		}

		return 0;

	}
}

sub __CreateThread {
	my $self    = shift;
	my $jobGUID = shift;
	my $port    = shift;
	my $pcbId   = shift;

	my $worker = threads->create( sub { $self->__WorkerMethod( $jobGUID, $port, $pcbId ) } );
	$worker->set_thread_exit_only(1); # tell only this child thread will be exited

	return $worker->tid();
}

# This method is called, when new thread starts
# Raise Event, whoch handler should contain "working code"
sub __WorkerMethod {
	my $self = shift;

	my $jobGUID = shift;
	my $port    = shift;
	my $pcbId   = shift;

	# TODO odkomentovat
	my $inCAM = InCAM->new( "remote" => 'localhost', "port" => $port );

	#my $inCAM = undef;
	$inCAM->ServerReady();

	$SIG{'KILL'} = sub {

		$self->__CleanUpAndExit( $inCAM, $jobGUID, Enums->ExitType_FORCE );

		exit;    #exit only this child thread

	};

	my $onThreadWorker = $self->{'onThreadWorker'};
	if ( $onThreadWorker->Handlers() ) {
		$onThreadWorker->Do( $pcbId, $jobGUID, $inCAM, \$THREAD_PROGRESS_EVT, \$THREAD_MESSAGE_EVT );
	}

	$self->__CleanUpAndExit( $inCAM, $jobGUID, Enums->ExitType_SUCCES );

}

sub __CleanUpAndExit {
	my ( $selfMain, $inCAM, $jobGUID, $exitType ) = @_;

	$inCAM->ClientFinish();

	my %resExit : shared = ();
	$resExit{"jobGUID"}  = $jobGUID;
	$resExit{"thrId"}    = threads->tid();
	$resExit{"exitType"} = $exitType;

	my $threvent2 = new Wx::PlThreadEvent( -1, $THREAD_END_EVT, \%resExit );
	Wx::PostEvent( $selfMain->{"exporterFrm"}, $threvent2 );

}

sub __ThreadEnded {
	my ( $self, $jobGUID, $exitType ) = @_;

	for ( my $i = 0 ; $i < scalar( @{ $self->{"threads"} } ) ; $i++ ) {
		if ( @{ $self->{"threads"} }[$i]->{"jobGUID"} eq $jobGUID ) {

			my $thrObj = threads->object( @{ $self->{"threads"} }[$i]->{"thrId"} );

			if ( defined $thrObj ) {
				$thrObj->detach();
				print "\ndetach\n";
			}

			splice @{ $self->{"threads"} }, $i, 1;    #delete thread from list

			my %res : shared = ();
			$res{"jobGUID"}  = $jobGUID;
			$res{"exitType"} = $exitType;

			my $threvent = new Wx::PlThreadEvent( -1, $THREAD_DONE_EVT, \%res );
			Wx::PostEvent( $self->{"exporterFrm"}, $threvent );

			last;
		}

	}

}

sub __ThreadEndedHandler {
	my ( $self, $frame, $event ) = @_;

	my %d = %{ $event->GetData };

	$self->__ThreadEnded( $d{"jobGUID"}, $d{"exitType"} );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $app = MyApp2->new();

	#$app->Test();

	#$app->MainLoop;

}

1;
