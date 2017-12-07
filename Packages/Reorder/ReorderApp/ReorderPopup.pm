
#-------------------------------------------------------------------------------------------#
# Description: Application logic of checking and processing reorder
# Logic for poup form
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ReorderApp::ReorderPopup;

#3th party library
#use strict;
use warnings;
use threads;
use threads::shared;
use Try::Tiny;

#use strict;

#local library

use aliased 'Packages::Reorder::ReorderApp::Forms::ReorderPopupFrm';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::Events::Event';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Reorder::ReorderApp::Enums';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsIS';
use aliased 'Packages::Reorder::ProcessReorder::ProcessReorder';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Unit::Helper' => "UnitHelper";
use aliased 'Programs::Exporter::ExportChecker::Enums'                       => 'CheckerEnums';
use aliased 'CamHelpers::CamHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

my $PROCESS_EVT : shared;        #evt reise when process progress
my $PROCESS_END_EVT : shared;    # evt raise when processing reorder is done

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"jobId"}     = shift;
	$self->{"parentFrm"} = shift;
	$self->{"orders"}    = shift;

	$self->{"inCAM"} = undef;

	$self->{"processErr"} = [];

	#Events
	#$self->{"onResultEvt"} = Event->new();
	$self->{'onClose'} = Event->new();

	$self->{"type"} = undef;    # type of process job locally/on server

	$self->{"isPool"} = HegMethods->GetPcbIsPool( $self->{"jobId"} );

	return $self;
}

sub Init {
	my $self = shift;
	$self->{"type"}     = shift;
	$self->{"launcher"} = shift;

	$self->{"inCAM"} = $self->{"launcher"}->GetInCAM();

	# Main application form
	$self->{"form"} = ReorderPopupFrm->new( $self->{"parentFrm"}->{"mainFrm"}, $self->{"jobId"}, $self->{"type"} );
	$self->{"form"}->{"mainFrm"}->Show(1);

	$self->__SetHandlers();

}

sub Run {
	my $self = shift;

	$self->{"inCAM"}->ClientFinish();

	#start new process, where check job before export
	my $worker = threads->create( sub { $self->__ProcessAsyncWorker( $self->{"jobId"}, $self->{"type"}, $self->{"launcher"}->GetServerPort() ) } );
	$worker->set_thread_exit_only(1);
	$self->{"threadId"} = $worker->tid();

}

# ================================================================================
# PRIVATE WORKER (child thread) METHODS
# ================================================================================

sub __ProcessAsyncWorker {
	my $self        = shift;
	my $jobId       = shift;
	my $processType = shift;
	my $serverPort  = shift;

	$self->{"inCAM"} = InCAM->new( "remote" => 'localhost', "port" => $serverPort );

	$self->{"inCAM"}->ServerReady();

	eval {

		if ( $self->{"type"} eq Enums->Process_LOCALLY ) {

			$self->__ProcessLocally()

		}
		elsif ( $self->{"type"} eq Enums->Process_SERVER ) {

			$self->__ProcessServer();
		}
	};
	if ($@) {

		my %res1 : shared = ();
		$res1{"progress"}  = 0;
		$res1{"succes"}    = 0;
		$res1{"errorMess"} = "Unexpected error: " . $@;

		$self->__ThreadEvt( \%res1 );

	}

	$self->{"inCAM"}->ClientFinish();

	my %res : shared = ();

	my $threvent = new Wx::PlThreadEvent( -1, $PROCESS_END_EVT, \%res );
	Wx::PostEvent( $self->{"form"}->{"mainFrm"}, $threvent );

}

# Process reorder locally
sub __ProcessLocally {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Init Process reorder class

	my $processReorder = ProcessReorder->new( $inCAM, $jobId );

	unless ( $self->{"isPool"} ) {
		unless ( $processReorder->ExcludeChange("EXPORT") ) {
			die "Unable to exclude automatic change \"EXPORT\"";
		}
	}

	# 1) Task: Process job reorder

	my $errMess = "";
	my $result  = $processReorder->RunTasks( \$errMess );

	my %res1 : shared = ();
	$res1{"progress"}  = 50;
	$res1{"succes"}    = 1;
	$res1{"errorMess"} = $errMess;

	unless ($result) {
		$res1{"succes"}    = 0;
		$res1{"errorMess"} = $errMess;
	}

	$self->__ThreadEvt( \%res1 );

	# 2) Task: Set orders state

	my %res2 : shared = ();
	$res2{"progress"}  = 100;
	$res2{"succes"}    = 1;
	$res2{"errorMess"} = "";

	if ($result) {
		eval {

			# 2) Set state
			my $orderState = EnumsIS->CurStep_PROCESSREORDEROK;

			if ( $self->{"isPool"} ) {

				$orderState = EnumsIS->CurStep_KPANELIZACI;
			}

			foreach ( @{ $self->{"orders"} } ) {

				HegMethods->UpdatePcbOrderState( $_->{"reference_subjektu"}, $orderState, 1 );
			}
		};
		if ($@) {

			my $err = "" . $@;

			$res2{"succes"}    = 0;
			$res2{"errorMess"} = $err;
		}
	}

	$self->__ThreadEvt( \%res2 );
}

# Process reorder on server
sub __ProcessServer {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1) Task: If no Pool, do check before export

	my %res1 : shared = ();
	$res1{"progress"}  = 35;
	$res1{"succes"}    = 1;
	$res1{"errorMess"} = "";

	#	unless ( $self->{"isPool"} ) {
	#
	#		my $units = UnitHelper->PrepareUnits( $inCAM, $jobId );
	#
	#		my @activeOnUnits = grep { $_->GetGroupState() eq CheckerEnums->GroupState_ACTIVEON } @{ $units->{"units"} };
	#
	#		foreach my $unit (@activeOnUnits) {
	#
	#			my $resultMngr = -1;
	#			my $succes = $unit->CheckBeforeExport( $inCAM, \$resultMngr );
	#
	#			if ( $resultMngr->GetErrorsCnt() ) {
	#
	#				$res1{"succes"} = 0;
	#				$res1{"errorMess"} .= $resultMngr->GetErrorsStr(1);
	#			}
	#		}
	#	}

	$self->__ThreadEvt( \%res1 );

	unless ( $res1{"succes"} ) {
		return 0;
	}

	# 2) Task: Close job

	my %res2 : shared = ();
	$res2{"progress"}  = 75;
	$res2{"succes"}    = 1;
	$res2{"errorMess"} = "";

	$self->{"inCAM"}->COM( "save_job",    "job" => "$jobId" );
	$self->{"inCAM"}->COM( "check_inout", "job" => "$jobId", "mode" => "in", "ent_type" => "job" );
	$self->{"inCAM"}->COM( "close_job",   "job" => "$jobId" );

	$self->__ThreadEvt( \%res2 );

	# 3) Task: Set orders state

	my %res3 : shared = ();
	$res3{"progress"}  = 100;
	$res3{"succes"}    = 1;
	$res3{"errorMess"} = "";

	eval {

		foreach ( @{ $self->{"orders"} } ) {

			HegMethods->UpdatePcbOrderState( $_->{"reference_subjektu"}, EnumsIS->CurStep_ZPRACOVANIAUTO, 1 );
		}
	};
	if ($@) {

		my $err = "" . $@;

		$res3{"succes"}    = 0;
		$res3{"errorMess"} = $err;

	}

	$self->__ThreadEvt( \%res3 );

	return 1;

}

sub __ThreadEvt {
	my $self = shift;
	my $res  = shift;

	my $threvent = new Wx::PlThreadEvent( -1, $PROCESS_EVT, $res );
	Wx::PostEvent( $self->{"form"}->{"mainFrm"}, $threvent );
}

sub __SetHandlers {
	my $self = shift;

	$PROCESS_EVT = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"form"}->{"mainFrm"}, -1, $PROCESS_EVT, sub { $self->__ProcessHandler(@_) } );

	$PROCESS_END_EVT = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"form"}->{"mainFrm"}, -1, $PROCESS_END_EVT, sub { $self->__ProcessEndHandler(@_) } );

	$self->{"form"}->{'procIndicatorClick'}->Add( sub { $self->__OnProcIndicatorClick(@_) } );
	$self->{"form"}->{'okClick'}->Add( sub            { $self->{'onClose'}->Do(@_) } );
}

# ================================================================================
# Private methods
# ================================================================================

sub __ProcessHandler {
	my ( $self, $frame, $event ) = @_;

	my %d = %{ $event->GetData };

	# 1) Data from worker thread

	unless ( $d{"succes"} ) {

		push( @{ $self->{"processErr"} }, $d{"errorMess"} );
	}

	# 2) Update GUI
	$self->{"form"}->SetErrIndicator( scalar( @{ $self->{"processErr"} } ) );

	$self->{"form"}->SetGaugeVal( $d{"progress"} );

}

sub __ProcessEndHandler {
	my $self = shift;

	# Reconnect again InCAM, after  was used by child thread
	$self->{"inCAM"}->Reconnect();

	# Set progress bar
	$self->{"form"}->SetGaugeVal(100);

	my $result = scalar( @{ $self->{"processErr"} } ) ? 0 : 1;

	$self->{"form"}->SetResult($result);

	if ( $self->{"type"} eq Enums->Process_LOCALLY ) {

		# if export locall + pcb is not pool + process succes
		# Display information message about export
		my $pnlExist = CamHelper->StepExists( $self->{"inCAM"}, $self->{"jobId"}, "panel" );

		if (
			scalar( @{ $self->{"processErr"} } ) == 0
			&& ( !$self->{"isPool"} || ( $self->{"isPool"} && $pnlExist ) )
		  )
		{
			my $messMngr = $self->{"form"}->_GetMessageMngr();
			my @mess     = ("Don't forget export job now.");
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess );
		}
	}

}

# ================================================================================
# FORM HANDLERS
# ================================================================================

sub __OnProcIndicatorClick {
	my $self = shift;
	my $type = shift;

	my $messMngr = $self->{"form"}->_GetMessageMngr();

	#my @mess = ( @{$self->{"procErrMess"}} );
	my @mess = ("test");
	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, $self->{"processErr"} );

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

