#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportUtility::ExportUtility::Forms::ErrorIndicator;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;


#local library
use Widgets::Style;
 
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
 
	my $mode    = shift;
	my $size = shift;
	my $showCnt = shift;
	
	unless($showCnt){
		$showCnt = 1;
	}

	my $self = $class->SUPER::new($parent);

	bless($self);

	$self->{"mode"}    = $mode;
	$self->{"size"}    = $size;
	$self->{"showCnt"} = $showCnt;
	$self->{"errCnt"} = 0;

	$self->__SetLayout();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	# size in px
	 Wx::InitAllImageHandlers();
	my $size = $self->{"size"}."x".$self->{"size"};

	# Decide which picture show
	if ( $self->{"mode"} eq EnumsGeneral->MessageType_ERROR ) {

		$self->{"pathDisable"} = GeneralHelper->Root() . "/Resources/Images/ErrorDisable".$size.".png";
		$self->{"pathEnable"}  = GeneralHelper->Root() . "/Resources/Images/Error".$size.".png";

	}
	elsif ( $self->{"mode"} eq EnumsGeneral->MessageType_WARNING ) {
		$self->{"pathDisable"} = GeneralHelper->Root() . "/Resources/Images/WarningDisable".$size.".png";
		$self->{"pathEnable"}  = GeneralHelper->Root() . "/Resources/Images/Warning".$size.".png";

	}

	#define panels

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

 

	# DEFINE CONTROLS
 
	my $cntValTxt = Wx::StaticText->new( $self, -1, "0" );
	$cntValTxt->SetFont($Widgets::Style::fontLbl);
	my $btmError = Wx::Bitmap->new( $self->{"pathDisable"}, &Wx::wxBITMAP_TYPE_PNG );
	my $statBtmError = Wx::StaticBitmap->new( $self, -1, $btmError );
	 

	# SET EVENTS
	#Wx::Event::EVT_COMBOBOX( $colorCb, -1, sub { $self->__OnColorChangeHandler(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$szMain->Add( $cntValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $statBtmError,    0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	 
	$self->SetSizer($szMain);

	# SAVE REFERENCES
	$self->{"cntValTxt"} = $cntValTxt;
	$self->{"statBtmError"}  = $statBtmError;

}


sub SetErrorCnt {
	my $self  = shift;
	my $cnt  = shift;
	 
	$self->{"errCnt"}  = $cnt;
	$self->{"cntValTxt"}->SetLabel($self->{"errCnt"});
	
	if($self->{"errCnt"} == 1){
		
		 
		my $err = Wx::Bitmap->new( $self->{"pathEnable"}, &Wx::wxBITMAP_TYPE_PNG );
		$self->{"statBtmError"}->SetBitmap($err);
	}
}

		

 

1;
