
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
use List::Util qw(first);

#local library

use aliased 'Programs::Panelisation::PnlWizard::Forms::PnlWizardForm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::PartContainer';
use aliased 'Programs::Panelisation::PnlWizard::Core::StorageModelMngr';
use aliased 'Programs::Panelisation::PnlWizard::Enums';
use aliased 'Programs::Panelisation::PnlWizard::Core::BackgroundTaskMngr';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamLayer';

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
use aliased 'Programs::Panelisation::PnlCreator::Helpers::StepProfile';
use aliased 'Connectors::HeliosConnector::HegMethods';
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
use aliased 'Helpers::GeneralHelper';

#use aliased 'Helpers::JobHelper';
#use aliased 'Widgets::Forms::LoadingForm';
#use aliased 'CamHelpers::CamHelper';
#use aliased 'CamHelpers::CamJob';
#use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Panelisation::PnlWizard::Core::WizardModel';

#use aliased 'Packages::Export::PreExport::FakeLayers';

# ================================================================================
# PUBLIC METHOD
# ================================================================================

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"jobId"} = shift;

	$self->{"serverPort"} = shift;

	$self->{"pnlType"} = undef;

	$self->{"inCAM"} = undef;

	# Launcher, helper, which do connection to InCAm editor
	$self->{"launcher"} = undef;

	# Main application form
	$self->{"form"} = undef;

	# Class whin manage popup form for checking
	#$self->{"pnlWizardChecker"} = ExportPopup->new( $self->{"jobId"} );

	# Background task manager for executing background operation
	$self->{"backgroundTaskMngr"} = undef;

	# Keep all references of used groups/units in form
	$self->{"partContainer"} = undef;

	# Manage group date (store/load group data from/to disc)
	$self->{"storageModelMngr"} = undef;

	$self->{"popupChecker"} = undef;

	# Old panel name (backuped step right before run Panelisation. Will be restored if cancel panelisation)
	$self->{"pnlStepBackup"} = undef;

	# Name of steps with adjusted profile bz cvrlpin layer (created before start and destroyed after close app)
	$self->{"cvrlpinSteps"} = [];

	return $self;
}

sub Init {
	my $self     = shift;
	my $launcher = shift;
	my $pnlType  = shift;    # contain InCAM library conencted to server
	                         # 1) Get background worker and InCAM library from launcher

	$main::configPath = GeneralHelper->Root() . "\\Programs\\Panelisation\\PnlWizard\\Config\\Config_" . $pnlType . ".txt";

	$self->{"launcher"} = $launcher;

	$self->{"pnlType"} = $pnlType;

	$self->{"form"} = PnlWizardForm->new( -1, $self->{"jobId"}, $self->{"pnlType"} );

	$self->{"storageModelMngr"} = StorageModelMngr->new( $self->{"jobId"}, $self->{"pnlType"} );

	$self->{"launcher"}->InitBackgroundWorker( $self->{"form"}->{"mainFrm"} );

	$self->{"backgroundTaskMngr"} = BackgroundTaskMngr->new( $self->{"jobId"}, $self->{"pnlType"} );

	$self->{"backgroundTaskMngr"}->Init( $launcher->GetBackgroundWorker() );

	$self->{"inCAM"} = $launcher->GetInCAM();

	$self->{"inCAM"}->SupressToolkitException();

	#$self->{"inCAM"}->SetDisplay(0);

	$self->{"partContainer"} = PartContainer->new( $self->{"jobId"}, $self->{"backgroundTaskMngr"} );

	$self->{"partContainer"}->Init( $self->{"inCAM"}, $self->{"pnlType"} );

	my $title    = "Check before panelisation " . $self->{"jobId"};
	my $taskName = "Create force";

	$self->{"launcher"}->InitPopupChecker( $self->{"jobId"}, $self->{"form"}->{"mainFrm"}, $title, $taskName );

	$self->{"popupChecker"} = $launcher->GetPopupChecker();

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

	if ( $self->{"storageModelMngr"}->ExistModelData() ) {

		$self->{"form"}->EnableLoadLastBtn( 1, $self->{"storageModelMngr"}->GetModelDate( 1, 1 ) );
	}
	else {
		$self->{"form"}->EnableLoadLastBtn(0);
	}

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

	$self->__InitModel();

	$self->__BackupPanelStep();

	my @cvrlpinSteps = StepProfile->PrepareCvrlPinSteps( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"cvrlpinSteps"} = \@cvrlpinSteps;

	print STDERR "Init model START\n";
	$self->{"partContainer"}->InitPartModel( $self->{"inCAM"} );
	print STDERR "Init model END\n";

	$self->__RefreshGUI();
	#

	print STDERR "Refresh START\n";
	$self->{"partContainer"}->RefreshGUI();
	print STDERR "Refresh END\n";

	$self->__SetHandlers();

	#	$self->{"inCAM"}->COM("get_step");
	#	my $test = $self->{"inCAM"}->GetReply();

	#	print STDERR "endr RUN $test\n";
	$self->__InCAMEditorPreviewMode(1);

	print STDERR "Init model async START\n";
	$self->{"partContainer"}->AsyncInitSelCreatorModel();
	print STDERR "Init model async END\n";

	#
	#$self->{"partContainer"}->RefreshWrapper();

	# After first loading group data, create event/handler connection between groups
	#$self->{"partContainer"}->BuildGroupEventConn( $self->{"groupTables"} );

	#	$self->__RefreshForm();
	#
	#	#set handlers for main app form

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
sub __OnCreateClickHndl {
	my $self = shift;

	my $result = 1;

	# Check if all parts are already inited (due to asynchrounous initialization)
	if ( $self->{"backgroundTaskMngr"}->GetCurrentTasksCnt() != 0 ) {
		die "Some background task are running ( " . $self->{"backgroundTaskMngr"}->GetCurrentTasksCnt() . ")";
	}

	$self->__StoreModelToDisc();

	$self->{"partContainer"}->ClearErrors();

	$self->{"form"}->SetFinalProcessLayout( 1, $self->{"partContainer"}->GetPreview() );

	$self->{"popupChecker"}->ClearCheckClasses();

	foreach my $checkClass ( $self->{"partContainer"}->GetPartsCheckClass() ) {

		$self->{"popupChecker"}->AddCheckClass( $checkClass->{"checkClassId"},    $checkClass->{"checkClassPackage"},
												$checkClass->{"checkClassTitle"}, $checkClass->{"checkClassData"} );

	}

	$self->{"popupChecker"}->AsyncCheck();
}

sub __OnCancelClickHndl {
	my $self = shift;

	# Check if all parts are already inited (due to asynchrounous initialization)
	if ( $self->{"backgroundTaskMngr"}->GetCurrentTasksCnt() != 0 ) {
		die "Some background task are running ( " . $self->{"backgroundTaskMngr"}->GetCurrentTasksCnt() . ")";
	}

	$self->__StoreModelToDisc();

	# Restore backuped step
	if ( defined $self->{"pnlStepBackup"} ) {

		my $oriName = $self->{"pnlStepBackup"};
		$oriName =~ s/_backup//i;

		if ( CamHelper->StepExists( $self->{"inCAM"}, $self->{"jobId"}, $self->{"pnlStepBackup"} ) ) {

			if ( CamHelper->StepExists( $self->{"inCAM"}, $self->{"jobId"}, $oriName ) ) {
				CamStep->DeleteStep( $self->{"inCAM"}, $self->{"jobId"}, $oriName );
			}

			CamStep->RenameStep( $self->{"inCAM"}, $self->{"jobId"}, $self->{"pnlStepBackup"}, $oriName );
		}

	}

	# Remove cvrlpisn step
	StepProfile->RemoveCvrlPinSteps( $self->{"inCAM"}, $self->{"jobId"}, $self->{"cvrlpinSteps"} );

	#CamStep->CopyStep( $self->{"inCAM"}, $self->{"jobId"}, $self->{"model"}->GetStep(), $self->{"jobId"}, $self->{"pnlStepBackup"} );

	$self->__InCAMEditorPreviewMode(0);

	if ( $self->{"inCAM"}->IsConnected() ) {

		$self->{"inCAM"}->CloseServer();

	}

	$self->{"form"}->{"mainFrm"}->Destroy();

	#}

}

sub __OnLeaveClickHndl {
	my $self = shift;

	# Check if all parts are already inited (due to asynchrounous initialization)
	if ( $self->{"backgroundTaskMngr"}->GetCurrentTasksCnt() != 0 ) {
		die "Some background task are running ( " . $self->{"backgroundTaskMngr"}->GetCurrentTasksCnt() . ")";
	}

	# Remove backup panel step
	if ( CamHelper->StepExists( $self->{"inCAM"}, $self->{"jobId"}, $self->{"pnlStepBackup"} ) ) {

		CamStep->DeleteStep( $self->{"inCAM"}, $self->{"jobId"}, $self->{"pnlStepBackup"} );
	}

	# Replace cvrlpin steps if exist
	StepProfile->ReplaceCvrlpinSteps( $self->{"inCAM"}, $self->{"jobId"}, $self->{"model"}->GetStep() );

	# Remove cvrlpisn step
	StepProfile->RemoveCvrlPinSteps( $self->{"inCAM"}, $self->{"jobId"}, $self->{"cvrlpinSteps"} );

	$self->__StoreModelToDisc();

	if ( $self->{"inCAM"}->IsConnected() ) {

		$self->{"inCAM"}->CloseServer();

	}

	$self->{"form"}->{"mainFrm"}->Destroy();

}

sub __OnShowInCAMClickHndl {
	my $self = shift;

	# Check if all parts are already inited (due to asynchrounous initialization)
	if ( $self->{"backgroundTaskMngr"}->GetCurrentTasksCnt() != 0 ) {
		die "Some background task are running ( " . $self->{"backgroundTaskMngr"}->GetCurrentTasksCnt() . ")";
	}

	$self->{"form"}->{"mainFrm"}->Hide();
	$self->{"inCAM"}->PAUSE("Check panel (do not modify panel, it will have no affect!)");
	$self->{"form"}->{"mainFrm"}->Show();

}

sub __OnLoadLastClickHndl {
	my $self = shift;

	# Check if all parts are already inited (due to asynchrounous initialization)
	if ( $self->{"backgroundTaskMngr"}->GetCurrentTasksCnt() != 0 ) {
		die "Some background task are running ( " . $self->{"backgroundTaskMngr"}->GetCurrentTasksCnt() . ")";
	}

	die "Model data not exist" if ( !$self->{"storageModelMngr"}->ExistModelData() );

	my $restoredModel = $self->{"storageModelMngr"}->LoadModel();
	$self->{"model"} = $restoredModel;    # update model

	# Set main form
	$self->__RefreshGUI();

	# Set parts

	$self->{"partContainer"}->InitPartModel( $self->{"inCAM"}, $restoredModel );
	$self->{"partContainer"}->RefreshGUI();

	# Check if there is active preview (go fromlast part)
	# If so asynchrounos creator processing will be called
	if ( $self->{"partContainer"}->GetPreview() ) {

		my @parts = $self->{"partContainer"}->GetParts();

		# If so Process parts
		for ( my $i = scalar(@parts) - 1 ; $i >= 0 ; $i-- ) {

			my $partModel = $restoredModel->GetPartModelById( $parts[$i]->GetPartId() );

			if ( $partModel->GetPreview() ) {
				$self->{"partContainer"}->SetPreviewOnAllPart( $parts[$i]->GetPartId() );
				last;
			}
		}
	}

}

sub __OnLoadDefaultClickHndl {
	my $self = shift;

	# Check if all parts are already inited (due to asynchrounous initialization)
	if ( $self->{"backgroundTaskMngr"}->GetCurrentTasksCnt() != 0 ) {
		die "Some background task are running ( " . $self->{"backgroundTaskMngr"}->GetCurrentTasksCnt() . ")";
	}

	$self->__InitModel();
	$self->__RefreshGUI();

	$self->{"partContainer"}->InitPartModel( $self->{"inCAM"} );    # Load generally model
	$self->{"partContainer"}->RefreshGUI();
	$self->{"partContainer"}->AsyncInitSelCreatorModel();           # Load asynchronously selected model

}

sub __OnShowLayersClickHndl {
	my $self    = shift;
	my $showSig = shift;
	my $showNC  = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @dispAllLayers = CamMatrix->GetDisplayedLayers( $inCAM, $jobId );
	my @allLayers = map { $_->{"gROWname"} } CamJob->GetBoardLayers( $inCAM, $jobId );

	my @layers2Disp = ();
	if ($showSig) {

		@layers2Disp = grep { $_ =~ /^[cs]$/ } @allLayers;
	}

	if ($showNC) {

		@layers2Disp = grep { $_ =~ /^f$/ || $_ =~ /^score$/ } @allLayers;
	}

	my @dispLayers    = ();
	my @notDispLayers = ();

	foreach my $l (@layers2Disp) {

		my $disp = ( defined first { $_ eq $l } @dispAllLayers ) ? 1 : 0;

		push( @dispLayers,    $l ) if ($disp);
		push( @notDispLayers, $l ) if ( !$disp );
	}

	if ( scalar(@dispLayers) > scalar(@notDispLayers) ) {

		# Deactivate all
		CamLayer->DisplayLayers( $inCAM, \@layers2Disp, 0, 0 );

	}
	else {

		# Activate all
		CamLayer->DisplayLayers( $inCAM, \@layers2Disp, 1, 0 );
		$inCAM->COM( "display_sr", "display" => "yes" );

	}

}

sub __OnCheckResultHndl {
	my $self   = shift;
	my $result = shift;

	if ($result) {

		$self->{"partContainer"}->AsyncCreatePanel();
	}
	else {
		$self->{"form"}->SetFinalProcessLayout( 0, $self->{"partContainer"}->GetPreview() );

	}

}

sub __OnAsyncPanelCreatedHndl {
	my $self    = shift;
	my $result  = shift;
	my $errMess = shift;

	$self->{"form"}->SetFinalProcessLayout( 0, $self->{"partContainer"}->GetPreview() );

	if ($result) {

		# Do flatten if requested
		if ( $self->{"model"}->GetFlatten() ) {

			my @layerFilter = map { $_->{"gROWname"} } CamJob->GetBoardLayers( $self->{"inCAM"}, $self->{"jobId"} );
			CamStep->CreateFlattenStep( $self->{"inCAM"}, $self->{"jobId"},
										$self->{"model"}->GetStep(),
										$self->{"model"}->GetStep() . "_flatten",
										1, \@layerFilter );
			CamStep->DeleteStep( $self->{"inCAM"}, $self->{"jobId"}, $self->{"model"}->GetStep() );

		}

		# Remove backup step
		if ( CamHelper->StepExists( $self->{"inCAM"}, $self->{"jobId"}, $self->{"pnlStepBackup"} ) ) {

			CamStep->DeleteStep( $self->{"inCAM"}, $self->{"jobId"}, $self->{"pnlStepBackup"} );
		}

		# Remove cvrlpisn step
		StepProfile->RemoveCvrlPinSteps( $self->{"inCAM"}, $self->{"jobId"}, $self->{"cvrlpinSteps"} );

		$self->__InCAMEditorPreviewMode(0);
		if ( $self->{"inCAM"}->IsConnected() ) {

			$self->{"inCAM"}->ClientFinish();

		}

		$self->{"form"}->{"mainFrm"}->Destroy();

	}
	else {

		my $messMngr = $self->{"form"}->GetMessageMngr();

		my @mess1 = ();
		push( @mess1, "==========================================" );
		push( @mess1, "<b>Error during panel creation</b>" );
		push( @mess1, "==========================================\n" );
		push( @mess1, "Detail:" );
		push( @mess1, "$errMess" );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess1 );

	}

}

# Request from parts to show/hode whole form mostly during user interaction with InCAM editor
sub __OnShowPnlWizardFrmHndl {
	my $self = shift;
	my $show = shift;

	if ($show) {

		$self->{"form"}->{"mainFrm"}->Show();
	}
	else {

		$self->{"form"}->{"mainFrm"}->Hide();

	}

}

# ================================================================================
# PRIVATE METHODS
# ================================================================================

sub __OnFormPreviewChangedlHndl {
	my $self    = shift;
	my $preview = shift;

	if ($preview) {

		$self->{"partContainer"}->SetPreviewOnAllPart();
	}
	else {

		$self->{"partContainer"}->SetPreviewOffAllPart();
	}

	$self->{"form"}->SetPreviewChangedLayout( $self->{"partContainer"}->GetPreview() );
}

sub __OnPartPreviewChangedlHndl {
	my $self = shift;

	# Disable/Enable Show in InCAM btn
	$self->{"form"}->SetPreviewChangedLayout( $self->{"partContainer"}->GetPreview() );

}

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

	if ($isBusy) {

		$self->{"form"}->SetInCAMBusyLayout( 1, $self->{"partContainer"}->GetPreview() );

	}
	else {

		$self->{"form"}->SetInCAMBusyLayout( 0, $self->{"partContainer"}->GetPreview() );
	}

	print STDERR "InCAM is busy: $isBusy in  PnlWizard\n";

}

sub __OnBackgroundTaskCntChangedHndl {
	my $self      = shift;
	my $taskCount = shift;

	if ($taskCount) {

		$self->{"form"}->SetAsyncTaskRunningLayout( 1, $self->{"partContainer"}->GetPreview() );

	}
	else {

		$self->{"form"}->SetAsyncTaskRunningLayout( 0, $self->{"partContainer"}->GetPreview() );
	}

}

sub __OnBackgroundTaskDieHndl {
	my $self     = shift;
	my $taskId   = shift;
	my $errMesss = shift;

	my $messMngr = $self->{"form"}->GetMessageMngr();

	my @mess1 = ();
	push( @mess1, "==========================================" );
	push( @mess1, "<b>Error during running background task </b>" );
	push( @mess1, "==========================================\n" );
	push( @mess1, "Detail:" );
	push( @mess1, "$errMesss" );

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess1 );

	$self->{"partContainer"}->ClearErrors();
	$self->{"partContainer"}->HideLoading();

	$self->{"form"}->SetAsyncTaskRunningLayout( 0, $self->{"partContainer"}->GetPreview() );

}

sub __SetHandlers {
	my $self = shift;

	# Popup checker handlers
	$self->{"popupChecker"}->{"checkResultEvt"}->Add( sub { $self->__OnCheckResultHndl(@_) } );

	# Form handlers
	$self->{"form"}->{"cancelClickEvt"}->Add( sub    { $self->__OnCancelClickHndl(@_) } );
	$self->{"form"}->{"leaveClickEvt"}->Add( sub     { $self->__OnLeaveClickHndl(@_) } );
	$self->{"form"}->{"showInCAMClickEvt"}->Add( sub { $self->__OnShowInCAMClickHndl(@_) } );
	$self->{"form"}->{"createClickEvt"}->Add( sub    { $self->__OnCreateClickHndl(@_) } );

	$self->{"form"}->{"showSigLClickEvt"}->Add( sub { $self->__OnShowLayersClickHndl( 1, 0 ) } );
	$self->{"form"}->{"showNCLClickEvt"}->Add( sub  { $self->__OnShowLayersClickHndl( 0, 1 ) } );
	$self->{"form"}->{"loadLastClickEvt"}->Add( sub { $self->__OnLoadLastClickHndl(@_) } );
	$self->{"form"}->{"loadDefaultClickEvt"}->Add( sub { $self->__OnLoadDefaultClickHndl(@_) } );

	$self->{"form"}->{"previewChangedEvt"}->Add( sub { $self->__OnFormPreviewChangedlHndl(@_) } );
	$self->{"form"}->{"stepChangedEvt"}->Add( sub    { $self->{"partContainer"}->UpdateStep(@_) } );

	$self->{"partContainer"}->{"asyncPanelCreatedEvt"}->Add( sub { $self->__OnAsyncPanelCreatedHndl(@_) } );
	$self->{"partContainer"}->{"showPnlWizardFrmEvt"}->Add( sub  { $self->__OnShowPnlWizardFrmHndl(@_) } );
	$self->{"partContainer"}->{"previewChangedEvt"}->Add( sub    { $self->__OnPartPreviewChangedlHndl(@_) } );

	#$self->{"partContainer"}->{"previewChangedEvt"}->Add( sub    { $self->__OnPartPreviewChangedlHndl(@_) } );

	$self->{"backgroundTaskMngr"}->{"taskCntChangedEvt"}->Add( sub { $self->__OnBackgroundTaskCntChangedHndl(@_) } );
	$self->{"backgroundTaskMngr"}->{"asyncTaskDieEvt"}->Add( sub   { $self->__OnBackgroundTaskDieHndl(@_) } );

	#		$self->{"form"}->{"onExportASync"}->Add( sub { $self->__ExportASyncFormHandler(@_) } );
	#		$self->{"form"}->{"onClose"}->Add( sub       { $self->__OnCloseFormHandler(@_) } );
	#		$self->{"form"}->{"onUncheckAll"}->Add( sub  { $self->__UncheckAllHandler(@_) } );
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

sub __StoreModelToDisc {
	my $self = shift;

	$self->__UpdateModel();

	return $self->{"storageModelMngr"}->StoreModel( $self->{"model"} );

}

sub __UpdateModel {
	my $self = shift;

	# Set model property from main form

	# Set part models
	foreach my $partModelInf ( @{ $self->{"partContainer"}->GetModel() } ) {

		$self->{"model"}->SetPartModelById( $partModelInf->[0], $partModelInf->[1] );
	}

	$self->{"model"}->SetStep( $self->{"form"}->GetStep() );
	$self->{"model"}->SetPreview( $self->{"form"}->GetPreview() );
	$self->{"model"}->SetFlatten( $self->{"form"}->GetFlatten() );

}

sub __InitModel {
	my $self = shift;

	# Create fresh model
	$self->{"model"} = WizardModel->new( $self->{"jobId"} );

	# Set model step
	my $step = "unknown_name";

	if ( $self->{"pnlType"} eq PnlCreEnums->PnlType_PRODUCTIONPNL ) {

		$step = "panel";
	}
	elsif ( $self->{"pnlType"} eq PnlCreEnums->PnlType_CUSTOMERPNL ) {
		$step = "mpanel";
	}

	$self->{"model"}->SetStep($step);

	$self->{"model"}->SetFlatten( HegMethods->GetPcbIsPool( $self->{"jobId"} ) );

	# Set preview
	$self->{"model"}->SetPreview(0);

	# Set part models
	foreach my $partModelInf ( @{ $self->{"partContainer"}->GetModel(1) } ) {

		my $modelKey = $partModelInf->[0];
		my $model    = $partModelInf->[1];

		$model->SetPreview(0);

		$self->{"model"}->SetPartModelById( $modelKey, $model );

	}

	# Pre init creator models
	my %parts = %{ $self->{"model"}->GetParts() };
	foreach my $partId ( keys %parts ) {

		my @creators = @{ $parts{$partId}->GetCreators() };

		foreach my $modelCreator (@creators) {

			$modelCreator->SetStep($step);
		}

	}

}

sub __RefreshGUI {
	my $self = shift;

	$self->{"form"}->SetStep( $self->{"model"}->GetStep() );
	$self->{"form"}->SetPreview( $self->{"model"}->GetPreview() );
	$self->{"form"}->SetFlatten( $self->{"model"}->GetFlatten() );

}

sub __InCAMEditorPreviewMode {
	my $self    = shift;
	my $preview = shift;

	$self->{"inCAM"}->COM( "show_component", "component" => "Action_Area", "show" => ( $preview ? "no" : "yes" ) );
	$self->{"inCAM"}->COM( "show_component", "component" => "Layers_List", "show" => ( $preview ? "no" : "yes" ) );
}

sub __BackupPanelStep {
	my $self = shift;

	# Backup old panel (restore if cancel panelisation)
	$self->{"pnlStepBackup"} = $self->{"model"}->GetStep() . "_backup";
	if ( CamHelper->StepExists( $self->{"inCAM"}, $self->{"jobId"}, $self->{"model"}->GetStep() ) ) {

		CamStep->CopyStep( $self->{"inCAM"}, $self->{"jobId"}, $self->{"model"}->GetStep(), $self->{"jobId"}, $self->{"pnlStepBackup"} );
		CamStep->DeleteStep( $self->{"inCAM"}, $self->{"jobId"}, $self->{"model"}->GetStep() );
	}
}

#

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

