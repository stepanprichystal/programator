
#-------------------------------------------------------------------------------------------#
# Description: Base item class, wchich is managed by container MyWxCustomQueue
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Widgets::Forms::CustomQueue::MyWxCustomQueueItem;
use base qw(Wx::Panel);

#3th party library
use Wx;

use strict;
use warnings;

#local library
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $itemId = shift;

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ -1, -1 ], &Wx::wxBORDER_SIMPLE );

	bless($self);

	$self->{"selected"} = 0;
	$self->{"itemId"}   = $itemId;
	$self->{"position"} = -1;

	$self->__SetLayout();

	#EVENTS

	$self->{"onItemClick"} = Event->new();

	return $self;
}

#-------------------------------------------------------------------------------------------#
#  Public methods
#-------------------------------------------------------------------------------------------#

sub GetItemId {
	my $self = shift;

	return $self->{"itemId"};
}

sub GetPosition {
	my $self = shift;
	return $self->{"position"};
}


# This method register handler LEFT_DOWN on every ("Wx::Panel", "Wx::StaticSizer", "Wx::StaticText")
# child controls of this control
# Thus, every child control will react on left button click 
sub RecursiveHandler {
	my $self    = shift;
	my $control = shift;

	my @controls = ( "Wx::Panel", "Wx::StaticSizer", "Wx::StaticText" );

	if ( scalar( grep { $control->isa($_) } @controls ) ) {

		Wx::Event::EVT_LEFT_DOWN( $control, sub { $self->__MouseDown( $control, @_ ) } );

		print $control. "handler added \n";
	}

	my @childrens = $control->GetChildren();

	if (@childrens) {

		foreach my $childControl (@childrens) {

			$self->RecursiveHandler($childControl);
		}

	}

}

sub GetItemHeight {
	my $self = shift;

	my ( $width, $height ) = $self->GetSizeWH();

	print "Height of item is : " . $height . "\n";

	return $height;

}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
 

	#Wx::Event::EVT_BUTTON( $btnDefault, -1, sub { $self->__OnClick() } );

	$szMain->Add( 1, 20, 1, &Wx::wxGROW );

	#$szMain->Add( $txt2,       0 );
	#$szMain->Add( $btnDefault, 0 );
	$self->SetSizer($szMain);

	$self->RecursiveHandler($self);

}

 

sub __MouseDown {
	my ( $self, $item, $c, $d ) = @_;
 
	if ( $d->ButtonDown() ) {

 
		$self->{"onItemClick"}->Do($self);

	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
