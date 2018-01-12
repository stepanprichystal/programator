package Popup;

use strict;
use Wx;
use base qw(Wx::PopupWindow);
use warnings;

use Wx qw(wxSOLID);
use Wx::Event qw(EVT_PAINT);

sub new {
    my( $class, @args ) = @_;
    my $self = $class->SUPER::new( @args );

    EVT_PAINT( $self, \&on_paint );

    return $self;
}

sub on_paint {
    my( $self, $event ) = @_;
    my $dc = Wx::PaintDC->new( $self );

    $dc->SetBrush( Wx::Brush->new( Wx::Colour->new( 0, 192, 0 ), wxSOLID ) );
    $dc->SetPen( Wx::Pen->new( Wx::Colour->new( 0, 0, 0 ), 1, wxSOLID ) );
    $dc->DrawRectangle( 0, 0, $self->GetSize->x, $self->GetSize->y );
}

1;