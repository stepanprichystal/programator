
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportCheckerMini::ExportCheckerMini;

use Class::Interface;
&implements('Packages::InCAMHelpers::AppLauncher::IAppLauncher');

#3th party library
use strict;
use warnings;
use threads;
use threads::shared;
use Win32::Process;
use Wx;
use Try::Tiny;

#use strict;

#local library

use aliased 'Programs::Exporter::ExportCheckerMini::Forms::ExportCheckerMiniForm';

use aliased 'Packages::InCAM::InCAM';

use aliased 'Connectors::HeliosConnector::HegMethods';

use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'Managers::AsyncJobMngr::Enums'                          => 'EnumsJobMngr';
use aliased 'Programs::Exporter::ExportUtility::DataTransfer::Enums' => 'EnumsTransfer';

use aliased 'Helpers::JobHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Widgets::Forms::LoadingForm';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamLayer';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';

use aliased 'Packages::Export::PreExport::FakeLayers';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::DefaultInfo::DefaultInfo';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Forms::GroupWrapperForm';
use aliased 'Packages::ItemResult::ItemResultMngr';
use aliased 'Packages::ItemResult::Enums' => 'ResEnums';
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::UnitBuilder';
use aliased 'Programs::Exporter::ExportUtility::DataTransfer::DataTransfer';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Unit::Units';
use aliased 'Packages::Exceptions::BaseException';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Unit::Helper' => "UnitHelper";
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
#my $CHECKER_START_EVT : shared;
#my $CHECKER_END_EVT : shared;
#my $CHECKER_FINISH_EVT : shared;
#my $THREAD_FORCEEXIT_EVT : shared;

my $EXPORT_FINISH_EVT : shared;

# ================================================================================
# PUBLIC METHOD
# ================================================================================

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"jobId"} = shift;

	$self->{"unitId"}     = shift;
	$self->{"unitDim"}    = shift;
	$self->{"fakeLayers"} = shift // 1;

	$self->{"fakeLayers"} = 0 if ( JobHelper->GetJobIsOffer( $self->{"jobId"} ) );

	$self->{"units"} = Units->new();    # wrapper for one unit

	$self->{"inCAM"} = undef;

	# Launcher, helper, which do connection to InCAm editor
	$self->{"launcher"} = undef;

	# Main application form
	$self->{"form"} = ExportCheckerMiniForm->new( -1, $self->{"jobId"}, $self->{"unitDim"} );

	# Class whin manage popup form for checking
	$self->{"messMngr"} = $self->{"form"}->GetMessageMngr();

	$self->{"fakeStackup"} = 0;    # indicate if fake temporarz stackup was created in order show export

	return $self;
}

sub Init {
	my $self     = shift;
	my $launcher = shift;          # contain InCAM library conencted to server

	# 1) Get InCAm from Launcher

	$self->{"launcher"} = $launcher;
	$self->{"inCAM"}    = $launcher->GetInCAM();
	$self->{"inCAM"}->SetDisplay(0);

	# 2) Create fake layers which will be exported, but are created automatically

	$self->{"inCAM"}->SetDisplay(0);
	FakeLayers->CreateFakeLayers( $self->{"inCAM"}, $self->{"jobId"}, undef, 1 ) if ( $self->{"fakeLayers"} );

	# 3) Initialization of whole export app

	$self->{"unit"} = UnitHelper->GetUnitById( $self->{"unitId"}, $self->{"jobId"} );

	# Init unit/units
	my $step = undef;
	if ( CamHelper->StepExists( $self->{"inCAM"}, $self->{"jobId"}, "panel" ) ) {
		$step = "panel";
	}
	elsif ( CamHelper->StepExists( $self->{"inCAM"}, $self->{"jobId"}, "o+1" ) ) {
		$step = "o+1";
	}
	else {
		$step = ( CamStep->GetAllStepNames( $self->{"inCAM"}, $self->{"jobId"} ) )[0];
	}

	# Hide temporary inner signal layers if stackup not exist
	my $layerCnt = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );
	if ( $layerCnt > 2 && !JobHelper->StackupExist( $self->{"jobId"} ) ) {

		$self->{"hidenLayers"} = [ CamJob->GetSignalLayerNames( $self->{"inCAM"}, $self->{"jobId"} ) ];
		foreach my $l ( @{ $self->{"hidenLayers"} } ) {
			CamLayer->SetLayerContextLayer( $self->{"inCAM"}, $self->{"jobId"}, $l, "misc" );
		}

	}

	$self->{"units"}->Init( $self->{"inCAM"}, $self->{"jobId"}, $step, [ $self->{"unit"} ] );
	$self->{"units"}->InitDataMngr( $self->{"inCAM"} );

	# Add unit to form
	my $groupWrapper = GroupWrapperForm->new( $self->{"form"}->{"mainFrm"}, UnitEnums->GetTitle( $self->{"unitId"} ) );
	$self->{"unit"}->InitForm( $groupWrapper, $self->{"inCAM"} );
	$groupWrapper->Init( $self->{"unit"}->GetForm() );
	$self->{"form"}->SetGroup($groupWrapper);

	$self->{"unit"}->GetForm()->DisableControls();

	$self->{"units"}->RefreshGUI();

	$self->{"units"}->RefreshWrapper();

	$self->__SetHandlers();

}

sub Run {
	my $self = shift;

	$self->{"form"}->{"mainFrm"}->Show(1);

	#	# When all succesinit, close waiting form
	#	if ( $self->{"loadingFrmPid"} ) {
	#		Win32::Process::KillProcess( $self->{"loadingFrmPid"}, 0 );
	#	}

	#Helper->ShowAbstractQueueWindow(0,"Loading Exporter Checker");

	$self->{"form"}->MainLoop();

}

# ================================================================================
# HANDLERS
# ================================================================================
sub __OnExportHndl {
	my $self = shift;

	$self->{"units"}->UpdateGroupData();

	if ( $self->__CheckBeforeExport() ) {
		$self->__Export();
	}

}

sub __OnExportItemResult {
	my $self       = shift;
	my $itemResult = shift;
	my $errors     = shift;
	my $warnings   = shift;

	if ( $itemResult->Result() eq ResEnums->ItemResult_Fail ) {

		push( @{$warnings}, $itemResult->GetWarningStr() );
		push( @{$errors},   $itemResult->GetErrorStr() );

	}

}

sub __OnExportStatusResult {
	my $self = shift;
	my $res  = shift;

	$self->{"form"}->SetStatusText($res);

}

sub __ExportFinishHandler {
	my ( $self, $frame, $event ) = @_;

	$self->{"inCAM"}->Reconnect();

	$self->{"form"}->ShowGauge(0);

	my %d = %{ $event->GetData };

	my @errors   = @{ $d{"errors"} };
	my @warinngs = @{ $d{"warnings"} };

	if ( !scalar(@errors) && !scalar(@warinngs) ) {

		my @mess = ("Export <g><b>SUCCES</b></g>");

		$self->{"messMngr"}->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess );    #  Script is stopped

		$self->__CleanUpAndExitForm();

	}
	else {
		my @mess = ( "Export <b>FAILURE</b>", "See details:\n" );
		push( @mess, "Warnings:" );
		push( @mess, @warinngs );
		push( @mess, "Errors:" );
		push( @mess, @errors );

		$self->{"messMngr"}->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );          #  Script is stopped
	}

}

sub __OnSwitchAppHandler {
	my $self = shift;

	die "Not omplemented";

}

# ================================================================================
# PRIVATE METHODS
# ================================================================================

sub __CheckBeforeExport {
	my $self = shift;

	my $result = 1;

	# Set status

	my $mngr = -1;
	$result = $self->{"unit"}->CheckBeforeExport( $self->{"inCAM"}, \$mngr, EnumsJobMngr->TaskMode_SYNC );

	unless ($result) {

		my @mess = ();
		push( @mess, "============================================" );
		push( @mess, "<b>Check before export:</b>" );
		push( @mess, "============================================\n" );
		push( @mess, "<b>Warnings:</b>" );
		push( @mess, $mngr->GetErrorsStr(1) );
		push( @mess, "<b>Errors:</b>" );
		push( @mess, $mngr->GetWarningsStr(1) );

		$self->{"messMngr"}->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess, [ "Export force", "Repair it" ] );    #  Script is stopped

		if ( $self->{"messMngr"}->Result() == 0 ) {
			$result = 1;
		}
	}

	return $result;
}

sub __Export {
	my $self  = shift;
	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	if ( $inCAM->IsConnected() ) {
		$inCAM->ClientFinish();
	}

	$self->{"form"}->ShowGauge(1);

	#start new process, where check job before export
	my $worker = threads->create(
		sub {
			$self->__ExportBackground( $self->{"jobId"}, $self->{"launcher"}->GetServerPort(), $self->{"units"}, $self->{"unitId"} );
		}
	);
	$worker->set_thread_exit_only(1);
	$self->{"threadId"} = $worker->tid();

	$worker

}

sub __ExportBackground {
	my $self   = shift;
	my $jobId  = shift;
	my $port   = shift;
	my $units  = shift;
	my $unitId = shift;

	my $inCAM = InCAM->new( "remote" => 'localhost',
							"port"   => $port );
	$inCAM->ServerReady();

	#$self->{"form"}->SetStatusText("Export...");

	my $p = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();

	# Build json data file for Unit builder
	my $dataTransfer = DataTransfer->new( $jobId, EnumsTransfer->Mode_WRITE, $units, undef, $p );
	$dataTransfer->SaveData();

	my $jobStrData = FileHelper->ReadAsString($p);

	my @errors   = ();
	my @warnings = ();
	try {
		# Build unit class for export
		my $unitBuilder = UnitBuilder->new( $inCAM, $jobId, $jobStrData );

		my %unitWorkers = $unitBuilder->GetUnits();
		my $unitWorker  = $unitWorkers{$unitId};
		$unitWorker->Init( $inCAM, $jobId );

		$unitWorker->{"onItemResult"}->Add( sub { $self->__OnExportItemResult( @_, \@errors, \@warnings ) } );
		$unitWorker->{"onStatusResult"}->Add( sub { $self->__OnExportStatusResult(@_) } );

		$unitWorker->Run();

	}
	catch {

		my $eMess = "Export checker thread was unexpectedly exited\n\n";
		my $e = BaseException->new( $eMess, $_ );

		push( @errors, $e->Error() );

		#print STDERR "Su zde: $e";
	};

	$inCAM->ClientFinish();

	my %res : shared = ();

	# fill errors data
	my @err : shared  = ();
	my @warn : shared = ();
	$res{"errors"}   = \@err;
	$res{"warnings"} = \@warn;

	foreach my $e (@errors) {

		push( @{ $res{"errors"} }, $e );
	}

	foreach my $w (@warnings) {

		push( @{ $res{"warnings"} }, $w );
	}
	my $threvent = new Wx::PlThreadEvent( -1, $EXPORT_FINISH_EVT, \%res );
	Wx::PostEvent( $self->{"form"}->{"mainFrm"}, $threvent );

}

sub __SetHandlers {
	my $self = shift;

	$self->{"form"}->{"onExportEvt"}->Add( sub { $self->__OnExportHndl(@_) } );
	$self->{"form"}->{"onCloseEvt"}->Add( sub  { $self->__CleanUpAndExitForm(@_) } );
	$EXPORT_FINISH_EVT = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"form"}->{"mainFrm"}, -1, $EXPORT_FINISH_EVT, sub { $self->__ExportFinishHandler(@_) } );

	$self->{"units"}->{"switchAppEvt"}->Add( sub { $self->__OnSwitchAppHandler(@_) } );

}

sub __CleanUpAndExitForm {
	my ($self) = @_;

	FakeLayers->RemoveFakeLayers( $self->{"inCAM"}, $self->{"jobId"} ) if ( $self->{"fakeLayers"} );

	foreach my $l ( @{ $self->{"hidenLayers"} } ) {
			CamLayer->SetLayerContextLayer( $self->{"inCAM"}, $self->{"jobId"}, $l, "board" );
	 }

	$self->{"inCAM"}->ClientFinish();

	$self->{"form"}->{"mainFrm"}->Destroy();

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

