
#-------------------------------------------------------------------------------------------#
# Description: Form represent one JobQueue item. Contain controls which show
# status of merging job.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::PoolMerge::PoolMerge::Forms::JobQueueItemForm;
use base qw(Managers::AbstractQueue::AbstractQueue::Forms::JobQueueItemForm);

#3th party library
use Wx;

use strict;
use warnings;

#local library
use aliased 'Packages::Events::Event';
use aliased 'Enums::EnumsGeneral';
use aliased 'Widgets::Forms::ErrorIndicator::ErrorIndicator';
use aliased 'Widgets::Forms::ResultIndicator::ResultIndicator';
use aliased 'Managers::AsyncJobMngr::Enums' => 'EnumsJobMngr';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class        = shift;
	my $parent       = shift;
	my $jobId        = shift;
	my $taskId       = shift;
	my $taskData     = shift;
	my $toExportMngr = shift;
	my $taskMngr     = shift;
	my $groupMngr    = shift;
	my $itemMngr     = shift;

	my $self = $class->SUPER::new( $parent, $jobId, $taskId, $taskData, $taskMngr, $groupMngr, $itemMngr );

	bless($self);

	# PROPERTIES
	$self->{"toExportMngr"} = $toExportMngr;
	$self->{"taskData"}     = $taskData;

	$self->__SetLayout();

	# EVENTS

	$self->{"onToExport"} = Event->new();

	return $self;
}

# ==============================================
# FUNCTIONS SET CONTENT OF ITEM QUEUE
# ==============================================

sub SetProgress {
	my $self  = shift;
	my $value = shift;

	$self->{"gauge"}->SetValue($value);
	$self->{"percentageTxt"}->SetLabel( $value . "%" );
}

# Set merge indicators

sub SetTaskResult {
	my $self   = shift;
	my $result = shift;    # tell if there was error during merging

	my $aborted         = shift;
	my $jobSentToExport = shift;    # tell if job was sent to toExport

	if ( $result eq EnumsGeneral->ResultType_FAIL ) {

		$self->{"btnToExport"}->Disable();

	}
	else {

		if ($jobSentToExport) {

			$self->{"btnToExport"}->Disable();
		}
		else {
			$self->{"btnToExport"}->Enable();
		}

	}

	unless ($aborted) {
		$self->SetProgress(100);
	}

	# set buttons

	$self->{"btnAbort"}->Disable();
	$self->{"btnRemove"}->Enable();
	$self->{"btnContinue"}->Disable();
	$self->{"btnRestart"}->Enable();

	$self->{"mergeRI"}->SetStatus($result);
}

sub SetTaskErrorCnt {
	my $self  = shift;
	my $count = shift;

	$self->{"mergeErrInd"}->SetErrorCnt($count);
}

sub SetTaskWarningCnt {
	my $self  = shift;
	my $count = shift;

	$self->{"mergeWarnInd"}->SetErrorCnt($count);
}

# Set "sent to toExport" indicators
sub SetToExportResult {
	my $self            = shift;
	my $stauts          = shift;
	my $jobSentToExport = shift;

	if ($jobSentToExport) {

		$stauts = EnumsGeneral->ResultType_OK;
		$self->SetStatus("Job was sent to toExport");
		$self->{"btnToExport"}->Disable();
	}

	$self->{"toExportRI"}->SetStatus($stauts);
}

sub SetToExportErrors {
	my $self  = shift;
	my $count = shift;

	$self->{"toExportErrInd"}->SetErrorCnt($count);
}

sub SetToExportWarnings {
	my $self  = shift;
	my $count = shift;

	$self->{"toExportWarnInd"}->SetErrorCnt($count);
}

sub SetStatus {
	my $self = shift;
	my $text = shift;

	$self->{"stateTxt"}->SetLabel($text);
}

sub SetItemOrder {
	my $self = shift;

	my $pos = ( $self->GetPosition() + 1 );

	$self->{"orderTxt"}->SetLabel($pos);
}

sub SetMasterJob {
	my $self      = shift;
	my $masterJob = shift;

	$self->{"poolMasterTxt"}->SetLabel("master: $masterJob");
}

sub SetJobItemStopped {
	my $self = shift;

	# set buttons
	$self->{"btnToExport"}->Disable();
	$self->{"btnAbort"}->Disable();
	$self->{"btnRemove"}->Disable();
	$self->{"btnContinue"}->Enable();
	$self->{"btnRestart"}->Enable();
}

sub SetJobItemContinue {
	my $self = shift;

	# set buttons
	$self->{"btnToExport"}->Disable();
	$self->{"btnAbort"}->Enable();
	$self->{"btnRemove"}->Disable();
	$self->{"btnContinue"}->Disable();
	$self->{"btnRestart"}->Disable();
}

# ==============================================
# ITEM QUEUE HANDLERS
# ==============================================

sub __OnToExport {
	my $self = shift;

	$self->{"onToExport"}->Do( $self->{"taskId"} );

}

sub __OnContinue {
	my $self = shift;

	# 1) Disable buttons
	# set buttons
	$self->{"btnToExport"}->Disable();
	$self->{"btnAbort"}->Disable();
	$self->{"btnRemove"}->Disable();
	$self->{"btnContinue"}->Enable();
	$self->{"btnRestart"}->Disable();
	
	$self->SetStatus("Preparing to continue ...");

	# 2) call base handler
	$self->_OnContinue(@_);

}

# ========================================================================
# SET LAYOUT
# ========================================================================
sub __SetLayout {
	my $self = shift;

	my $szMain  = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $orderSz = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $szCol  = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $gauge = Wx::Gauge->new( $self, -1, 100, [ -1, -1 ], [ -1, 4 ], &Wx::wxGA_HORIZONTAL );
	$gauge->SetValue(0);

	my $orderPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ 40, 45 ] );
	$orderPnl->SetBackgroundColour( Wx::Colour->new( 83, 215, 253 ) );
	my $orderTxt = Wx::StaticText->new( $orderPnl, -1, "0", [ -1, -1 ] );

	my $fontLblBold = Wx::Font->new( 11, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_BOLD );
	$orderTxt->SetForegroundColour( Wx::Colour->new( 1, 87, 112 ) );    # set text color
	$orderTxt->SetFont($fontLblBold);                                   # set text color

	my $title    = $self->__SetLayoutTitle();
	my $progress = $self->__SetLayoutProgres();
	my $toptions = $self->__SetLayoutOptions();
	my $result   = $self->__SetLayoutResult();
	my $buttons  = $self->__SetLayoutBtns();

	# DEFINE STRUCTURE

	$orderPnl->SetSizer($orderSz);

	$orderSz->Add( $orderTxt, 0, &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxALIGN_CENTER, 12 );
	$szRow1->Add( $toptions, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 5 );
	$szRow1->Add( $self->_GetDelimiter($self), 0, &Wx::wxEXPAND );    # add delimiter
	$szRow1->Add( $progress, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 10 );
	$szRow1->Add( $self->_GetDelimiter(), 0, &Wx::wxEXPAND );         # add delimiter

	$szRow1->Add( $result,  0, &Wx::wxEXPAND | &Wx::wxLEFT, 5 );
	$szRow1->Add( $buttons, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	$szRow2->Add( $gauge,   1, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );

	$szCol->Add( $szRow1, 1, &Wx::wxEXPAND );
	$szCol->Add( $szRow2, 0, &Wx::wxEXPAND );

	$szMain->Add( $orderPnl, 0, &Wx::wxEXPAND );
	$szMain->Add( $title, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 8 );
	$szMain->Add( $self->_GetDelimiter(), 0, &Wx::wxEXPAND | &Wx::wxLEFT, 10 );    # add delimiter
	$szMain->Add( $szCol, 1, &Wx::wxEXPAND );

	$self->SetSizer($szMain);

	# SAVE REFERENCES
	$self->{"orderTxt"} = $orderTxt;
	$self->{"gauge"}    = $gauge;

	# Set default control content
	$self->__SetMergeTime();
	$self->__SetMergeMode();
	$self->__SetSentToExport();
	$self->__SetSentToExportBtn();

	$self->RecursiveHandler($self);

}

sub __SetLayoutTitle {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# Fonts
	my $fontLblBold = Wx::Font->new( 10, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_BOLD );

	# DEFINE CONTROLS

	my $pnlName = $self->{"taskData"}->GetPanelName();

	my $pnlIdTxt = Wx::StaticText->new( $self, -1, $self->{"taskData"}->GetPanelName(), [ -1, -1 ] );
	$pnlIdTxt->SetFont($fontLblBold);

	my $pnlTimeTxt = Wx::StaticText->new( $self, -1, [ -1, -1 ] );
	$pnlTimeTxt->SetForegroundColour( Wx::Colour->new( 100, 100, 100 ) );    # set text color

	# DEFINE STRUCTURE
	$szMain->Add( 50, 4, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $pnlIdTxt,   0, &Wx::wxALIGN_CENTER | &Wx::wxALL, 0 );
	$szMain->Add( $pnlTimeTxt, 0, &Wx::wxALIGN_CENTER | &Wx::wxALL, 0 );

	# SAVE REFERENCES
	$self->{"pnlIdTxt"}   = $pnlIdTxt;
	$self->{"pnlTimeTxt"} = $pnlTimeTxt;

	return $szMain;
}

sub __SetLayoutProgres {
	my $self = shift;

	# DEFINE SIZERS

	my $szMain   = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szStatus = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# Fonts

	# DEFINE CONTROLS

	#my $gauge = Wx::Gauge->new( $self, -1, 100, [ -1, -1 ], [ 370, 20 ], &Wx::wxGA_HORIZONTAL );
	#$gauge->SetValue(0);

	my $percentageTxt = Wx::StaticText->new( $self, -1, "0%", [ -1, -1 ], [ 30, 10 ] );

	my $stateTxt = Wx::StaticText->new( $self, -1, "Waiting for InCAM", [ -1, -1 ], [ 235, 10 ] );

	# DEFINE STRUCTURE
	$szStatus->Add( $percentageTxt, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 5 );
	$szStatus->Add( $stateTxt,      1, &Wx::wxEXPAND | &Wx::wxLEFT, 10 );

	#$szMain->Add( $gauge, 50, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( 2, 2, 30, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $szStatus, 70, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# SAVE REFERENCES
	#$self->{"gauge"}         = $gauge;
	$self->{"percentageTxt"} = $percentageTxt;
	$self->{"stateTxt"}      = $stateTxt;

	return $szMain;
}

sub __SetLayoutOptions {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $szClm1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szClm2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS

	my $poolTypeTxt   = Wx::StaticText->new( $self, -1, "type: " . $self->{"taskData"}->GetPoolType(),       [ -1, -1 ], [ 100, 1 ] );
	my $poolSurfTxt   = Wx::StaticText->new( $self, -1, "surf: " . $self->{"taskData"}->GetPoolSurface(),    [ -1, -1 ], [ 100, 1 ] );
	my $poolTimeTxt   = Wx::StaticText->new( $self, -1, "export: " . $self->{"taskData"}->GetPoolExported(), [ -1, -1 ], [ 100, 1 ] );
	my $poolMasterTxt = Wx::StaticText->new( $self, -1, "master: -",                                         [ -1, -1 ], [ 100, 1 ] );

	$poolTypeTxt->SetForegroundColour( Wx::Colour->new( 100, 100, 100 ) );    # set text color
	$poolSurfTxt->SetForegroundColour( Wx::Colour->new( 100, 100, 100 ) );    # set text color
	$poolTimeTxt->SetForegroundColour( Wx::Colour->new( 100, 100, 100 ) );    # set text color
	$poolMasterTxt->SetForegroundColour( Wx::Colour->new( 100, 100, 100 ) );  # set text color

	#	my $fontLblBold = Wx::Font->new( 10, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_BOLD );
	#
	#	$poolMasterTxt->SetFont($fontLblBold);

	#	$poolTypeTxt->Disable();
	#	$poolSurfTxt->Disable();
	#	$poolTimeTxt->Disable();
	#	$poolMasterTxt->Disable();

	# DEFINE STRUCTURE

	$szClm1->Add( $poolTypeTxt, 50, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szClm1->Add( $poolSurfTxt, 50, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szClm2->Add( $poolTimeTxt,   50, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szClm2->Add( $poolMasterTxt, 50, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szMain->Add( $szClm1, 50, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $szClm2, 50, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# SAVE REFERENCES
	$self->{"poolMasterTxt"} = $poolMasterTxt;

	return $szMain;
}

sub __SetLayoutResult {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $mergeTxt    = Wx::StaticText->new( $self, -1, "Merge result :", [ -1, -1 ], [ 90, 20 ] );
	my $toExportTxt = Wx::StaticText->new( $self, -1, "Export result:", [ -1, -1 ], [ 90, 20 ] );

	my $mergeRI    = ResultIndicator->new( $self, 20 );
	my $toExportRI = ResultIndicator->new( $self, 20 );

	my $mergeErrInd  = ErrorIndicator->new( $self, EnumsGeneral->MessageType_ERROR,   15, undef, $self->{"jobId"} );
	my $mergeWarnInd = ErrorIndicator->new( $self, EnumsGeneral->MessageType_WARNING, 15, undef, $self->{"jobId"} );

	$mergeErrInd->AddMenu();
	$mergeErrInd->AddMenuItem( "Job",    $self->{"taskMngr"} );
	$mergeErrInd->AddMenuItem( "Groups", $self->{"groupMngr"} );
	$mergeErrInd->AddMenuItem( "Items",  $self->{"itemMngr"} );

	$mergeWarnInd->AddMenu();
	$mergeWarnInd->AddMenuItem( "Job",    $self->{"taskMngr"} );
	$mergeWarnInd->AddMenuItem( "Groups", $self->{"groupMngr"} );
	$mergeWarnInd->AddMenuItem( "Items",  $self->{"itemMngr"} );

	my $toExportErrInd  = ErrorIndicator->new( $self, EnumsGeneral->MessageType_ERROR,   15, undef, $self->{"jobId"}, $self->{"toExportMngr"} );
	my $toExportWarnInd = ErrorIndicator->new( $self, EnumsGeneral->MessageType_WARNING, 15, undef, $self->{"jobId"}, $self->{"toExportMngr"} );

	# DEFINE STRUCTURE

	$szRow1->Add( $mergeTxt,     0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $mergeRI,      0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( 15,            20, 0,                          &Wx::wxEXPAND );
	$szRow1->Add( $mergeErrInd,  0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $mergeWarnInd, 0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow2->Add( $toExportTxt,     0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $toExportRI,      0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( 15,               20, 0,                          &Wx::wxEXPAND );
	$szRow2->Add( $toExportErrInd,  0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $toExportWarnInd, 0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szMain->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxTOP, 1 );
	$szMain->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# SAVE REFERENCES
	$self->{"mergeRI"}         = $mergeRI;
	$self->{"toExportRI"}      = $toExportRI;
	$self->{"mergeErrInd"}     = $mergeErrInd;
	$self->{"mergeWarnInd"}    = $mergeWarnInd;
	$self->{"toExportErrInd"}  = $toExportErrInd;
	$self->{"toExportWarnInd"} = $toExportWarnInd;

	return $szMain;

}

sub __SetLayoutBtns {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szCol1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szCol2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szCol3 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS

	my $btnToExport = Wx::Button->new( $self, -1, "Export",   &Wx::wxDefaultPosition, [ 80, 10 ] );
	my $btnContinue = Wx::Button->new( $self, -1, "Continue", &Wx::wxDefaultPosition, [ 80, 10 ] );
	my $btnAbort    = Wx::Button->new( $self, -1, "Abort",    &Wx::wxDefaultPosition, [ 80, 10 ] );
	my $btnRestart  = Wx::Button->new( $self, -1, "Restart",  &Wx::wxDefaultPosition, [ 80, 10 ] );
	my $btnRemove   = Wx::Button->new( $self, -1, "Remove",   &Wx::wxDefaultPosition, [ 80, 10 ] );

	$btnRemove->Disable();
	$btnToExport->Disable();
	$btnContinue->Disable();
	$btnRestart->Disable();
	 

	# DEFINE EVENTS
	Wx::Event::EVT_BUTTON( $btnToExport, -1, sub { $self->__OnToExport(@_) } );
	Wx::Event::EVT_BUTTON( $btnContinue, -1, sub { $self->__OnContinue(@_) } );
	Wx::Event::EVT_BUTTON( $btnAbort,    -1, sub { $self->_OnAbort(@_) } );
	Wx::Event::EVT_BUTTON( $btnRemove,   -1, sub { $self->_OnRemove(@_) } );
	Wx::Event::EVT_BUTTON( $btnRestart,  -1, sub { $self->_OnRestart(@_) } );

	# DEFINE STRUCTURE

	$szCol1->Add( $btnToExport, 1, &Wx::wxEXPAND | &Wx::wxTOP, 1 );
	$szCol1->Add( $btnRestart,  1, &Wx::wxEXPAND | &Wx::wxTOP, 1 );

	$szCol2->Add( $btnContinue, 1, &Wx::wxEXPAND | &Wx::wxTOP, 1 );
	$szCol2->Add( $btnAbort,    1, &Wx::wxEXPAND | &Wx::wxTOP, 1 );

	$szCol3->Add( $btnRemove, 1, &Wx::wxEXPAND | &Wx::wxTOP, 1 );

	$szMain->Add( $szCol1, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 15 );
	$szMain->Add( $szCol2, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 1 );
	$szMain->Add( $szCol3, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 1 );

	# SAVE REFERENCES
	$self->{"btnToExport"} = $btnToExport;
	$self->{"btnAbort"}    = $btnAbort;
	$self->{"btnRemove"}   = $btnRemove;
	$self->{"btnContinue"} = $btnContinue;
	$self->{"btnRestart"}  = $btnRestart;

	return $szMain;

}

# ==============================================
# HELPER FUNCTION
# ==============================================

sub __SetMergeTime {
	my $self = shift;

	my $value = $self->{"taskData"}->GetTaskTime();

	$self->{"pnlTimeTxt"}->SetLabel($value);
}

sub __SetMergeMode {
	my $self = shift;

	#	my $value = $self->{"taskData"}->GetTaskMode();
	#
	#	if ( $value eq EnumsJobMngr->TaskMode_SYNC ) {
	#
	#		$value = 0;
	#	}
	#	elsif ( $value eq EnumsJobMngr->TaskMode_ASYNC ) {
	#
	#		$value = 1;
	#	}
	#
	#	$self->{"asyncChb"}->SetValue($value);
}

sub __SetSentToExport {
	my $self = shift;

	#my $value = $self->{"taskData"}->GetSentToExport();

	#$self->{"sentToExportChb"}->SetValue($value);
}

sub __SetSentToExportBtn {
	my $self = shift;

	$self->{"btnToExport"}->Disable();

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
