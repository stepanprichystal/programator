#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportUtility::ExportUtility::Forms::Group::ItemForm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;
 

#local library
use Widgets::Style;
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::Forms::ErrorIndicator';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
  	my $self = $class->SUPER::new($parent);

	bless($self);
 
	my $title  = shift;
	$self->{"subItem"}= shift;
	
	$self->__SetLayout( $title );

	return $self;
}

sub __SetLayout {
	my $self   = shift;
	my $title  = shift;
	

	#define panels
	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $bulletText = "-";
	unless($self->{"subItem"}){
		$bulletText = "";
	}

	# DEFINE CONTROLS
	my $bulletTxt = Wx::StaticText->new( $self, -1, $bulletText, &Wx::wxDefaultPosition );
	my $titleTxt = Wx::StaticText->new( $self, -1, $title, &Wx::wxDefaultPosition, [ 70, 20 ] );
	
	my $errIndicator  = ErrorIndicator->new( $self, EnumsGeneral->MessageType_ERROR, 15 );
	my $warnIndicator = ErrorIndicator->new( $self, EnumsGeneral->MessageType_WARNING, 15 );
 
	# SET EVENTS
	#Wx::Event::EVT_COMBOBOX( $colorCb, -1, sub { $self->__OnColorChangeHandler(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$szMain->Add( $bulletTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $titleTxt,    1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $errIndicator,   0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $warnIndicator,   0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$self->SetSizer($szMain);

	# SAVE REFERENCES
	$self->{"errIndicator"} = $errIndicator;
	$self->{"warnIndicator"}  = $warnIndicator;

}

sub SetErrors {
	my $self = shift;
	my $count = shift;
	 
	$self->{"errIndicator"}->SetErrorCnt($count);
}

sub SetWarnings {
	my $self = shift;
	my $count = shift;
	 
	$self->{"warnIndicator"}->SetErrorCnt($count);
}

1;
