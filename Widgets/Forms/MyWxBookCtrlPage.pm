package Widgets::Forms::MyWxBookCtrlPage;

use strict;
use base qw(Wx::Panel);
use Wx;
use Widgets::Style;



sub new {
    my( $class, $parent, $index ) = @_;
    my $self = $class->SUPER::new( $parent, -1, &Wx::wxDefaultPosition, [300, 300] );
	
	
	$self->{"id"} = $index;
	
	bless($self);
	
	#$self->SetBackgroundColour($Widgets::Style::clrLightRed);
  
    return $self;
}

sub GetPageId{
	my $self = shift;
	
	return $self->{"id"};
	
}

1;