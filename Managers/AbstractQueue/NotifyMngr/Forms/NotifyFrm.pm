#-------------------------------------------------------------------------------------------#
# Description: Form, which allow set nif quick notes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AbstractQueue::NotifyMngr::Forms::NotifyFrm;
use base 'Widgets::Forms::StandardFrm';

#3th party librarysss
use strict;
use warnings;
use Wx;
use Win32::GUI;

#local library

use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Events::Event';
use aliased 'Packages::Other::AppConf';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Events::Event';
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $class  = shift;
	
	#my @params = @_;
	#print STDERR "Parametry:" . join( ",", @params );

	my $parent = shift;
	my $w    = shift;
	my $h    = shift;
	my $posX = shift;
	my $posY = shift;
	 

	my @dimension = ( $w,    $h );
	my @pos       = ( $posX, $posY );

	my $flags = &Wx::wxCLOSE_BOX | &Wx::wxFRAME_NO_TASKBAR | &Wx::wxSTAY_ON_TOP;

	my $self = $class->SUPER::new( $parent, "", \@dimension, $flags, \@pos);

	bless($self);

	$self->__SetLayout();


	# Properties
	
	$self->{"notifyId"} = GeneralHelper->GetGUID();  
	
	# Events
	
	$self->{'onCloseClick'} = Event->new();


	return $self;
}

sub ShowNotify {
	my $self = shift;

	$self->{"mainFrm"}->Show(1);

}

sub CloseNotify {
	my $self = shift;

	$self->{"mainFrm"}->Show(1);

}

sub Init {
	my $self     = shift;
	my $launcher = shift;    # Launcher cobject

}

sub GetContentParent{
	my $self = shift;
	
	
	return $self->{"pnlMain"};
}

sub AddNotifyContent {
	my $self = shift;
	my $content = shift;
	

	$self->{"contentSz"}->Add( $content,  1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$self->{"contentSz"}->Layout();
}

sub GetNotifyId{
	my $self  = shift;
	return $self->{"notifyId"};
	
	
}


#-------------------------------------------------------------------------------------------#
#  Set layout
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self = shift;


	# DEFINE CONTROLS
 



	# DEFINE CONTROLS

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $pnlMain = Wx::Panel->new( $self->{"mainFrm"}, -1 );
	
	$pnlMain->SetBackgroundColour(  AppConf->GetColor("clrGroupBackg") );

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRowWrap = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	 

	my $pnlRow1 = Wx::Panel->new( $pnlMain, -1 );
	 

	
	$pnlRow1->SetBackgroundColour(AppConf->GetColor("clrStatusBar") );
	

 
	# HEADER of notifz frame
	 

	# apllication ico
	my $bitmpaIco = Wx::Bitmap->new( GeneralHelper->Root() . "/Resources/Images/" . AppConf->GetValue("appIcon"), &Wx::wxBITMAP_TYPE_BMP );
	my $statBtmIco = Wx::StaticBitmap->new( $pnlRow1, -1, $bitmpaIco );

	my $appNameTxt = Wx::StaticText->new( $pnlRow1, -1, AppConf->GetValue("appName"), &Wx::wxDefaultPosition, [ 100, 20 ] );
	my $f = Wx::Font->new( 11, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL,
		&Wx::wxFONTWEIGHT_NORMAL );
	$appNameTxt->SetFont($f);
	# close btn
	my $bitmpaClose = Wx::Bitmap->new( GeneralHelper->Root() . "/Resources/Images/close_button.bmp", &Wx::wxBITMAP_TYPE_BMP );
	my $statBtmClose = Wx::StaticBitmap->new( $pnlRow1, -1, $bitmpaClose );

	# SET EVENTS

	Wx::Event::EVT_LEFT_UP( $statBtmClose, sub { $self->{"onCloseClick"}->Do($self) } );

	# BUILD STRUCTURE OF LAYOUT
	

	
	$szRow1->Add( $statBtmIco,  0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $appNameTxt,  1, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szRow1->Add( $statBtmClose, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	#$szRow1->Add( 0,  50, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	
	$pnlMain->SetSizer($szMain);
	
	$szRowWrap->Add( $szRow1,  1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$pnlRow1->SetSizer($szRowWrap);
	 
	
	$szMain->Add( $pnlRow1,  0, &Wx::wxEXPAND | &Wx::wxALL, 0);
	 

	$self->AddContent($pnlMain, 0);
	
	
	 $self->SetButtonHeight(0);

	my $btnTest = $self->AddButton( "test", sub { $self->{'onCloseClick'}->Do($self->{"notifyId"}) } );
	
	$self->{"contentSz"} = $szMain;
	$self->{"pnlMain"} = $pnlMain;
	
	
	 

}

sub test {
	my $self = shift;

	my $frm = PureWindow->new(-1);
	$frm->{"mainFrm"}->Show();

	print STDERR "test";

	push( @{ $self->{"queue"} }, $frm );

}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#
 


1;

