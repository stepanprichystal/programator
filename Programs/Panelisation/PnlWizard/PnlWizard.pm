
#-------------------------------------------------------------------------------------------#
# Description: Base
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::PnlWizard;

use Class::Interface;
&implements('Packages::InCAMHelpers::AppLauncher::IAppLauncher');

#3th party library
use threads;
use threads::shared;
use Wx;
use strict;
use warnings;

#local library

use aliased 'Programs::Panelisation::PnlWizard::Forms::PnlWizardForm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::PartContainer';
use aliased 'Programs::Panelisation::PnlWizard::Core::StorageModelMngr';
use aliased 'Programs::Panelisation::PnlWizard::Core::WizardModel';

use aliased 'Programs::Panelisation::PnlWizard::Core::BackgCreatorTaskMngr';

#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Forms::ExportCheckerForm';
#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Forms::ExportPopupForm';
#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Unit::Units';
#
#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupBuilder::StandardBuilder';
#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupBuilder::TemplateBuilder';
#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupBuilder::V0Builder';
#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupBuilder::OfferBuilder';
#
#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupTable::GroupTables';
#use aliased 'Packages::InCAM::InCAM';
#
#use aliased 'Connectors::HeliosConnector::HegMethods';
#
#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::StorageMngr';
#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::ExportPopup';
#use aliased 'Programs::Exporter::ExportUtility::RunExport::RunExportUtility';
#
#use aliased 'Programs::Exporter::ExportUtility::DataTransfer::DataTransfer';
#use aliased 'Programs::Exporter::ExportChecker::Enums';
#use aliased 'Managers::AsyncJobMngr::Enums'                          => 'EnumsJobMngr';
#use aliased 'Programs::Exporter::ExportUtility::DataTransfer::Enums' => 'EnumsTransfer';
#
#use aliased 'Helpers::GeneralHelper';
#use aliased 'Helpers::JobHelper';
#use aliased 'Widgets::Forms::LoadingForm';
#use aliased 'CamHelpers::CamHelper';
#use aliased 'CamHelpers::CamJob';
#use aliased 'Enums::EnumsPaths';
#use aliased 'Enums::EnumsGeneral';
#
#use aliased 'Packages::Export::PreExport::FakeLayers';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
#my $CHECKER_START_EVT : shared;
#my $CHECKER_END_EVT : shared;
#my $CHECKER_FINISH_EVT : shared;
#my $THREAD_FORCEEXIT_EVT : shared;

# ================================================================================
# PUBLIC METHOD
# ================================================================================

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"jobId"} = shift;

	$self->{"serverPort"} = shift;

	$self->{"inCAM"} = undef;

	# Launcher, helper, which do connection to InCAm editor
	$self->{"launcher"} = undef;

	# Main application form
	$self->{"form"} = PnlWizardForm->new( -1, $self->{"jobId"} );

	# Class whin manage popup form for checking
	#$self->{"pnlWizardChecker"} = ExportPopup->new( $self->{"jobId"} );

	# Background task manager for executing background operation
	$self->{"backgroundTaskMngr"} = BackgroundTaskMngr->new( $self->{"jobId"} );

	$self->{"wizardModel"} = WizardModel->new( $self->{"jobId"} );

	# Keep all references of used groups/units in form
	$self->{"partContainer"} = PartContainer->new( $self->{"jobId"}, $self->{"wizardModel"}, $self->{"backgroundTaskMngr"} );

	# Manage group date (store/load group data from/to disc)
	$self->{"storageModelMngr"} = StorageModelMngr->new( $self->{"jobId"}, $self->{"wizardModel"}, $self->{"partContainer"} );

	return $self;
}

sub Init {
	my $self     = shift;
	my $launcher = shift;    # contain InCAM library conencted to server
	                         # 1) Get background worker and InCAM library from launcher

	$self->{"launcher"} = $launcher;

	$self->{"inCAM"} = $launcher->GetInCAM();

	$self->{"backgroundTaskMngr"}->Init( $launcher, $self->{"form"}->{"mainFrm"} );

	#$self->{"inCAM"}->SetDisplay(0);

	$self->{"wizardModel"}->Init( $self->{"inCAM"} );

	$self->{"partContainer"}->Init( $self->{"inCAM"}, $self->{"backgroundTaskMngr"} );

	# 3) Initialization of whole export app

	# Keep structure of groups
	#$self->__DefineTableGroups();

	# Save all references of groups
	#	my @cells = $self->{"groupTables"}->GetAllUnits();
	#$self->{"partContainer"}->Init( $self->{"inCAM"}, $self->{"jobId"}, "panel" ,\@cells );
	#
	#	# Build phyisic table with groups, which has completely set GUI
	my @parts = $self->{"partContainer"}->GetParts();
	$self->{"form"}->BuildPartContainer( $self->{"inCAM"}, \@parts );

	# 4) Initialization of each single group

	#posloupnost volani metod
	#1) new()
	#2) InitForm()
	#3) BuildGUI()
	#4) InitDataMngr()
	#5) RefreshGUI()
	#6) RefreshWrapper()
	#==> export
	#7) CheckBeforeExport()
	#8) GetGroupData()

	print STDERR "Init model START\n";
	$self->{"partContainer"}->InitModel( $self->{"inCAM"} );
	print STDERR "Init model END\n";
	#

	print STDERR "Refresh START\n";
	$self->{"partContainer"}->RefreshGUI();
	print STDERR "Refresh END\n";

	print STDERR "Init model async START\n";
	$self->{"partContainer"}->InitModelAsync();
	print STDERR "Init model async END\n";

	#
	#$self->{"partContainer"}->RefreshWrapper();

	# After first loading group data, create event/handler connection between groups
	#$self->{"partContainer"}->BuildGroupEventConn( $self->{"groupTables"} );

	#	$self->__RefreshForm();
	#
	#	#set handlers for main app form
	$self->__SetHandlers();

	print STDERR "endr RUN\n";

}

sub Run {
	my $self = shift;

	print STDERR "start SHOW\n";

	$self->{"form"}->{"mainFrm"}->Show(1);

	#	# When all succesinit, close waiting form
	#	if ( $self->{"loadingFrmPid"} ) {
	#		Win32::Process::KillProcess( $self->{"loadingFrmPid"}, 0 );
	#	}

	#Helper->ShowAbstractQueueWindow(0,"Loading Exporter Checker");

	$self->{"form"}->MainLoop();

}

# ================================================================================
# FORM HANDLERS
# ================================================================================
#sub __ExportSyncFormHandler {
#	my $self = shift;
#
#	#if ( $client->ClientConnected() ) {
#	#
#	#		print STDERR "Close\n";
#	#		$self->{"inCAM"}->CloseServer();
#	#
#	#	}\
#
#	#use Win32::OLE;
#	#my $typeOfPcb = HegMethods->GetTypeOfPcb( $self->{"jobId"} );
#
#	#my $typeOfPcb = HegMethods->GetTypeOfPcb( $self->{"jobId"} );
#	$self->__CheckBeforeExport( EnumsJobMngr->TaskMode_SYNC );
#}
#
#sub __ExportASyncFormHandler {
#	my $self     = shift;
#	my $onServer = shift;
#
#	my $client = $self->{"client"};
#
#	#if ( $client->ClientConnected() ) {
#	#
#	#		print STDERR "Close\n";
#	#		$self->{"inCAM"}->CloseServer();
#	#
#	#	}\
#
#	#use Win32::OLE;
#	#my $typeOfPcb = HegMethods->GetTypeOfPcb( $self->{"jobId"} );
#
#	#my $typeOfPcb = HegMethods->GetTypeOfPcb( $self->{"jobId"} );
#	$self->__CheckBeforeExport( EnumsJobMngr->TaskMode_ASYNC, $onServer );
#
#}
#
#sub __OnCloseFormHandler {
#	my $self = shift;
#
#	$self->__CleanUpAndExitForm();
#
#}
#
#sub __CheckBeforeExport {
#	my $self     = shift;
#	my $mode     = shift;
#	my $onServer = shift // 0;    # default is not export on server
#
#	#disable from during checking
#	$self->{"disableForm"} = 1;
#	$self->__RefreshForm();
#
#	my $inCAM = $self->{"inCAM"};
#
#	$self->{"units"}->UpdateGroupData();
#
#	#get all gorup data and save them to disc
#	$self->{"storageMngr"}->SaveGroupData();
#
#	#test if client is connected
#	#if so, disconnect, because child porcess has to connect to server itself
#	if ( $inCAM->IsConnected() ) {
#		$inCAM->ClientFinish();
#
#		#$client->SetConnected(0);
#	}
#
#	#Win32::OLE->Uninitialize();
#
#	#init and run checking form
#	$self->{"exportPopup"}->Init( $mode, $onServer, $self->{"units"}, $self->{"form"} );
#	$self->{"exportPopup"}->CheckBeforeExport( $self->{"launcher"}->GetServerPort() );
#
#}
#
#sub __CleanUpAndExitForm {
#	my ($self) = @_;
#
#	#my $client     = $self->{"client"};
#	#my $serverPort = $client->ServerPort();
#
#	print STDERR "On close\n";
#
#	#reconnect again for exit server
#
#	#if ( $client->IsConnected() ) {
#
#	#$self->{"inCAM"}->ClientFinish();
#
#	#$self->{"inCAM"} = InCAM->new( "port" => $serverPort );
#
#	#if ( $self->{"inCAM"}->ServerReady() ) {
#	#	$self->{"inCAM"}->CloseServer();
#	#}
#
#	#}
#
#	FakeLayers->RemoveFakeLayers( $self->{"inCAM"}, $self->{"jobId"} ) if ( !JobHelper->GetJobIsOffer( $self->{"jobId"} ) );
#
#	$self->{"form"}->{"mainFrm"}->Destroy();
#
#}
#
#sub __UncheckAllHandler {
#	my $self = shift;
#
#	$self->{"units"}->SetGroupState( Enums->GroupState_ACTIVEOFF );
#
#	# Refresh wrapper
#	$self->{"units"}->RefreshWrapper();
#
#	# Refresh form
#	$self->__RefreshForm();
#
#}
#
#sub __LoadLastHandler {
#	my $self = shift;
#
#	# Load/get saved group data
#	$self->{"units"}->InitDataMngr( $self->{"inCAM"}, $self->{"storageMngr"} );
#
#	# Refresh loaded data in group form
#	$self->{"units"}->RefreshGUI();
#	$self->{"units"}->RefreshWrapper();
#
#	# Refresh form
#	$self->__RefreshForm();
#
#}
#
#sub __LoadDefaultHandler {
#	my $self = shift;
#
#	$self->{"units"}->InitDataMngr( $self->{"inCAM"} );
#
#	# Refresh loaded data in group form
#	$self->{"units"}->RefreshGUI();
#	$self->{"units"}->RefreshWrapper();
#
#	# Refresh form
#	$self->__RefreshForm();
#}
#
#sub __OnGroupChangeState {
#	my $self = shift;
#	my $unit = shift;
#
#	print STDERR "Unif " . $unit->{"unitId"} . " change state: " . $unit->GetGroupState() . "\n";
#	print STDERR "All units state: " . $self->{"units"}->GetGroupState() . "\n";
#
#	$self->__RefreshForm();
#
#}
#
#sub __OnSwitchAppHandler {
#	my $self    = shift;
#	my $appName = shift;
#
#	die "Not implemented";
#
#}

# ================================================================================
# EXPORT POPUP HANDLERS
# ================================================================================
#sub __OnClosePopupHandler {
#	my $self = shift;
#
#	# After close popup window is necessery Re-connect to income server
#	# Because checking was processed in child thread and was connected
#	# to this income server
#
#	$self->{"inCAM"}->Reconnect();
#
#	$self->{"disableForm"} = 0;
#	$self->__RefreshForm();
#
#	#$self->__CleanUpAndExitForm();
#
#}
#
#sub __OnResultPopupHandler {
#	my $self       = shift;
#	my $resultType = shift;
#	my $exportMode = shift;
#	my $onServer   = shift;
#
#	# After close popup window is necessery Re-connect to income server
#	# Because checking was processed in child thread and was connected
#	# to this income server
#
#	$self->{"inCAM"}->Reconnect();
#
#	my $active    = 1;
#	my $toProduce = $self->{"form"}->GetToProduce($active);
#
#	if (    $resultType eq Enums->PopupResult_EXPORTFORCE
#		 || $resultType eq Enums->PopupResult_SUCCES )
#	{
#
#		FakeLayers->RemoveFakeLayers( $self->{"inCAM"}, $self->{"jobId"} );
#
#		my $pathExportFile = EnumsPaths->Client_EXPORTFILES . $self->{"jobId"};
#
#		if ( $exportMode eq EnumsJobMngr->TaskMode_ASYNC && $onServer ) {
#			$pathExportFile = EnumsPaths->Jobs_EXPORTFILESPCB . $self->{"jobId"};
#		}
#
#		my $dataTransfer = DataTransfer->new( $self->{"jobId"}, EnumsTransfer->Mode_WRITE, $self->{"units"}, undef, $pathExportFile );
#
#		my $inCAM = $self->{"inCAM"};
#
#		# Get orders on CAM department
#		my @orders = HegMethods->GetPcbOrderNumbers( $self->{"jobId"} );
#		@orders = map { $_->{"reference_subjektu"} } grep { $_->{"stav"} == 2 } @orders;
#
#		if ( $exportMode eq EnumsJobMngr->TaskMode_ASYNC ) {
#
#			# Save and close job
#			$self->{"form"}->{"mainFrm"}->Hide();
#
#			CamJob->SaveJob( $inCAM, $self->{"jobId"} );
#			CamJob->CheckInJob( $inCAM, $self->{"jobId"} );
#			CamJob->CloseJob( $inCAM, $self->{"jobId"} );
#
#			if ( $inCAM->IsConnected() ) {
#				$inCAM->CloseServer();
#			}
#
#			# Save exported data
#			$dataTransfer->SaveData( $exportMode, $toProduce, undef, undef, \@orders );
#
#		}
#		elsif ( $exportMode eq EnumsJobMngr->TaskMode_SYNC ) {
#
#			# Generate random port number
#
#			#my $portNumber = "200". int(rand(9));    #random number
#			#my $portNumber = "2001";    #random number
#			#my $serverPID  = $$;        # PID
#
#			# Save and hide form
#			$self->{"form"}->{"mainFrm"}->Hide();
#			CamJob->SaveJob( $inCAM, $self->{"jobId"} );
#
#			my $formPos = $self->{"form"}->{"mainFrm"}->GetPosition();
#
#			# Save exported data
#			$dataTransfer->SaveData( $exportMode, $toProduce, $self->{"launcher"}->GetServerPort(), $formPos, \@orders );
#
#			#test if client is connected
#			#if so, disconnect, because exportUtility connect to this server (launched in InCAM toolkit)
#
#			if ( $inCAM->IsConnected() ) {
#				$inCAM->ClientFinish();
#
#				#$client->SetConnected(0);
#			}
#
#			$self->{"launcher"}->SetLetServerRun();
#
#			# Start server in this script
#
#			#my $serverPath = GeneralHelper->Root() . "\\Managers\\AsyncJobMngr\\Server\\ServerExporter.pl";
#
#			#$ARGV[0] = $self->{"serverPort"};    # port number of server running in Toolkit, pass as argument
#			#require $serverPath;
#
#		}
#
#		if ($onServer) {
#
#			# Show summary message
#			$self->{"form"}->{"messageMngr"}->ShowModal( $self->{"form"}->{"mainFrm"},
#														 EnumsGeneral->MessageType_INFORMATION,
#														 [ "Job: \"" . $self->{"jobId"} . "\" was succesfully sent to server." ] );
#
#		}
#		else {
#
#			# Launch export utility if hasn't launched before
#			my $utility = RunExportUtility->new(0);
#		}
#
#		# Exit export window
#		$self->{"form"}->{"mainFrm"}->Destroy();
#
#		return 1;
#
#	}
#	elsif ( $resultType eq Enums->PopupResult_CHANGE ) {
#
#		#do nothing
#
#	}
#
#	$self->{"disableForm"} = 0;
#	$self->__RefreshForm();
#}

# ================================================================================
# PRIVATE METHODS
# ================================================================================

#sub __RefreshForm {
#	my $self = shift;
#
##	# Disable/enable whole form
##	$self->{"form"}->DisableForm( $self->{"disableForm"} );
##
##	# Disable/enable button Load last button
##	$self->{"form"}->SetLoadLastBtn( $self->{"storageMngr"}->ExistGroupData() );
##
##	# Set export buttons
##	my %groupsState = $self->{"units"}->GetGroupState();
##
##	if ( $groupsState{ Enums->GroupState_ACTIVEON } == 0 ) {
##		$self->{"form"}->DisableExportBtn(1);
##	}
##	else {
##		$self->{"form"}->DisableExportBtn(0);
##	}
#
#	# Display default TAB
#
#}
#

sub __OnInCAMIsBusyHndl {
	my $self   = shift;
	my $isBusy = shift;

	print STDERR "InCAM is busy: $isBusy in  PnlWizard\n";

}

sub __SetHandlers {
	my $self = shift;

	#	$self->{"form"}->{"onExportSync"}->Add( sub  { $self->__ExportSyncFormHandler(@_) } );
	#	$self->{"form"}->{"onExportASync"}->Add( sub { $self->__ExportASyncFormHandler(@_) } );
	#	$self->{"form"}->{"onClose"}->Add( sub       { $self->__OnCloseFormHandler(@_) } );
	#	$self->{"form"}->{"onUncheckAll"}->Add( sub  { $self->__UncheckAllHandler(@_) } );
	#	$self->{"form"}->{"onLoadLast"}->Add( sub    { $self->__LoadLastHandler(@_) } );
	#	$self->{"form"}->{"onLoadDefault"}->Add( sub { $self->__LoadDefaultHandler(@_) } );
	#
	#	$self->{"exportPopup"}->{"onResultEvt"}->Add( sub { $self->__OnResultPopupHandler(@_) } );
	#	$self->{"exportPopup"}->{'onClose'}->Add( sub     { $self->__OnClosePopupHandler(@_) } );
	#
	#	$self->{"units"}->SetGroupChangeHandler( sub { $self->__OnGroupChangeState(@_) } );
	#	$self->{"units"}->{"switchAppEvt"}->Add( sub { $self->__OnSwitchAppHandler(@_) } );

	$self->{"launcher"}->{"inCAMIsBusyEvt"}->Add( sub { $self->__OnInCAMIsBusyHndl(@_) } );

	# 				$self->{"backgroundWorker"}->{"thrPogressInfoEvt"}->Add(sub {$self->__OnTaskStartHndl(@_)} );
	# 					$self->{"backgroundWorker"}->{"thrMessageInfoEvt"}->Add(sub {$self->__OnTaskStartHndl(@_)} );

}
#

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

