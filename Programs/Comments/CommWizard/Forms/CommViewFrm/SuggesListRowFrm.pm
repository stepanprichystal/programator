
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Comments::CommWizard::Forms::CommViewFrm::SuggesListRowFrm;
use base qw(Widgets::Forms::CustomQueue::MyWxCustomQueueItem);

#3th party library
use utf8;
use Wx;

use strict;
use warnings;

#local library
use aliased 'Packages::Events::Event';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Comments::Enums';
use Widgets::Style;

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $order  = shift;

	my $self = $class->SUPER::new( $parent, $order, undef );

	bless($self);

	# PROPERTIES

	$self->__SetLayout();

	# EVENTS
	$self->{'onRemoveSuggesEvt'} = Event->new();
	$self->{'onChangeSuggesEvt'} = Event->new();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	# DEFINE SIZERS

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my @letters = ( "a", "b", "c", "d", "e", "f", "g", "h", "ch", "i", "j" );

	my $suggNumTxt = Wx::StaticText->new( $self, -1, $letters[ $self->GetItemId() ] . ")", &Wx::wxDefaultPosition, [ 20, -1 ] );
	my $suggTextTxt = Wx::TextCtrl->new( $self, -1, "", &Wx::wxDefaultPosition, [ -1, 25 ] );
	my $btnRemoveSugg = Wx::Button->new( $self, -1, "- Remove", &Wx::wxDefaultPosition, [ 80, 25 ] );

	# DEFINE LAYOUT

	$szMain->Add( $suggNumTxt,    0,  &Wx::wxALL, 1 );
	$szMain->Add( $suggTextTxt,   1, &Wx::wxALL, 1 );
	$szMain->Add( $btnRemoveSugg, 0, &Wx::wxALL, 1 );

	$self->SetSizer($szMain);

	# SET EVENTS
	Wx::Event::EVT_BUTTON( $btnRemoveSugg, -1, sub { $self->{"onRemoveSuggesEvt"}->Do( $self->GetItemId() ) } );

	Wx::Event::EVT_TEXT( $suggTextTxt, -1, sub { $self->{"onChangeSuggesEvt"}->Do( $self->GetItemId(), $suggTextTxt->GetValue() ) } );

	# SET REFERENCES

	$self->{"suggTextTxt"} = $suggTextTxt;

}

# ==============================================
# ITEM QUEUE HANDLERS
# ==============================================

# ==============================================
# PUBLIC FUNCTION
# ==============================================
sub SetSuggestionLayout {
	my $self       = shift;
	my $suggLayout = shift;

	$self->{"suggTextTxt"}->SetValue($suggLayout);
}

# ==============================================
# HELPER FUNCTION
# ==============================================

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
