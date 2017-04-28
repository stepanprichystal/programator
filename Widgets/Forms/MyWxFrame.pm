package Widgets::Forms::MyWxFrame;
use base qw(Wx::Frame);

use strict;

use Wx;
use Wx qw(:icon wxTheApp wxNullBitmap);
use Widgets::Style;

use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Events::Event';

sub new {
	my $class  = shift;
	my $parent = shift;

	if ( defined $parent && $parent == -1 ) {
		$parent = undef;
	}

	my $self = $class->SUPER::new( $parent, @_ );

	$self->SetBackgroundColour($Widgets::Style::clrWhite);

	my $btmIco = Wx::Bitmap->new( GeneralHelper->Root() . "/Resources/Images/Icon.bmp", &Wx::wxBITMAP_TYPE_BMP );
	my $icon = Wx::Icon->new();
	$icon->CopyFromBitmap($btmIco);
	$self->SetIcon($icon);

	#event, when some action happen
	$self->{'onClose'} = Event->new();

	#Define EVENTS
	Wx::Event::EVT_CLOSE( $self, sub { $self->OnClose() } );

	return $self;
}

# Set nwe BMP icon
sub SetCustomIcon{
	my $self = shift;
	my $iconPath = shift;
	
	unless(-e $iconPath){
		die "icon path $iconPath doesnt exist";
	}
 
	my $btmIco = Wx::Bitmap->new( $iconPath, &Wx::wxBITMAP_TYPE_BMP );
	my $icon = Wx::Icon->new();
	$icon->CopyFromBitmap($btmIco);
	$self->SetIcon($icon);
}


sub OnClose {
	my $self = shift;

	 

	my $onClose = $self->{'onClose'};
	if ($onClose->Handlers() ) {

		$onClose->Do($self);
	}
	else {
		
		$self->Destroy();
	}

}

1;
