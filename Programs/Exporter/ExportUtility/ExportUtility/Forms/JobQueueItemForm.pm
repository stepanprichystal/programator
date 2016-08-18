
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::ExportUtility::Forms::JobQueueItemForm;
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
	my $class  = shift;
	my $parent = shift;
	my $text   = shift;

	my $self = $class->SUPER::new( $parent, -1 );

	bless($self);

	$self->{"text"} = $text;

	#$self->{"state"} = Enums->GroupState_ACTIVEON;

	$self->__SetLayout();

	#EVENTS

	#$self->{"onChangeState"} = Event->new();

	return $self;
}

#sub Init {
#	my $self      = shift;
#	my $groupName = shift;
#	my $groupBody = shift;
#
#	$self->{"headerTxt"}->SetLabel($groupName);
#
#	$self->{"bodySizer"}->Add( $groupBody, 1, &Wx::wxEXPAND | &Wx::wxALL, 2 );
#
#	$self->{"groupHeight"} = $groupBody->{"groupHeight"};
#
#	# panel, which contain group content
#	$self->{"groupBody"} = $groupBody;
#
#	#$self->{"groupBody"}->Disable();
#	$self->Refresh();
#
#	#$self->{"bodySizer"}->Layout();
#
#	#my ($w, $h) = $self->{"bodySizer"}->GetSizeWH();
#
#	#$self->{"bodySizer"}->Fit($self->{"groupBody"});
#	#$self->{"szHeaderBody"}->Fit($self);
#	#	$self->Layout();
#
#	#my ( $w, $h ) = $groupBody->GetSizeWH();
#
#	print 1;
#
#}

#sub GetGroupHeight {
#
#	my $self = shift;
#	return $self->{"groupHeight"};
#
#}

sub __SetLayout {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	$self->SetBackgroundColour( Wx::Colour->new( 50, 245, 20 ) );

	my $txt  = Wx::StaticText->new( $self, -1, "Job " . $self->{"text"},  [ -1, -1 ], [ 200, 30 ] );
	my $txt2 = Wx::StaticText->new( $self, -1, "Job2 " . $self->{"text"}, [ -1, -1 ], [ 200, 30 ] );
	my $btnDefault = Wx::Button->new( $self, -1, "Default settings", &Wx::wxDefaultPosition, [ 110, 22 ] );

	Wx::Event::EVT_BUTTON( $btnDefault, -1, sub { $self->__OnClick() } );

	$szMain->Add( $txt,        0 );
	$szMain->Add( $txt2,       0 );
	$szMain->Add( $btnDefault, 0 );
	$self->SetSizer($szMain);

	$self->RecursiveHandler($self);

}

sub __OnClick {
	my $self = shift;

	print "button pressed";
}

sub RecursiveHandler {
	my $self    = shift;
	my $control = shift;

	my @controls = ("Wx::Panel", "Wx::StaticSizer", "Wx::StaticText");

	if ( scalar(grep{  $control->isa($_) } @controls)) {

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

sub __MouseDown {
	my ( $self, $pnlSwitch, $c, $d ) = @_;

	#print $c->{"visited"};
	#print $d->{"visited"};

	#$d->{"visited"} = 1;

	#	$c->SafelyProcessEvent($d);

	if ( $d->ButtonDown() ) {

		print $pnlSwitch. " pressed\n";
	}
	else {

		#$c->ProcessEvent($d);

	}

}

sub GetItemHeight {
	my $self = shift;

	my ( $width, $height ) = $self->GetSizeWH();

	print "Height of item is : " . $height . "\n";

	return $height;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
