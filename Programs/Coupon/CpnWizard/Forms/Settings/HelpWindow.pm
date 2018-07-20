#-------------------------------------------------------------------------------------------#
# Description: Form, which allow set nif quick notes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::Forms::Settings::HelpWindow;
use base 'Widgets::Forms::StandardModalFrm';

#3th party librarysss
use strict;
use warnings;
use Wx;
use Image::Size;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::GeneralHelper';
use aliased 'Programs::Coupon::CpnWizard::WizardCore::Helper';

#tested form

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $class     = shift;
	my $parent    = shift;
	my $helpLabel = shift;
	my $helpText  = shift;
	my $helpImage = shift;
	
	my @dimension = ( 400, 400 );
	
	# if image exist set dimension by image dim
	if ( -e $helpImage ) {
		( my $x, my $y ) = imgsize($helpImage);
		
		@dimension = ($x, $y + 80); # 80 space for help text
		
	}

	#my $flags = &Wx::wxCAPTION | &Wx::wxFRAME_NO_TASKBAR;

	my $flags = &Wx::wxCAPTION ;

	my $self = $class->SUPER::new( $parent, "Help - $helpLabel", \@dimension, undef );

	bless($self);

	# Properties
	$self->{"helpLabel"} = $helpLabel;
	$self->{"helpText"}  = $helpText;
	$self->{"helpImage"} = $helpImage;

	$self->__SetLayout();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $pnlMain = Wx::Panel->new( $self, -1 );
	#$pnlMain->SetBackgroundColour( Wx::Colour->new( 215, 215, 215 ) );

	#$pnlMain->SetForegroundColour( Wx::Colour->new( 250, 250, 250 ) );

	#my $stepBackg = Wx::Colour->new( 215, 215, 215 );
	#$pnlMain->SetBackgroundColour( $stepBackg );    #green

	my $maxTrackTxt = Wx::TextCtrl->new( $pnlMain, -1, $self->{"helpText"}, &Wx::wxDefaultPosition, [ -1, 50 ], &Wx::wxTE_MULTILINE | &Wx::wxTE_READONLY);
	#$maxTrackTxt->SetBackgroundColour( Wx::Colour->new( 215, 215, 215 ) );
	  
	Wx::InitAllImageHandlers();
	   
	my $btmIco = undef;
	if ( -e $self->{"helpImage"} ) {
		$btmIco = Wx::Bitmap->new( $self->{"helpImage"}, &Wx::wxBITMAP_TYPE_PNG );    #wxBITMAP_TYPE_PNG
	}
	else {
		$btmIco = Wx::Bitmap->new( Helper->GetResourcePath()."help\\noImage.png", &Wx::wxBITMAP_TYPE_PNG );    #wxBITMAP_TYPE_PNG
	}
 
	my $p  ='c:\Perl\site\lib\TpvScripts\Scripts\Programs\Coupon\CpnWizard\Resources\Help\stepName.png';
		
     # Wx::InitAllImageHandlers();
     # $btmIco = Wx::Bitmap->new( $self->{"helpImage"}, &Wx::wxBITMAP_TYPE_PNG );    #wxBITMAP_TYPE_PNG
#        my $handler = Wx::JPEGHandler->new();
#        my $image = Wx::Image->new();
#        my $bmp;    # used to hold the bitmap.
#        $handler->LoadFile( $image, 'c:\Perl\site\lib\TpvScripts\Scripts\Programs\Coupon\CpnWizard\Resources\Help\stepName.jpeg' );
#       unless(-e $p){
#       	die;
#       }
       
      # $btmIco = Wx::Bitmap->new( $image);    #wxBITMAP_TYPE_PNG

       my $statBtmIco = Wx::StaticBitmap->new( $self, -1, $btmIco );

           # $this->{ImageViewer}= Wx::StaticBitmap->new($this, -1, $bm

	#my $test = Wx::StaticBitmap::ScaleMode->("Scale_AspectFit");

	# EVENTS

	Wx::Event::EVT_LEFT_DOWN( $statBtmIco,  sub { $self->__WindowClick(@_) } );
	Wx::Event::EVT_LEFT_DOWN( $maxTrackTxt, sub { $self->__WindowClick(@_) } );
	Wx::Event::EVT_LEFT_DOWN( $pnlMain,     sub { $self->__WindowClick(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$pnlMain->SetSizer($szMain);    # DEFINE LAYOUT STRUCTURE
	#$szMain->Add( 10, 10, 0, );
	$szMain->Add( $maxTrackTxt, 0, &Wx::wxEXPAND, 10 );
	#$szMain->Add( 10, 10, 0, );
	$szMain->Add( $statBtmIco, 1 );

	$self->AddContent( $pnlMain, 0 );

	$self->SetButtonHeight(0);

	#$self->AddButton( "Ok", sub { $self->__GenerateClick(@_) } );

}

sub __WindowClick {
	my $self = shift;

	$self->Destroy();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased "Programs::Coupon::CpnWizard::Forms::WizardStep1::GeneratorFrm";
	#
	#	my @dimension = ( 500, 800 );
	#
	my $test = GeneratorFrm->new(-1);

}

1;

