
#-------------------------------------------------------------------------------------------#
# Description: Form represent one JobQueue item. Contain controls which show
# status of exporting job.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::ExportUtility::Forms::JobQueueItemForm;
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
	my $class       = shift;
	my $parent      = shift;
	my $jobId       = shift;
	my $taskId      = shift;
	my $taskData    = shift;
	my $produceMngr = shift;
	my $taskMngr    = shift;
	my $groupMngr   = shift;
	my $itemMngr    = shift;

	my $self = $class->SUPER::new( $parent, $jobId, $taskId, $taskData, $taskMngr, $groupMngr, $itemMngr );

	bless($self);

	# PROPERTIES
	$self->{"produceMngr"} = $produceMngr;

	$self->__SetLayout();

	# EVENTS

	$self->{"onProduce"} = Event->new();

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

sub SetTaskResult {
	my $self   = shift;
	my $result = shift;    # tell if there was error during export

	my $aborted          = shift;
	my $jobSentToProduce = shift;    # tell if job was sent to produce

	my $value     = $self->{"taskData"}->GetToProduce();
	my $toProduce = $self->{"taskData"}->GetToProduce();    # tell if user check sent to produce chcekbox

	if ( $result eq EnumsGeneral->ResultType_FAIL ) {

		$self->{"btnProduce"}->Disable();

	}
	else {

		if ($jobSentToProduce) {

			$self->{"btnProduce"}->Disable();
		}
		else {
			$self->{"btnProduce"}->Enable();
		}

	}

	#	if ( $toProduce && $result eq EnumsGeneral->ResultType_OK ) {
	#		$self->{"btnProduce"}->Disable();
	#
	#	}
	#	elsif ( $toProduce && $result eq EnumsGeneral->ResultType_FAIL ) {
	#
	#		$self->{"btnProduce"}->Enable();
	#	}
	#	elsif ( !$toProduce && $result eq EnumsGeneral->ResultType_OK ) {
	#
	#		$self->{"btnProduce"}->Enable();
	#	}
	#	elsif ( !$toProduce && $result eq EnumsGeneral->ResultType_FAIL ) {
	#
	#		$self->{"btnProduce"}->Enable();
	#	}

	$self->{"sentToProduceChb"}->SetValue($value);

	unless ($aborted) {
		$self->SetProgress(100);
	}

	$self->{"btnAbort"}->Disable();
	$self->{"btnRemove"}->Enable();

	$self->{"exportRI"}->SetStatus($result);
}

sub SetTaskErrorCnt {
	my $self  = shift;
	my $count = shift;

	$self->{"exportErrInd"}->SetErrorCnt($count);
}

sub SetTaskWarningCnt {
	my $self  = shift;
	my $count = shift;

	$self->{"exportWarnInd"}->SetErrorCnt($count);
}

# Set "sent to produce" indicators
sub SetProduceResult {
	my $self             = shift;
	my $stauts           = shift;
	my $jobSentToProduce = shift;

	if ($jobSentToProduce) {

		$stauts = EnumsGeneral->ResultType_OK;
		$self->SetStatus("Job was sent to produce");
		$self->{"btnProduce"}->Disable();
	}

	$self->{"produceRI"}->SetStatus($stauts);
}

sub SetProduceErrors {
	my $self  = shift;
	my $count = shift;

	$self->{"produceErrInd"}->SetErrorCnt($count);
}

sub SetProduceWarnings {
	my $self  = shift;
	my $count = shift;

	$self->{"produceWarnInd"}->SetErrorCnt($count);
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


# ==============================================
# ITEM QUEUE HANDLERS
# ==============================================

sub __OnProduce {
	my $self = shift;

	$self->{"onProduce"}->Do( $self->{"taskId"} );

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
	my $orderTxt = Wx::StaticText->new( $orderPnl, -1, "0", [ -1, -1 ] );
	
	my $fontLblBold = Wx::Font->new( 11, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_BOLD );
	$orderTxt->SetForegroundColour( Wx::Colour->new( 98, 75, 0 ) );    # set text color
	$orderTxt->SetFont($fontLblBold);                                   # set text color

	my $title = $self->__SetLayoutTitle();

	my $gauge = Wx::Gauge->new( $self, -1, 100, [ -1, -1 ], [ 250, 35 ], &Wx::wxGA_HORIZONTAL );
	$gauge->SetValue(0);

	my $percentageTxt = Wx::StaticText->new( $self, -1, "0%", [ -1, -1 ], [ 30, 20 ] );

	my $stateTxt = Wx::StaticText->new( $self, -1, "Waiting for InCAM", [ -1, -1 ], [ 150, 20 ] );

	my $toptions = $self->__SetLayoutOptions();

	my $result = $self->__SetLayoutResult();

	my $btnProduce = Wx::Button->new( $self, -1, "Produce", &Wx::wxDefaultPosition, [ 60, 20 ] );
	my $btnAbort   = Wx::Button->new( $self, -1, "Abort",   &Wx::wxDefaultPosition, [ 60, 20 ] );
	my $btnRemove  = Wx::Button->new( $self, -1, "Remove",  &Wx::wxDefaultPosition, [ 60, 20 ] );

	$btnRemove->Disable();

	#
	#	$gauge->SetValue(0);
	#my $txt2 = Wx::StaticText->new( $self, -1, "Job2 " . $self->{"text"}, [ -1, -1 ], [ 200, 30 ] );
	#my $btnDefault = Wx::Button->new( $self, -1, "Default settings", &Wx::wxDefaultPosition, [ 110, 22 ] );

	# DEFINE EVENTS
	Wx::Event::EVT_BUTTON( $btnProduce, -1, sub { $self->__OnProduce(@_) } );
	Wx::Event::EVT_BUTTON( $btnAbort,   -1, sub { $self->_OnAbort(@_) } );
	Wx::Event::EVT_BUTTON( $btnRemove,  -1, sub { $self->_OnRemove(@_) } );

	# DEFINE STRUCTURE

	$szMain->Add( 0, 40, 0 );

	$orderSz->Add( $orderTxt, 0, &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxALIGN_CENTER, 15 );

	$szMain->Add( $orderPnl, 0, &Wx::wxEXPAND );
	$szMain->Add( $title,    0, &Wx::wxEXPAND );
	$szMain->Add( $gauge,    0, &Wx::wxEXPAND | &Wx::wxLEFT, 10 );

	$szMain->Add( $percentageTxt, 0, &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxLEFT, 10 );

	$szMain->Add( $stateTxt, 0, &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxLEFT, 6 );

	$szMain->Add( $self->_GetDelimiter(), 0, &Wx::wxEXPAND );    # add delimiter

	$szMain->Add( $toptions, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 5 );

	$szMain->Add( $self->_GetDelimiter($self), 0, &Wx::wxEXPAND );    # add delimiter

	$szMain->Add( $result, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 5 );

	$szMain->Add( $btnProduce, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 15 );
	$szMain->Add( $btnAbort,   0, &Wx::wxEXPAND | &Wx::wxLEFT, 2 );
	$szMain->Add( $btnRemove,  0, &Wx::wxEXPAND | &Wx::wxLEFT, 2 );

	$orderPnl->SetSizer($orderSz);

	$self->SetSizer($szMain);

	# SAVE REFERENCES
	$self->{"orderTxt"}      = $orderTxt;
	$self->{"gauge"}         = $gauge;
	$self->{"percentageTxt"} = $percentageTxt;
	$self->{"stateTxt"}      = $stateTxt;
	$self->{"btnProduce"}    = $btnProduce;
	$self->{"btnAbort"}      = $btnAbort;
	$self->{"btnRemove"}     = $btnRemove;

	# Set default control content
	$self->__SetExportTime();
	$self->__SetExportMode();
	$self->__SetToProduce();
	$self->__SetToProduceBtn();

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
	my $sentToProduceChb = Wx::CheckBox->new( $self, -1, "Sent to produce", [ -1, -1 ], [ 130, 20 ] );

	$asyncChb->Disable();
	$sentToProduceChb->Disable();

	# DEFINE STRUCTURE

	$szMain->Add( $asyncChb,         0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $sentToProduceChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# SAVE REFERENCES
	$self->{"asyncChb"}         = $asyncChb;
	$self->{"sentToProduceChb"} = $sentToProduceChb;

	return $szMain;

}

sub __SetLayoutResult {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $exportTxt  = Wx::StaticText->new( $self, -1, "Export result  :", [ -1, -1 ], [ 90, 20 ] );
	my $produceTxt = Wx::StaticText->new( $self, -1, "Sent to produce:", [ -1, -1 ], [ 90, 20 ] );

	my $exportRI  = ResultIndicator->new( $self, 20 );
	my $produceRI = ResultIndicator->new( $self, 20 );

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

	my $produceErrInd  = ErrorIndicator->new( $self, EnumsGeneral->MessageType_ERROR,   15, undef, $self->{"jobId"}, $self->{"produceMngr"} );
	my $produceWarnInd = ErrorIndicator->new( $self, EnumsGeneral->MessageType_WARNING, 15, undef, $self->{"jobId"}, $self->{"produceMngr"} );

	# DEFINE STRUCTURE

	$szRow1->Add( $exportTxt,     0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $exportRI,      0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( 15,             20, 0,                          &Wx::wxEXPAND );
	$szRow1->Add( $exportErrInd,  0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $exportWarnInd, 0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow2->Add( $produceTxt,     0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $produceRI,      0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( 15,              20, 0,                          &Wx::wxEXPAND );
	$szRow2->Add( $produceErrInd,  0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $produceWarnInd, 0,  &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szMain->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# SAVE REFERENCES
	$self->{"exportRI"}       = $exportRI;
	$self->{"produceRI"}      = $produceRI;
	$self->{"exportErrInd"}   = $exportErrInd;
	$self->{"exportWarnInd"}  = $exportWarnInd;
	$self->{"produceErrInd"}  = $produceErrInd;
	$self->{"produceWarnInd"} = $produceWarnInd;

	return $szMain;

}

# ==============================================
# HELPER FUNCTION
# ==============================================

sub __SetExportTime {
	my $self = shift;

	my $value = $self->{"taskData"}->GetTaskTime();

	$self->{"jobTimeTxt"}->SetLabel($value);
}

sub __SetExportMode {
	my $self = shift;

	my $value = $self->{"taskData"}->GetTaskMode();

	if ( $value eq EnumsJobMngr->TaskMode_SYNC ) {

		$value = 0;
	}
	elsif ( $value eq EnumsJobMngr->TaskMode_ASYNC ) {

		$value = 1;
	}

	$self->{"asyncChb"}->SetValue($value);
}

sub __SetToProduce {
	my $self  = shift;
	my $value = $self->{"taskData"}->GetToProduce();

	$self->{"sentToProduceChb"}->SetValue($value);
}

sub __SetToProduceBtn {
	my $self = shift;

	my $value = $self->{"taskData"}->GetToProduce();
	if ( $self->{"taskData"}->GetToProduce() ) {
		$self->{"btnProduce"}->Disable();
	}

	$self->{"sentToProduceChb"}->SetValue($value);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
