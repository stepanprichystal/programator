
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

use aliased 'Programs::Panelisation::PnlWizard::Core::BackgroundTaskMngr';

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
use aliased 'Enums::EnumsGeneral';
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

	$self->{"pnlType"} = undef;

	$self->{"inCAM"} = undef;

	# Launcher, helper, which do connection to InCAm editor
	$self->{"launcher"} = undef;

	# Main application form
	$self->{"form"} = PnlWizardForm->new( -1, $self->{"jobId"} );

	# Class whin manage popup form for checking
	#$self->{"pnlWizardChecker"} = ExportPopup->new( $self->{"jobId"} );

	# Background task manager for executing background operation
	$self->{"backgroundTaskMngr"} = BackgroundTaskMngr->new( $self->{"jobId"} );

	# Keep all references of used groups/units in form
	$self->{"partContainer"} = PartContainer->new( $self->{"jobId"}, $self->{"backgroundTaskMngr"} );

	# Manage group date (store/load group data from/to disc)
	$self->{"storageModelMngr"} = undef;

	$self->{"popupChecker"} = undef;

	return $self;
}

sub Init {
	my $self     = shift;
	my $launcher = shift;
	my $pnlType  = shift;    # contain InCAM library conencted to server
	                         # 1) Get background worker and InCAM library from launcher

	$self->{"launcher"} = $launcher;

	$self->{"pnlType"} = $pnlType;

	$self->{"storageModelMngr"} = StorageModelMngr->new( $self->{"jobId"}, $self->{"pnlType"} );

	$self->{"launcher"}->InitBackgroundWorker( $self->{"form"}->{"mainFrm"} );

	$self->{"backgroundTaskMngr"}->Init( $launcher->GetBackgroundWorker() );

	$self->{"inCAM"} = $launcher->GetInCAM();

	#$self->{"inCAM"}->SetDisplay(0);

	$self->{"wizardModel"}->Init( $self->{"inCAM"} );

	$self->{"partContainer"}->Init( $self->{"inCAM"}, $self->{"backgroundTaskMngr"} );

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
	
	if($self->{"storageModelMngr"}->ExistModelData()){
		
		$self->{"form"}->EnableLoadLastBtn(1, $self->{"storageModelMngr"}->GetModelDate(1,1) )
	}else{
		$self->{"form"}->EnableLoadLastBtn(0)
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

	print STDERR "Init model START\n";
	$self->{"partContainer"}->InitModel( $self->{"inCAM"} );
	print STDERR "Init model END\n";
	#

	print STDERR "Refresh START\n";
	$self->{"partContainer"}->RefreshGUI();
	print STDERR "Refresh END\n";

	$self->__SetHandlers();

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
sub __OnCreateClickHndl {
	my $self = shift;

	my $result = 1;

	# Check if all parts are already inited (due to asynchrounous initialization)
	if ( $self->{"backgroundTaskMngr"}->GetCurrentTasksCnt() != 0 ) {
		die "Some background task are running ( " . $self->{"backgroundTaskMngr"}->GetCurrentTasksCnt() . ")";
	}

	$self->__StoreModelToDisc();

	$self->{"form"}->SetFinalProcessLayout(1);

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

	if ( $self->{"inCAM"}->IsConnected() ) {

		$self->{"inCAM"}->ClientFinish();

	}
	$self->{"form"}->{"mainFrm"}->Destroy();

	#}

}

sub __OnShowInCAMClickHndl {
	my $self = shift;

	# Check if all parts are already inited (due to asynchrounous initialization)
	if ( $self->{"backgroundTaskMngr"}->GetCurrentTasksCnt() != 0 ) {
		die "Some background task are running ( " . $self->{"backgroundTaskMngr"}->GetCurrentTasksCnt() . ")";
	}

	$self->__StoreModelToDisc();

}

sub __OnLoadLastClickHndl {
	my $self = shift;

	# Check if all parts are already inited (due to asynchrounous initialization)
	if ( $self->{"backgroundTaskMngr"}->GetCurrentTasksCnt() != 0 ) {
		die "Some background task are running ( " . $self->{"backgroundTaskMngr"}->GetCurrentTasksCnt() . ")";
	}

	die "Model data not exist" if ( !$self->{"storageModelMngr"}->ExistModelData() );

	my $restoredModel = $self->{"storageModelMngr"}->LoadModel();

	$self->{"partContainer"}->InitModel( $self->{"inCAM"}, $restoredModel );
	$self->{"partContainer"}->RefreshGUI();

}

sub __OnLoadDefaultClickHndl {
	my $self = shift;

	# Check if all parts are already inited (due to asynchrounous initialization)
	if ( $self->{"backgroundTaskMngr"}->GetCurrentTasksCnt() != 0 ) {
		die "Some background task are running ( " . $self->{"backgroundTaskMngr"}->GetCurrentTasksCnt() . ")";
	}

	$self->{"partContainer"}->InitModel( $self->{"inCAM"} );
	$self->{"partContainer"}->RefreshGUI();

}

sub __OnCheckResultHndl {
	my $self   = shift;
	my $result = shift;

	if ($result) {

		$self->{"partContainer"}->AsyncCreatePanel();
	}
	else {
		$self->{"form"}->SetFinalProcessLayout(0);
	}

}

sub __OnAsyncPanelCreatedHndl {
	my $self    = shift;
	my $result  = shift;
	my $errMess = shift;

	$self->{"form"}->SetFinalProcessLayout(0);

	if ($result) {

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

# ================================================================================
# PRIVATE METHODS
# ================================================================================

sub __OnPreviewChangedlHndl {
	my $self    = shift;
	my $preview = shift;

	if ($preview) {

		$self->{"partContainer"}->SetPreviewOnAllPart();
	}
	else {

		$self->{"partContainer"}->SetPreviewOffAllPart();
	}

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

		$self->{"form"}->SetInCAMBusyLayout(1);

	}
	else {

		$self->{"form"}->SetInCAMBusyLayout(0);
	}

	print STDERR "InCAM is busy: $isBusy in  PnlWizard\n";

}

sub __OnCurrentTaskCntChangedHndl {
	my $self      = shift;
	my $taskCount = shift;

	if ($taskCount) {

		$self->{"form"}->SetAsyncTaskRunningLayout(1);

	}
	else {

		$self->{"form"}->SetAsyncTaskRunningLayout(0);
	}

}

sub __SetHandlers {
	my $self = shift;

	# Popup checker handlers
	$self->{"popupChecker"}->{"checkResultEvt"}->Add( sub { $self->__OnCheckResultHndl(@_) } );

	# Form handlers

	$self->{"form"}->{"createClickEvt"}->Add( sub    { $self->__OnCreateClickHndl(@_) } );
	$self->{"form"}->{"cancelClickEvt"}->Add( sub    { $self->__OnCancelClickHndl(@_) } );
	$self->{"form"}->{"showInCAMClickEvt"}->Add( sub { $self->__OnShowInCAMClickHndl(@_) } );

	$self->{"form"}->{"loadLastClickEvt"}->Add( sub    { $self->__OnLoadLastClickHndl(@_) } );
	$self->{"form"}->{"loadDefaultClickEvt"}->Add( sub { $self->__OnLoadDefaultClickHndl(@_) } );

	$self->{"form"}->{"previewChangedEvt"}->Add( sub { $self->__OnPreviewChangedlHndl(@_) } );

	$self->{"partContainer"}->{"asyncPanelCreatedEvt"}->Add( sub   { $self->__OnAsyncPanelCreatedHndl(@_) } );
	$self->{"backgroundTaskMngr"}->{"taskCntChangedEvt"}->Add( sub { $self->__OnCurrentTaskCntChangedHndl(@_) } );

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

	my $model = $self->{"partContainer"}->GetModel();

	return $self->{"storageModelMngr"}->StoreModel($model);

}
#

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

