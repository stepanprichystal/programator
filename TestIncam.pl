use Wx;
use Wx qw(:icon wxTheApp wxNullBitmap);

package Widgets::Forms::MyTaskBarIcon;
use base 'Wx::TaskBarIcon';

use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Events::Event';

sub new {
	my ( $class, $title ) = @_;
	my $self = $class->SUPER::new();
	bless($self);

	my $btmIco = Wx::Bitmap->new( GeneralHelper->Root() . "/Resources/Images/Icon.bmp", &Wx::wxBITMAP_TYPE_BMP );
	my $icon = Wx::Icon->new();
	$icon->CopyFromBitmap($btmIco);

	#$self->SetIcon($icon);

	Wx::Event::EVT_TASKBAR_LEFT_UP( $self, sub { $self->__OnLeftClick(@_) } );

	$self->SetIcon( $icon, $title );

	$self->{"formShowed"} = 1;

	# EVENTS
	$self->{"onLeftClick"} = Event->new();

	return $self;

}

sub __OnLeftClick {
	my $self = shift;

	print "left click\n";

}

#sub CreatePopupMenu {
#    my ($this) = @_;
#
#   # say "xx"; # This never gets called
#
#
#
#    return $menu;
#}

1;

# Creating MyTaskBarIcon

my $form;

my $trayicon = MyTaskBarIcon->new( "Exporter", $form );

$trayicon->IsOk() || die;

my $menu = Wx::Menu->new();
$menu->Append( -1, "menu 1" );
$menu->Append( -1, "menu 2" );

$trayicon->PopupMenu($menu);

#

# $trayicon->IsOk() || die;

