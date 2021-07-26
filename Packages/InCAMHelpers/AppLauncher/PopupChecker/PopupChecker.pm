
#-------------------------------------------------------------------------------------------#
# Description: Application logic of checking stencil before echport
# Logic for poup form
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::InCAMHelpers::AppLauncher::PopupChecker::PopupChecker;

#3th party library
#use strict;
use warnings;
use threads;
use threads::shared;
use Try::Tiny;
use Time::HiRes qw (sleep);
use List::Util qw(first);

#use strict;

#local library
use aliased 'Packages::InCAMHelpers::AppLauncher::PopupChecker::BackgroundWorkerMngr';
use aliased 'Packages::InCAMHelpers::AppLauncher::PopupChecker::PopupCheckerFrm';
use aliased 'Packages::Events::Event';
use aliased 'Enums::EnumsGeneral';

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
	my $titleName     = shift;
	my $commitBtnName = shift;

	$self->{"form"} = PopupCheckerFrm->new( $self->{"parentFrm"}, $self->{"jobId"}, $titleName, $commitBtnName );

	$self->{"backgroundWorkerMngr"} = BackgroundWorkerMngr->new( $self->{"jobId"} );

	$self->{"checkClasses"} = [];

	#	$self->{"dataMngr"}        = shift;
	#	$self->{"stencilDataMngr"} = shift;
	#	$self->{"stencilSrc"}      = shift;
	#	$self->{"jobIdSrc"}        = shift;
	#
	#
	#
	$self->{"checkErr"}  = [];
	$self->{"checkWarn"} = [];
	#
	#	#Events
	$self->{'checkResultEvt'} = Event->new();

	#	$self->{'stencilOutputEvt'} = Event->new();

	return $self;
}

sub Init {
	my $self = shift;

	my $worker = shift;

	$self->{"backgroundWorkerMngr"}->Init($worker);

	#	my
	#	$appMainFrm, $self->{"server"}->{"inCAM"}, $worker
	#
	#	$self->{"launcher"} = shift;
	#
	#	$self->{"inCAM"} = $self->{"launcher"}->GetInCAM();
	#
	#	$self->{"checkErr"}  = [];
	#	$self->{"checkWarn"} = [];
	#
	#	# Main application form

	$self->__SetHandlers();

}

sub ClearCheckClasses {
	my $self = shift;

	$self->{"checkClasses"} = [];
}

sub AddCheckClass {
	my $self                 = shift;
	my $checkClassId         = shift;
	my $checkClassPackage    = shift;    # package name, must implement ICheckClass
	my $checkClassTitle      = shift;    # must be able to be serialiyed to json
	my $checkClassConstrData = shift
	  // [];    # Parameters for check class constructor method. Must be able to be serialiyed to json. Must be array reference
	my $checkClassCheckData = shift // []; # Parameters for check class Check method. must be able to be serialiyed to json. . Must be array reference

	my %classInfo = ();

	$classInfo{"checkClassId"}         = $checkClassId;              # get full package name
	$classInfo{"checkClassPackage"}    = ref($checkClassPackage);    # get full package name
	$classInfo{"checkClassTitle"}      = $checkClassTitle;
	$classInfo{"checkClassConstrData"} = $checkClassConstrData;
	$classInfo{"checkClassCheckData"}  = $checkClassCheckData;

	push( @{ $self->{"checkClasses"} }, \%classInfo );

}

sub AsyncCheck {
	my $self = shift;

	# Reset old values

	$self->{"checkErr"}  = [];
	$self->{"checkWarn"} = [];

	$self->{"form"}->SetWarnIndicator(0);
	$self->{"form"}->SetErrIndicator(0);

	$self->{"form"}->SetGaugeProgress(0);

	# Visible buttons if no errors
	$self->{"form"}->EnableForceBtn(0);
	$self->{"form"}->EnableCancelBtn(0);
	$self->{"form"}->EnableStopBtn(0);

	$self->{"form"}->SetStatusText("");

	$self->{'form'}->{"mainFrm"}->CentreOnParent(&Wx::wxBOTH);

	# Start background task

	$self->{"backgroundWorkerMngr"}->CheckClasses( $self->{"checkClasses"} );

	$self->{"form"}->{"mainFrm"}->Show(1);

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

#
#sub __OnCheckError {
#	my $self       = shift;
#	my $itemResult = shift;
#
#	my %res2 : shared = ();
#
#	if ( $itemResult->GetWarningCount() ) {
#
#		$res2{"type"} = EnumsGeneral->MessageType_WARNING;
#		$res2{"mess"} = $itemResult->GetWarningStr();
#	}
#
#	if ( $itemResult->GetErrorCount() ) {
#
#		$res2{"type"} = EnumsGeneral->MessageType_ERROR;
#		$res2{"mess"} = $itemResult->GetErrorStr();
#	}
#
#	$self->__ThreadEvt( \%res2 );
#
#}
#
#sub __ThreadEvt {
#	my $self = shift;
#	my $res  = shift;
#
#	my $threvent = new Wx::PlThreadEvent( -1, $PROCESS_EVT, $res );
#	Wx::PostEvent( $self->{"form"}->{"mainFrm"}, $threvent );
#}

sub __SetHandlers {
	my $self = shift;

	# Background worker handlers

	$self->{"backgroundWorkerMngr"}->{"checkClassErrEvt"}->Add( sub   { $self->__OnClassCheckErrHndl(@_) } );
	$self->{"backgroundWorkerMngr"}->{"checkClassStartEvt"}->Add( sub { $self->__OnClassCheckStartHndl(@_) } );
	$self->{"backgroundWorkerMngr"}->{"checkClassEndEvt"}->Add( sub   { $self->__OnClassCheckEndHndl(@_) } );

	$self->{"backgroundWorkerMngr"}->{"checkStartEvt"}->Add( sub  { $self->__OnCheckStartHndl(@_) } );
	$self->{"backgroundWorkerMngr"}->{"checkFinishEvt"}->Add( sub { $self->__OnCheckFinishHndl(@_) } );
	$self->{"backgroundWorkerMngr"}->{"checkDieEvt"}->Add( sub    { $self->__OnCheckDieHndl(@_) } );
	$self->{"backgroundWorkerMngr"}->{"checkAbortEvt"}->Add( sub  { $self->__OnCheckAbortHndl(@_) } );

	# Popup form handlers

	$self->{"form"}->{'warnIndClickEvent'}->Add( sub { $self->__OnWarnIndicatorClick(@_) } );
	$self->{"form"}->{'errIndClickEvent'}->Add( sub  { $self->__OnErrIndicatorClick(@_) } );

	$self->{"form"}->{"forceClickEvt"}->Add( sub  { $self->__OnForceClickHndl(@_) } );
	$self->{"form"}->{'cancelClickEvt'}->Add( sub { $self->__OnCancelClickHndl(@_) } );
	$self->{"form"}->{'stopClickEvt'}->Add( sub   { $self->__OnStopClickHndl(@_) } );

	#$self->{"form"}->{"mainFrm"}->{"onClose"}->Add( sub { $self->__OnCancelClickHndl(@_) } );

}

# ================================================================================
# Check popup handlers
# ================================================================================

sub __OnStopClickHndl {
	my $self = shift;
	$self->{"form"}->SetStatusText( "Stoping check", 1 );

	$self->{"form"}->EnableStopBtn(0);
	$self->{"form"}->EnableForceBtn(0);
	$self->{"form"}->EnableCancelBtn(0);

	$self->{"backgroundWorkerMngr"}->StopChecking();

}

sub __OnForceClickHndl {
	my $self = shift;

	$self->{"form"}->{"mainFrm"}->Hide();
	$self->{"checkResultEvt"}->Do(1);

}

sub __OnCancelClickHndl {
	my $self = shift;

	$self->{"form"}->{"mainFrm"}->Hide();
	$self->{"checkResultEvt"}->Do(0);

}

# ================================================================================
# Background worker handlers
# ================================================================================

sub __OnClassCheckErrHndl {
	my $self         = shift;
	my $checkClassId = shift;
	my $errType      = shift;
	my $errMess      = shift;

	# 1) Data from worker thread

	if ( $errType eq EnumsGeneral->MessageType_WARNING ) {

		push( @{ $self->{"checkWarn"} }, { "checkClassId" => $checkClassId, "errMess" => $errMess } );
		$self->{"form"}->SetWarnIndicator( scalar( @{ $self->{"checkWarn"} } ) );
	}

	if ( $errType eq EnumsGeneral->MessageType_ERROR ) {

		push( @{ $self->{"checkErr"} }, { "checkClassId" => $checkClassId, "errMess" => $errMess } );
		$self->{"form"}->SetErrIndicator( scalar( @{ $self->{"checkErr"} } ) );
	}

}

sub __OnClassCheckStartHndl {
	my $self         = shift;
	my $checkClassId = shift;

	my $title = first { $_->{"checkClassId"} eq $checkClassId } @{ $self->{"checkClasses"} };
	$self->{"form"}->SetStatusText( $title->{"checkClassTitle"}, 1 );

	my $progress = 0;

	for ( my $i = 0 ; $i < scalar( @{ $self->{"checkClasses"} } ) ; $i++ ) {

		if ( $self->{"checkClasses"}->[$i]->{"checkClassId"} eq $checkClassId ) {

			$progress =
			  100 / scalar( @{ $self->{"checkClasses"} } ) * ( $i + 1 ) - 100 / scalar( @{ $self->{"checkClasses"} } ) / 2;

			last;
		}
	}

	$self->{"form"}->SetGaugeProgress($progress);

	# Visible buttons if no errors
	$self->{"form"}->EnableCancelBtn(0);

}

sub __OnClassCheckEndHndl {
	my $self         = shift;
	my $checkClassId = shift;

	$self->{"form"}->SetStatusText("");
	$self->{"form"}->EnableStopBtn(0);
	$self->{"form"}->EnableForceBtn(0);
	$self->{"form"}->EnableCancelBtn(1);

	my $progress = 0;

	for ( my $i = 0 ; $i < scalar( @{ $self->{"checkClasses"} } ) ; $i++ ) {

		if ( $self->{"checkClasses"}->[$i]->{"checkClassId"} eq $checkClassId ) {

			$progress =
			  100 / scalar( @{ $self->{"checkClasses"} } ) * ( $i + 1 );

			last;
		}
	}

	$self->{"form"}->SetGaugeProgress(-10);

}

# If no errors, Hide Popup and raise CheckFinish
sub __OnCheckStartHndl {
	my $self = shift;

	$self->{"form"}->EnableStopBtn(1);

}

# If no errors, Hide Popup and raise CheckFinish
sub __OnCheckFinishHndl {
	my $self = shift;

	if (    scalar( @{ $self->{"checkWarn"} } ) == 0
		 && scalar( @{ $self->{"checkErr"} } ) == 0 )
	{

		$self->{"form"}->{"mainFrm"}->Hide();
		$self->{"checkResultEvt"}->Do(1);
	}

	$self->{"form"}->SetStatusText("Done");
	$self->{"form"}->EnableStopBtn(0);
	$self->{"form"}->EnableCancelBtn(1);
	$self->{"form"}->SetGaugeProgress(100);

}

sub __OnCheckDieHndl {
	my $self   = shift;
	my $taskId = shift;
	my $error  = shift;

	$self->{"form"}->SetStatusText("Unexpected error occured");
	$self->{"form"}->EnableStopBtn(0);
	$self->{"form"}->EnableForceBtn(0);
	$self->{"form"}->EnableCancelBtn(1);

	$self->{"form"}->SetGaugeProgress(100);

	my $messMngr = $self->{"form"}->_GetMessageMngr();
	my @mess     = ();
	push( @mess, "Checking has stopped due to unexpected error." );
	push( @mess, "\nDetails:\n" );
	push( @mess, $error );

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_SYSTEMERROR, \@mess );
}

sub __OnCheckAbortHndl {
	my $self = shift;

	$self->{"form"}->SetStatusText("Aborted");
	$self->{"form"}->EnableStopBtn(0);
	$self->{"form"}->EnableForceBtn(0);
	$self->{"form"}->EnableCancelBtn(1);

	$self->{"form"}->SetGaugeProgress(100);
}

# ================================================================================
# FORM HANDLERS
# ================================================================================

sub __OnWarnIndicatorClick {
	my $self = shift;
	my $type = shift;

	my $messMngr = $self->{"form"}->_GetMessageMngr();

	my $mess = $self->__GetErrMesssText( $self->{"checkWarn"} );

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, [$mess] );

	$self->{"warnViewed"} = 1;

	$self->{"form"}->EnableForceBtn(1) if ( $self->__DoEnableForceBtn() );
}

sub __OnErrIndicatorClick {
	my $self = shift;
	my $type = shift;

	my $messMngr = $self->{"form"}->_GetMessageMngr();

	my $mess = $self->__GetErrMesssText( $self->{"checkErr"} );

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, [$mess] );

	$self->{"errViewed"} = 1;

	$self->{"form"}->EnableForceBtn(1) if ( $self->__DoEnableForceBtn() );
}

sub __DoEnableForceBtn {
	my $self = shift;

	my $enable = 1;



	if ( scalar( @{ $self->{"checkWarn"} } ) && !$self->{"warnViewed"} ) {

		$enable = 0;
	}

	if ( scalar( @{ $self->{"checkErr"} } ) && !$self->{"errViewed"} ) {

		$enable = 0;
	}

	return $enable

}

sub __GetErrMesssText {
	my $self = shift;
	my @err  = @{ shift(@_) };

	my $mess         = "";
	my $checkClassId = undef;
	foreach my $err (@err) {

		if ( !defined $checkClassId || $err->{"checkClassId"} ne $checkClassId ) {

			my $title = first { $_->{"checkClassId"} eq $err->{"checkClassId"} } @{ $self->{"checkClasses"} };

			my $checkClassTitle = $mess .= "\n";
			$mess .= "=====================================================\n";
			$mess .= " <b>" . $title->{"checkClassTitle"} . "</b>\n";
			$mess .= "=====================================================\n\n";

		}

		$checkClassId = $err->{"checkClassId"};

		$mess .= $err->{"errMess"} . "\n";
	}

	return $mess;
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

