#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportUtility::ExportUtility::Forms::ResultIndicator;
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
 
	 
	my $size = shift;
	#my $showCnt = shift;
	
	#unless($showCnt){
	#	$showCnt = 1;
	#}

	my $self = $class->SUPER::new($parent);

	bless($self);

	#$self->{"mode"}    = $mode;
	$self->{"size"}    = $size;
	$self->{"state"}    = EnumsGeneral->ResultType_NA;
	 

	$self->__SetLayout();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	# size in px
	 
	my $size = $self->{"size"}."x".$self->{"size"};
 
	 $self->{"pathOk"} = GeneralHelper->Root() . "/Resources/Images/Ok".$size.".bmp";
	 $self->{"pathFail"}  = GeneralHelper->Root() . "/Resources/Images/Fail".$size.".bmp";
	 $self->{"pathNA"}  = GeneralHelper->Root() . "/Resources/Images/NA".$size.".bmp";
	 

	#define panels

 
	# DEFINE CONTROLS
	
	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
 
 
	my $btmError = Wx::Bitmap->new( $self->{"pathNA"}, &Wx::wxBITMAP_TYPE_BMP );
	my $statBtmError = Wx::StaticBitmap->new( $self, -1, $btmError );
	 

	# SET EVENTS
	 
	# BUILD STRUCTURE OF LAYOUT
	$szMain->Add( $statBtmError,    0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	 
	$self->SetSizer($szMain);

	# SAVE REFERENCES
	$self->{"statBtmError"}  = $statBtmError;
}


sub SetStatus {
	my $self  = shift;
	my $status  = shift;
 
	my $path = undef;
	
	if($status eq EnumsGeneral->ResultType_NA){
		 
		$path = Wx::Bitmap->new( $self->{"pathNA"}, &Wx::wxBITMAP_TYPE_BMP );
		
	
	}elsif($status eq EnumsGeneral->ResultType_OK){
		
		$path = Wx::Bitmap->new( $self->{"pathOk"}, &Wx::wxBITMAP_TYPE_BMP );
	
	}elsif($status eq EnumsGeneral->ResultType_FAIL){
		
		$path = Wx::Bitmap->new( $self->{"pathFail"}, &Wx::wxBITMAP_TYPE_BMP );
	}
	
	
	$self->{"statBtmError"}->SetBitmap($path);
}

		

 

1;
