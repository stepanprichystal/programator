#-------------------------------------------------------------------------------------------#
# Description: Popup, which shows result from export checking
# Allow terminate thread, which does checking
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::ExportChecker::Forms::ExportPopupForm;
use base 'Wx::App';

#3th party librarysss
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);
use Wx qw(:icon wxTheApp wxNullBitmap);

BEGIN {
	eval { require Wx::RichText; };
}

#local library

use aliased 'Widgets::Forms::MyWxFrame';
use Widgets::Style;
use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';

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

	my $mainFrm = $self->__SetLayout($parent);

	# Properties
	$self->{"jobId"}       = shift;
	

	return $self;
}

sub OnInit {
	my $self = shift;

	return 1;
}



sub __SetLayout {
	my $self   = shift;
	my $parent = shift;

	#main formDefain forms
	my $mainFrm = MyWxFrame->new(
		$parent,                       # parent window
		-1,                            # ID -1 means any
		"Checking export settings",    # title
		&Wx::wxDefaultPosition,        # window position
		[ 500, 1000 ],                                              # size
		&Wx::wxCAPTION | &Wx::wxCLOSE_BOX | &Wx::wxSTAY_ON_TOP |
		  &Wx::wxMINIMIZE_BOX    #  &Wx::wxSYSTEM_MENU |  | &Wx::wxCLIP_CHILDREN | &Wx::wxRESIZE_BORDER | &Wx::wxMINIMIZE_BOX
	);

	$mainFrm->CentreOnParent(&Wx::wxBOTH);

	# DEFINE STATICBOXES

	my $frstStatBox = Wx::StaticBox->new( $mainFrm, -1, 'Checking groups' );
	my $szFrstStatBox = Wx::StaticBoxSizer->new( $frstStatBox, &Wx::wxVERTICAL );


	# DEFINE SIZERS

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow4 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow5 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $pnlBtns     = Wx::Panel->new( $mainFrm, -1 );
	my $szBtns      = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szBtnsChild = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	$pnlBtns->SetBackgroundColour($Widgets::Style::clrDefaultFrm);

	# DEFINE CONTROLS

	my $jobTxt = Wx::StaticText->new( $mainFrm, -1, "Job id(s): " );
	$jobTxt->SetFont($Widgets::Style::fontLbl);
	
	my $jobValTxt = Wx::TextCtrl->new( $mainFrm, -1, "" );
	$jobValTxt->SetFont($Widgets::Style::fontLbl);

	#row 2
	
		my $jobTxt = Wx::StaticText->new( $mainFrm, -1, "Job id(s): " );
	$jobTxt->SetFont($Widgets::Style::fontLbl);
	
	my $jobValTxt = Wx::TextCtrl->new( $mainFrm, -1, "" );
	$jobValTxt->SetFont($Widgets::Style::fontLbl);
	
	my $gauge = Wx::Gauge->new( $mainFrm, -1, 100, [ -1, -1 ], [ 300, 20 ], &Wx::wxGA_HORIZONTAL );
	$gauge->SetValue(0);

	#row 3
	my $errorsCntTxt = Wx::StaticText->new( $mainFrm, -1, "Errors: " );
	$errorsCntTxt->SetFont($Widgets::Style::fontLbl);
	my $errorsCntValTxt = Wx::StaticText->new( $mainFrm, -1, "0" );
	$errorsCntValTxt->SetFont($Widgets::Style::fontLbl);
	my $btmError = Wx::Bitmap->new( GeneralHelper->Root() . "/Resources/Images/ErrorDisable20x20.bmp", &Wx::wxBITMAP_TYPE_BMP );
	my $statBtmError = Wx::StaticBitmap->new( $mainFrm, -1, $btmError );
	my $btnError = Wx::Button->new( $mainFrm, -1, "Show", &Wx::wxDefaultPosition, [ 70, 20 ] );
	$btnError->SetFont($Widgets::Style::fontBtn);
	$btnError->Disable();

	#row 4
	my $warnsCntTxt    = Wx::StaticText->new( $mainFrm, -1, "Warnings: " );
	my $warnsCntValTxt = Wx::StaticText->new( $mainFrm, -1, "0" );
	$warnsCntValTxt->SetFont($Widgets::Style::fontLbl);
	$warnsCntTxt->SetFont($Widgets::Style::fontLbl);
	my $btmWarn = Wx::Bitmap->new( GeneralHelper->Root() . "/Resources/Images/WarningDisable20x20.bmp", &Wx::wxBITMAP_TYPE_BMP );
	my $statBtmWarns = Wx::StaticBitmap->new( $mainFrm, -1, $btmWarn );
	my $btnWarn = Wx::Button->new( $mainFrm, -1, "Show", &Wx::wxDefaultPosition, [ 70, 20 ] );
	$btnWarn->SetFont($Widgets::Style::fontBtn);
	$btnWarn->Disable();

	#row 5
	my $btnStop   = Wx::Button->new( $pnlBtns, -1, "Stop checking" );
	my $btnExport = Wx::Button->new( $pnlBtns, -1, "Export force" );
	my $btnChange = Wx::Button->new( $pnlBtns, -1, "Change settings" );
	$btnExport->Disable();
	$btnChange->Disable();

	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $groupNameTxt,    25, &Wx::wxEXPAND );
	$szRow1->Add( $groupNameValTxt, 75, &Wx::wxEXPAND );

	$szRow2->Add( $gauge, 1, &Wx::wxEXPAND );

	$szRow3->Add( $errorsCntTxt,    30, &Wx::wxEXPAND );
	$szRow3->Add( $errorsCntValTxt, 5,  &Wx::wxEXPAND );
	$szRow3->Add( $statBtmError,    5,  &Wx::wxEXPAND );
	$szRow3->Add( 10, 10, 60, &Wx::wxGROW );
	$szRow3->Add( $btnError, 0, &Wx::wxEXPAND );

	$szRow4->Add( $warnsCntTxt,    30, &Wx::wxEXPAND );
	$szRow4->Add( $warnsCntValTxt, 5,  &Wx::wxEXPAND );
	$szRow4->Add( $statBtmWarns,   5,  &Wx::wxEXPAND );
	$szRow4->Add( 10, 10, 60, &Wx::wxGROW );
	$szRow4->Add( $btnWarn, 0, &Wx::wxEXPAND );

	$szBtnsChild->Add( $btnExport, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szBtnsChild->Add( $btnChange, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szBtnsChild->Add( $btnStop,   0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$szBtns->Add( 10, 10, 1, &Wx::wxGROW );
	$szBtns->Add( $szBtnsChild, 0, &Wx::wxALIGN_RIGHT | &Wx::wxALL );

	$pnlBtns->SetSizer($szBtns);

	$szFrstStatBox->Add( $szRow1, 0, &Wx::wxEXPAND );
	$szFrstStatBox->Add( $szRow2, 0, &Wx::wxEXPAND );

	$szSecStatBox->Add( $szRow3, 0, &Wx::wxEXPAND );
	$szSecStatBox->Add( $szRow4, 0, &Wx::wxEXPAND );

	$szMain->Add( $szFrstStatBox, 0,  &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szMain->Add( 10,             10, 0,                          &Wx::wxGROW );
	$szMain->Add( $szSecStatBox,  0,  &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szMain->Add( 10,             10, 1,                          &Wx::wxGROW );
	$szMain->Add( $pnlBtns,       0,  &Wx::wxEXPAND );

	# REGISTER EVENTS

	Wx::Event::EVT_BUTTON( $btnExport, -1, sub { $self->__OnExportForceClick(@_) } );
	Wx::Event::EVT_BUTTON( $btnChange, -1, sub { $self->__OnChangeClick(@_) } );
	Wx::Event::EVT_BUTTON( $btnStop,   -1, sub { $self->__OnStopClick(@_) } );

	Wx::Event::EVT_BUTTON( $btnError, -1, sub { $self->__OnErrorClick(@_) } );
	Wx::Event::EVT_BUTTON( $btnWarn,  -1, sub { $self->__OnWarningClick(@_) } );

	$mainFrm->{"onClose"}->Add( sub { $self->__OnCloseHandler(@_) } );
	$mainFrm->SetSizer($szMain);

	# SAVE NECESSARY CONTROLS
	$self->{"mainFrm"}         = $mainFrm;
	$self->{"groupNameValTxt"} = $groupNameValTxt;
	$self->{"errorsCntValTxt"} = $errorsCntValTxt;
	$self->{"warnsCntValTxt"}  = $warnsCntValTxt;
	$self->{"gauge"}           = $gauge;

	$self->{"btnStop"}      = $btnStop;
	$self->{"btnExport"}    = $btnExport;
	$self->{"btnChange"}    = $btnChange;
	$self->{"btnError"}     = $btnError;
	$self->{"btnWarn"}      = $btnWarn;
	$self->{"statBtmError"} = $statBtmError;
	$self->{"statBtmWarns"} = $statBtmWarns;

	$mainFrm->Layout();

	return $mainFrm;
}

sub __OnErrorClick {
	my $self = shift;

	$self->{"errorShowed"} = 1;

	my $warnCnt = $self->__GetWarnCnt();

	if ( $self->{"exportFinished"} ) {
		if ( $warnCnt == 0 || ( $warnCnt > 0 && $self->{"warningShowed"} ) ) {

			$self->{"btnExport"}->Enable();
		}
	}

	my @err = @{ $self->{"errors"} };
	my $str = "";

	foreach my $eItem (@err) {
		$str .= "\n\n===============================\n";
		$str .= "Group name:  <b> " . $eItem->{"group"} . "</b>\n";
		$str .= "===============================\n";

		my $cnt = scalar( @{ $eItem->{"errors"} } );
		for ( my $i = 0 ; $i < $cnt ; $i++ ) {

			my $e = @{ $eItem->{"errors"} }[$i];

			$str .= "<b>" . ( $i + 1 ) . ") Name:" . $e->{"itemId"} . "</b>\n";
			$str .= "Error: " . $e->{"value"} . "\n";
		}
	}

	my @mess = ($str);
	$self->{"messageMngr"}->ShowModal( $self->{"mainFrm"}, EnumsGeneral->MessageType_ERROR, \@mess );
}

sub __OnWarningClick {
	my $self = shift;

	$self->{"warningShowed"} = 1;
	my $errCnt = $self->__GetErrCnt();

	if ( $self->{"exportFinished"} ) {

		if ( $errCnt == 0 || ( $errCnt > 0 && $self->{"errorShowed"} ) ) {

			$self->{"btnExport"}->Enable();
		}
	}

	my @warn = @{ $self->{"warnings"} };
	my $str  = "";

	foreach my $wItem (@warn) {
		$str .= "\n\n===============================\n";
		$str .= "Group name: <b>" . $wItem->{"group"} . "</b>\n";
		$str .= "===============================\n";

		my $cnt = scalar( @{ $wItem->{"warnings"} } );
		for ( my $i = 0 ; $i < $cnt ; $i++ ) {

			my $e = @{ $wItem->{"warnings"} }[$i];

			$str .= "<b>" . ( $i + 1 ) . ") Name:" . $e->{"itemId"} . "</b>\n";
			$str .= "Warning: " . $e->{"value"} . "\n";
		}
	}

	my @mess = ($str);
	$self->{"messageMngr"}->ShowModal( $self->{"mainFrm"}, EnumsGeneral->MessageType_WARNING, \@mess );
}

sub __OnStopClick {
	my $self = shift;

	$self->{"btnStop"}->Disable();
	$self->{"groupNameValTxt"}->SetLabel("Exiting checking thread...");
	$self->{"onStopClickEvt"}->Do(@_);

}

sub __OnExportForceClick {
	my $self = shift;

	$self->{"mainFrm"}->Hide();
	$self->{"onResultEvt"}->Do( Enums->PopupResult_EXPORTFORCE );
}

sub __OnChangeClick {
	my $self = shift;

	$self->{"mainFrm"}->Hide();
	$self->{"onResultEvt"}->Do( Enums->PopupResult_CHANGE );
}

sub __OnCloseHandler {
	my $self = shift;

	#$self->{"mainFrm"}->Hide();
	$self->{"btnStop"}->Disable();
	$self->{"groupNameValTxt"}->SetLabel("Exiting checking thread...");
	$self->{"onStopClickEvt"}->Do(@_);

	#raise events
	$self->{"onClose"}->Do(@_);

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	my $test = Programs::Exporter::ExportChecker::ExportChecker::Forms::ExportPopupForm->new( undef, "f13608" );
	$test->ShowPopup();
	$test->MainLoop();
}

1;

1;

