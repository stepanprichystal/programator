
#-------------------------------------------------------------------------------------------#
# Description:  Reorder app which check and proces reorders
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ReorderApp::ReorderApp;

#3th party library
use strict;
use warnings;
use threads;
use threads::shared;
use Wx;

#local library
use aliased 'Packages::Reorder::ReorderApp::Forms::ReorderAppFrm';
use aliased 'Packages::Reorder::CheckReorder::CheckReorder';
use aliased 'Packages::Reorder::ProcessReorder::ProcessReorder';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Reorder::ReorderApp::Enums';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsIS';
use aliased 'Packages::Reorder::ReorderApp::ReorderPopup';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

my $CHECK_EVT : shared;        #evt reise when check progress
my $CHECK_END_EVT : shared;    # evt raise when checking is done

# ================================================================================
# PUBLIC METHOD
# ================================================================================

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"jobId"} = shift;

	# PROPERTIES

	# InCAM library
	$self->{"inCAM"} = undef;

	# Launcher, helper, which do connection to InCAm editor
	$self->{"launcher"} = undef;

	# Affected orders
	my @orders = HegMethods->GetPcbReorders( $self->{"jobId"} );
	@orders = grep { $_->{"aktualni_krok"} eq EnumsIS->CurStep_ZPRACOVANIMAN || $_->{"aktualni_krok"} eq EnumsIS->CurStep_CHECKREORDERERROR } @orders;
	$self->{"orders"} = \@orders;

	# Main form of app
	$self->{"form"} = ReorderAppFrm->new( -1, $self->{"jobId"}, $self->{"orders"} );

	# Popup form
	$self->{"reorderPopup"} = ReorderPopup->new( $self->{"jobId"}, $self->{"form"}, $self->{"orders"} );

	# if no order has aktualni_krok zpracovani-rucni, it means all has checkReorder-error.
	# Thus allow only proces locally

	$self->{"onlyLocally"} = scalar( grep { $_->{"aktualni_krok"} eq EnumsIS->CurStep_CHECKREORDERERROR } @orders ) ? 1 : 0;

	$self->{"manChanges"} = [];    # not processed manual changes

	$self->{"manChangesCritic"} = [];    # not processed manual changes - critical

	return $self;
}

sub Init {
	my $self     = shift;
	my $launcher = shift;

	$self->{"launcher"} = $launcher;
	$self->{"inCAM"}    = $launcher->GetInCAM();

	#set handlers for main app form
	$self->__SetHandlers();

}

sub Run {
	my $self = shift;

	# Do check asynchrounously

	$self->{"form"}->{"mainFrm"}->Show(1);

	$self->__DoChecks();

	$self->{"form"}->MainLoop();

}

# ================================================================================
# FORM HANDLERS
# ================================================================================

sub __OnErrIndicatorHandler {
	my $self = shift;

	my $messMngr = $self->{"form"}->_GetMessageMngr();

	if ( scalar( @{ $self->{"manChanges"} } ) ) {

		my $str = "";

		for ( my $i = 0 ; $i < scalar( @{ $self->{"manChanges"} } ) ; $i++ ) {

			$str .=  ($i+1).")\n".$self->{"manChanges"}->[$i] . "\n\n";

		}

		my @mess = ($str);

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );

		# If user saw errors and there are no critical errorsm enable buttons
		unless ( scalar( @{ $self->{"manChangesCritic"} } ) ) {

			$self->{"form"}->EnableBtnServer(1);
			$self->{"form"}->EnableBtnLocall(1);

			if ( $self->{"onlyLocally"} ) {

				$self->{"form"}->EnableBtnServer(0);
			}
		}
	}

}

sub __OnErrCriticIndicatorHandler {
	my $self = shift;

	my $messMngr = $self->{"form"}->_GetMessageMngr();

	if ( scalar( @{ $self->{"manChangesCritic"} } ) ) {

		my $str = "";

		for ( my $i = 0 ; $i < scalar( @{ $self->{"manChangesCritic"} } ) ; $i++ ) {

			$str .=  ($i+1).")\n".$self->{"manChangesCritic"}->[$i] . "\n\n";

		}


		my @mess = ($str);

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );
	}

}

sub __OnProcessReorderEvent {
	my $self = shift;
	my $type = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
 

	# 3) show reorder popup

	$self->{"reorderPopup"}->Init( $type, $self->{"launcher"} );
	$self->{"reorderPopup"}->Run();

	return 1;
}

sub __OnClosePopupHandler {
	my $self = shift;

	$self->{"form"}->{"mainFrm"}->Close();

}

# ================================================================================
# PRIVATE METHODS
# ================================================================================

sub __DoChecks {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	$self->{"inCAM"}->ClientFinish();

	#start new process, where check job before export
	my $worker = threads->create( sub { $self->__DoChecksAsyncWorker( $self->{"jobId"}, $self->{"launcher"}->GetServerPort() ) } );
	$worker->set_thread_exit_only(1);
	$self->{"threadId"} = $worker->tid();

}


sub __SetHandlers {
	my $self = shift;

	# Events when group is in the end of checking
	$CHECK_EVT = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"form"}->{"mainFrm"}, -1, $CHECK_EVT, sub { $self->__CheckHandler(@_) } );

	$CHECK_END_EVT = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"form"}->{"mainFrm"}, -1, $CHECK_END_EVT, sub { $self->__CheckEndHandler(@_) } );

	$self->{"form"}->{"errIndClickEvent"}->Add( sub       { $self->__OnErrIndicatorHandler(@_) } );
	$self->{"form"}->{"errCriticIndClickEvent"}->Add( sub { $self->__OnErrCriticIndicatorHandler(@_) } );

	$self->{"form"}->{"processReorderEvent"}->Add( sub { $self->__OnProcessReorderEvent(@_) } );

	$self->{"reorderPopup"}->{'onClose'}->Add( sub { $self->__OnClosePopupHandler(@_) } )

}


sub __CheckHandler {
	my ( $self, $frame, $event ) = @_;

	my %d = %{ $event->GetData };

	# Data from worker thread

	my @changeMess  = @{ $d{"changesMess"} };
	my @changeType  = @{ $d{"changesType"} };
	my $progressVal = $d{"progress"} * 100;

	# 1) Updata not processed manual changes

	for ( my $i = 0 ; $i < scalar(@changeMess) ; $i++ ) {

		if ( $changeType[$i] == 1 ) {

			push( @{ $self->{"manChangesCritic"} }, $changeMess[$i] );

		}
		else {
			push( @{ $self->{"manChanges"} }, $changeMess[$i] );
		}
	}

	$self->{"form"}->SetErrIndicator( scalar( @{ $self->{"manChanges"} } ) );
	$self->{"form"}->SetErrCriticIndicator( scalar( @{ $self->{"manChangesCritic"} } ) );

	# 2) update progress bar
	$self->{"form"}->SetGaugeVal($progressVal);

}

sub __CheckEndHandler {
	my $self = shift;

	# Reconnect again InCAM, after  was used by child thread
	$self->{"inCAM"}->Reconnect();

	# Set progress bar
	$self->{"form"}->SetGaugeVal(100);

	if ( scalar( @{ $self->{"manChanges"} } ) || scalar( @{ $self->{"manChangesCritic"} } ) ) {

		$self->{"form"}->EnableBtnServer(0);
		$self->{"form"}->EnableBtnLocall(0);
	}
	else {

		$self->{"form"}->EnableBtnServer(1);
		$self->{"form"}->EnableBtnLocall(1);

		if ( $self->{"onlyLocally"} ) {
			$self->{"form"}->EnableBtnServer(0);
		}
	}
}

# ================================================================================
# Async woker method
# ================================================================================
sub __DoChecksAsyncWorker {
	my $self       = shift;
	my $jobId      = shift;
	my $serverPort = shift;

	my $inCAM = InCAM->new( "remote" => 'localhost', "port" => $serverPort );
	$inCAM->ServerReady();

	my $ch = CheckReorder->new( $inCAM, $jobId );
	$self->{"total"} = $ch->GetItemCnt();

	$self->{"processed"} = 0;

	$ch->{"onItemResult"}->Add( sub { $self->__OnCheckHandler( @_, ); } );

	my @arr = $ch->RunChecks();

	my %res : shared = ();

	$inCAM->ClientFinish();

	my $threvent = new Wx::PlThreadEvent( -1, $CHECK_END_EVT, \%res );
	Wx::PostEvent( $self->{"form"}->{"mainFrm"}, $threvent );

}

#this is raised by child process
sub __OnCheckHandler {
	my $self     = shift;
	my $itemRes  = shift;
	my $progress = shift;    # start/end

	$self->{"processed"}++;

	my @changes = @{ $itemRes->GetData() };

	my %res : shared = ();
	$res{"progress"} = $self->{"processed"} / $self->{"total"};

	# fill errors data
	my @changeMess : shared = ();
	my @changeType : shared = ();
	$res{"changesMess"} = \@changeMess;
	$res{"changesType"} = \@changeType;

	foreach my $ch (@changes) {
		push( @{ $res{"changesMess"} }, $ch->{"text"} );
		push( @{ $res{"changesType"} }, $ch->{"critical"} );
	}

	my $threvent = new Wx::PlThreadEvent( -1, $CHECK_EVT, \%res );
	Wx::PostEvent( $self->{"form"}->{"mainFrm"}, $threvent );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::ReorderApp::ReorderApp';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52457";

	my $app = ReorderApp->new($jobId);

	my $launcher = Launcher->new(56753);

	$app->Init($launcher);

	$app->Run();

}

1;

