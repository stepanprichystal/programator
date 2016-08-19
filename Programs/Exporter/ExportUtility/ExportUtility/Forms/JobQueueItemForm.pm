
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

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $jobId = shift;
	
	my $self = $class->SUPER::new( $parent, -1 );

	bless($self);

	# PROPERTIES

	$self->{"jobId"} = $jobId;

	$self->__SetLayout();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	

	# DEFINE CONTROLS

	my $orderTxt = Wx::StaticText->new( $self, -1, "0)",     [ -1, -1 ], [ 20, 20 ] );
	my $jobIdTxt = Wx::StaticText->new( $self, -1, $self->{"jobId"}, [ -1, -1 ], [ 40, 20 ] );

	my $gauge = Wx::Gauge->new( $self, -1, 100, [ -1, -1 ], [ 250, 40 ], &Wx::wxGA_HORIZONTAL );
	$gauge->SetValue(0);

	my $percentageTxt = Wx::StaticText->new( $self, -1, "10%", [ -1, -1 ], [ 30, 20 ] );

	my $errIndicator  = ErrorIndicator->new( $self, EnumsGeneral->MessageType_ERROR );
	my $warnIndicator = ErrorIndicator->new( $self, EnumsGeneral->MessageType_WARNING );

	my $statusTxt = Wx::StaticText->new( $self, -1, "Waiting for InCAM", [ -1, -1 ], [ 100, 20 ] );
	my $stepTxt   = Wx::StaticText->new( $self, -1, "Exportovano",       [ -1, -1 ], [ 70, 20 ] );

	my $resultTxt = Wx::StaticText->new( $self, -1, "Ok", [ -1, -1 ], [ 30, 20 ] );

	my $btnAbort  = Wx::Button->new( $self, -1, "Abort", &Wx::wxDefaultPosition, [ 70, 20 ] );
	my $btnRemove = Wx::Button->new( $self, -1, "Remove", &Wx::wxDefaultPosition, [ 70, 20 ] );

	#
	#	$gauge->SetValue(0);
	#my $txt2 = Wx::StaticText->new( $self, -1, "Job2 " . $self->{"text"}, [ -1, -1 ], [ 200, 30 ] );
	#my $btnDefault = Wx::Button->new( $self, -1, "Default settings", &Wx::wxDefaultPosition, [ 110, 22 ] );

	# DEFINE EVENTS

	Wx::Event::EVT_BUTTON( $btnAbort,  -1, sub { $self->__OnAbort(@_) } );
	Wx::Event::EVT_BUTTON( $btnRemove, -1, sub { $self->__OnRemove(@_) } );

	# DEFINE STRUCTURE

	$szMain->Add( $orderTxt,      0, &Wx::wxEXPAND |  &Wx::wxLEFT, 20);
	$szMain->Add( $jobIdTxt,      0, &Wx::wxEXPAND  |  &Wx::wxLEFT,20);
	$szMain->Add( $gauge,         0,      &Wx::wxLEFT,10);
	$szMain->Add( $percentageTxt, 0, &Wx::wxEXPAND  |  &Wx::wxLEFT,10);
	$szMain->Add( $errIndicator,  0, &Wx::wxEXPAND  |  &Wx::wxLEFT,20);
	$szMain->Add( $warnIndicator, 0, &Wx::wxEXPAND  |  &Wx::wxLEFT,10);

	$szMain->Add( $statusTxt, 0, &Wx::wxEXPAND  |  &Wx::wxLEFT,10);
	$szMain->Add( $stepTxt, 0, &Wx::wxEXPAND |  &Wx::wxLEFT,20);
	
	$szMain->Add( $resultTxt, 0, &Wx::wxEXPAND |  &Wx::wxLEFT,20);
	$szMain->Add( $btnAbort,  0, &Wx::wxEXPAND |  &Wx::wxLEFT,20);
	$szMain->Add( $btnRemove, 0, &Wx::wxEXPAND |  &Wx::wxLEFT,5);

	$self->SetSizer($szMain);
	
	
	# SAVE REFERENCES
	$self->{"orderTxt"} = $orderTxt;
	$self->{"gauge"} = $gauge;
	$self->{"percentageTxt"} = $percentageTxt;
	$self->{"errIndicator"} = $errIndicator;
	$self->{"warnIndicator"} = $warnIndicator;
	$self->{"statusTxt"} = $statusTxt;
	$self->{"stepTxt"} = $stepTxt;
	$self->{"resultTxt"} = $resultTxt;

	$self->RecursiveHandler($self);

}
 
sub SetOrder {
	my $self = shift;
	my $value = shift;

	$self->{"orderTxt"}->SetLabel($value);
}

sub SetProgress {
	my $self = shift;
	my $value = shift;
	 
	$self->{"gauge"}->SetValue($value);
	$self->{"percentageTxt"}->SetLabel($value);
}

sub SetErrors {
	my $self = shift;
	my $count = shift;
	 
	$self->{"errIndicator"}->AddError($count);
}

sub SetWarnings {
	my $self = shift;
	my $count = shift;
	 
	$self->{"warnIndicator"}->AddError($count);
}

sub SetStatusText {
	my $self = shift;
	my $text = shift;
	 
	$self->{"statusTxt"}->SetLabel($text);
}

sub SetStepText {
	my $self = shift;
	my $stepText = shift;
	 
	$self->{"stepTxt"}->SetLabel($stepText);
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
