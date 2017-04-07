
#-------------------------------------------------------------------------------------------#
# Description: Form represent one JobQueue item. Contain controls which show
# status of exporting job.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportPool::ExportPool::Forms::JobQueueItemForm;
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
use aliased 'Managers::AbstractQueue::ExportData::Enums' => 'EnumsTransfer';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class        = shift;
	my $parent       = shift;
	my $jobId        = shift;
	my $taskId       = shift;
	my $exportedData = shift;
	my $ExportMngr  = shift;
	my $taskMngr     = shift;
	my $groupMngr    = shift;
	my $itemMngr     = shift;

	my $self = $class->SUPER::new( $parent, $jobId, $taskId, $exportedData, $taskMngr, $groupMngr, $itemMngr );

	bless($self);

	# PROPERTIES
	$self->{"ExportMngr"} = $ExportMngr;

	$self->__SetLayout();

	# EVENTS

	$self->{"onExport"} = Event->new();

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

# Set export indicators

sub SetExportResult {
	my $self   = shift;
	my $result = shift;    # tell if there was error during export

	my $aborted          = shift;
	my $jobSendToExport = shift;    # tell if job was send to export

	my $value     = $self->{"exportedData"}->GetToExport();
	my $ToExport = $self->{"exportedData"}->GetToExport();    # tell if user check send to export chcekbox

	if ( $result eq EnumsGeneral->ResultType_FAIL ) {

		$self->{"btnExport"}->Disable();

	}
	else {

		if ($jobSendToExport) {

			$self->{"btnExport"}->Disable();
		}
		else {
			$self->{"btnExport"}->Enable();
		}

	}

	#	if ( $ToExport && $result eq EnumsGeneral->ResultType_OK ) {
	#		$self->{"btnExport"}->Disable();
	#
	#	}
	#	elsif ( $ToExport && $result eq EnumsGeneral->ResultType_FAIL ) {
	#
	#		$self->{"btnExport"}->Enable();
	#	}
	#	elsif ( !$ToExport && $result eq EnumsGeneral->ResultType_OK ) {
	#
	#		$self->{"btnExport"}->Enable();
	#	}
	#	elsif ( !$ToExport && $result eq EnumsGeneral->ResultType_FAIL ) {
	#
	#		$self->{"btnExport"}->Enable();
	#	}

	$self->{"SendToExportChb"}->SetValue($value);

	unless ($aborted) {
		$self->SetProgress(100);
	}

	$self->{"btnAbort"}->Disable();
	$self->{"btnRemove"}->Enable();

	$self->{"exportRI"}->SetStatus($result);
}

sub SetExportErrorCnt {
	my $self  = shift;
	my $count = shift;

	$self->{"exportErrInd"}->SetErrorCnt($count);
}

sub SetExportWarningCnt {
	my $self  = shift;
	my $count = shift;

	$self->{"exportWarnInd"}->SetErrorCnt($count);
}

# Set "send to export" indicators
sub SetToExportResult {
	my $self             = shift;
	my $stauts           = shift;
	my $jobSendToExport = shift;

	if ($jobSendToExport) {

		$stauts = EnumsGeneral->ResultType_OK;
		$self->SetStatus("Job was send to export");
		$self->{"btnExport"}->Disable();
	}

	$self->{"ExportRI"}->SetStatus($stauts);
}

sub SetExportErrors {
	my $self  = shift;
	my $count = shift;

	$self->{"ExportErrInd"}->SetErrorCnt($count);
}

sub SetExportWarnings {
	my $self  = shift;
	my $count = shift;

	$self->{"ExportWarnInd"}->SetErrorCnt($count);
}

sub SetStatus {
	my $self = shift;
	my $text = shift;

	$self->{"stateTxt"}->SetLabel($text);
}

sub SetItemOrder {
	my $self = shift;

	my $pos = ( $self->GetPosition() + 1 ) . ")";

	$self->{"orderTxt"}->SetLabel($pos);
}

sub GetTaskId {
	my $self = shift;
	return $self->{"taskId"};
}

# ==============================================
# ITEM QUEUE HANDLERS
# ==============================================

sub __OnExport {
	my $self = shift;

	$self->{"onExport"}->Do( $self->{"taskId"} );

}

# ========================================================================
# SET LAYOUT
# ========================================================================
sub __SetLayout {
	my $self = shift;

	my $szMain  = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $orderSz = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $orderPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ 40, 40 ] );
	$orderPnl->SetBackgroundColour( Wx::Colour->new( 255, 200, 10 ) );
	my $orderTxt = Wx::StaticText->new( $orderPnl, -1, "0)", [ -1, -1 ] );

	my $title = $self->__SetLayoutTitle();

	my $gauge = Wx::Gauge->new( $self, -1, 100, [ -1, -1 ], [ 250, 35 ], &Wx::wxGA_HORIZONTAL );
	$gauge->SetValue(0);

	my $percentageTxt = Wx::StaticText->new( $self, -1, "0%", [ -1, -1 ], [ 30, 20 ] );

	my $stateTxt = Wx::StaticText->new( $self, -1, "Waiting for InCAM", [ -1, -1 ], [ 150, 20 ] );

	my $toptions = $self->__SetLayoutOptions();

	my $result = $self->__SetLayoutResult();

	my $btnExport = Wx::Button->new( $self, -1, "Export", &Wx::wxDefaultPosition, [ 60, 20 ] );
	my $btnAbort   = Wx::Button->new( $self, -1, "Abort",   &Wx::wxDefaultPosition, [ 60, 20 ] );
	my $btnRemove  = Wx::Button->new( $self, -1, "Remove",  &Wx::wxDefaultPosition, [ 60, 20 ] );

	$btnRemove->Disable();

	#
	#	$gauge->SetValue(0);
	#my $txt2 = Wx::StaticText->new( $self, -1, "Job2 " . $self->{"text"}, [ -1, -1 ], [ 200, 30 ] );
	#my $btnDefault = Wx::Button->new( $self, -1, "Default settings", &Wx::wxDefaultPosition, [ 110, 22 ] );

	# DEFINE EVENTS
	Wx::Event::EVT_BUTTON( $btnExport, -1, sub { $self->__OnExport(@_) } );
	Wx::Event::EVT_BUTTON( $btnAbort,   -1, sub { $self->__OnAbort(@_) } );
	Wx::Event::EVT_BUTTON( $btnRemove,  -1, sub { $self->__OnRemove(@_) } );

	# DEFINE STRUCTURE

	$szMain->Add( 0, 40, 0 );

	$orderSz->Add( $orderTxt, 0, &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxALIGN_CENTER, 10 );

	$szMain->Add( $orderPnl, 0, &Wx::wxEXPAND );
	$szMain->Add( $title,    0, &Wx::wxEXPAND );
	$szMain->Add( $gauge,    0, &Wx::wxEXPAND | &Wx::wxLEFT, 10 );

	$szMain->Add( $percentageTxt, 0, &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxLEFT, 10 );

	$szMain->Add( $stateTxt, 0, &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxLEFT, 6 );

	$szMain->Add( $self->_GetDelimiter(), 0, &Wx::wxEXPAND );    # add delimiter

	$szMain->Add( $toptions, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 5 );

	$szMain->Add( $self->_GetDelimiter($self), 0, &Wx::wxEXPAND );    # add delimiter

	$szMain->Add( $result, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 5 );

	$szMain->Add( $btnExport, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 15 );
	$szMain->Add( $btnAbort,   0, &Wx::wxEXPAND | &Wx::wxLEFT, 2 );
	$szMain->Add( $btnRemove,  0, &Wx::wxEXPAND | &Wx::wxLEFT, 2 );

	$orderPnl->SetSizer($orderSz);

	$self->SetSizer($szMain);

	# SAVE REFERENCES
	$self->{"orderTxt"}      = $orderTxt;
	$self->{"gauge"}         = $gauge;
	$self->{"percentageTxt"} = $percentageTxt;
	$self->{"stateTxt"}      = $stateTxt;
	$self->{"btnExport"}    = $btnExport;
	$self->{"btnAbort"}      = $btnAbort;
	$self->{"btnRemove"}     = $btnRemove;

	# Set default control content
	$self->__SetExportTime();
	$self->__SetExportMode();
	$self->__SetToExport();
	$self->__SetToExportBtn();

	$self->RecursiveHandler($self);

}

sub __SetLayoutTitle {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# Fonts
	my $fontLblBold = Wx::Font->new( 10, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_BOLD );

	# DEFINE CONTROLS

	my $jobIdTxt = Wx::StaticText->new( $self, -1, $self->{"jobId"}, [ -1, -1 ] );
	$jobIdTxt->SetFont($fontLblBold);

	my $jobTimeTxt = Wx::StaticText->new( $self, -1, [ -1, -1 ] );
	$jobTimeTxt->SetForegroundColour( Wx::Colour->new( 100, 100, 100 ) );    # set text color

	# DEFINE STRUCTURE
	$szMain->Add( 50, 4, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $jobIdTxt,   0, &Wx::wxALIGN_CENTER | &Wx::wxALL, 0 );
	$szMain->Add( $jobTimeTxt, 0, &Wx::wxALIGN_CENTER | &Wx::wxALL, 0 );

	# SAVE REFERENCES
	$self->{"jobIdTxt"}   = $jobIdTxt;
	$self->{"jobTimeTxt"} = $jobTimeTxt;

	return $szMain;
}

sub __SetLayoutOptions {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS

	my $asyncChb         = Wx::CheckBox->new( $self, -1, "On background",   [ -1, -1 ], [ 130, 20 ] );
	my $SendToExportChb = Wx::CheckBox->new( $self, -1, "send to export", [ -1, -1 ], [ 130, 20 ] );

	$asyncChb->Disable();
	$SendToExportChb->Disable();

	# DEFINE STRUCTURE

	$szMain->Add( $asyncChb,         0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $SendToExportChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# SAVE REFERENCES
	$self->{"asyncChb"}         = $asyncChb;
	$self->{"SendToExportChb"} = $SendToExportChb;

	return $szMain;

}

sub __SetLayoutResult {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $exportTxt  = Wx::StaticText->new( $self, -1, "Export result  :", [ -1, -1 ], [ 90, 20 ] );
	my $ExportTxt = Wx::StaticText->new( $self, -1, "send to export:", [ -1, -1 ], [ 90, 20 ] );

	my $exportRI  = ResultIndicator->new( $self, 20 );
	my $ExportRI = ResultIndicator->new( $self, 20 );

	my $exportErrInd  = ErrorIndicator->new( $self, EnumsGeneral->MessageType_ERROR,   15, undef, $self->{"jobId"} );
	my $exportWarnInd = ErrorIndicator->new( $self, EnumsGeneral->MessageType_WARNING, 15, undef, $self->{"jobId"} );

	$exportErrInd->AddMenu();
	$exportErrInd->AddMenuItem( "Job",    $self->{"taskMngr"} );
	$exportErrInd->AddMenuItem( "Groups", $self->{"groupMngr"} );
	$exportErrInd->AddMenuItem( "Items",  $self->{"itemMngr"} );

	$exportWarnInd->AddMenu();
	$exportWarnInd->AddMenuItem( "Job",    $self->{"taskMngr"} );
	$exportWarnInd->AddMenuItem( "Groups", $self->{"groupMngr"} );
	$exportWarnInd->AddMenuItem( "Items",  $self->{"itemMngr"} );

	my $ExportErrInd  = ErrorIndicator->new( $self, EnumsGeneral->MessageType_ERROR,   15, undef, $self->{"jobId"}, $self->{"ExportMngr"} );
	my $ExportWarnInd = ErrorIndicator->new( $self, EnumsGeneral->MessageType_WARNING, 15, undef, $self->{"jobId"}, $self->{"ExportMngr"} );

	# DEFINE STRUCTURE

	$szRow1->Add( $exportTxt,     0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $exportRI,      0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( 15,             20, 0,                          &Wx::wxEXPAND );
	$szRow1->Add( $exportErrInd,  0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $exportWarnInd, 0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow2->Add( $ExportTxt,     0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $ExportRI,      0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( 15,              20, 0,                          &Wx::wxEXPAND );
	$szRow2->Add( $ExportErrInd,  0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $ExportWarnInd, 0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szMain->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# SAVE REFERENCES
	$self->{"exportRI"}       = $exportRI;
	$self->{"ExportRI"}      = $ExportRI;
	$self->{"exportErrInd"}   = $exportErrInd;
	$self->{"exportWarnInd"}  = $exportWarnInd;
	$self->{"ExportErrInd"}  = $ExportErrInd;
	$self->{"ExportWarnInd"} = $ExportWarnInd;

	return $szMain;

}

# ==============================================
# HELPER FUNCTION
# ==============================================

sub __SetExportTime {
	my $self = shift;

	my $value = $self->{"exportedData"}->GetExportTime();

	$self->{"jobTimeTxt"}->SetLabel($value);
}

sub __SetExportMode {
	my $self = shift;

	my $value = $self->{"exportedData"}->GetExportMode();

	if ( $value eq EnumsTransfer->ExportMode_SYNC ) {

		$value = 0;
	}
	elsif ( $value eq EnumsTransfer->ExportMode_ASYNC ) {

		$value = 1;
	}

	$self->{"asyncChb"}->SetValue($value);
}

sub __SetToExport {
	my $self  = shift;
	my $value = $self->{"exportedData"}->GetToExport();

	$self->{"SendToExportChb"}->SetValue($value);
}

sub __SetToExportBtn {
	my $self = shift;

	my $value = $self->{"exportedData"}->GetToExport();
	if ( $self->{"exportedData"}->GetToExport() ) {
		$self->{"btnExport"}->Disable();
	}

	$self->{"SendToExportChb"}->SetValue($value);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
