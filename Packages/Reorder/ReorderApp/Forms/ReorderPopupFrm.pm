#-------------------------------------------------------------------------------------------#
# Description: Form, which allow set nif quick notes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ReorderApp::Forms::ReorderPopupFrm;
use base 'Widgets::Forms::StandardFrm';

#3th party librarysss
use strict;
use warnings;
use Wx;

#local library
use aliased 'Widgets::Forms::ErrorIndicator::ErrorIndicator';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Events::Event';
use aliased 'Packages::Reorder::ReorderApp::Enums';
use aliased 'Widgets::Forms::ResultIndicator::ResultIndicator';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $class  = shift;
	my $parent = shift;
	my $jobId  = shift;
	my $type   = shift;    # process type /locall/server

	my @dimension = ( 430, 240 );

	my $title = "Process reorder ($jobId)";
	
	my $flags = &Wx::wxSTAY_ON_TOP | &Wx::wxSYSTEM_MENU | &Wx::wxCAPTION  | &Wx::wxMINIMIZE_BOX | &Wx::wxMAXIMIZE_BOX | &Wx::wxCLOSE_BOX;

	my $self = $class->SUPER::new( $parent, $title, \@dimension, $flags );

	bless($self);
	
	# Properties
	$self->{"processType"} = $type;

	# Set layout
	$self->__SetLayout();


	# Events
	$self->{"procIndicatorClick"} = Event->new();
	$self->{"okClick"}            = Event->new();

	return $self;
}

 

sub SetResult {
	my $self   = shift;
	my $result = shift;

	my $state = EnumsGeneral->ResultType_OK;
	unless ($result) {
		$state = EnumsGeneral->ResultType_FAIL;
	}

	$self->{"resultInd"}->SetStatus($state);
	
	$self->{"btnOk"}->Enable();

}

sub SetGaugeVal {
	my $self = shift;
	my $val  = shift;

	$val = int($val);

	print STDERR $val . "\n";

	$self->{"gauge"}->SetValue($val);
	$self->{"progressTxt"}->SetLabel( $val . "%" );
}

sub SetErrIndicator {
	my $self = shift;
	my $cnt  = shift;

	if ($cnt) {

		$self->{"procErrInd"}->SetErrorCnt($cnt);
	}
}

#-------------------------------------------------------------------------------------------#
#  Set layout
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $process  = $self->__SetLayoutInfo( $self->{"mainFrm"} );
	my $progress = $self->__SetLayoutProgress( $self->{"mainFrm"} );

	$szMain->Add( $process, 0, &Wx::wxEXPAND );
	$szMain->Add( 10, 10, 1, &Wx::wxEXPAND );
	$szMain->Add( $progress, 0, &Wx::wxEXPAND | &Wx::wxALL, 5 );

	$self->AddContent($szMain);

	$self->SetButtonHeight(20);

	my $btnOk = $self->AddButton( "Close", sub { $self->{"okClick"}->Do(@_) } );
	$btnOk->Disable();

 	# EVENTS
 	
 	 # when click on WINDOWS close button (), behave like click on close button in status bar
 	$self->{"mainFrm"}->{'onClose'}->Add(sub { $self->{"okClick"}->Do(@_) } );
 	
 
 
	# DEFINE LAYOUT STRUCTURE

	# KEEP REFERENCES

	$self->{"btnOk"} = $btnOk;

}

sub __SetLayoutInfo {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes

	my $txt = $self->{"processType"} eq Enums->Process_LOCALLY ? "Processing reorder LOCALLY" : "Preparing to proces on SERVER";

	my $statBox = Wx::StaticBox->new( $parent, -1, $txt );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szRow5 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $errTxt = Wx::StaticText->new( $statBox, -1, "Errors:", &Wx::wxDefaultPosition, [ 200, 20 ] );
	my $errInd = ErrorIndicator->new( $statBox, EnumsGeneral->MessageType_ERROR, 15, undef, $self->{"jobId"} );

	$errInd->{"onClick"}->Add( sub { $self->{"procIndicatorClick"}->Do( EnumsGeneral->MessageType_ERROR ) } );

	$szMain->Add( $errTxt, 0  );
	$szMain->Add( $errInd, 0 );
	$szStatBox->Add( $szMain, 0, &Wx::wxEXPAND | &Wx::wxTOP, 10 );

	# SAVE REFERENCES
	$self->{"procErrInd"} = $errInd;

	return $szStatBox;
}

sub __SetLayoutProgress {
	my $self   = shift;
	my $parent = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $resultTxt = Wx::StaticText->new( $parent, -1, "Result: ", &Wx::wxDefaultPosition, [ 210, 30 ] );
	my $resultInd = ResultIndicator->new( $parent, 20 );

	#my $progressNameTxt = Wx::StaticText->new( $parent, -1, "In progress: ", &Wx::wxDefaultPosition, [ 210, 30 ] );
	#my $progressValTxt  = Wx::StaticText->new( $parent, -1, "ttt",           &Wx::wxDefaultPosition, [ 200, 30 ] );

	my $gauge = Wx::Gauge->new( $parent, -1, 100, [ -1, -1 ], [ 300, 20 ], &Wx::wxGA_HORIZONTAL );
	$gauge->SetValue(0);

	my $progressTxt = Wx::StaticText->new( $parent, -1, "0%", &Wx::wxDefaultPosition, [ 30, 30 ] );

	$szRow1->Add( $resultTxt, 0 );
	$szRow1->Add( $resultInd, 0 );

	$szRow2->Add( $gauge, 1 );
	$szRow2->Add( $progressTxt, 0, &Wx::wxLEFT, 5 );

	#$szRow2->Add( $progressNameTxt, 0 );
	#$szRow2->Add( $progressValTxt,  0 );
	$szMain->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# SAVE REFERENCES
	$self->{"resultInd"}   = $resultInd;
	$self->{"gauge"}       = $gauge;
	$self->{"progressTxt"} = $progressTxt;

	return $szMain;
}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::ReorderApp::Forms::ReorderPopupFrm';

	my $form = ReorderPopupFrm->new();
	$form->{"mainFrm"}->Show();
	$form->MainLoop();

}

1;

