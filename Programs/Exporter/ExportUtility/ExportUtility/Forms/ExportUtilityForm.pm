
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
	my $class  = shift;
	my $parent = shift;

	if ( defined $parent && $parent == -1 ) {
		$parent = undef;
	}

	my $title = "Exporter jobu";
	my @dimension = ( 1100, 700 );

	my $self = $class->SUPER::new( $parent, $title, \@dimension );

	bless($self);

	#set base class handlers

	my $mainFrm = $self->__SetLayout();

	#$mainFrm->Show(1);

	#$self->{'onSetLayout'}->Add( sub { $self->__OnSetLayout(@_)});

	$self->{"onClick"} = Event->new();

	return $self;
}

sub AddNewTaskGUI {
	my $self = shift;
	my $task = shift;

	my $taskId = $task->GetTaskId();
	my $taskData = $task->GetExportData();

	# Add new item to queue

	my $jobQueue = $self->{"jobQueue"};
	my $jobQueueItem = $jobQueue->AddItem( $taskId, $task->GetJobId(), $taskData);
	
	
	# SET HANDLERS
	$jobQueueItem->{"onProduce"}->Add(sub{ $self->__OnProduceClick(@_) });
	
	
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
	
	# Select alreadz added job item
	$self->{"jobQueue"}->SetSelectedItem($taskId);
	
	# Refresh form
	$self->{"mainFrm"}->Refresh();

}

sub __OnProduceClick{
	my $self = shift;
	my $taskId = shift;
	print "produce click\n";
	$self->__Test($taskId);
	
	
}

sub AddNewTask {
	my $self = shift;
	my $task = shift;

	$self->_AddJobToQueue(  $task->GetJobId(), $task->GetTaskId() );
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
	my $groupsStatBox    = $self->__SetLayoutGroups($page1);

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

	$self->{"onClick"}->Do()

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
	$szStatBox->Add( $notebook,   1, &Wx::wxEXPAND );
	$self->{"groupStatBox"}   = $statBox;
	$self->{"groupStatBoxSz"} = $szStatBox;
	$self->{"notebook"}       = $notebook;

	return $szStatBox;
}

# ========================================================================================== #
#  PRIVATE HELPER METHOD
# ========================================================================================== #


sub __GroupTableRefresh{
	my $self         = shift;
	my $taskId = 	shift;
	
	my $page = $self->{"notebook"}->GetPage($taskId);
	my $groupTable = $page->GetPageContent();

	my ($w, $pageHight)         = $self->{"notebook"}->GetSizeWH();

	$groupTable->RearrangeGroups($page, $pageHight);  
	
	
	$page->RefreshContent();
	
	 
	
}
# ============================================
# Mehtods for update job queue items
# ============================================
sub SetJobItemStatus{
	my $self         = shift;
	my $taskId = 	shift;
	my $status = 	shift;
	
	my $jobItem = $self->{"jobQueue"}->GetItem($taskId);
	
	$jobItem->SetStatus($status);
}

sub SetJobItemProgress{
	my $self         = shift;
	my $taskId = 	shift;
	my $value = 	shift;

	my $jobItem = $self->{"jobQueue"}->GetItem($taskId);
	
	$jobItem->SetProgress($value);
}

sub SetJobItemResult{
	my $self         = shift;
	my $taskId = 	shift;
	
	my $jobItem = $self->{"jobQueue"}->GetItem($taskId);
	
	$jobItem->SetJobItemResult();
}





sub __Test{
	my $self         = shift;
	my $taskId = 	shift;
	
	my $page = $self->{"notebook"}->GetPage($taskId);
	my $groupTable = $page->GetPageContent();

	my ($w, $pageHight)         = $self->{"notebook"}->GetSizeWH();

	$groupTable->Construct($page,$pageHight);  
	
	
	$page->RefreshContent();
 
}


sub __JobItemSeletedChange {
	my $self         = shift;
	my $jobQueueItem = shift;

	my $taskId = $jobQueueItem->GetTaskId();

	$self->{"notebook"}->ShowPage($taskId);
	
	#	$self->Layout();
	#$self->Refresh();

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

sub __Refresh {
	my ( $self, $frame, $event ) = @_;

	#$self->_SetDestroyServerOnDemand(1);

	my $txt2 = $self->_GetInfoServers();
	my $txt  = $self->_GetInfoJobs();

	$self->{"txt"}->SetLabel($txt);
	$self->{"txt2"}->SetLabel($txt2);

}

sub doExport {
	my ( $id, $inCAM ) = @_;

	my $errCode = $inCAM->COM( "clipb_open_job", job => $id, update_clipboard => "view_job" );

	#
	#	$errCode = $inCAM->COM(
	#		"open_entity",
	#		job  => "F17116+2",
	#		type => "step",
	#		name => "test"
	#	);

	#return 0;
	for ( my $i = 0 ; $i < 5 ; $i++ ) {

		sleep(3);
		$inCAM->COM(
					 'output_layer_set',
					 layer        => "c",
					 angle        => '0',
					 x_scale      => '1',
					 y_scale      => '1',
					 comp         => '0',
					 polarity     => 'positive',
					 setupfile    => '',
					 setupfiletmp => '',
					 line_units   => 'mm',
					 gscl_file    => ''
		);

		$inCAM->COM(
					 'output',
					 job                  => $id,
					 step                 => 'input',
					 format               => 'Gerber274x',
					 dir_path             => "c:/Perl/site/lib/TpvScripts/Scripts/data",
					 prefix               => "incam1_" . $id . "_$i",
					 suffix               => "",
					 break_sr             => 'no',
					 break_symbols        => 'no',
					 break_arc            => 'no',
					 scale_mode           => 'all',
					 surface_mode         => 'contour',
					 min_brush            => '25.4',
					 units                => 'inch',
					 coordinates          => 'absolute',
					 zeroes               => 'Leading',
					 nf1                  => '6',
					 nf2                  => '6',
					 x_anchor             => '0',
					 y_anchor             => '0',
					 wheel                => '',
					 x_offset             => '0',
					 y_offset             => '0',
					 line_units           => 'mm',
					 override_online      => 'yes',
					 film_size_cross_scan => '0',
					 film_size_along_scan => '0',
					 ds_model             => 'RG6500'
		);

	}
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
