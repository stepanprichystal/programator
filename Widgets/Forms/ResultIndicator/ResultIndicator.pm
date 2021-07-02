#-------------------------------------------------------------------------------------------#
# Description: Widget can show result Fail/Succes that is all.
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Widgets::Forms::ResultIndicator::ResultIndicator;
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

	my $self = $class->SUPER::new($parent);

	bless($self);

	$self->{"size"}    = $size;
	$self->{"status"}    = EnumsGeneral->ResultType_NA;
	 

	$self->__SetLayout();

	return $self;
}




sub SetStatus {
	my $self  = shift;
	my $status  = shift;
 
	my $path = undef;
	
	if($status eq EnumsGeneral->ResultType_NA){
		 
		$path = Wx::Bitmap->new( $self->{"pathNA"}, &Wx::wxBITMAP_TYPE_PNG );
		
	
	}elsif($status eq EnumsGeneral->ResultType_OK){
		
		$path = Wx::Bitmap->new( $self->{"pathOk"}, &Wx::wxBITMAP_TYPE_PNG );
	
	}elsif($status eq EnumsGeneral->ResultType_FAIL){
		
		$path = Wx::Bitmap->new( $self->{"pathFail"}, &Wx::wxBITMAP_TYPE_PNG );
	}
	
	$self->{"status"} = $status;
	
	
	$self->{"statBtmError"}->SetBitmap($path);
	
	$self->{"szMain"}->Layout();
	 
}

sub GetStatus {
	my $self  = shift;
	 
	return $self->{"status"};
}

sub __SetLayout {
	my $self = shift;

	# size in px
	 
	  Wx::InitAllImageHandlers();
	 
	my $size = $self->{"size"}."x".$self->{"size"};
 
	 $self->{"pathOk"} = GeneralHelper->Root() . "/Resources/Images/Ok".$size.".png";
	 $self->{"pathFail"}  = GeneralHelper->Root() . "/Resources/Images/Failure".$size.".png";
	 $self->{"pathNA"}  = GeneralHelper->Root() . "/Resources/Images/OkDisable".$size.".png";
	 

	#define panels

 
	# DEFINE CONTROLS
	
	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
 
 
	my $btmError = Wx::Bitmap->new( $self->{"pathNA"}, &Wx::wxBITMAP_TYPE_PNG );
	my $statBtmError = Wx::StaticBitmap->new( $self, -1, $btmError );
	 

	# SET EVENTS
	

	 
	# BUILD STRUCTURE OF LAYOUT
	$szMain->Add( $statBtmError,    0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	 
	$self->SetSizer($szMain);

	# SAVE REFERENCES
	$self->{"statBtmError"}  = $statBtmError;
	$self->{"szMain"} = $szMain;
}

1;
