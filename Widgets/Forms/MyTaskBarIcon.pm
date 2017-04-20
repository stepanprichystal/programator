#-------------------------------------------------------------------------------------------#
# Description: Custom task bar icon
# On left click, close form
# On right click, do action, which is set when menu item is added.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Widgets::Forms::MyTaskBarIcon;

#3th party library
use Wx;

#use Wx::TaskBarIcon;
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my ( $class, $title, $form, $iconPath ) = @_;

	my $self = {};
	bless($self);

	$self->{"taskBarIcon"} = Wx::TaskBarIcon->new();

	my $btmIco = Wx::Bitmap->new( $iconPath , &Wx::wxBITMAP_TYPE_BMP );
	my $icon = Wx::Icon->new();
	$icon->CopyFromBitmap($btmIco);

	#$self->SetIcon($icon);

	$self->{"taskBarIcon"}->SetIcon( $icon, $title );
	$self->{"menu"} = Wx::Menu->new();
	$self->{"form"} = $form;

	my %itemsActions = ();
	$self->{"menuItemActions"} = \%itemsActions;

	#$self->{"formShowed"} = 1;

	# EVENTS

	Wx::Event::EVT_TASKBAR_LEFT_UP( $self->{"taskBarIcon"}, sub { $self->__OnLeftClick(@_) } );
	Wx::Event::EVT_TASKBAR_RIGHT_DOWN( $self->{"taskBarIcon"}, sub { $self->__OnRightClick(@_) } );

	#$self->{"onLeftClick"} = Event->new();

	return $self;
}

sub DESTROY{
	my $self = shift;
	
	$self->{"taskBarIcon"}->RemoveIcon();
	
}

sub AddMenuItem {
	my $self   = shift;
	my $title  = shift;
	my $action = shift;

	my $menuItem = $self->{"menu"}->Append( -1, $title );

	Wx::Event::EVT_MENU( $self->{"menu"}, $menuItem, sub { $action->( $self->{"form"} ) } );

	$self->{"menuItemActions"}->{$menuItem} = $action;

}

sub __OnLeftClick {
	my $self = shift;

	print "LEFT click\n";

	#$self->{"formShowed"} = !$self->{"formShowed"};

	#print "isShown".$self->{"form"}->IsShown()."\n" ;
	#print "IsShownOnScreen".$self->{"form"}->IsShownOnScreen()."\n" ;
	my $showed = $self->{"form"}->IsShown();

	if ( !$showed ) {
		$self->{"form"}->Show();
		$self->{"form"}->Iconize(0);

	}
	else {

		#$self->{"form"}->Iconize(1);
		$self->{"form"}->Hide();

	}

}

sub __OnRightClick {
	my $self = shift;

	#my $menuItem = shift;

	$self->{"taskBarIcon"}->PopupMenu( $self->{"menu"} );

	print "Right click\n";

}

sub __OnMenuItemClick {
	my $self     = shift;
	my $menuItem = shift;
	my $b        = shift;
	my $c        = shift;

	#$self->{"taskBarIcon"}->PopupMenu( $self->{"menu"} );

	my $action = $self->{"menuItemActions"}->{$menuItem};

	print "Menu iterm click\n";

	if ($action) {
		$action->( $self->{"menu"} );
	}

}
 

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

#	use aliased 'Widgets::Forms::MyTaskBarIcon';
#
#	my $form;
#
#	my $trayicon = MyTaskBarIcon->new( "Exporter", $form );
#
#	$trayicon->IsOk() || die;
#
#	my $menu = Wx::Menu->new();
#	$menu->Append( -1, "menu 1" );
#	$menu->Append( -1, "menu 2" );
#
#	$trayicon->PopupMenu($menu);

}

1;

