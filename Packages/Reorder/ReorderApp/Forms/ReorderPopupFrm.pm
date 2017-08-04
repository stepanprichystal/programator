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

	my $class     = shift;
	my $parent    = shift;
	my $jobId     = shift;
	 
	my @dimension = ( 450, 280 );

	my $title = "Process reorder ($jobId)";
 

	my $self = $class->SUPER::new( $parent, $title, \@dimension );

	bless($self);

	$self->__SetLayout();

	# Properties

	$self->{"checkIndicatorClick"} = Event->new();
	$self->{"procIndicatorClick"}  = Event->new();
	$self->{"continueClick"}       = Event->new();
	$self->{"okClick"}             = Event->new();

	return $self;
}

# Show popup form
sub ShowPopup {
	my $self = shift;

	$self->{"mainFrm"}->Show(1);
	$self->{"mainFrm"}->Refresh();
}

sub CheckReorderStart {
	my $self = shift;

	$self->{"gauge"}->SetValue(10);

}

sub CheckReorderEnd {
	my $self    = shift;
	my $errCnt  = shift;
	my $warnCnt = shift;

	$self->{"checkErrInd"}->SetErrorCnt($errCnt);
	$self->{"checkWarnInd"}->SetErrorCnt($warnCnt);

	$self->{"gauge"}->SetValue(50);

	$self->{"mainFrm"}->Refresh();
}

sub ProcessReorderStart {
	my $self = shift;

	$self->{"gauge"}->SetValue(60);

}

sub ProcessReorderEnd {
	my $self   = shift;
	my $errCnt = shift;

	$self->{"procErrInd"}->SetErrorCnt($errCnt);

	$self->{"gauge"}->SetValue(100);

	$self->{"mainFrm"}->Refresh();

}

sub SetResult {
	my $self        = shift;
	my $result      = shift;
	my $btnContinue = shift;
	my $btnOk       = shift;

	if ($btnContinue) {
		$self->{"btnContinue"}->Enable();
	}
	else {
		$self->{"btnContinue"}->Disable();
	}

	if ($btnOk) {
		$self->{"btnOk"}->Enable();
	}
	else {
		$self->{"btnOk"}->Disable();
	}

	$self->{"resultInd"}->SetStatus($result);

}

#-------------------------------------------------------------------------------------------#
#  Set layout
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS
	my $szMain   = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $checks   = $self->__SetLayoutChecks( $self->{"mainFrm"} );
	my $process  = $self->__SetLayoutProcess( $self->{"mainFrm"} );
	my $progress = $self->__SetLayoutProgress( $self->{"mainFrm"} );

	$szMain->Add( $checks,  0, &Wx::wxEXPAND );
	$szMain->Add( $process, 0, &Wx::wxEXPAND );
	$szMain->Add( 10, 10, 0, &Wx::wxEXPAND );
	$szMain->Add( $progress, 1, &Wx::wxEXPAND | &Wx::wxALL, 5 );

	$self->AddContent($szMain);

	$self->SetButtonHeight(20);

	my $btnContinue = $self->AddButton( "Continue", sub { $self->{"continueClick"}->Do(@_) } );
	$btnContinue->Disable();
	my $btnOk = $self->AddButton( "Close", sub { $self->{"okClick"}->Do(@_) } );
	$btnOk->Disable();

	#my $btnServer = $self->AddButton( "Process on server", sub { $self->{"processReorderEvent"}->Do(Enums->Process_SERVER) } );

	# DEFINE LAYOUT STRUCTURE

	# KEEP REFERENCES

	$self->{"btnContinue"} = $btnContinue;
	$self->{"btnOk"}       = $btnOk;

}

sub __SetLayoutChecks {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Check before process' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	my $szRow1    = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2    = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szRow5 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $errTxt = Wx::StaticText->new( $statBox, -1, "Errors:", &Wx::wxDefaultPosition, [ 200, 20 ] );
	my $errInd = ErrorIndicator->new( $statBox, EnumsGeneral->MessageType_ERROR, 15, undef, $self->{"jobId"} );

	my $warnTxt = Wx::StaticText->new( $statBox, -1, "Warnings:", &Wx::wxDefaultPosition, [ 200, 20 ] );
	my $warnInd = ErrorIndicator->new( $statBox, EnumsGeneral->MessageType_WARNING, 15, undef, $self->{"jobId"} );

	$errInd->{"onClick"}->Add( sub  { $self->{"checkIndicatorClick"}->Do( EnumsGeneral->MessageType_ERROR ) } );
	$warnInd->{"onClick"}->Add( sub { $self->{"checkIndicatorClick"}->Do( EnumsGeneral->MessageType_WARNING ) } );

	$szRow1->Add( $errTxt, 0 );
	$szRow1->Add( $errInd, 0 );

	$szRow2->Add( $warnTxt, 0 );
	$szRow2->Add( $warnInd, 0 );

	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# SAVE REFERENCES

	$self->{"checkErrInd"}  = $errInd;
	$self->{"checkWarnInd"} = $warnInd;

	return $szStatBox;
}

sub __SetLayoutProcess {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Process reorder' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szRow5 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $errTxt = Wx::StaticText->new( $statBox, -1, "Errors:", &Wx::wxDefaultPosition, [ 200, 20 ] );
	my $errInd = ErrorIndicator->new( $statBox, EnumsGeneral->MessageType_ERROR, 15, undef, $self->{"jobId"} );

	$errInd->{"onClick"}->Add( sub { $self->{"procIndicatorClick"}->Do( EnumsGeneral->MessageType_ERROR ) } );

	$szMain->Add( $errTxt, 0 );
	$szMain->Add( $errInd, 0 );
	$szStatBox->Add( $szMain, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

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

	my $resultTxt = Wx::StaticText->new( $parent, -1, "Result ", &Wx::wxDefaultPosition, [ 210, 30 ] );
	my $resultInd = ResultIndicator->new( $parent, 20 );

	#my $progressNameTxt = Wx::StaticText->new( $parent, -1, "In progress: ", &Wx::wxDefaultPosition, [ 210, 30 ] );
	#my $progressValTxt  = Wx::StaticText->new( $parent, -1, "ttt",           &Wx::wxDefaultPosition, [ 200, 30 ] );

	my $gauge = Wx::Gauge->new( $parent, -1, 100, [ -1, -1 ], [ 300, 20 ], &Wx::wxGA_HORIZONTAL );
	$gauge->SetValue(0);

	$szRow1->Add( $resultTxt, 0 );
	$szRow1->Add( $resultInd, 0 );

	#$szRow2->Add( $progressNameTxt, 0 );
	#$szRow2->Add( $progressValTxt,  0 );
	$szMain->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $gauge,  0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# SAVE REFERENCES
	$self->{"resultInd"} = $resultInd;
	$self->{"gauge"}     = $gauge;

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
	$form->ShowPopup();
	$form->MainLoop();

}

1;

