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

#local library
#use aliased 'Packages::Tests::Test';
#use aliased 'Widgets::Forms::MyWxFrame';
#use aliased 'Packages::Events::Event';
#use aliased 'Managers::MessageMngr::MessageMngr';
#use aliased 'Programs::Comments::CommWizard::Forms::CommListViewFrm::CommListViewFrm';
#use aliased 'Programs::Comments::CommWizard::Forms::CommViewFrm::CommViewFrm';
#use Widgets::Style;
#use aliased 'Widgets::Forms::MyWxStaticBoxSizer';
use aliased 'Programs::Panelisation::PnlWizard::Forms::PartContainerForm';
use aliased 'Programs::Panelisation::PnlWizard::EnumsStyle';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class  = shift;
	my $parent = shift;

	my $jobId  = shift;
	my $orders = shift;

	my @dimension = ( 1000, 800 );
	my $flags = &Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxMINIMIZE_BOX | &Wx::wxMAXIMIZE_BOX | &Wx::wxCLOSE_BOX | &Wx::wxRESIZE_BORDER;

	my $self = $class->SUPER::new( $parent, "Panelisation - $jobId", \@dimension, $flags );

	bless($self);

	$self->__SetLayout();

	# Properties

	#EVENTS

	#	$self->{"onExportSync"}  = Event->new();
	#	$self->{"onExportASync"} = Event->new();
	#	$self->{"onClose"}       = Event->new();
	#
	#	$self->{"onUncheckAll"}  = Event->new();
	#	$self->{"onLoadLast"}    = Event->new();
	#	$self->{"onLoadDefault"} = Event->new();

	#$mainFrm->Show(1);

	return $self;
}
#
#sub GetToProduce {
#	my $self = shift;
#
#	return $self->{"chbProduce"}->GetValue();
#}
#
## Disable all controls on form
#sub DisableForm {
#	my $self    = shift;
#	my $disable = shift;
#
#	if ($disable) {
#
#		$self->{"mainPnl"}->Disable();
#		$self->{"nb"}->Disable();
#
#	}
#	else {
#
#		$self->{"mainPnl"}->Enable();
#		$self->{"nb"}->Enable();
#	}
#
#}
#
## Disable all controls on form
#sub DisableExportBtn {
#	my $self    = shift;
#	my $disable = shift;
#
#	if ($disable) {
#
#		$self->{"btnSync"}->Disable();
#		$self->{"btnASync"}->Disable();
#		$self->{"btnASyncServer"}->Disable();
#	}
#	else {
#
#		$self->{"btnSync"}->Enable();
#		$self->{"btnASync"}->Enable();
#		$self->{"btnASyncServer"}->Enable();
#	}
#
#}
#
## Set "Load last" button visibility
#sub SetLoadLastBtn {
#	my $self   = shift;
#	my $enable = shift;
#
#	if ($enable) {
#		$self->{"btnLoadLast"}->Enable();
#	}
#	else {
#		$self->{"btnLoadLast"}->Disable();
#	}
#}
#
#sub OnInit {
#	my $self = shift;
#
#	return 1;
#}
#
## Return group builder, which is responsible for building
## groups gui and adding groups to form
#sub GetGroupBuilder {
#	my $self = shift;
#	return $self->{"groupBuilder"};
#}
#
## Add new page in nootebook
#sub AddPage {
#	my ( $self, $title ) = @_;
#	my $count = $self->{"nb"}->GetPageCount();
#	my $page = MyWxBookCtrlPage->new( $self->{"nb"}, $count );
#
#	$self->{"nb"}->AddPage( $page, $title . "    ", 0, $count );
#	$self->{"nb"}->SetPageImage( $count, 0 );
#
#	#row height is 10px. When we get total height of panel in scrollwindow
#	# then we compute number of rows as: totalHeight/10px
#	my $rowHeight = 10;
#	my $scrollPnl = ScrollPanel->new( $page, $rowHeight );
#
#	my $szTab = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
#
#	$szTab->Add( $scrollPnl, 1, &Wx::wxEXPAND );
#
#	$page->SetSizer($szTab);
#
#	$page->{"scrollPnl"} = $scrollPnl;
#
#	#$self->{"scrollPnl"} = $scrollPnl;
#
#	Wx::Event::EVT_PAINT( $scrollPnl, sub { $self->__OnScrollPaint(@_) } );
#
#	return $page;
#}
#
sub BuildPartContainer {
	my $self  = shift;
	my $inCAM = shift;
	my $parts = shift;

	$self->{"mainFrm"}->Freeze();

	$self->{"partContainer"}->InitContainer($parts);

	$self->{"mainFrm"}->Thaw();
}
#
## Create event/handler connection between groups by binding handlers to evnets
## provided by groups
#sub BuildGroupEventConn {
#	my $self = shift;
#
#	# class keep rows structure and group instances
#	my $groupTables = shift;
#
#	# 1) Do conenction between units events/handlers
#	my @units = $groupTables->GetAllUnits();
#
#	foreach my $unitA (@units) {
#
#		my $evtClassA = $unitA->GetEventClass();
#
#		unless ($evtClassA) {
#			next;
#		}
#
#		my @unitEvents = $unitA->GetEventClass()->GetEvents();
#
#		# search handler for this event type in all units
#		foreach my $unitB (@units) {
#
#			my $evtClassB = $unitB->GetEventClass();
#
#			if ($evtClassB) {
#				$unitB->GetEventClass()->ConnectEvents( \@unitEvents );
#			}
#
#		}
#	}
#
#
#}
#
#sub __OnExportSync {
#	my $self = shift;
#
#	#raise events
#	$self->{"onExportSync"}->Do();
#
#}
#
#sub __OnExportASync {
#	my $self     = shift;
#	my $onServer = shift;
#
#	#raise events
#	$self->{"onExportASync"}->Do($onServer);
#
#}
#
#sub __OnCloseHandler {
#	my $self = shift;
#
#	#raise events
#	$self->{"onClose"}->Do();
#
#}
#
#sub __OnLoadDefaultClick {
#	my $self = shift;
#
#	#raise events
#	$self->{"onLoadDefault"}->Do();
#
#}
#
#sub __OnUncheckAllClick {
#	my $self = shift;
#
#	#raise events
#	$self->{"onUncheckAll"}->Do();
#
#}
#
#sub __OnLoadLastClick {
#	my $self = shift;
#
#	#raise events
#	$self->{"onLoadLast"}->Do();
#
#}

sub __SetLayout {
	my $self = shift;

	$self->{"mainFrm"} ->SetBackgroundColour( EnumsStyle->BACKGCLR_LIGHTGRAY );

	# DEFINE CONTROLS
	my $szMain       = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $headerLayout = $self->__SetLayoutHeader( $self->{"mainFrm"} );
	my $partLayout   = $self->__SetLayoutParts( $self->{"mainFrm"} );

	$szMain->Add( $headerLayout, 0, &Wx::wxEXPAND );
	$szMain->Add( 5, 5, 0, &Wx::wxEXPAND );
	$szMain->Add( $partLayout, 1, &Wx::wxEXPAND );

	$self->AddContent($szMain);
	$self->SetButtonHeight(30);
	my $btnCancel    = $self->AddButton( "Cancel",     sub { $self->{"cancelEvt"}->Do() } );
	my $btnLeave     = $self->AddButton( "Leave",      sub { $self->{"leaveEvt"}->Do() } );
	my $btnShowInCAM = $self->AddButton( "Show InCAM", sub { $self->{"showInCAMEvt"}->Do() } );
	my $btnCreate    = $self->AddButton( "Create",     sub { $self->{"createEvt"}->Do() } );

	

	# DEFINE LAYOUT STRUCTURE

	# KEEP REFERENCES
	$self->{"btnCancel"}    = $btnCancel;
	$self->{"btnLeave"}     = $btnLeave;
	$self->{"btnShowInCAM"} = $btnShowInCAM;
	$self->{"btnCreate"}    = $btnCreate;
}

#
# Set header
sub __SetLayoutHeader {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes

	my $szMain     = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szMainSett = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $szSett     = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szSettRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szSettRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	
	my $szQuickBtn     = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	 

	# Define panels

	my $pnlMain = Wx::Panel->new( $parent, -1 );

	my $pnlSett = Wx::Panel->new( $pnlMain, -1 );

	$pnlMain->SetBackgroundColour( EnumsStyle->BACKGCLR_HEADERBLUE);
	$pnlSett->SetBackgroundColour( EnumsStyle->BACKGCLR_LIGHTGRAY );

	# DEFINE CONTROLS
	my $titleTxt = Wx::StaticText->new( $pnlMain, -1, "Customer panel", &Wx::wxDefaultPosition, [ 260, -1 ] );
	$titleTxt->SetForegroundColour( Wx::Colour->new( 255, 255, 255 ) );
		my $f = Wx::Font->new( 14, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL,
		&Wx::wxFONTWEIGHT_BOLD );
	$titleTxt->SetFont($f);

	my $stepTxt = Wx::StaticText->new( $pnlSett, -1, "Step name:", &Wx::wxDefaultPosition , [ 70, 22 ]);
	my $stepValTxt = Wx::TextCtrl->new( $pnlSett, -1, "mpanel", &Wx::wxDefaultPosition );

	my $previewTxt = Wx::StaticText->new( $pnlSett, -1, "Preview:", &Wx::wxDefaultPosition , [ 70, 22 ]);
	my $previewChb = Wx::CheckBox->new( $pnlSett, -1, "", &Wx::wxDefaultPosition );

	my $loadLastBtn    = Wx::Button->new( $pnlSett, -1, "Load last",    &Wx::wxDefaultPosition, [ 120, 23 ] );
	my $loadDefaultBtn = Wx::Button->new( $pnlSett, -1, "Load default", &Wx::wxDefaultPosition, [ 120, 23 ] );

	# BUILD LAYOUT STRUCTURE

	$szSettRow1->Add( $stepTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szSettRow1->Add( $stepValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szSettRow2->Add( $previewTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szSettRow2->Add( $previewChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szSett->Add( $szSettRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szSett->Add( $szSettRow2, 0, &Wx::wxEXPAND | &Wx::wxTOP, 1 );

	$szMainSett->Add( 10,10,         0,  );
	$szMainSett->Add( $szSett,         1, &Wx::wxALL, 2 );
	
	$szQuickBtn->Add( $loadLastBtn,    0,  &Wx::wxALL, 1);
	$szQuickBtn->Add( $loadDefaultBtn, 0,  &Wx::wxALL, 1 );
	
	$szMainSett->Add( $szQuickBtn,         0,  &Wx::wxALL, 2 );

	$pnlMain->SetSizer($szMain);
	$pnlSett->SetSizer($szMainSett);

	 
	$szMain->Add( 14, 4, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $titleTxt,   0, &Wx::wxALIGN_CENTER | &Wx::wxALL, 0 );
	
	$szMain->Add( $pnlSett,  1, &Wx::wxEXPAND | &Wx::wxALL, 5 );

	# REGISTER EVENTS

	#$szRow1->Add( $defaultTxt,   1, &Wx::wxEXPAND );
	#	$szRow1->Add( $noteTxt, 1, &Wx::wxEXPAND );
	#
	#	$szMain->Add( $szRow1, 1, &Wx::wxEXPAND );
	#
	#	$szStatBox->Add( $szMain, 1, &Wx::wxEXPAND );

	return $pnlMain;
}

# Set header
sub __SetLayoutParts {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes

	#my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# Define panels

	my $partContainer = PartContainerForm->new( $parent, -1 );

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

sub __OnScrollPaint {
	my $self      = shift;
	my $scrollPnl = shift;
	my $event     = shift;

	$self->{"mainFrm"}->Layout();
	$scrollPnl->FitInside();
}

# It is important do layout and refresh, when resize,
# for correct "size changing" of sizers placed in inside VScrolledWindow
sub __OnResize {
	my $self = shift;

	$self->{"mainFrm"}->Layout();
	$self->{"mainFrm"}->Refresh();

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

