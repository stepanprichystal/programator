
#-------------------------------------------------------------------------------------------#
# Description: Application logic of checking and processing reorder
# Logic for poup form
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::StencilCreator::StencilPopup;

#3th party library
#use strict;
use warnings;
use threads;
use threads::shared;
use Try::Tiny;

#use strict;

#local library

use aliased 'Programs::StencilCreator::Forms::StencilPopupFrm';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::Events::Event';
use aliased 'Enums::EnumsGeneral';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Programs::StencilCreator::Helpers::OutputCheck';

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

	$self->{"dataMngr"}        = shift;
	$self->{"stencilDataMngr"} = shift;
	$self->{"stencilSrc"}      = shift;
	$self->{"jobIdSrc"}        = shift;

	$self->{"inCAM"} = undef;

	$self->{"checkErr"}  = [];
	$self->{"checkWarn"} = [];

	#Events
	$self->{'onClose'} = Event->new();

	return $self;
}

sub Init {
	my $self = shift;
	$self->{"launcher"} = shift;

	$self->{"inCAM"} = $self->{"launcher"}->GetInCAM();

	# Main application form
	$self->{"form"} = StencilPopupFrm->new( $self->{"parentFrm"}->{"mainFrm"}, $self->{"jobId"} );
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

		$self->__DoChecks()

	};
	if ($@) {

		my %res1 : shared = ();
		$res1{"succes"}    = 0;
		$res1{"errorMess"} = "Unexpected error: " . $@;

		$self->__ThreadEvt( \%res1 );

	}

	$self->{"inCAM"}->ClientFinish();

	my %res : shared = ();

	my $threvent = new Wx::PlThreadEvent( -1, $PROCESS_END_EVT, \%res );
	Wx::PostEvent( $self->{"form"}->{"mainFrm"}, $threvent );

}

# Do checks of stencil settings
sub __DoChecks {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Init Process reorder class

	my $outputCheck = OutputCheck->new( $inCAM, $jobId, $self->{"dataMngr"}, $self->{"stencilDataMngr"}, $self->{"stencilSrc"}, $self->{"jobIdSrc"} );
 	$outputCheck->{"onItemResult"}->Add( sub { $self->__OnCheckError(@_) } );

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

sub __OnCheckError{
	my $self = shift;
	my $itemResult = shift;
 	
 	my %res2 : shared = ();
 
	if($itemResult->GetWarningCount()){
		
		$res2{"type"} = EnumsGeneral->MessageType_WARNING;
		$res2{"mess"} = $itemResult->GetWarningStr();
	}
	
	if($itemResult->GetErrorCount()){
		
		$res2{"type"} = EnumsGeneral->MessageType_ERROR;
		$res2{"mess"} = $itemResult->GetErrorStr();
	}
	
	$self->__ThreadEvt( \%res2 );
 	
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

	$self->{"form"}->{'warnIndClickEvent'}->Add( sub { $self->__OnWarnIndicatorClick(@_) } );
	$self->{"form"}->{'errIndClickEvent'}->Add( sub  { $self->__OnErrIndicatorClick(@_) } );

	$self->{"form"}->$self->{"outputForceClick"}->Add( sub { $self->__OnOutputForceClick(@_) } );
	$self->{"form"}->{'cancelClick'}->Add( sub             { $self->{'onClose'}->Do(@_) } );

	$self->{"form"}->$self->{"cancelClick"}->Add( sub { $self->__OnProcIndicatorClick(@_) } );

}

# ================================================================================
# Private methods
# ================================================================================

sub __ProcessHandler {
	my ( $self, $frame, $event ) = @_;

	my %d = %{ $event->GetData };

	# 1) Data from worker thread

	if ( $d{"type"} eq EnumsGeneral->MessageType_WARNING ) {

		push( @{ $self->{"checkWarn"} }, $d{"mess"} );
		$self->{"form"}->SetErrIndicator( scalar( @{ $self->{"checkWarn"} } ) );
	}
	
	if ( $d{"type"} eq EnumsGeneral->MessageType_ERROR ) {

		push( @{ $self->{"checkErr"} }, $d{"mess"} );
		$self->{"form"}->SetWarnIndicator( scalar( @{ $self->{"checkErr"} } ) );
	}	
 
}

sub __ProcessEndHandler {
	my $self = shift;

	# Reconnect again InCAM, after  was used by child thread
	$self->{"inCAM"}->Reconnect();

	# Set progress bar
	$self->{"form"}->SetGaugeVal(100);

	my $result = scalar( @{ $self->{"processErr"} } ) ? 0 : 1;

	$self->{"form"}->SetResult($result);

	# if export locall + pcb is not pool + process succes
	# Display information message about export

	if (    $self->{"type"} eq Enums->Process_LOCALLY
		 && scalar( @{ $self->{"processErr"} } ) == 0
		 && !$self->{"isPool"} )
	{
		my $messMngr = $self->{"form"}->_GetMessageMngr();
		my @mess     = ("Don't forget export job now.");
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess );
	}

}

# ================================================================================
# FORM HANDLERS
# ================================================================================
 
sub __OnWarnIndicatorClick {
	my $self = shift;
	my $type = shift;

	my $messMngr = $self->{"form"}->_GetMessageMngr();

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, $self->{"checkWarn"} );
}

sub __OnErrIndicatorClick {
	my $self = shift;
	my $type = shift;

	my $messMngr = $self->{"form"}->_GetMessageMngr();

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, $self->{"checkErr"} );
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

