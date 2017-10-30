
#-------------------------------------------------------------------------------------------#
# Description: Application logic of checking stencil before echport
# Logic for poup form
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Stencil::StencilCreator::StencilPopup;

#3th party library
#use strict;
use warnings;
use threads;
use threads::shared;
use Try::Tiny;
use Time::HiRes qw (sleep);

#use strict;

#local library

use aliased 'Programs::Stencil::StencilCreator::Forms::StencilPopupFrm';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::Events::Event';
use aliased 'Enums::EnumsGeneral';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Programs::Stencil::StencilCreator::Helpers::OutputCheck';

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
	$self->{'onClose'}          = Event->new();
	$self->{'stencilOutputEvt'} = Event->new();

	return $self;
}

sub Init {
	my $self = shift;
	$self->{"launcher"} = shift;

	$self->{"inCAM"} = $self->{"launcher"}->GetInCAM();

	$self->{"checkErr"}  = [];
	$self->{"checkWarn"} = [];

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
		$res1{"type"} = EnumsGeneral->MessageType_SYSTEMERROR;
		$res1{"mess"} = "Unexpected error: " . $@;

		print STDERR "Chyba:" . $res1{"mess"};

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

	sleep(0.2);    #test delete this line

	# Init Process reorder class

	my $outputCheck = OutputCheck->new( $inCAM, $jobId, $self->{"dataMngr"}, $self->{"stencilDataMngr"}, $self->{"stencilSrc"}, $self->{"jobIdSrc"} );
	$outputCheck->{"onItemResult"}->Add( sub { $self->__OnCheckError(@_) } );

	# 1) Do checks

	$outputCheck->Check();

}

sub __OnCheckError {
	my $self       = shift;
	my $itemResult = shift;

	my %res2 : shared = ();

	if ( $itemResult->GetWarningCount() ) {

		$res2{"type"} = EnumsGeneral->MessageType_WARNING;
		$res2{"mess"} = $itemResult->GetWarningStr();
	}

	if ( $itemResult->GetErrorCount() ) {

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
	Wx::Event::EVT_COMMAND( $self->{"form"}->{"mainFrm"}, -1, $PROCESS_EVT, sub { $self->__CheckErrHandler(@_) } );

	$PROCESS_END_EVT = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"form"}->{"mainFrm"}, -1, $PROCESS_END_EVT, sub { $self->__CheckEndHandler(@_) } );

	$self->{"form"}->{'warnIndClickEvent'}->Add( sub { $self->__OnWarnIndicatorClick(@_) } );
	$self->{"form"}->{'errIndClickEvent'}->Add( sub  { $self->__OnErrIndicatorClick(@_) } );

	$self->{"form"}->{"outputForceClick"}->Add(
		sub {
			$self->{"form"}->{"mainFrm"}->Hide();
			$self->{'stencilOutputEvt'}->Do(@_);
		}
	);
	$self->{"form"}->{'cancelClick'}->Add( sub { $self->{"form"}->{"mainFrm"}->Hide() } );

	$self->{"form"}->{"cancelClick"}->Add( sub { $self->{"form"}->{"mainFrm"}->Hide() } );

}

# ================================================================================
# Private methods
# ================================================================================

sub __CheckErrHandler {
	my ( $self, $frame, $event ) = @_;

	print STDERR "TEST";

	my %d = %{ $event->GetData };

	# 1) Data from worker thread

	if ( $d{"type"} eq EnumsGeneral->MessageType_WARNING ) {

		push( @{ $self->{"checkWarn"} }, $d{"mess"} );
		$self->{"form"}->SetWarnIndicator( scalar( @{ $self->{"checkWarn"} } ) );
	}

	if ( $d{"type"} eq EnumsGeneral->MessageType_ERROR ) {

		push( @{ $self->{"checkErr"} }, $d{"mess"} );
		$self->{"form"}->SetErrIndicator( scalar( @{ $self->{"checkErr"} } ) );
	}

	if ( $d{"type"} eq EnumsGeneral->MessageType_SYSTEMERROR ) {

		my $messMngr = $self->{"form"}->_GetMessageMngr();

		my @m = ( $d{"mess"} );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_SYSTEMERROR, \@m );

	}

}

sub __CheckEndHandler {
	my $self = shift;

	# Reconnect again InCAM, after  was used by child thread
	$self->{"inCAM"}->Reconnect();

	# Set progress bar
	$self->{"form"}->HideGauge();

	# Visible buttons if no errors
	$self->{"form"}->EnableCancelBtn(1);

	if ( scalar( @{ $self->{"checkErr"} } ) == 0 && scalar( @{ $self->{"checkWarn"} } ) == 0 ) {

		$self->{"form"}->{"mainFrm"}->Hide();
		$self->{'stencilOutputEvt'}->Do();

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

	$self->{"warnViewed"} = 1;
}

sub __OnErrIndicatorClick {
	my $self = shift;
	my $type = shift;

	my $messMngr = $self->{"form"}->_GetMessageMngr();

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, $self->{"checkErr"} );

	$self->{"errViewed"} = 1;

	$self->{"form"}->EnableForceBtn(1);
}

sub __EnableForceBtn {
	my $self = shift;

	my $enable = 1;

	if ( scalar( @{ $self->{"checkWarn"} } ) && !$self->{"warnViewed"} ) {

		$enable = 0;
	}

	if ( scalar( @{ $self->{"checkErr"} } ) && !$self->{"errViewed"} ) {

		$enable = 0;
	}

	if ($enable) {

		$self->{"form"}->EnableForceBtn(1);
	}

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

