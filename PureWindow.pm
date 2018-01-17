#-------------------------------------------------------------------------------------------#
# Description: Form, which allow set nif quick notes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package PureWindow;
use base 'Widgets::Forms::StandardFrm';

#3th party librarysss
use strict;
use warnings;
use Wx;
use Win32::GUI;

#local library

use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Events::Event';
use aliased 'Packages::Reorder::ReorderApp::Enums';
use aliased 'Popup';
use aliased 'Managers::AbstractQueue::NotifyMngr::NotifyMngr';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class  = shift;
	my @params = @_;

	print STDERR "Parametry:" . join( ",", @params );

	my $jobId     = "f52456";
	my $w         = 250;
	my $h         = 300;
	my @dimension = ( $w, $h );

	my $self = $class->SUPER::new( -1, "test123", \@dimension, undef );

	bless($self);

	$self->__SetLayout();

	$self->{"queue"}      = [];
	$self->{"notifyMngr"} = NotifyMngr->new( $self->{"mainFrm"} );

	# Properties

	return $self;
}

sub Run {
	my $self = shift;

	$self->{"mainFrm"}->Show(1);

}

sub Init {
	my $self     = shift;
	my $launcher = shift;    # Launcher cobject

}

#-------------------------------------------------------------------------------------------#
#  Set layout
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	$self->SetButtonHeight(30);

	my $btnTest = $self->AddButton( "notify 1", sub { $self->test1(@_) } );

	my $btnTest2 = $self->AddButton( "notify 2", sub { $self->test2(@_) } );
	my $btnTest3 = $self->AddButton( "test 3",      sub { $self->test3(@_) } );

	# DEFINE LAYOUT STRUCTURE

	# KEEP REFERENCES

}

sub test1 {
	my $self = shift;

 

}
sub test2 {
	my $self = shift;
	
	my $taskId = "";

	#sleep(2);
	my $frm = $self->{"notifyMngr"}->GetNotifyFrame();
	my $contentParent = $frm->GetContentParent();

	#my $pnlMain = Wx::Panel->new( $frm->{"pnlMain"}, -1 );

	# DEFINE SIZERS

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $jobIdTxt = Wx::StaticText->new( $contentParent, -1, "F123457", &Wx::wxDefaultPosition, [ 70, 20 ] );
	my $f = Wx::Font->new( 11, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_NORMAL );
	$jobIdTxt->SetFont($f);
	
	my $btnShow = Wx::Button->new( $contentParent, -1, "Show task", &Wx::wxDefaultPosition,  [ 200, 22 ] );

	my $messageTxt = Wx::StaticText->new( $contentParent, -1, "- was added to queue...", &Wx::wxDefaultPosition, [ 100, 20 ] );
	my $f2 = Wx::Font->new( 10, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_NORMAL );
	$messageTxt->SetFont($f2);
	
	# DEFINE EVENTS
	Wx::Event::EVT_BUTTON( $btnShow, -1, sub { $self->{"notifyMngr"}->ShowTaskById($taskId)} );
	
	# SET LAYOUT
 
	 
	$szRow1->Add( $jobIdTxt,   0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $btnShow,   0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	
	$szMain->Add( 10, 10, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 5 );
	$szMain->Add( $messageTxt, 1, &Wx::wxEXPAND | &Wx::wxALL, 5 );
 


	#$pnlMain->SetSizer($szMain);

	$frm->AddNotifyContent($szMain);

	my $hwnd = $frm->{"mainFrm"}->GetHandle();

	$self->{"notifyMngr"}->AddNotify( $frm, $taskId, 0, 1 );

	#$AnimateWindow->Call($hwnd, $msec, AW_HIDE | AW_VER_POSITIVE   );

}

sub test3 {
	my $self = shift;

	 $self->{"notifyMngr"}->CleanUp();
}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

1;

