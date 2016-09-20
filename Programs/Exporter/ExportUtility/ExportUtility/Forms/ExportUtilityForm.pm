
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::ExportUtility::Forms::ExportUtilityForm;
use base 'Managers::AsyncJobMngr::AsyncJobMngr';

#3th party library

use Wx;
use strict;
use warnings;
use Win32::GuiTest qw(FindWindowLike SetFocus SetForegroundWindow);

#local library
use Widgets::Style;
use aliased 'Widgets::Forms::MyWxFrame';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';

use aliased 'Packages::Events::Event';

use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::Forms::JobQueueForm';
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::Forms::GroupTable::GroupTableForm';
use aliased 'Widgets::Forms::CustomNotebook::CustomNotebook';
use aliased 'Widgets::Forms::MyWxBookCtrlPage';
use aliased 'Programs::Exporter::DataTransfer::Enums' => 'EnumsTransfer';
use aliased 'Managers::AsyncJobMngr::ServerMngr::ServerInfo';

#my $THREAD_MESSAGE_EVT : shared;
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

#use constant {
#			   ITEM_RESULT  => "itemResult",
#			   ITEM_ERROR   => "itemError",
#			   GROUP_EXPORT => "groupExport"
#};

sub new {
	my $class   = shift;
	my $runMode = shift;
	my $parent  = shift;

	if ( defined $parent && $parent == -1 ) {
		$parent = undef;
	}

	my $title = "Exporter utility";
	my @dimension = ( 1140, 700 );

	my $self = $class->SUPER::new( $runMode, $parent, $title, \@dimension );

	bless($self);

	#set base class handlers

	$self->{"messageMngr"} = MessageMngr->new("Exporter");

	my $mainFrm = $self->__SetLayout();

	#$mainFrm->Show(1);

	#$self->{'onSetLayout'}->Add( sub { $self->__OnSetLayout(@_)});

	$self->{"onClick"}     = Event->new();
	$self->{"onToProduce"} = Event->new();
	$self->{"onRemoveJob"} = Event->new();

	return $self;
}

sub AddNewTaskGUI {
	my $self = shift;
	my $task = shift;

	my $taskId   = $task->GetTaskId();
	my $taskData = $task->GetExportData();

	# Add new item to queue

	my $jobQueue = $self->{"jobQueue"};

	my $produceMngr = $task->ProduceResultMngr();
	my $taskMngr    = $task->GetTaskResultMngr();
	my $groupMngr   = $task->GetGroupResultMngr();
	my $itemMngr    = $task->GetGroupItemResultMngr();

	my $jobQueueItem = $jobQueue->AddItem( $taskId, $task->GetJobId(), $taskData, $produceMngr, $taskMngr, $groupMngr, $itemMngr );

	# SET HANDLERS
	$jobQueueItem->{"onProduce"}->Add( sub { $self->__OnProduceJobClick(@_) } );
	$jobQueueItem->{"onRemove"}->Add( sub  { $self->__OnRemoveJobClick(@_) } );
	$jobQueueItem->{"onAbort"}->Add( sub   { $self->__OnAbortJobClick(@_) } );

	#$jobQueueItem->SetExportTime($taskData->GetExportTime());
	#$jobQueueItem->SetExportMode($taskData->GetExportMode());
	#$jobQueueItem->SetToProduce($taskData->GetToProduce());

	# Add new item to notebook
	my @units = $task->GetAllUnits();

	my $notebook = $self->{"notebook"};
	my $page     = $notebook->AddPage($taskId);

	my $groupTableForm = GroupTableForm->new( $page->GetParent() );
	$groupTableForm->InitGroupTable( \@units );

	$page->AddContent($groupTableForm);
	print " ======= zde 4\n";

	# Select alreadz added job item
	$self->{"jobQueue"}->SetSelectedItem($taskId);

	# Refresh form
	$self->{"mainFrm"}->Refresh();

}

sub AddNewTask {
	my $self = shift;
	my $task = shift;

	my $exportData = $task->GetExportData();

	my $mode = $exportData->GetExportMode();

	if ( $mode eq EnumsTransfer->ExportMode_SYNC ) {

		my $port = $exportData->GetPort();

		#my $pid = $exportData->GetServerPID();

		my $serverInfo = ServerInfo->new();
		$serverInfo->{"port"} = $port;

		#$serverInfo->{"pidServer"} = $pid;

		$self->_AddJobToQueue( $task->GetJobId(), $task->GetTaskId(), $serverInfo );
	}
	elsif ( $mode eq EnumsTransfer->ExportMode_ASYNC ) {

		$self->_AddJobToQueue( $task->GetJobId(), $task->GetTaskId() );
	}

}

sub __SetLayout {

	my $self    = shift;
	my $mainFrm = $self->{"mainFrm"};

	# DEFINE SIZERS

	my $szMain  = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szPage1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szPage2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $szBtns      = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szBtnsChild = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE PANELS

	my $pnlBtns = Wx::Panel->new( $mainFrm, -1 );
	$pnlBtns->SetBackgroundColour($Widgets::Style::clrDefaultFrm);

	# DEFINE CONTROLS

	my $btnHide = Wx::Button->new( $pnlBtns, -1, "Hide", &Wx::wxDefaultPosition, [ 160, 33 ] );
	$btnHide->SetFont($Widgets::Style::fontBtn);
	Wx::Event::EVT_BUTTON( $btnHide, -1, sub { $self->__OnClick(@_) } );

	my $nb = Wx::Notebook->new( $mainFrm, -1, &Wx::wxDefaultPosition, &Wx::wxDefaultSize );
	my $imagelist = Wx::ImageList->new( 10, 25 );
	$nb->AssignImageList($imagelist);

	my $page1 = MyWxBookCtrlPage->new( $nb, 0 );
	$nb->AddPage( $page1, "Job queue", 0, 0 );
	$nb->SetPageImage( 0, 0 );

	my $page2 = MyWxBookCtrlPage->new( $nb, 1 );
	$nb->AddPage( $page2, "Settings", 0, 1 );
	$nb->SetPageImage( 0, 1 );

	my $jobsQueueStatBox = $self->__SetLayoutJobsQueue($page1);

	#my $settingsStatBox  = $self->__SetLayoutInCAMSettings($page1);
	my $groupsStatBox = $self->__SetLayoutGroups($page1);

	# BUILD STRUCTURE OF LAYOUT

	$szBtnsChild->Add( $btnHide, 0, &Wx::wxALL, 2 );
	$szBtns->Add( 10, 10, 1, &Wx::wxGROW );
	$szBtns->Add( $szBtnsChild, 0, &Wx::wxALIGN_RIGHT | &Wx::wxALL );
	$pnlBtns->SetSizer($szBtns);

	$page1->SetSizer($szPage1);
	$page2->SetSizer($szPage2);

	$szRow1->Add( $jobsQueueStatBox, 80, &Wx::wxEXPAND );

	#$szRow1->Add( $settingsStatBox,  20, &Wx::wxEXPAND );

	$szRow2->Add( $groupsStatBox, 1, &Wx::wxEXPAND );

	$szPage1->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szPage1->Add( $szRow2, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szMain->Add( $nb,      1, &Wx::wxEXPAND );
	$szMain->Add( $pnlBtns, 0, &Wx::wxEXPAND );

	# REGISTER EVENTS
	#Wx::Event::EVT_BUTTON( $btnHide, -1, sub { $self->__OnHideExporter() } );

	#Wx::Event::EVT_BUTTON( $btnExport, -1, sub { $self->__OnExportForceClick(@_) } );

	# SAVE NECESSARY CONTROLS

	$self->{"mainFrm"} = $mainFrm;
	$self->{"szMain"}  = $szMain;

	$mainFrm->SetSizer($szMain);

	return $mainFrm;

}

sub ActivateForm {
	my $self     = shift;
	my $activate = shift;
	my $position = shift;

	if ($activate) {

		if ($position) {

			$self->{"mainFrm"}->Move($position);
		}

		$self->{"mainFrm"}->Show(1);
		$self->{"mainFrm"}->Iconize(0);

		$self->{"mainFrm"}->SetFocus();
		$self->{"mainFrm"}->Raise();

#		my @windows = FindWindowLike( 0, "Exporter utility" );
#		for (@windows) {
#
#			   SetForegroundWindow( $_);
#			   SetFocus( $_);
#		}
#	 

	}
	else {

		$self->{"mainFrm"}->Hide();
	}
}

#sub __SetLayout {
#
#	my $self    = shift;
#	my $mainFrm = $self->{"mainFrm"};
#
#	#SIZERS
#	my $sz = Wx::BoxSizer->new(&Wx::wxVERTICAL);
#
#	#CONTROLS
#	my $txt = Wx::StaticText->new( $mainFrm, -1, "ahoj", &Wx::wxDefaultPosition, [ 100, 50 ] );
#	$self->{"txt"} = $txt;
#
#	my $txt2 = Wx::StaticText->new( $mainFrm, -1, "ahoj2", &Wx::wxDefaultPosition, [ 100, 50 ] );
#	$self->{"txt2"} = $txt2;
#
#	my $button = Wx::Button->new( $mainFrm, -1, "test click" );
#
#	Wx::Event::EVT_BUTTON( $button, -1, sub { $self->__OnClick($button) } );
#
#	my $button2 = Wx::Button->new( $mainFrm, -1, "exit job" );
#
#	Wx::Event::EVT_BUTTON( $button2, -1, sub { $self->__OnClickExit($button2) } );
#
#	my $button3 = Wx::Button->new( $mainFrm, -1, "run new job" );
#
#	Wx::Event::EVT_BUTTON( $button3, -1, sub { $self->__OnClickNew($button3) } );
#
#	my $pcbidTxt   = Wx::TextCtrl->new( $mainFrm, -1, "", &Wx::wxDefaultPosition, [ 150, 25 ] );
#	my $pcbguidTxt = Wx::TextCtrl->new( $mainFrm, -1, "", &Wx::wxDefaultPosition, [ 150, 25 ] );
#
#	my $gauge = Wx::Gauge->new( $mainFrm, -1, 100, [ -1, -1 ], [ 300, 20 ], &Wx::wxGA_HORIZONTAL );
#
#	$gauge->SetValue(0);
#
#	$sz->Add( $txt,        1, &Wx::wxEXPAND );
#	$sz->Add( $txt2,       1, &Wx::wxEXPAND );
#	$sz->Add( $gauge,      0, &Wx::wxEXPAND );
#	$sz->Add( $button,     0, &Wx::wxEXPAND );
#	$sz->Add( $button2,    0, &Wx::wxEXPAND );
#	$sz->Add( $button3,    0, &Wx::wxEXPAND );
#	$sz->Add( $pcbidTxt,   0, &Wx::wxEXPAND );
#	$sz->Add( $pcbguidTxt, 0, &Wx::wxEXPAND );
#
#	$mainFrm->SetSizer($sz);
#
#	$self->{"gauge"}      = $gauge;
#	$self->{"pcbidTxt"}   = $pcbidTxt;
#	$self->{"pcbguidTxt"} = $pcbguidTxt;
#
#
#
#	#$THREAD_MESSAGE_EVT = Wx::NewEventType;
#	#Wx::Event::EVT_COMMAND( $self->{"mainFrm"}, -1, $THREAD_MESSAGE_EVT, sub { $self->__JobExportMessHandler(@_) } );
#
#	return $mainFrm;
#
#}

# ========================================================================================== #
#  BUILD GUI SECTION
# ========================================================================================== #

# Set layout for Quick set box
sub __SetLayoutJobsQueue {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Jobs queue' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	#my @dimension = [ 500, 500 ];
	my $jobQueue = JobQueueForm->new( $parent, [ 500, 200 ] );

	$jobQueue->{"onSelectItemChange"}->Add( sub { $self->__JobItemSeletedChange(@_) } );

	#my $btnDefault    = Wx::Button->new( $statBox, -1, "Default settings",   &Wx::wxDefaultPosition, [ 110, 22 ] );

	$szStatBox->Add( $jobQueue, 1, &Wx::wxEXPAND );

	$self->{"jobQueue"} = $jobQueue;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutInCAMSettings {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'InCAM settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $btnDefault = Wx::Button->new( $statBox, -1, "Default settings", &Wx::wxDefaultPosition, [ 110, 22 ] );

	Wx::Event::EVT_BUTTON( $btnDefault, -1, sub { $self->__OnClick(@_) } );

	$szStatBox->Add( $btnDefault, 1, &Wx::wxEXPAND );

	return $szStatBox;
}

sub __OnClick {
	my $self = shift;

	my $x;

	my $y;
	my $point = $self->{"mainFrm"}->GetPosition();
	print $point->x();
	print $point->y();

	#$self->{"onClick"}->Do()

}

# Set layout for Quick set box
sub __SetLayoutGroups {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Job details' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	#my $btnDefault = Wx::Button->new( $statBox, -1, "Default settings", &Wx::wxDefaultPosition, [ 110, 22 ] );
	my $notebook = CustomNotebook->new( $statBox, -1 );

	#$szStatBox->Add( $btnDefault, 0, &Wx::wxEXPAND );
	$szStatBox->Add( $notebook, 1, &Wx::wxEXPAND );
	$self->{"groupStatBox"}   = $statBox;
	$self->{"groupStatBoxSz"} = $szStatBox;
	$self->{"notebook"}       = $notebook;

	return $szStatBox;
}

# ============================================
# Mehtods for update job queue items
# ============================================

sub SetJobItemStatus {
	my $self   = shift;
	my $taskId = shift;
	my $status = shift;

	my $jobItem = $self->{"jobQueue"}->GetItem($taskId);

	$jobItem->SetStatus($status);
}

sub SetJobItemProgress {
	my $self   = shift;
	my $taskId = shift;
	my $value  = shift;

	my $jobItem = $self->{"jobQueue"}->GetItem($taskId);

	$jobItem->SetProgress($value);
}

sub SetJobItemResult {
	my $self = shift;
	my $task = shift;

	my $jobItem = $self->{"jobQueue"}->GetItem( $task->GetTaskId() );

	$jobItem->SetExportResult( $task->Result(), $task->GetJobAborted(), $task->GetJobSentToProduce() );

}

sub SetJobItemToProduceResult {
	my $self = shift;
	my $task = shift;

	my $jobItem = $self->{"jobQueue"}->GetItem( $task->GetTaskId() );

	$jobItem->SetProduceErrors( $task->GetProduceErrorsCnt() );
	$jobItem->SetProduceWarnings( $task->GetProduceWarningsCnt() );
	$jobItem->SetProduceResult( $task->ResultToProduce(), $task->GetJobSentToProduce() );
}

sub SetJobQueueErrorCnt {
	my $self = shift;
	my $task = shift;

	my $jobItem = $self->{"jobQueue"}->GetItem( $task->GetTaskId() );

	$jobItem->SetExportErrorCnt( $task->GetErrorsCnt() );

}

sub SetJobQueueWarningCnt {
	my $self = shift;
	my $task = shift;

	my $jobItem = $self->{"jobQueue"}->GetItem( $task->GetTaskId() );

	$jobItem->SetExportWarningCnt( $task->GetWarningsCnt() );

}

sub RefreshGroupTable {
	my $self = shift;
	my $task = shift;

	my $page       = $self->{"notebook"}->GetPage( $task->GetTaskId() );
	my $groupTable = $page->GetPageContent();

	my ( $w, $pageHight ) = $self->{"notebook"}->GetSizeWH();

	$groupTable->RearrangeGroups( $page, $pageHight );

	$page->RefreshContent();

}

sub BuildGroupTableForm {
	my $self = shift;

	# class keep rows structure and group instances
	my $units = shift;

	#use aliased 'Programs::Exporter::ExportUtility::ExportUtility::Forms::GroupWrapperForm';
	#my $form = GroupWrapperForm->new($self->{"mainFrm"});

	#$self->{"szMain"}->Add( $form, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	my $groupTableForm = GroupTableForm->new( $self->{"groupStatBox"} );

	$groupTableForm->InitGroupTable($units);

	$self->{"groupStatBoxSz"}->Add( $groupTableForm, 0, &Wx::wxEXPAND );

	#$self->{"szMain"}->Add( $groupTableForm, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

}

# ======================================================
# HANDLERS
# ======================================================

sub __JobItemSeletedChange {
	my $self         = shift;
	my $jobQueueItem = shift;

	my $taskId = $jobQueueItem->GetTaskId();

	$self->{"notebook"}->ShowPage($taskId);

	#	$self->Layout();
	#$self->Refresh();

}

sub __OnProduceJobClick {
	my $self   = shift;
	my $taskId = shift;

	$self->{"onToProduce"}->Do($taskId);

}

sub __OnRemoveJobClick {
	my $self   = shift;
	my $taskId = shift;

	my $jobItem = $self->{"jobQueue"}->GetItem($taskId);

	$self->{"jobQueue"}->RemoveJobFromQueue($taskId);

	$self->{"notebook"}->RemovePage($taskId);

	$self->{"onRemoveJob"}->Do($taskId);

}

sub __OnAbortJobClick {
	my $self   = shift;
	my $taskId = shift;

	$self->_AbortJob($taskId);

}

sub __Test {
	my $self   = shift;
	my $taskId = shift;

	my $page       = $self->{"notebook"}->GetPage($taskId);
	my $groupTable = $page->GetPageContent();

	my ( $w, $pageHight ) = $self->{"notebook"}->GetSizeWH();

	$groupTable->Construct( $page, $pageHight );

	$page->RefreshContent();

}

sub __OnClickExit {

	my ( $self, $button ) = @_;
	$self->_AbortJob( $self->{"pcbidTxt"}->GetValue() );

}

sub __OnClickNew {

	my ( $self, $button ) = @_;

	#my @j = @{ $self->{"jobs"} };
	#my $i = ( grep { $j[$_]->{"pcbId"} eq $self->{"pcbidTxt"}->GetValue() } 0 .. $#j )[0];

	#if ( defined $i ) {

	my $jobGUID = $self->_AddJobToQueue( $self->{"pcbidTxt"}->GetValue() );

	#}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Programs::Exporter::ExporterUtility';

	#my $exporter = ExporterUtility->new();

	#$app->Test();

	#$exporter->MainLoop;

}

1;

1;
