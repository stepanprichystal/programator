
#-------------------------------------------------------------------------------------------#
# Description: Custom queue list. Keep items of type MyWxCustomQueueItem
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Widgets::Forms::MyWxStaticBoxSizer;
use base qw(Wx::Panel);

#3th party library
use Wx;
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class        = shift;
	my $parent       = shift;
	my $orientation  = shift;                                   # &Wx::wxHORIZONTAL | &Wx::wxVERTICAL
	my $title        = shift;
	my $titleBodyGap = shift // 0;
	my $titleFont    = shift;
	my $titleClr     = shift // Wx::Colour->new( 0, 0, 0 );
	my $titleBackg   = shift // Wx::Colour->new( 255, 0, 0 );
	my $boxBackg     = shift // Wx::Colour->new( 0, 255, 0 );
	my $titlePadding = shift // 2;

	my $self = $class->SUPER::new($parent);

	bless($self);

	# PROPERTIES

	$self->__SetLayout( $orientation, $title, $titleBodyGap, $titleFont, $titleClr, $titleBackg, $boxBackg, $titlePadding );

	#EVENTS

	return $self;
}

#-------------------------------------------------------------------------------------------#
#  Public methods
#-------------------------------------------------------------------------------------------#

#-------------------------------------------------------------------------------------------#
#  Methods for set queue
#-------------------------------------------------------------------------------------------#

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self         = shift;
	my $orientation  = shift;    # &Wx::wxHORIZONTAL | &Wx::wxVERTICAL
	my $title        = shift;
	my $titleBodyGap = shift;
	my $titleFont    = shift;
	my $titleClr     = shift;
	my $titleBackg   = shift;
	my $boxBackg     = shift;
	my $titlePadding = shift;

	#$self->SetBackgroundColour( Wx::Colour->new( 230, 230, 230 ) );

	# DEFINE SIZERS

	my $szMain  = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szBody  = Wx::BoxSizer->new($orientation);
	my $szTitle = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE PANELS

	my $titlePnl = Wx::Panel->new($self);

	# Define controls
	my $titleTxt = Wx::StaticText->new( $titlePnl, -1, $title, &Wx::wxDefaultPosition );
	$titleTxt->SetForegroundColour($titleClr);

	if ( defined $titleFont ) {
		$titleTxt->SetFont($titleFont);
	}

	$titlePnl->SetBackgroundColour($titleBackg);
	$self->SetBackgroundColour($boxBackg);

	# BUILD LAYOUT STRUCTURE
	$self->SetSizer($szMain);
	$titlePnl->SetSizer($szTitle);

	$szTitle->Add( $titleTxt, 1, &Wx::wxEXPAND | &Wx::wxALL , $titlePadding );

	$szMain->Add( $titlePnl, 0, &Wx::wxEXPAND );
	$szMain->Add( $titleBodyGap, $titleBodyGap, 0, &Wx::wxEXPAND );
	$szMain->Add( $szBody, 1, &Wx::wxEXPAND );

	# SET REFERENCE
	$self->{"szBody"} = $szBody;
}

sub Add {
	my $self = shift;

	$self->{"szBody"}->Add(@_);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
