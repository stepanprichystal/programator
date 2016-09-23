package Widgets::Forms::MyWxScrollPanel;

use strict;
use base qw(Wx::PlVScrolledWindow);
use Wx qw(wxWHITE wxHORIZONTAL wxVERTICAL);

use Wx;
use Wx qw(:icon wxTheApp wxNullBitmap);
use Widgets::Style;

use aliased 'Helpers::GeneralHelper';

sub new {
	my ( $class, $parent, $rowHeight ) = @_;
	my $self = $class->SUPER::new( $parent, -1 );
	$self->{"rowHeight"} = $rowHeight;


	return $self;
}


sub OnGetRowHeight {
	my ( $self, $item ) = @_;
 
	return $self->{"rowHeight"};

}

1;
