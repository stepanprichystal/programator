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
use aliased 'Packages::Tests::Test';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Forms::ScrollPanel';
use aliased 'Widgets::Forms::MyWxFrame';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Events::Event';
use aliased 'Widgets::Forms::MyWxBookCtrlPage';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Forms::GroupTableForm';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsIS';
use aliased 'Helpers::JobHelper';

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
	$self->{"isOffer"}     = JobHelper->GetJobIsOffer( $self->{"jobId"} );

	#$self->{"groupBuilder"} = GroupBuilder->new($self);

	my $mainFrm = $self->__SetLayout($parent);

	$self->{"messageMngr"} = MessageMngr->new("Exporter checker");
	

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
		$self->{"btnASyncServer"}->Disable();
	}
	else {

		$self->{"btnSync"}->Enable();
		$self->{"btnASync"}->Enable();
		$self->{"btnASyncServer"}->Enable();
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

sub BuildGroupTableForm {
	my $self  = shift;
	my $inCAM = shift;

	# class keep rows structure and group instances
	my $groupTables = shift;

	$self->{"mainFrm"}->Freeze();

	my $defSelPageTab = undef;    # Default selected notebook page

	foreach my $table ( $groupTables->GetTables() ) {

		my $pageTab   = $self->AddPage( $table->GetTitle() );
		my $scrollPnl = $pageTab->{"scrollPnl"};

		# physics structure of groups, tab is parent
		my $groupTableForm = GroupTableForm->new($scrollPnl);

		#crete physic "table" structure from "groupTable" object
		#my $table = $self->__DefineTableGroups();
		$groupTableForm->InitGroupTable( $table, $inCAM );

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

		DiagSTDERR( "Table title: " . $table->GetTitle() . ", dim: $width x $height \n" );

		#compute number of rows. One row has height 10 px
		$scrollPnl->SetRowCount( $height / 10 );

		$defSelPageTab = $pageTab if ( defined $groupTables->GetDefaultSelected() && $table eq $groupTables->GetDefaultSelected() );
	}

	# Set default selected table
	if ( defined $groupTables->GetDefaultSelected() ) {
		$self->{"nb"}->SetSelection( $groupTables->GetDefaultSelected()->GetOrderNumber() - 1 );
	}

	$self->{"mainFrm"}->Thaw();
}

# Create event/handler connection between groups by binding handlers to evnets
# provided by groups
sub BuildGroupEventConn {
	my $self = shift;

	# class keep rows structure and group instances
	my $groupTables = shift;

	# 1) Do conenction between units events/handlers
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

sub __OnExportSync {
	my $self = shift;

	#raise events
	$self->{"onExportSync"}->Do();

}

sub __OnExportASync {
	my $self     = shift;
	my $onServer = shift;

	#raise events
	$self->{"onExportASync"}->Do($onServer);

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
		$parent,                                        # parent window
		-1,                                             # ID -1 means any
		"Exporter checker Job: " . $self->{"jobId"},    # title
		&Wx::wxDefaultPosition,                         # window position
		[ 1150, 800 ],    # size
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

	my $customerNote = $self->__SetLayoutCustomerNote($mainPnl);
	my $otherOptions = $self->__SetLayoutOther($mainPnl);
	my $quickOptions = $self->__SetLayoutQuickSet($mainPnl);

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

	my $btnSync = Wx::Button->new( $pnlBtns, -1,"Export".($self->{"isOffer"}? " offer" : ""), &Wx::wxDefaultPosition, [ 130, 33 ] );
	$btnSync->SetFont($Widgets::Style::fontBtn);
	my $btnASyncServer = Wx::Button->new( $pnlBtns, -1, "Export on server (beta)", &Wx::wxDefaultPosition, [ 160, 33 ] );
	$btnASyncServer->SetFont($Widgets::Style::fontBtn);
	my $btnASync = Wx::Button->new( $pnlBtns, -1, "Export on background", &Wx::wxDefaultPosition, [ 160, 33 ] );
	$btnASync->SetFont($Widgets::Style::fontBtn);

	# If offer alwazs disable
	if ( $self->{"isOffer"} ) {
		$btnASyncServer->Hide();
		$btnASync->Hide();
	}

	# REGISTER EVENTS

	Wx::Event::EVT_BUTTON( $btnSync,        -1, sub { $self->__OnExportSync() } );
	Wx::Event::EVT_BUTTON( $btnASyncServer, -1, sub { $self->__OnExportASync(1) } );
	Wx::Event::EVT_BUTTON( $btnASync,       -1, sub { $self->__OnExportASync() } );

	$mainFrm->{"onClose"}->Add( sub { $self->__OnCloseHandler(@_) } );

	$szBtnsChild->Add( $btnSync,        0, &Wx::wxALL, 2 );
	$szBtnsChild->Add( $btnASync,       0, &Wx::wxALL, 2 );
	$szBtnsChild->Add( $btnASyncServer, 0, &Wx::wxALL, 2 );
	$szBtns->Add( 10, 10, 1, &Wx::wxGROW );
	$szBtns->Add( $szBtnsChild, 0, &Wx::wxALIGN_RIGHT | &Wx::wxALL );
	$pnlBtns->SetSizer($szBtns);

	$szRow1->Add( $customerNote, 1, &Wx::wxEXPAND );
	$szRow1->Add( $otherOptions, 0, &Wx::wxEXPAND );
	$szRow1->Add( $quickOptions, 0, &Wx::wxEXPAND );

	$szSecStatBox->Add( $nb, 1, &Wx::wxEXPAND );

	$szMain->Add( $szRow1,       0, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szMain->Add( $szSecStatBox, 1, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szMain->Add( $pnlBtns,      0, &Wx::wxEXPAND );

	$mainPnl->SetSizer($szMain);

	$szMainParent->Add( $mainPnl, 1, &Wx::wxEXPAND );

	$mainFrm->SetSizer($szMainParent);

	# SAVE CONTROLS

	$self->{"mainFrm"} = $mainFrm;
	$self->{"mainPnl"} = $mainPnl;
	$self->{"szMain"}  = $szMain;

	$self->{"nb"} = $nb;

	$self->{"btnSync"}        = $btnSync;
	$self->{"btnASync"}       = $btnASync;
	$self->{"btnASyncServer"} = $btnASyncServer;

	return $mainFrm;
}

# Set layout for Quick set box
sub __SetLayoutCustomerNote {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Customer note' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $note      = HegMethods->GetTpvCustomerNote( $self->{"jobId"} );
	my $noteFinal = "";

	if ($note) {
		my @notes = split( /\n/, $note );

		foreach my $note (@notes) {

			$note =~ s/[\r\n\t]//;
			$note =~ s/^\s*//;
			$note =~ s/\s*$//;

			if ( $note ne "" ) {
				$noteFinal .= " - " . $note . "\n";
			}
		}

		$noteFinal = substr( $noteFinal, 0, length($noteFinal) - 1 );    # delete last \n

	}

	my $noteTxt = Wx::TextCtrl->new( $statBox, -1, $noteFinal, &Wx::wxDefaultPosition,
									 [ -1, -1 ],
									 &Wx::wxTE_MULTILINE | &Wx::wxBORDER_NONE | &Wx::wxTE_NO_VSCROLL );

	# REGISTER EVENTS

	#$szRow1->Add( $defaultTxt,   1, &Wx::wxEXPAND );
	$szRow1->Add( $noteTxt, 1, &Wx::wxEXPAND );

	$szMain->Add( $szRow1, 1, &Wx::wxEXPAND );

	$szStatBox->Add( $szMain, 1, &Wx::wxEXPAND );

	return $szStatBox;
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
	$szRow1->Add( $btnDefault, 0 );

	#$szRow2->Add( $uncheckAllTxt,   1, &Wx::wxEXPAND );
	$szRow2->Add( $btnUncheckAll, 0 );

	#$szRow3->Add( $loadLastTxt,   1, &Wx::wxEXPAND );
	$szRow3->Add( $btnLoadLast, 0 );

	$szMain->Add( $szRow1, 1, &Wx::wxEXPAND );
	$szMain->Add( $szRow2, 1, &Wx::wxEXPAND );
	$szMain->Add( $szRow3, 1, &Wx::wxEXPAND );

	$szStatBox->Add( $szMain, 1, &Wx::wxEXPAND );

	$self->{"btnLoadLast"} = $btnLoadLast;

	return $szStatBox;

}

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

# Set layout for Export path box
sub __SetLayoutOther {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Other options' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $noteTextTxt = undef;

	#my $orderNum = HegMethods->GetPcbOrderNumber($self->{"jobId"});
	my @affectOrder = ();

	push( @affectOrder, HegMethods->GetOrdersByState( $self->{"jobId"}, 2 ) );    # Orders on Predvzrobni priprava
	push( @affectOrder, HegMethods->GetOrdersByState( $self->{"jobId"}, 4 ) );    # Orders on Ve vyrobe

	my @affectOrderNum = sort { $a <=> $b } map { $_->{"reference_subjektu"} =~ /-(\d+)/ } @affectOrder;

	$noteTextTxt = Wx::StaticText->new( $statBox, -1, "   REORDER (" . join( "; ", @affectOrderNum ) . ")   ", &Wx::wxDefaultPosition, [ 110, 22 ] );
	$noteTextTxt->SetForegroundColour( Wx::Colour->new( 255, 0, 0 ) );

	#my $firstOrder = grep { $_ == 1 } @affectOrderNum;

	if ( scalar(@affectOrderNum) <= 1 ) {
		$noteTextTxt->Hide();
	}

	my $sentToProduce = 1;

	# if affected orders are all reorders and has state "Hotovo-zadat" or "Zadano"
	# Uncheck sent to produce

	my @exported =
	  grep { $_->{"aktualni_krok"} eq EnumsIS->CurStep_HOTOVOZADAT || $_->{"aktualni_krok"} eq EnumsIS->CurStep_ZADANO } @affectOrder;

	if ( scalar(@exported) == scalar(@affectOrder) ) {
		$sentToProduce = 0;
	}

	my $chbProduce = Wx::CheckBox->new( $statBox, -1, "Sent to produce", &Wx::wxDefaultPosition, [ 110, 22 ] );
	$chbProduce->SetValue($sentToProduce);
	$chbProduce->Disable() if ( $self->{"isOffer"} );

	#$chbProduce->SetTransparent(0);
	#$chbProduce->Refresh();
	#$chbProduce->SetBackgroundStyle(&Wx::wxBG_STYLE_TRANSPARENT);
	$chbProduce->SetBackgroundColour( Wx::Colour->new( 255, 255, 255 ) );

	$chbProduce->SetBackgroundColour( Wx::Colour->new( 255, 255, 255 ) );
	$chbProduce->Refresh();

	$szMain->Add( $noteTextTxt, 0 );

	#$szMain->Add( 20,20, 0, &Wx::wxEXPAND );
	$szMain->Add( $chbProduce, 0 );
	$szStatBox->Add( $szMain, 1, &Wx::wxEXPAND );

	# SAVE REFERENCES
	$self->{"chbProduce"} = $chbProduce;

	return $szStatBox;

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

