
#-------------------------------------------------------------------------------------------#
# Description: Helper pro obecne operace se soubory
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

#use aliased 'Enums::EnumsGeneral';
#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

my $THREAD_PROGRESS_EVT : shared;
my $THREAD_MESSAGE_EVT : shared;
my $THREAD_DONE_EVT : shared;
my $THREAD_END_EVT : shared;

sub new {

	my $self = shift;    # Create an anonymous hash, and #self points to it.
	$self = {};
	bless $self;         # Connect the hash to the package Cocoa.

	my @threads = ();

	$self->{"threads"} = \@threads;

	#events
	$self->{"onThreadWorker"} = Event->new();
	                     #raise when new thread start

	#$self->{"maxCntUser"}      = 2;

	return $self;        # Return the reference to the hash.
}

sub Init {
	my $self = shift;

	$self->{"exporterFrm"} = shift;

	$THREAD_PROGRESS_EVT   = ${ shift(@_) };
	$THREAD_MESSAGE_EVT    = ${ shift(@_) };
	$THREAD_DONE_EVT = ${ shift(@_) };

	$THREAD_END_EVT = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"exporterFrm"}, -1, $THREAD_END_EVT, sub { $self->__ThreadEndedHandler(@_) } );

}

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

				#				while ( $thrObj->is_running() ) {
				#
				#					$thrObj = threads->object( $thr->{"thrId"} );
				#					my $run = $thrObj->is_running();
				#
				#					print "$run.??";
				#
				#					sleep(0.1);
				#				}
			}
			else {

				#nastala nejaka chyba, thread uy asi nebezi. Ukoncim natvrdo
				$self->__ThreadEnded( $jobGUID, Enums->ExitType_FORCE );
			}

			#$self->__ThreadEnded($thrId, Enums->ExitType_FORCE, $thrObj );
			#print "\nThread skoncil FORCE\n";

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
	$worker->set_thread_exit_only(1);

	return $worker->tid();
}

sub __WorkerMethod {
	my $self = shift;

	my $jobGUID = shift;
	my $port    = shift;
	my $pcbId   = shift;

	use aliased 'Packages::InCAM::InCAM';
	print 1;
	
	#require Win32::OLE;
	#import Win32::OLE qw(in);
	
	# TODO odkomentovat
	my $inCAM = InCAM->new( "remote" => 'localhost', "port" => $port );
	#my $inCAM = undef;
	$inCAM->ServerReady();

	$SIG{'KILL'} = sub {

		$self->__CleanUpAndExit( $inCAM, $jobGUID, Enums->ExitType_FORCE );

		exit;    #exit onlz this thread

	};

	#$selfMain->{"threadBaseMethod"}->($pcbId,$jobGUID, $inCAM, \$THREAD_PROGRESS_EVT);

	my $onThreadWorker = $self->{'onThreadWorker'};
	if ( $onThreadWorker->Handlers() ) {
		$onThreadWorker->Do( $pcbId, $jobGUID, $inCAM, \$THREAD_PROGRESS_EVT, \$THREAD_MESSAGE_EVT );
	}

	#$selfMain->{"threadWorker"}->($pcbId,$jobGUID, $inCAM);

	#$JobExport->Init( $self->{"mainFrm"}, \$THREAD_PROGRESS_EVT, \$THREAD_MESSAGE_EVT, \$THREAD_DONE_EVT );

	#run export method

	#$JobExport->RunThread();
	#$refAction->{"action"}->($self)

	#doExport( $port, $pcbId );

	#try {

	#print "Thread port $port is sleeping\n";

	#	  } catch {
	#		my $e = $_;
	#		my $mess;

	#			my $errorType = undef;
	#
	#			if ( ref($e) && $e->isa("Packages::Exceptions::InCamException") ) {
	#				$errorType = "InCAM";
	#			}
	#			elsif ( ref($e) && $e->isa("Packages::Exceptions::HeliosException") ) {
	#				$errorType = "Helios";
	#			}
	#			else {
	#				$errorType = "Scripting";
	#			}

	#	}

	#my %result : shared = (
	#						"port"  => $port,
	#						"pcbId" => $pcbId
	#);

	#	my %res : shared = ();
	#	for ( my $i = 0 ; $i < 50 ; $i++ ) {
	#
	#		$res{"jobGUID"} = $jobGUID;
	#		$res{"port"}    = $port;
	#		$res{"value"}   = $i;
	#
	#		my $threvent2 = new Wx::PlThreadEvent( -1, $THREAD_PROGRESS_EVT, \%res );
	#		Wx::PostEvent( $selfMain->{"exporterFrm"}, $threvent2 );
	#
	#		sleep(1);
	#	}

	$self->__CleanUpAndExit( $inCAM, $jobGUID, Enums->ExitType_SUCCES );

	#print "wooker method end\n";
	#print 1;
	#print 2;

}

sub __CleanUpAndExit {
	my ( $selfMain, $inCAM, $jobGUID, $exitType ) = @_;

	#Win32::OLE->Uninitialize();

	$inCAM->ClientFinish();

	my %resExit : shared = ();
	$resExit{"jobGUID"}  = $jobGUID;
	$resExit{"thrId"}    = threads->tid();
	$resExit{"exitType"} = $exitType;

	my $threvent2 = new Wx::PlThreadEvent( -1, $THREAD_END_EVT, \%resExit );
	Wx::PostEvent( $selfMain->{"exporterFrm"}, $threvent2 );

}

sub doExport {
	my ( $port, $id ) = @_;

	my $inCAM = InCAM->new( 'localhost', $port );

	my $errCode = $inCAM->COM( "clipb_open_job", job => $id, update_clipboard => "view_job" );

	#
	#	$errCode = $inCAM->COM(
	#		"open_entity",
	#		job  => "F17116+2",
	#		type => "step",
	#		name => "test"
	#	);

	#return 0;
	for ( my $i = 0 ; $i < 5 ; $i++ ) {

		sleep(3);
		$inCAM->COM(
					 'output_layer_set',
					 layer        => "c",
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
					 dir_path             => "c:/Perl/site/lib/TpvScripts/Scripts/data",
					 prefix               => "incam1_" . $id . "_$i",
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

sub __ThreadEnded {
	my ( $self, $jobGUID, $exitType ) = @_;

	#my $thrObj = threads->object( $thrId );

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

	#print "\nThread skoncil uspecne\n";
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

