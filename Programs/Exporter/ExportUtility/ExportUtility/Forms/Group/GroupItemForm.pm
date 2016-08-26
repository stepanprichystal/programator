#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportUtility::ExportUtility::Forms::Group::GroupItemForm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;
 

#local library
use Widgets::Style;
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::Forms::ErrorIndicator';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;

 
	my $title  = shift;
 	
 	my $self = $class->SUPER::new($parent);

	bless($self);
 
	$self->__SetLayout( $title );

	return $self;
}

sub __SetLayout {
	my $self   = shift;
	my $title  = shift;
	

	#define panels
	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	

	# DEFINE CONTROLS
	
	my $titleTxt = Wx::StaticText->new( $self, -1, $title, &Wx::wxDefaultPosition, [ 70, 20 ] );

	# SET EVENTS
	#Wx::Event::EVT_COMBOBOX( $colorCb, -1, sub { $self->__OnColorChangeHandler(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	
	$szMain->Add( $titleTxt,    1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	
	$self->SetSizer($szMain);

	# SAVE REFERENCES

}


1;
