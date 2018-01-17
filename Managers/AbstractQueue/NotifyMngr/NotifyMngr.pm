#-------------------------------------------------------------------------------------------#
# Description: Base class of notify manager. Class is able to prepare notify window
#
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AbstractQueue::NotifyMngr::NotifyMngr;

#3th party library
use strict;
use warnings;
use Win32::GUI;
use Win32;
use Win32::API;

#local library
use aliased 'Packages::Events::Event';
use aliased 'Managers::AbstractQueue::NotifyMngr::Forms::NotifyFrm';
use aliased 'Managers::AbstractQueue::NotifyMngr::Notify';
use aliased 'Packages::Other::AppConf';
use aliased 'Widgets::Forms::ResultIndicator::ResultIndicator';

#-------------------------------------------------------------------------------------------#
#  NC task, all layers, all machines..
#-------------------------------------------------------------------------------------------#
use constant AW_VER_POSITIVE => 0x00000004;
use constant AW_VER_NEGATIVE => 0x00000008;
use constant AW_HIDE         => 0x00010000;
use constant AW_ACTIVATE     => 0x00020000;
use constant AW_SLIDE        => 0x00040000;

#-------------------------------------------------------------------------------------------#
#  PUBLIC METHODS
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	# PROPERTIES
	$self->{"abstractQueue"} = shift;
	 

	$self->{"notifyQueue"} = [];

	# EVENTS

	#	$self->{"onItemResult"} = Event->new();
	#	$self->{"onStatusResult"} = Event->new();

	$self->__SetTimer();

	return $self;
}

# Destroz all existing notify frame, typicallz before exist app
sub CleanUp {
	my $self = shift;

	$self->{"timer"}->Stop();

	# close all notify window
	for ( my $i = @{ $self->{"notifyQueue"} } - 1 ; $i >= 0 ; $i-- ) {

		say STDERR "CLOSE notify";

		$self->__DestroyNotify( $self->{"notifyQueue"}->[$i] );
	}

}

sub DestroyNotifiesByTaskId {
	my $self   = shift;
	my $taskId = shift;

	my @notifies = grep { $_->GetTaskId() eq $taskId } @{ $self->{"notifyQueue"} };

	# close all notify window
	for ( my $i = @notifies - 1 ; $i >= 0 ; $i-- ) {

		$self->__DestroyNotify( $notifies[$i] );
	}
}

#-------------------------------------------------------------------------------------------#
#  PROTECTED METHODS
#-------------------------------------------------------------------------------------------#

# Run task of group
sub _GetNotifyFrame {
	my $self = shift;

	my $desk = Win32::GUI::GetDesktopWindow();
	my $dw   = Win32::GUI::Width($desk);
	my $dh   = Win32::GUI::Height($desk);

	my $w = 180;
	my $h = 230;

	my $posX = $dw - $w - 5;
	my $posY = $dh - $h - 50;

	my $frame = NotifyFrm->new( 1, $w, $h, $posX, $posY );

	$frame->{"onCloseClick"}->Add(

		sub {

			my $notifyFrm = shift;

			my $notify = ( grep { $_->GetNotifyId() eq $notifyFrm->GetNotifyId() } @{ $self->{"notifyQueue"} } )[0];

			$self->__DestroyNotify($notify);
		}
	);

	return $frame;
}

sub _AddNotify {
	my $self        = shift;
	my $notifyFrame = shift;
	my $taskId      = shift;    # abstractQueue task asociated with this notify frm
	my $autoClose   = shift;
	my $dispTime    = shift;    # time how long is message displayed

	my $notify = Notify->new( $notifyFrame, $taskId, $autoClose, $dispTime );

	push( @{ $self->{"notifyQueue"} }, $notify );

	$self->__ShowNotify($notify);

}

sub _ShowTaskById {
	my $self   = shift;
	my $taskId = shift;

	my $parentFrm = $self->{"abstractQueue"}->{"mainFrm"};

	# Show main form
	my $showed = $parentFrm->IsShown();

	if ( !$showed ) {
		$parentFrm->Show();        # show form
		$parentFrm->Iconize(0);    # if form is minimalised, restore
		$parentFrm->Raise();       # bring to front

	}
	elsif ( $showed && $parentFrm->IsIconized() ) {
		$parentFrm->Iconize(0);
		$parentFrm->Raise();
	}

	# select  task by id

	$self->{"abstractQueue"}->SelectJobItem($taskId);

}

# Method show standard message notify window with simple text
sub _ShowStandardMessNotify {
	my $self     = shift;
	my $taskId   = shift;
	my $jobId    = shift;
	my $message  = shift;
	my $autoHide = shift;
	my $dispTime = shift;

	my $frm           = $self->_GetNotifyFrame();
	my $contentParent = $frm->GetContentParent();

	# DEFINE SIZERS

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $jobIdTxt = Wx::StaticText->new( $contentParent, -1, $jobId, &Wx::wxDefaultPosition, [ 70, 20 ] );
	my $f = Wx::Font->new( 11, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_NORMAL );
	$jobIdTxt->SetFont($f);

	my $btnShow = Wx::Button->new( $contentParent, -1, "Show task", &Wx::wxDefaultPosition, [ 200, 22 ] );

	my $messageTxt = Wx::StaticText->new( $contentParent, -1, $message, &Wx::wxDefaultPosition, [ 100, 20 ] );
	my $f2 = Wx::Font->new( 10, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_NORMAL );
	$messageTxt->SetFont($f2);

	# DEFINE EVENTS
	Wx::Event::EVT_BUTTON( $btnShow, -1, sub { $self->_ShowTaskById($taskId) } );

	# SET LAYOUT

	$szRow1->Add( $jobIdTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $btnShow,  0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$szMain->Add( 10, 10, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $szRow1,     0, &Wx::wxEXPAND | &Wx::wxALL, 5 );
	$szMain->Add( $messageTxt, 1, &Wx::wxEXPAND | &Wx::wxALL, 5 );

	$frm->AddNotifyContent($szMain);

	# show notify

	$self->_AddNotify( $frm, $taskId, $autoHide, $dispTime );

}

# Method show standard message notify window with simple text, and two result indicators
sub _ShowStandardResNotify {
	my $self          = shift;
	my $taskId        = shift;
	my $jobId         = shift;
	my $message       = shift;
	my $autoHide      = shift;
	my $dispTime      = shift;
	my $resultStatus1 = shift;
	my $resultStatus2 = shift;
	my $resMess1      = shift;
	my $resMess2      = shift;

	my $frm           = $self->_GetNotifyFrame();
	my $contentParent = $frm->GetContentParent();

	# DEFINE SIZERS

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $jobIdTxt = Wx::StaticText->new( $contentParent, -1, $jobId, &Wx::wxDefaultPosition, [ 70, 20 ] );
	my $f = Wx::Font->new( 11, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_NORMAL );
	$jobIdTxt->SetFont($f);

	my $btnShow = Wx::Button->new( $contentParent, -1, "Show task", &Wx::wxDefaultPosition, [ 200, 22 ] );

	my $messageTxt = Wx::StaticText->new( $contentParent, -1, $message, &Wx::wxDefaultPosition, [ 100, 20 ] );
	my $f2 = Wx::Font->new( 10, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_NORMAL );
	$messageTxt->SetFont($f2);

	my $res1Txt = Wx::StaticText->new( $contentParent, -1, $resMess1, &Wx::wxDefaultPosition, [ 100, 20 ] );
	my $res2Txt = Wx::StaticText->new( $contentParent, -1, $resMess2, &Wx::wxDefaultPosition, [ 100, 20 ] );

	my $res1RI = ResultIndicator->new( $contentParent, 20 );
	$res1RI->SetStatus($resultStatus1);

	my $res2RI = ResultIndicator->new( $contentParent, 20 );
	$res2RI->SetStatus($resultStatus2);

	# DEFINE EVENTS
	Wx::Event::EVT_BUTTON( $btnShow, -1, sub { $self->_ShowTaskById($taskId) } );

	# SET LAYOUT

	$szRow1->Add( $jobIdTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $btnShow,  0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$szRow2->Add( $res1Txt, 0, &Wx::wxEXPAND | &Wx::wxALL,  0 );
	$szRow2->Add( $res1RI,  1, &Wx::wxEXPAND | &Wx::wxLEFT, 5 );

	$szRow3->Add( $res2Txt, 0, &Wx::wxEXPAND | &Wx::wxALL,  0 );
	$szRow3->Add( $res2RI,  1, &Wx::wxEXPAND | &Wx::wxLEFT, 5 );

	$szMain->Add( 10, 10, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $szRow1,     0, &Wx::wxEXPAND | &Wx::wxALL, 5 );
	$szMain->Add( $messageTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 5 );
	$szMain->Add( $szRow2,     0, &Wx::wxEXPAND | &Wx::wxALL, 5 );
	$szMain->Add( $szRow3,     0, &Wx::wxEXPAND | &Wx::wxALL, 5 );

	$frm->AddNotifyContent($szMain);

	# show notify

	$self->_AddNotify( $frm, $taskId, 1, $dispTime );

}

#-------------------------------------------------------------------------------------------#
#  PRIVATE METHODS
#-------------------------------------------------------------------------------------------#

sub __ShowNotify {
	my $self   = shift;
	my $notify = shift;

	$notify->SetDisplayed( time() );

	my $hwnd = $notify->GetNotifyFrm()->{"mainFrm"}->GetHandle();

	my $AnimateWindow = new Win32::API( "user32", "AnimateWindow", [ 'N', 'N', 'N' ], 'N' ) or die "ttt";

	# set animation duration in ms (usually 200ms)
	my $msec = 250;

	$AnimateWindow->Call( $hwnd, $msec, AW_VER_NEGATIVE | AW_SLIDE );

}

sub __DestroyNotify {
	my $self   = shift;
	my $notify = shift;

	my $hwnd = $notify->GetNotifyFrm()->{"mainFrm"}->GetHandle();

	my $AnimateWindow = new Win32::API( "user32", "AnimateWindow", [ 'N', 'N', 'N' ], 'N' ) or die "ttt";

	# set animation duration in ms (usually 200ms)
	my $msec = 250;

	$AnimateWindow->Call( $hwnd, $msec, AW_HIDE | AW_VER_POSITIVE | AW_SLIDE );

	$notify->GetNotifyFrm()->{"mainFrm"}->Destroy();

	# remove from queue

	for ( my $i = @{ $self->{"notifyQueue"} } - 1 ; $i >= 0 ; $i-- ) {

		if ( $notify->GetNotifyId() eq $self->{"notifyQueue"}->[$i]->GetNotifyId() ) {

			splice @{ $self->{"notifyQueue"} }, $i, 1;
		}
	}

	return 1;
}

sub __SetTimer {
	my $self = shift;

	my $parentFrm = $self->{"abstractQueue"}->{"mainFrm"};

	my $timertask = Wx::Timer->new( $parentFrm, -1, );
	Wx::Event::EVT_TIMER( $parentFrm, $timertask, sub { __TimerHandler( $self, @_ ) } );
	$timertask->Start(1000);

	$self->{"timer"} = $timertask;

}

sub __TimerHandler {
	my $self = shift;

	foreach my $notify ( @{ $self->{"notifyQueue"} } ) {

		unless ( $notify->GetAutoClose() ) {
			next;
		}

		if ( ( $notify->GetDisplayed() + $notify->GetDispTime() ) < time() ) {

			$self->__DestroyNotify($notify);
		}

	}

}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

