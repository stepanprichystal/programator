#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::ExportChecker::Forms::ExportCheckerForm;
use base 'Wx::App';

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

BEGIN {
	eval { require Wx::RichText; };
}

#local library

use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Forms::ScrollPanel';
use aliased 'Widgets::Forms::MyWxFrame';

use aliased 'Packages::Events::Event';
use aliased 'Widgets::Forms::MyWxBookCtrlPage';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Forms::GroupTableForm';

use Widgets::Style;

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $self   = shift;
	my $parent = shift;

	$self = {};

	if ( !defined $parent || $parent == -1 ) {
		$self = Wx::App->new( \&OnInit );
	}

	bless($self);

	# PROPERTIES

	$self->{"jobId"} = shift;
	$self->{"inCAM"} = shift;

	#$self->{"groupBuilder"} = GroupBuilder->new($self);

	my $mainFrm = $self->__SetLayout($parent);

	#EVENTS

	$self->{"onExportSync"}  = Event->new();
	$self->{"onExportASync"} = Event->new();
	$self->{"onClose"}       = Event->new();

	$self->{"onUncheckAll"}  = Event->new();
	$self->{"onLoadLast"}    = Event->new();
	$self->{"onLoadDefault"} = Event->new();

	#$mainFrm->Show(1);

	return $self;
}

## Return tab reference by number
#sub GetTab {
#	my $self      = shift;
#	my $tabNumber = shift;
#
#	my $tab = $self->{"nb"}->GetPage($tabNumber);
#	return $tab;
#}

sub GetToProduce {
	my $self = shift;

	return $self->{"chbProduce"}->GetValue();
}

# Disable all controls on form
sub DisableForm {
	my $self    = shift;
	my $disable = shift;

	if ($disable) {

		$self->{"mainPnl"}->Disable();
		$self->{"nb"}->Disable();

	}
	else {

		$self->{"mainPnl"}->Enable();
		$self->{"nb"}->Enable();
	}

}

# Disable all controls on form
sub DisableExportBtn {
	my $self    = shift;
	my $disable = shift;

	if ($disable) {

		$self->{"btnSync"}->Disable();
		$self->{"btnASync"}->Disable();
	}
	else {

		$self->{"btnSync"}->Enable();
		$self->{"btnASync"}->Enable();
	}

}

# Set "Load last" button visibility
sub SetLoadLastBtn {
	my $self   = shift;
	my $enable = shift;

	if ($enable) {
		$self->{"btnLoadLast"}->Enable();
	}
	else {
		$self->{"btnLoadLast"}->Disable();
	}
}

sub OnInit {
	my $self = shift;

	return 1;
}

# Return group builder, which is responsible for building
# groups gui and adding groups to form
sub GetGroupBuilder {
	my $self = shift;
	return $self->{"groupBuilder"};
}

# Add new page in nootebook
sub AddPage {
	my ( $self, $title ) = @_;
	my $count = $self->{"nb"}->GetPageCount();
	my $page = MyWxBookCtrlPage->new( $self->{"nb"}, $count );

	$self->{"nb"}->AddPage( $page, $title . "    ", 0, $count );
	$self->{"nb"}->SetPageImage( $count, 0 );

	#row height is 10px. When we get total height of panel in scrollwindow
	# then we compute number of rows as: totalHeight/10px
	my $rowHeight = 10;
	my $scrollPnl = ScrollPanel->new( $page, $rowHeight );

	my $szTab = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	$szTab->Add( $scrollPnl, 1, &Wx::wxEXPAND );

	$page->SetSizer($szTab);

	$page->{"scrollPnl"} = $scrollPnl;

	#$self->{"scrollPnl"} = $scrollPnl;

	Wx::Event::EVT_PAINT( $scrollPnl, sub { $self->__OnScrollPaint(@_) } );

	return $page;
}

sub __OnExportSync {
	my $self = shift;

	#raise events
	$self->{"onExportSync"}->Do();

}

sub __OnExportASync {
	my $self = shift;

	#raise events
	$self->{"onExportASync"}->Do();

}

sub __OnCloseHandler {
	my $self = shift;

	#raise events
	$self->{"onClose"}->Do();

}

sub __OnLoadDefaultClick {
	my $self = shift;

	#raise events
	$self->{"onLoadDefault"}->Do();

}

sub __OnUncheckAllClick {
	my $self = shift;

	#raise events
	$self->{"onUncheckAll"}->Do();

}

sub __OnLoadLastClick {
	my $self = shift;

	#raise events
	$self->{"onLoadLast"}->Do();

}

sub __SetLayout {
	my $self   = shift;
	my $parent = shift;

	#main formDefain forms
	my $mainFrm = MyWxFrame->new(
		$parent,                   # parent window
		-1,                        # ID -1 means any
		"Exporter checker Job: ".$self->{"jobId"},        # title
		&Wx::wxDefaultPosition,    # window position
		[ 1100, 750 ],             # size
		                           #&Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxCLIP_CHILDREN | &Wx::wxRESIZE_BORDER | &Wx::wxMINIMIZE_BOX
	);

	$mainFrm->Centre(&Wx::wxCENTRE_ON_SCREEN);
	Wx::Event::EVT_SIZE( $mainFrm, sub { $self->__OnResize(@_) } );

	#DEFINE PANELS

	my $mainPnl = Wx::Panel->new( $mainFrm, -1 );

	#DEFINE SIZERS

	my $szMainParent = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	#main sizer for top frame
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# Sizer inside first static box
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#define staticboxes
	my $frstStatBox = Wx::StaticBox->new( $mainPnl, -1, 'Export settings' );
	my $szFrstStatBox = Wx::StaticBoxSizer->new( $frstStatBox, &Wx::wxHORIZONTAL );

	#my $secStatBox = Wx::StaticBox->new( $mainPnl, -1, '' );
	#my $szSecStatBox = Wx::StaticBoxSizer->new( $secStatBox, &Wx::wxVERTICAL );
	my $szSecStatBox = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $pnlBtns = Wx::Panel->new( $mainPnl, -1 );
	$pnlBtns->SetBackgroundColour($Widgets::Style::clrDefaultFrm);
	my $szBtns      = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szBtnsChild = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $nb = Wx::Notebook->new( $mainPnl, -1, &Wx::wxDefaultPosition, &Wx::wxDefaultSize );
	my $imagelist = Wx::ImageList->new( 10, 25 );
	$nb->AssignImageList($imagelist);

	my $btnSync = Wx::Button->new( $pnlBtns, -1, "Export", &Wx::wxDefaultPosition, [ 160, 33 ] );
	$btnSync->SetFont($Widgets::Style::fontBtn);
	my $btnASync = Wx::Button->new( $pnlBtns, -1, "Export on background", &Wx::wxDefaultPosition, [ 160, 33 ] );
	$btnASync->SetFont($Widgets::Style::fontBtn);

	# REGISTER EVENTS

	Wx::Event::EVT_BUTTON( $btnSync,  -1, sub { $self->__OnExportSync() } );
	Wx::Event::EVT_BUTTON( $btnASync, -1, sub { $self->__OnExportASync() } );
	$mainFrm->{"onClose"}->Add( sub { $self->__OnCloseHandler(@_) } );

	$szBtnsChild->Add( $btnSync,  0, &Wx::wxALL, 2 );
	$szBtnsChild->Add( $btnASync, 0, &Wx::wxALL, 2 );
	$szBtns->Add( 10, 10, 1, &Wx::wxGROW );
	$szBtns->Add( $szBtnsChild, 0, &Wx::wxALIGN_RIGHT | &Wx::wxALL );
	$pnlBtns->SetSizer($szBtns);

	$szRow1->Add( $self->__SetLayoutOther($mainPnl),      0,  &Wx::wxEXPAND | &Wx::wxLEFT, 2 );
	$szRow1->Add( $self->__SetLayoutExportPath($mainPnl), 0,  &Wx::wxEXPAND | &Wx::wxLEFT, 2 );
	$szRow1->Add( 10,                                     10, 1,                           &Wx::wxEXPAND );
	$szRow1->Add( $self->__SetLayoutQuickSet($mainPnl),   0,  &Wx::wxEXPAND | &Wx::wxLEFT, 2 );

	$szFrstStatBox->Add( $szRow1, 1, &Wx::wxEXPAND );
	$szSecStatBox->Add( $nb, 1, &Wx::wxEXPAND );

	$szMain->Add( $szFrstStatBox, 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szMain->Add( $szSecStatBox,  1, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szMain->Add( $pnlBtns,       0, &Wx::wxEXPAND );

	$mainPnl->SetSizer($szMain);

	$szMainParent->Add( $mainPnl, 1, &Wx::wxEXPAND );

	$mainFrm->SetSizer($szMainParent);

	# SAVE CONTROLS

	$self->{"mainFrm"} = $mainFrm;
	$self->{"mainPnl"} = $mainPnl;
	$self->{"szMain"}  = $szMain;

	$self->{"nb"} = $nb;

	$self->{"btnSync"}  = $btnSync;
	$self->{"btnASync"} = $btnASync;

	return $mainFrm;
}

# Set layout for Quick set box
sub __SetLayoutQuickSet {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Quick option' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $defaultTxt    = Wx::StaticText->new( $statBox, -1, "Default settings", &Wx::wxDefaultPosition, [ 80, 18 ] );
	#my $uncheckAllTxt    = Wx::StaticText->new( $statBox, -1, "Uncheck all", &Wx::wxDefaultPosition, [ 80, 18 ] );
	#my $loadLastTxt    = Wx::StaticText->new( $statBox, -1, "Last used settings", &Wx::wxDefaultPosition, [ 80, 18 ] );

	my $btnDefault    = Wx::Button->new( $statBox, -1, "Default settings",   &Wx::wxDefaultPosition, [ 110, 22 ] );
	my $btnUncheckAll = Wx::Button->new( $statBox, -1, "Uncheck all",        &Wx::wxDefaultPosition, [ 110, 22 ] );
	my $btnLoadLast   = Wx::Button->new( $statBox, -1, "Last used settings", &Wx::wxDefaultPosition, [ 110, 22 ] );

	# REGISTER EVENTS
	Wx::Event::EVT_BUTTON( $btnDefault,    -1, sub { $self->__OnLoadDefaultClick() } );
	Wx::Event::EVT_BUTTON( $btnUncheckAll, -1, sub { $self->__OnUncheckAllClick() } );
	Wx::Event::EVT_BUTTON( $btnLoadLast,   -1, sub { $self->__OnLoadLastClick() } );

	#$szRow1->Add( $defaultTxt,   1, &Wx::wxEXPAND );
	$szRow1->Add( $btnDefault, 0, &Wx::wxEXPAND );

	#$szRow2->Add( $uncheckAllTxt,   1, &Wx::wxEXPAND );
	$szRow2->Add( $btnUncheckAll, 0, &Wx::wxEXPAND );

	#$szRow3->Add( $loadLastTxt,   1, &Wx::wxEXPAND );
	$szRow3->Add( $btnLoadLast, 0, &Wx::wxEXPAND );

	$szMain->Add( $szRow1, 1, &Wx::wxEXPAND );
	$szMain->Add( $szRow2, 1, &Wx::wxEXPAND );
	$szMain->Add( $szRow3, 1, &Wx::wxEXPAND );

	$szStatBox->Add( $szMain, 1, &Wx::wxEXPAND );

	$self->{"btnLoadLast"} = $btnLoadLast;

	return $szStatBox;

}

# Set layout for Export path box
sub __SetLayoutExportPath {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Export location' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $rbClient = Wx::RadioButton->new( $statBox, -1, "C:/Export", &Wx::wxDefaultPosition, [ 110, 22 ], &Wx::wxRB_GROUP );
	$rbClient->SetBackgroundColour( Wx::Colour->new( 228, 232, 243 ) );
	my $rbArchiv = Wx::RadioButton->new( $statBox, -1, "Job archive ", &Wx::wxDefaultPosition, [ 110, 22 ] );
	$rbArchiv->SetBackgroundColour( Wx::Colour->new( 0, 0, 0 ) );

	#$szRow1->Add( $defaultTxt,   1, &Wx::wxEXPAND );
	$szRow1->Add( $rbClient, 0, &Wx::wxEXPAND );

	#$szRow2->Add( $uncheckAllTxt,   1, &Wx::wxEXPAND );
	$szRow2->Add( $rbArchiv, 0, &Wx::wxEXPAND );

	$szMain->Add( $szRow1, 1, &Wx::wxEXPAND );
	$szMain->Add( $szRow2, 1, &Wx::wxEXPAND );

	$szStatBox->Add( $szMain, 1, &Wx::wxEXPAND );

	return $szStatBox;

}

# Set layout for Export path box
sub __SetLayoutOther {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Other options' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $chbProduce = Wx::CheckBox->new( $statBox, -1, "Sent to produce", &Wx::wxDefaultPosition, [ 110, 22 ] );
	$chbProduce->SetValue(1);

	#$chbProduce->SetTransparent(0);
	#$chbProduce->Refresh();
	#$chbProduce->SetBackgroundStyle(&Wx::wxBG_STYLE_TRANSPARENT);
	$chbProduce->SetBackgroundColour( Wx::Colour->new( 255, 255, 255 ) );
	Wx::Event::EVT_ERASE_BACKGROUND( $chbProduce, sub { $self->Test(@_) } );

	$chbProduce->SetBackgroundColour( Wx::Colour->new( 255, 255, 255 ) );
	$chbProduce->Refresh();

	$szMain->Add( $chbProduce, 1, &Wx::wxEXPAND );
	$szStatBox->Add( $szMain, 1, &Wx::wxEXPAND );

	# SAVE REFERENCES
	$self->{"chbProduce"} = $chbProduce;

	return $szStatBox;

}

sub Test {
	my $self   = shift;
	my $parent = shift;
	my $evt    = shift;

	my $dc = $evt->GetDC();

	$dc->Clear();

	# $self->{"chbProduce"}->Refresh();
}

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

sub BuildGroupTableForm {
	my $self = shift;

	# class keep rows structure and group instances
	my $groupTables = shift;
	$self->{"inCAM"} = shift;

	$self->{"mainFrm"}->Freeze();

	foreach my $table ( $groupTables->GetTables() ) {

		my $pageTab   = $self->AddPage( $table->GetTitle() );
		my $scrollPnl = $pageTab->{"scrollPnl"};

		# physics structure of groups, tab is parent
		my $groupTableForm = GroupTableForm->new($scrollPnl);

		#crete physic "table" structure from "groupTable" object
		#my $table = $self->__DefineTableGroups();
		$groupTableForm->InitGroupTable( $table, $self->{"inCAM"} );

		my $scrollSizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
		$scrollSizer->Add( $groupTableForm, 1, &Wx::wxEXPAND );

		#$scrollSizer->Layout();
		$scrollPnl->SetSizer($scrollSizer);

		# get height of group table, for init scrollbar panel
		$scrollPnl->Layout();

		$self->{"nb"}->InvalidateBestSize();
		$scrollPnl->FitInside();

		#$self->{"mainFrm"}->Layout();
		$scrollPnl->Layout();
		my ( $width, $height ) = $groupTableForm->GetSizeWH();

		print "Height of scrollPnale is: $height\n\n";

		#compute number of rows. One row has height 10 px
		$scrollPnl->SetRowCount( $height / 10 );
	}
	
	$self->{"mainFrm"}->Thaw();

	# Do conenction between units events/handlers
	my @units = $groupTables->GetAllUnits();

	foreach my $unitA (@units) {

		my $evtClassA = $unitA->GetEventClass();

		unless ($evtClassA) {
			next;
		}

		my @unitEvents = $unitA->GetEventClass()->GetEvents();

		# search handler for this event type in all units
		foreach my $unitB (@units) {

			my $evtClassB = $unitB->GetEventClass();

			if ($evtClassB) {
				$unitB->GetEventClass()->ConnectEvents( \@unitEvents );
			}

		}
	}

}

sub _AddEvent {
	my $self      = shift;
	my $event     = shift;
	my $eventType = shift;

	$self->{"mainFrm"}->Layout();

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $test = Programs::Exporter::ExportChecker::Forms::GroupTableForm->new();

	#$test->MainLoop();
}

1;

