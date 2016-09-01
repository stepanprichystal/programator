
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::ExportUtility::Forms::JobQueueItemForm;
use base qw(Widgets::Forms::CustomQueue::MyWxCustomQueueItem);

#3th party library
use Wx;

use strict;
use warnings;

#local library
use aliased 'Packages::Events::Event';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::Forms::ErrorIndicator';
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::Forms::ResultIndicator';
use aliased 'Programs::Exporter::DataTransfer::Enums' => 'EnumsTransfer';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $jobId  = shift;
	my $taskId = shift;
	my $self   = $class->SUPER::new( $parent, $taskId );

	bless($self);

	# PROPERTIES
	$self->{"jobId"}  = $jobId;
	$self->{"taskId"} = $taskId;
	$self->__SetLayout();

	# EVENTS
	$self->{"onProduce"} = Event->new();
	$self->{"onAbort"}   = Event->new();
	$self->{"onRemove"}  = Event->new();

	return $self;
}

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
	$gauge->SetValue(80);

	my $percentageTxt = Wx::StaticText->new( $self, -1, "10%", [ -1, -1 ], [ 30, 30 ] );

	my $stateTxt = Wx::StaticText->new( $self, -1, "Waiting for InCAM", [ -1, -1 ], [ 150, 30 ] );

	my $toptions = $self->__SetLayoutOptions();

	my $result = $self->__SetLayoutResult();

	my $btnProduce = Wx::Button->new( $self, -1, "Produce", &Wx::wxDefaultPosition, [ 70, 20 ] );
	my $btnAbort   = Wx::Button->new( $self, -1, "Abort",   &Wx::wxDefaultPosition, [ 70, 20 ] );
	my $btnRemove  = Wx::Button->new( $self, -1, "Remove",  &Wx::wxDefaultPosition, [ 70, 20 ] );

	#
	#	$gauge->SetValue(0);
	#my $txt2 = Wx::StaticText->new( $self, -1, "Job2 " . $self->{"text"}, [ -1, -1 ], [ 200, 30 ] );
	#my $btnDefault = Wx::Button->new( $self, -1, "Default settings", &Wx::wxDefaultPosition, [ 110, 22 ] );

	# DEFINE EVENTS
	Wx::Event::EVT_BUTTON( $btnProduce, -1, sub { $self->__OnProduce(@_) } );
	Wx::Event::EVT_BUTTON( $btnAbort,   -1, sub { $self->__OnAbort(@_) } );
	Wx::Event::EVT_BUTTON( $btnRemove,  -1, sub { $self->__OnRemove(@_) } );

	# DEFINE STRUCTURE

	$szMain->Add( 0, 40, 0 );

	$orderSz->Add( $orderTxt, 0, &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxALIGN_CENTER, 10 );

	$szMain->Add( $orderPnl, 0, &Wx::wxEXPAND );
	$szMain->Add( $title,    0, &Wx::wxEXPAND );
	$szMain->Add( $gauge,    0, &Wx::wxEXPAND | &Wx::wxLEFT, 10 );

	$szMain->Add( $percentageTxt, 0, &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxLEFT, 10 );

	$szMain->Add( $stateTxt, 0, &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxLEFT, 10 );

	$szMain->Add( $self->__GetDelimiter(), 0, &Wx::wxEXPAND );    # add delimiter

	$szMain->Add( $toptions, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 5 );

	$szMain->Add( $self->__GetDelimiter($self), 0, &Wx::wxEXPAND );    # add delimiter

	$szMain->Add( $result, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 5 );

	$szMain->Add( $self->__GetDelimiter($self), 0, &Wx::wxEXPAND | &Wx::wxLEFT, 10 );    # add delimiter

	$szMain->Add( $btnProduce, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 5 );
	$szMain->Add( $btnAbort,   0, &Wx::wxEXPAND | &Wx::wxLEFT, 2 );
	$szMain->Add( $btnRemove,  0, &Wx::wxEXPAND | &Wx::wxLEFT, 2 );

	$orderPnl->SetSizer($orderSz);

	$self->SetSizer($szMain);

	# SAVE REFERENCES
	$self->{"orderTxt"}      = $orderTxt;
	$self->{"gauge"}         = $gauge;
	$self->{"percentageTxt"} = $percentageTxt;
	$self->{"stateTxt"}      = $stateTxt;

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

	my $jobTimeTxt = Wx::StaticText->new( $self, -1, $self->{"time"}, [ -1, -1 ] );

	# DEFINE STRUCTURE
	$szMain->Add( 50, 0, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
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

	my $asyncChb         = Wx::CheckBox->new( $self, -1, "On background", [ -1, -1 ], [ 130, 20 ] );
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

	my $exportTxt  = Wx::StaticText->new( $self, -1, "Export result",   [ -1, -1 ], [ 100, 20 ] );
	my $produceTxt = Wx::StaticText->new( $self, -1, "Sent to produce", [ -1, -1 ], [ 100, 20 ] );

	my $exportRI   = ResultIndicator->new( $self, 20 );
	my $producetRI = ResultIndicator->new( $self, 20 );

	my $exportErrInd  = ErrorIndicator->new( $self, EnumsGeneral->MessageType_ERROR,   20 );
	my $exportWarnInd = ErrorIndicator->new( $self, EnumsGeneral->MessageType_WARNING, 20 );

	my $produceErrInd  = ErrorIndicator->new( $self, EnumsGeneral->MessageType_ERROR,   20 );
	my $produceWarnInd = ErrorIndicator->new( $self, EnumsGeneral->MessageType_WARNING, 20 );

	# DEFINE STRUCTURE

	$szRow1->Add( $exportTxt,     0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $exportRI,      0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $exportErrInd,  0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $exportWarnInd, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow2->Add( $produceTxt,     0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $producetRI,     0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $produceErrInd,  0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $produceWarnInd, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szMain->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# SAVE REFERENCES
	$self->{"exportRI"}       = $exportRI;
	$self->{"producetRI"}     = $producetRI;
	$self->{"exportErrInd"}   = $exportErrInd;
	$self->{"exportWarnInd"}  = $exportWarnInd;
	$self->{"produceErrInd"}  = $produceErrInd;
	$self->{"produceWarnInd"} = $produceWarnInd;

	return $szMain;

}

sub __GetDelimiter {
	my $self = shift;

	my $pnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ 2, 2 ] );
	$pnl->SetBackgroundColour( Wx::Colour->new( 150, 150, 150 ) );

	#my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	#$pnl->SetSizer($szMain);

	return $pnl;
}

sub __OnProduce {
	my $self = shift;

	$self->{"onProduce"}->Do($self->{"taskId"});

}

sub __OnAbort {
	my $self = shift;

	$self->{"onAbort"}->Do($self->{"taskId"});

}

sub __OnRemove {
	my $self = shift;

	$self->{"onRemove"}->Do($self->{"taskId"});

}

sub GetTaskId {
	my $self = shift;
	return $self->{"taskId"};
}

sub SetExportTime {
	my $self  = shift;
	my $value = shift;

	$value = "[" . $value . "]";

	$self->{"jobTimeTxt"}->SetLabel($value);
}

sub SetExportMode {
	my $self  = shift;
	my $value = shift;

	if ( $value eq EnumsTransfer->ExportMode_SYNC ) {

		$value = 0;
	}
	elsif ( $value eq EnumsTransfer->ExportMode_ASYNC ) {

		$value = 1;
	}

	$self->{"asyncChb"}->SetValue($value);
}

sub SetToProduce {
	my $self  = shift;
	my $value = shift;

	$self->{"sentToProduceChb"}->SetValue($value);
}

sub SetProgress {
	my $self  = shift;
	my $value = shift;

	$self->{"gauge"}->SetValue($value);
	$self->{"percentageTxt"}->SetLabel($value);
}

# Set export indicators

sub SetExportResult {
	my $self   = shift;
	my $stauts = shift;

	if ($stauts) {
		$stauts = EnumsGeneral->ResultType_OK;
	}
	else {
		$stauts = EnumsGeneral->ResultType_FAIL;
	}

	$self->{"exportRI"}->SetStatus($stauts);
}

sub SetExportErrors {
	my $self  = shift;
	my $count = shift;

	$self->{"exportErrInd"}->SetErrorCnt($count);
}

sub SetExportWarnings {
	my $self  = shift;
	my $count = shift;

	$self->{"exportWarnInd"}->SetErrorCnt($count);
}

# Set "sent to produce" indicators

sub SetProduceResult {
	my $self   = shift;
	my $stauts = shift;

	if ($stauts) {
		$stauts = EnumsGeneral->ResultType_OK;
	}
	else {
		$stauts = EnumsGeneral->ResultType_FAIL;
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

sub SetStateText {
	my $self = shift;
	my $text = shift;

	$self->{"stateTxt"}->SetLabel($text);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
