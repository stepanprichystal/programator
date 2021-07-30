#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Forms::PnlWizardForm;
use base 'Widgets::Forms::StandardFrm';

#3th party library
use strict;
use warnings;
use Wx;
use Win32::GuiTest qw(FindWindowLike GetWindowText   SendKeys SetFocus SendRawKey :VK SendMessage);
use List::Util qw(first);

#local library
#use aliased 'Packages::Tests::Test';
#use aliased 'Widgets::Forms::MyWxFrame';
use aliased 'Packages::Events::Event';
use aliased 'Packages::Other::AppConf';

#use aliased 'Managers::MessageMngr::MessageMngr';
#use aliased 'Programs::Comments::CommWizard::Forms::CommListViewFrm::CommListViewFrm';
#use aliased 'Programs::Comments::CommWizard::Forms::CommViewFrm::CommViewFrm';
#use Widgets::Style;
#use aliased 'Widgets::Forms::MyWxStaticBoxSizer';
use aliased 'Programs::Panelisation::PnlWizard::Forms::PartContainerForm';
use aliased 'Programs::Panelisation::PnlWizard::EnumsStyle';
use aliased 'Programs::Panelisation::PnlWizard::Enums';
use aliased 'Packages::InCAMHelpers::AppLauncher::Helper';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'CamHelpers::CamJob';

use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamLayer';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class   = shift;
	my $parent  = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $pnlType = shift;

	my @dimension = ( 960, 880 );
	my $flags     = &Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxMINIMIZE_BOX | &Wx::wxMAXIMIZE_BOX | &Wx::wxCLOSE_BOX | &Wx::wxRESIZE_BORDER;
	my $title     = "Panel builder - $jobId";

	my $self = $class->SUPER::new( $parent, $title, \@dimension, $flags );

	bless($self);

	# Properties
	$self->{"inCAM"}           = $inCAM;
	$self->{"jobId"}           = $jobId;
	$self->{"title"}           = $title;
	$self->{"pnlType"}         = $pnlType;
	$self->{"loadLastEnabled"} = 0;
	$self->{"windowsDocked"}   = 0;

	$self->__SetLayout();

	#EVENTS

	$self->{"createClickEvt"}    = Event->new();
	$self->{"leaveClickEvt"}     = Event->new();
	$self->{"cancelClickEvt"}    = Event->new();
	$self->{"showInCAMClickEvt"} = Event->new();

	$self->{"loadLastClickEvt"}    = Event->new();
	$self->{"loadDefaultClickEvt"} = Event->new();

	$self->{"previewChangedEvt"} = Event->new();
	$self->{"stepChangedEvt"}    = Event->new();

	#	$self->{"onExportASync"} = Event->new();
	#	$self->{"onClose"}       = Event->new();
	#
	#	$self->{"onUncheckAll"}  = Event->new();
	#	$self->{"onLoadLast"}    = Event->new();
	#	$self->{"onLoadDefault"} = Event->new();

	#$mainFrm->Show(1);

	return $self;
}

sub SetInCAMBusyLayout {
	my $self          = shift;
	my $isBusy        = shift;
	my $previewActive = shift;

	if ($isBusy) {

		#$self->{"pnlInCAMBusy"}->Refresh();
		$self->{"pnlHeader"}->Disable();
		$self->{"partContainer"}->Disable();
		$self->{"pnlBtns"}->Disable();

		$self->{"waitFrmPID"} = Helper->ShowWaitFrm( $self->{"title"}, "Wait for background process until release InCAM" );

	}
	else {
		#$self->{"InCAMBusy"}->Hide();
		$self->{"pnlHeader"}->Enable();
		$self->{"partContainer"}->Enable();
		$self->{"pnlBtns"}->Enable();

		if ( $self->{"waitFrmPID"} ) {

			Helper->CloseWaitFrm( $self->{"waitFrmPID"} );
		}

		$self->SetPreviewChangedLayout($previewActive);
	}

}

sub SetFinalProcessLayout {
	my $self          = shift;
	my $val           = shift;    #
	my $previewActive = shift;

	if ($val) {

		$self->{"pnlHeaderSett"}->Disable();
		$self->{"partContainer"}->SetFinalProcessLayout($val);

		$self->EnableCreateBtn(0);
		$self->EnableLeaveBtn(0);
		$self->EnableShowInCAMBtn(0);
		$self->EnableCancelBtn(0);
	}
	else {
		$self->{"pnlHeaderSett"}->Enable();
		$self->{"partContainer"}->SetFinalProcessLayout($val);

		$self->EnableCreateBtn(1);
		$self->EnableLeaveBtn(1);
		$self->EnableShowInCAMBtn(1);
		$self->EnableCancelBtn(1);

		$self->SetPreviewChangedLayout($previewActive);
	}

}

sub SetAsyncTaskRunningLayout {
	my $self          = shift;
	my $val           = shift;    #
	my $previewActive = shift;

	if ($val) {

		$self->{"loadLastBtn"}->Disable();
		$self->{"loadDefaultBtn"}->Disable();

		$self->EnableCreateBtn(0);
		$self->EnableLeaveBtn(0);
		$self->EnableShowInCAMBtn(0);
		$self->EnableCancelBtn(0);
	}
	else {
		$self->{"loadLastBtn"}->Enable() if ( $self->{"loadLastEnabled"} );
		$self->{"loadDefaultBtn"}->Enable();
		$self->EnableCreateBtn(1);
		$self->EnableLeaveBtn(1);
		$self->EnableShowInCAMBtn(1);
		$self->EnableCancelBtn(1);

		$self->SetPreviewChangedLayout($previewActive);
	}

}

sub SetPreviewChangedLayout {
	my $self          = shift;
	my $previewActive = shift;

	# Disable/Enable Show in InCAM btn

	if ($previewActive) {
		$self->EnableLeaveBtn(1);
		$self->EnableShowInCAMBtn(1);
	}
	else {
		$self->EnableLeaveBtn(0);
		$self->EnableShowInCAMBtn(0);

	}

}

sub EnableCreateBtn {
	my $self   = shift;
	my $enable = shift;

	if ($enable) {
		$self->{"btnCreate"}->Enable();

	}
	else {
		$self->{"btnCreate"}->Disable();

	}
}

sub EnableLeaveBtn {
	my $self   = shift;
	my $enable = shift;

	if ($enable) {
		$self->{"btnLeave"}->Enable();

	}
	else {
		$self->{"btnLeave"}->Disable();

	}
}

sub EnableShowInCAMBtn {
	my $self   = shift;
	my $enable = shift;

	if ($enable) {
		$self->{"btnShowInCAM"}->Enable();

	}
	else {
		$self->{"btnShowInCAM"}->Disable();

	}
}

sub EnableCancelBtn {
	my $self   = shift;
	my $enable = shift;

	if ($enable) {
		$self->{"btnCancel"}->Enable();

	}
	else {
		$self->{"btnCancel"}->Disable();

	}

}

sub EnableLoadLastBtn {
	my $self   = shift;
	my $enable = shift;
	my $date   = shift;

	if ($enable) {
		$self->{"loadLastBtn"}->Enable();
		$self->{"loadLastBtn"}->SetLabel( "Last settings (" . $date . ")" );

	}
	else {
		$self->{"loadLastBtn"}->Disable();
		$self->{"loadLastBtn"}->SetLabel("Last settings");

	}

	$self->{"loadLastEnabled"} = $enable;

}

sub BuildPartContainer {
	my $self  = shift;
	my $inCAM = shift;
	my $parts = shift;

	$self->{"mainFrm"}->Freeze();

	my $messMngr = $self->_GetMessageMngr();

	$self->{"partContainer"}->InitContainer( $parts, $messMngr, $inCAM );

	$self->{"mainFrm"}->Thaw();
}

sub GetMessageMngr {
	my $self = shift;

	return $self->_GetMessageMngr();

}

sub GetStep {
	my $self = shift;

	return $self->{"stepValTxt"}->GetValue();
}

sub SetStep {
	my $self  = shift;
	my $value = shift;

	$self->{"stepValTxt"}->SetValue($value);
}

sub GetPreview {
	my $self = shift;

	if ( $self->{"previewChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

sub SetPreview {
	my $self  = shift;
	my $value = shift;

	$self->{"previewChb"}->SetValue($value);
}

sub GetFlatten {
	my $self = shift;

	if ( $self->{"flattenChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

sub SetFlatten {
	my $self  = shift;
	my $value = shift;

	$self->{"flattenChb"}->SetValue($value);
}

sub Destroy {
	my $self = shift;

	if ( $self->{"windowsDocked"} ) {
		$self->__OnDockWindows();

	}

	$self->{"mainFrm"}->Destroy();
}

sub __SetLayout {
	my $self = shift;

	$self->{"mainFrm"}->SetBackgroundColour( AppConf->GetColor("clrMainFrmBackground") );

	# DEFINE CONTROLS
	my $szMain       = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $headerLayout = $self->__SetLayoutHeader( $self->{"mainFrm"} );
	my $partLayout   = $self->__SetLayoutParts( $self->{"mainFrm"} );

	my $gauge = Wx::Gauge->new( $self->{"mainFrm"}, -1, 100, [ -1, -1 ], [ -10, 12 ], &Wx::wxGA_HORIZONTAL );
	$gauge->SetValue(100);
	$gauge->Pulse();
	$gauge->Hide();

	$szMain->Add( $headerLayout, 0, &Wx::wxEXPAND );
	$szMain->Add( 3, 3, 0, &Wx::wxEXPAND );
	$szMain->Add( $gauge,        0, &Wx::wxEXPAND );
	$szMain->Add( 2, 2, 0, &Wx::wxEXPAND );
	$szMain->Add( $partLayout, 1, &Wx::wxEXPAND );

	$self->AddContent($szMain);
	$self->SetButtonHeight(30);
	my $btnCancel = $self->AddButton( "Cancel", sub { $self->{"cancelClickEvt"}->Do() } );

	my $btnLeave     = $self->AddButton( "Leave as it is", sub { $self->{"leaveClickEvt"}->Do() } );
	my $btnShowInCAM = $self->AddButton( "Show in editor", sub { $self->{"showInCAMClickEvt"}->Do() } );
	my $btnCreate    = $self->AddButton( "Check + Create", sub { $self->{"createClickEvt"}->Do() } );

	$btnLeave->Disable();
	$btnShowInCAM->Disable();

	# DEFINE EVENTS
	$self->{"mainFrm"}->{"onClose"}->Add( sub { $self->{"cancelClickEvt"}->Do(); } );

	# DEFINE LAYOUT STRUCTURE

	# KEEP REFERENCES
	$self->{"btnCancel"} = $btnCancel;

	$self->{"btnLeave"}       = $btnLeave;
	$self->{"btnShowInCAM"}   = $btnShowInCAM;
	$self->{"btnCreate"}      = $btnCreate;
	$self->{"mainProgessbar"} = $gauge;
	$self->{"szMain"}         = $szMain;

}

#
# Set header
sub __SetLayoutHeader {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes

	my $szMain     = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szMainSett = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $szSettCol1     = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szSettCol2     = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szSettCol3     = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szSettCol4     = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szSettCol1Row1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szSettCol1Row2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szSettCol2Row1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $szQuickBtn = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# Define panels

	my $pnlMain = Wx::Panel->new( $parent, -1 );

	my $pnlSett = Wx::Panel->new( $pnlMain, -1 );
	my $pnlSepar = Wx::Panel->new( $pnlSett, -1, &Wx::wxDefaultPosition, [ 2, -1 ] );

	$pnlMain->SetBackgroundColour( AppConf->GetColor("clrMainHeaderBackground") );
	$pnlSett->SetBackgroundColour( AppConf->GetColor("clrMainHeaderSettBackground") );
	$pnlSepar->SetBackgroundColour( AppConf->GetColor("clrMainHeaderSeparator") );

	# DEFINE CONTROLS
	my $title = AppConf->GetValue("panelTypeTitle");

	my $titleTxt = Wx::StaticText->new( $pnlMain, -1, $title, &Wx::wxDefaultPosition, [ 238, -1 ] );
	$titleTxt->SetForegroundColour( AppConf->GetColor("clrTitleText") );
	my $f = Wx::Font->new( 14, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_BOLD );
	$titleTxt->SetFont($f);

	my $stepTxt = Wx::StaticText->new( $pnlSett, -1, "Step name:", &Wx::wxDefaultPosition, [ 70, 24 ] );
	my $stepValTxt = Wx::TextCtrl->new( $pnlSett, -1, "mpanel", &Wx::wxDefaultPosition );

	my $flattenTxt = Wx::StaticText->new( $pnlSett, -1, "Flatten:", &Wx::wxDefaultPosition, [ 70, 24 ] );
	my $flattenChb = Wx::CheckBox->new( $pnlSett, -1, "", &Wx::wxDefaultPosition, [ 70, 24 ] );
	if ( $self->{"pnlType"} ne PnlCreEnums->PnlType_CUSTOMERPNL ) {

		$flattenTxt->Hide();
		$flattenChb->Hide();
	}

	#my $previewTxt = Wx::StaticText->new( $pnlSett, -1, "Preview:", &Wx::wxDefaultPosition, [ 70, 22 ] );
	my $dockWindowsBtn = Wx::Button->new( $pnlSett, -1, "Dock windows", &Wx::wxDefaultPosition, [ 100, 24 ] );
	my $previewChb = Wx::CheckBox->new( $pnlSett, -1, "Preview", &Wx::wxDefaultPosition, [ 100, 24 ] );

	my $showSigLBtn = Wx::Button->new( $pnlSett, -1, "Show SIG layers", &Wx::wxDefaultPosition, [ 100, 24 ] );
	my $showNCLBtn  = Wx::Button->new( $pnlSett, -1, "Show NC layers",  &Wx::wxDefaultPosition, [ 100, 24 ] );

	my $loadLastBtn    = Wx::Button->new( $pnlSett, -1, "Last settings",    &Wx::wxDefaultPosition, [ 140, 24 ] );
	my $loadDefaultBtn = Wx::Button->new( $pnlSett, -1, "Default settings", &Wx::wxDefaultPosition, [ 140, 24 ] );

	# BUILD LAYOUT STRUCTURE

	$szSettCol1Row1->Add( $stepTxt,    0, &Wx::wxALL, 0 );
	$szSettCol1Row1->Add( $stepValTxt, 0, &Wx::wxALL, 0 );

	$szSettCol1Row2->Add( $flattenTxt, 0, &Wx::wxALL, 0 );
	$szSettCol1Row2->Add( $flattenChb, 0, &Wx::wxALL, 0 );

	$szSettCol1->Add( $szSettCol1Row1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szSettCol1->Add( $szSettCol1Row2, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szSettCol2->Add( $dockWindowsBtn, 0, &Wx::wxALL, 0 );
	$szSettCol2->Add( $previewChb,     0, &Wx::wxALL, 0 );

	$szSettCol3->Add( $showSigLBtn, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szSettCol3->Add( $showNCLBtn,  0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szSettCol4->Add( $loadDefaultBtn, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szSettCol4->Add( $loadLastBtn,    0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szMainSett->Add( 10, 10, 0, );
	$szMainSett->Add( $szSettCol1, 0, &Wx::wxALL,                                 2 );
	$szMainSett->Add( $pnlSepar,   0, &Wx::wxEXPAND | &Wx::wxLEFT | &Wx::wxRIGHT, 4 );
	$szMainSett->Add( $szSettCol2, 0, &Wx::wxALL,                                 2 );
	$szMainSett->Add( $szSettCol3, 0, &Wx::wxALL,                                 2 );
	$szMainSett->AddStretchSpacer(1);
	$szMainSett->Add( $szSettCol4, 0, &Wx::wxALL, 2 );

	$pnlMain->SetSizer($szMain);
	$pnlSett->SetSizer($szMainSett);

	$szMain->Add( 14, 4, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $titleTxt, 0, &Wx::wxALIGN_CENTER | &Wx::wxALL, 0 );

	$szMain->Add( $pnlSett, 1, &Wx::wxEXPAND | &Wx::wxALL, 5 );

	# REGISTER EVENTS

	Wx::Event::EVT_CHECKBOX( $previewChb, -1, sub { $self->{"previewChangedEvt"}->Do( ( $self->{"previewChb"}->IsChecked() ? 1 : 0 ) ) } );
	Wx::Event::EVT_TEXT( $stepValTxt, -1, sub { $self->{"stepChangedEvt"}->Do( $stepValTxt->GetValue() ) } );
	Wx::Event::EVT_BUTTON( $showSigLBtn, -1, sub { $self->__OnShowLayers( 1, 0 ) } );
	Wx::Event::EVT_BUTTON( $showNCLBtn,  -1, sub { $self->__OnShowLayers( 0, 1 ) } );
	Wx::Event::EVT_BUTTON( $loadLastBtn, -1, sub { $self->{"loadLastClickEvt"}->Do() } );
	Wx::Event::EVT_BUTTON( $loadDefaultBtn, -1, sub { $self->{"loadDefaultClickEvt"}->Do() } );
	Wx::Event::EVT_BUTTON( $dockWindowsBtn, -1, sub { $self->__OnDockWindows(@_) } );

	#$szRow1->Add( $defaultTxt,   1, &Wx::wxEXPAND );
	#	$szRow1->Add( $noteTxt, 1, &Wx::wxEXPAND );
	#
	#	$szMain->Add( $szRow1, 1, &Wx::wxEXPAND );
	#
	#	$szStatBox->Add( $szMain, 1, &Wx::wxEXPAND );

	$self->{"pnlHeader"}     = $pnlMain;
	$self->{"pnlHeaderSett"} = $pnlSett;

	$self->{"loadLastBtn"}    = $loadLastBtn;
	$self->{"loadDefaultBtn"} = $loadDefaultBtn;
	$self->{"dockWindowsBtn"} = $dockWindowsBtn;
	$self->{"showSigLBtn"}    = $showSigLBtn;
	$self->{"showNCLBtn"}     = $showNCLBtn;

	$self->{"stepValTxt"} = $stepValTxt;

	$self->{"previewChb"} = $previewChb;
	$self->{"flattenChb"} = $flattenChb;

	return $pnlMain;
}

# Set header
sub __SetLayoutParts {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes

	#my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# Define panels

	my $partContainer = PartContainerForm->new( $parent, $self->{"pnlType"} );

	#$pnlMain->SetBackgroundColour( Wx::Colour->new( 240, 240, 240 ) );

	# DEFINE CONTROLS

	# BUILD LAYOUT STRUCTURE

	#$pnlMain->SetSizer($szMain);

	# REGISTER EVENTS

	#$szRow1->Add( $defaultTxt,   1, &Wx::wxEXPAND );
	#	$szRow1->Add( $noteTxt, 1, &Wx::wxEXPAND );
	#
	#	$szMain->Add( $szRow1, 1, &Wx::wxEXPAND );
	#
	#	$szStatBox->Add( $szMain, 1, &Wx::wxEXPAND );

	# SET REFERENCES
	$self->{"partContainer"} = $partContainer;

	return $partContainer;
}
#

#
## Set layout for Quick set box
#sub __SetLayoutQuickSet {
#	my $self   = shift;
#	my $parent = shift;
#
#	#define staticboxes
#	my $statBox = Wx::StaticBox->new( $parent, -1, 'Quick option' );
#	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
#
#	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
#	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
#	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
#	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
#
#	#my $defaultTxt    = Wx::StaticText->new( $statBox, -1, "Default settings", &Wx::wxDefaultPosition, [ 80, 18 ] );
#	#my $uncheckAllTxt    = Wx::StaticText->new( $statBox, -1, "Uncheck all", &Wx::wxDefaultPosition, [ 80, 18 ] );
#	#my $loadLastTxt    = Wx::StaticText->new( $statBox, -1, "Last used settings", &Wx::wxDefaultPosition, [ 80, 18 ] );
#
#	my $btnDefault    = Wx::Button->new( $statBox, -1, "Default settings",   &Wx::wxDefaultPosition, [ 110, 22 ] );
#	my $btnUncheckAll = Wx::Button->new( $statBox, -1, "Uncheck all",        &Wx::wxDefaultPosition, [ 110, 22 ] );
#	my $btnLoadLast   = Wx::Button->new( $statBox, -1, "Last used settings", &Wx::wxDefaultPosition, [ 110, 22 ] );
#
#	# REGISTER EVENTS
#	Wx::Event::EVT_BUTTON( $btnDefault,    -1, sub { $self->__OnLoadDefaultClick() } );
#	Wx::Event::EVT_BUTTON( $btnUncheckAll, -1, sub { $self->__OnUncheckAllClick() } );
#	Wx::Event::EVT_BUTTON( $btnLoadLast,   -1, sub { $self->__OnLoadLastClick() } );
#
#	#$szRow1->Add( $defaultTxt,   1, &Wx::wxEXPAND );
#	$szRow1->Add( $btnDefault, 0 );
#
#	#$szRow2->Add( $uncheckAllTxt,   1, &Wx::wxEXPAND );
#	$szRow2->Add( $btnUncheckAll, 0 );
#
#	#$szRow3->Add( $loadLastTxt,   1, &Wx::wxEXPAND );
#	$szRow3->Add( $btnLoadLast, 0 );
#
#	$szMain->Add( $szRow1, 1, &Wx::wxEXPAND );
#	$szMain->Add( $szRow2, 1, &Wx::wxEXPAND );
#	$szMain->Add( $szRow3, 1, &Wx::wxEXPAND );
#
#	$szStatBox->Add( $szMain, 1, &Wx::wxEXPAND );
#
#	$self->{"btnLoadLast"} = $btnLoadLast;
#
#	return $szStatBox;
#
#}

## Set layout for Export path box
#sub __SetLayoutExportPath {
#	my $self   = shift;
#	my $parent = shift;
#
#	#define staticboxes
#	my $statBox = Wx::StaticBox->new( $parent, -1, 'Export location' );
#	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
#
#	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
#	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
#	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
#
#	my $rbClient = Wx::RadioButton->new( $statBox, -1, "C:/Export", &Wx::wxDefaultPosition, [ 110, 22 ], &Wx::wxRB_GROUP );
#	$rbClient->SetBackgroundColour( Wx::Colour->new( 228, 232, 243 ) );
#	my $rbArchiv = Wx::RadioButton->new( $statBox, -1, "Job archive ", &Wx::wxDefaultPosition, [ 110, 22 ] );
#	$rbArchiv->SetBackgroundColour( Wx::Colour->new( 0, 0, 0 ) );
#
#	#$szRow1->Add( $defaultTxt,   1, &Wx::wxEXPAND );
#	$szRow1->Add( $rbClient, 0, &Wx::wxEXPAND );
#
#	#$szRow2->Add( $uncheckAllTxt,   1, &Wx::wxEXPAND );
#	$szRow2->Add( $rbArchiv, 0, &Wx::wxEXPAND );
#
#	$szMain->Add( $szRow1, 1, &Wx::wxEXPAND );
#	$szMain->Add( $szRow2, 1, &Wx::wxEXPAND );
#
#	$szStatBox->Add( $szMain, 1, &Wx::wxEXPAND );
#
#	return $szStatBox;
#
#}
#
## Set layout for Export path box
#sub __SetLayoutOther {
#	my $self   = shift;
#	my $parent = shift;
#
#	#define staticboxes
#	my $statBox = Wx::StaticBox->new( $parent, -1, 'Other options' );
#	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
#	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
#
#	my $noteTextTxt = undef;
#
#	#my $orderNum = HegMethods->GetPcbOrderNumber($self->{"jobId"});
#	my @affectOrder = ();
#
#	push( @affectOrder, HegMethods->GetOrdersByState( $self->{"jobId"}, 2 ) );    # Orders on Predvzrobni priprava
#	push( @affectOrder, HegMethods->GetOrdersByState( $self->{"jobId"}, 4 ) );    # Orders on Ve vyrobe
#
#	my @affectOrderNum = sort { $a <=> $b } map { $_->{"reference_subjektu"} =~ /-(\d+)/ } @affectOrder;
#
#	$noteTextTxt = Wx::StaticText->new( $statBox, -1, "   REORDER (" . join( "; ", @affectOrderNum ) . ")   ", &Wx::wxDefaultPosition, [ 110, 22 ] );
#	$noteTextTxt->SetForegroundColour( Wx::Colour->new( 255, 0, 0 ) );
#
#	#my $firstOrder = grep { $_ == 1 } @affectOrderNum;
#
#	if ( scalar(@affectOrderNum) <= 1 ) {
#		$noteTextTxt->Hide();
#	}
#
#	my $sentToProduce = 1;
#
#	# if affected orders are all reorders and has state "Hotovo-zadat" or "Zadano"
#	# Uncheck sent to produce
#
#	my @exported =
#	  grep { $_->{"aktualni_krok"} eq EnumsIS->CurStep_HOTOVOZADAT || $_->{"aktualni_krok"} eq EnumsIS->CurStep_ZADANO } @affectOrder;
#
#	if ( scalar(@exported) == scalar(@affectOrder) ) {
#		$sentToProduce = 0;
#	}
#
#	my $chbProduce = Wx::CheckBox->new( $statBox, -1, "Sent to produce", &Wx::wxDefaultPosition, [ 110, 22 ] );
#	$chbProduce->SetValue($sentToProduce);
#	$chbProduce->Disable() if ( $self->{"isOffer"} );
#
#	#$chbProduce->SetTransparent(0);
#	#$chbProduce->Refresh();
#	#$chbProduce->SetBackgroundStyle(&Wx::wxBG_STYLE_TRANSPARENT);
#	$chbProduce->SetBackgroundColour( Wx::Colour->new( 255, 255, 255 ) );
#
#	$chbProduce->SetBackgroundColour( Wx::Colour->new( 255, 255, 255 ) );
#	$chbProduce->Refresh();
#
#	$szMain->Add( $noteTextTxt, 0 );
#
#	#$szMain->Add( 20,20, 0, &Wx::wxEXPAND );
#	$szMain->Add( $chbProduce, 0 );
#	$szStatBox->Add( $szMain, 1, &Wx::wxEXPAND );
#
#	# SAVE REFERENCES
#	$self->{"chbProduce"} = $chbProduce;
#
#	return $szStatBox;
#
#}

sub ShowProgressBar {
	my $self = shift;
	my $show = shift;

	if ($show) {
		$self->{"mainProgessbar"}->Show();

	}
	else {

		$self->{"mainProgessbar"}->Hide();

	}

	$self->{"szMain"}->Layout();
}

sub __OnDockWindows {
	my $self = shift;

	#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

	my $jobId = $self->{"jobId"};

	my $title          = $self->{"title"};
	my $pnlWizard      = GetWindowByTitle( $jobId, qr/^$title/i );
	my $pnlWizardInCAM = GetWindowByTitle( $jobId, qr/InCAM.*PID.*${jobId}/i );

	if ( !defined $pnlWizard || !defined $pnlWizardInCAM ) {

		my $messMngr = $self->_GetMessageMngr();
		my @mess1    = ("Error during docking windows");
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess1 );
	}

	if ( $self->{"windowsDocked"} ) {

		# UNDOCK window

		SendMessage( $pnlWizard, 0x0112, 0xF120, 0 );    # Restore

		SendMessage( $pnlWizardInCAM, 0x0112, 0xF120, 0 );    # Restore

		# UNDOCK window
		$self->{"windowsDocked"} = 0;
		$self->{"dockWindowsBtn"}->SetLabel("Dock Window");
		$self->{"inCAM"}->COM( "show_component", "component" => "Layers_List", "show" => "yes" );

	}
	else {
		# DOCK window
		$self->{"mainFrm"}->Freeze();
		SendMessage( $pnlWizard, 0x0112, 0xF030, 0 );         # Maximize window

		#  Dock to left half of screen
		SetFocus($pnlWizard);
		SendRawKey( VK_LWIN, 0 );
		SendKeys("{LEFT}");
		SendRawKey( VK_LWIN, KEYEVENTF_KEYUP );

		SendMessage( $pnlWizardInCAM, 0x0112, 0xF030, 0 );    # Maximize window

		#  Dock to right half of screen
		SetFocus($pnlWizardInCAM);
		SendRawKey( VK_LWIN, 0 );
		SendKeys("{RIGHT}");
		SendRawKey( VK_LWIN, KEYEVENTF_KEYUP );

		#		$self->{"previewChb"}->SetValue(1);                   # Activate preview if docking window
		#		$self->{"previewChangedEvt"}->Do(1);

		$self->{"windowsDocked"} = 1;
		$self->{"dockWindowsBtn"}->SetLabel("Undock Window");
		$self->{"inCAM"}->COM( "show_component", "component" => "Layers_List", "show" => "no" );
		$self->{"inCAM"}->COM("zoom_home");
		$self->{"mainFrm"}->Thaw();

	}

	sub GetWindowByTitle {
		my $jobId = shift;

		my $regexp = shift;

		my $win = undef;

		my @windows = FindWindowLike( 0, $jobId );
		foreach my $win (@windows) {

			my $winTitle = GetWindowText($win);

			if ( $winTitle =~ m/$regexp/ ) {

				return $win;
			}
		}
	}

	return 0;

}

sub __OnShowLayers {
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

	my $btnText = "";
	my $btn     = undef;
	if ($showSig) {
		$btnText = "SIG layers";
		$btn     = $self->{"showSigLBtn"};
	}
	if ($showNC) {
		$btnText = "NC layers";
		$btn     = $self->{"showNCLBtn"};
	}

	if ( scalar(@dispLayers) > scalar(@notDispLayers) ) {

		# Deactivate all
		CamLayer->DisplayLayers( $inCAM, \@layers2Disp, 0, 0 );

		$btn->SetLabel( "Show " . $btnText );

	}
	else {

		# Activate all
		CamLayer->DisplayLayers( $inCAM, \@layers2Disp, 1, 0 );
		$inCAM->COM( "display_sr", "display" => "yes" );
		$btn->SetLabel( "Hide " . $btnText );

	}

}

#
#sub _AddEvent {
#	my $self      = shift;
#	my $event     = shift;
#	my $eventType = shift;
#
#	$self->{"mainFrm"}->Layout();
#
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $test = Programs::Exporter::ExportChecker::Forms::GroupTableForm->new();

	#$test->MainLoop();
}

1;

