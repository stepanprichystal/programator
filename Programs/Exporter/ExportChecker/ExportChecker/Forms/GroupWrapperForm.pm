#-------------------------------------------------------------------------------------------#
# Description: Wrapper wifget for group form
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::ExportChecker::Forms::GroupWrapperForm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;
use Widgets::Style;

#local library

use aliased 'Programs::Exporter::ExportChecker::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my ( $class, $parent ) = @_;

	my $self = $class->SUPER::new($parent);

	bless($self);

	$self->{"state"} = Enums->GroupState_ACTIVEON;

	$self->__SetLayout();

	return $self;
}

sub Init {
	my $self      = shift;
	my $groupName = shift;
	my $groupBody = shift;

	$self->{"headerTxt"}->SetLabel($groupName);

	$self->{"bodySizer"}->Add( $groupBody, 1, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$self->{"groupHeight"} = $groupBody->{"groupHeight"};

	# panel, which contain group content
	$self->{"groupBody"} = $groupBody;

	#$self->{"groupBody"}->Disable();
	$self->Refresh();

	#$self->{"bodySizer"}->Layout();

	#my ($w, $h) = $self->{"bodySizer"}->GetSizeWH();

	#$self->{"bodySizer"}->Fit($self->{"groupBody"});
	#$self->{"szHeaderBody"}->Fit($self);
	#	$self->Layout();

	#my ( $w, $h ) = $groupBody->GetSizeWH();

	print 1;

}

sub GetGroupHeight {

	my $self = shift;
	return $self->{"groupHeight"};

}

sub __SetLayout {
	my $self = shift;

	#define panels
	my $szHeaderBody = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $pnlHeader = Wx::Panel->new( $self, -1 );

	#$pnlHeader->SetBackgroundColour($Widgets::Style::clrLightGreen);
	$pnlHeader->SetBackgroundColour( Wx::Colour->new( 228, 232, 243 ) );

	# use Wx qw( EVT_MOUSE_EVENTS);
	# use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

	my $szHeader = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $headerTxt = Wx::StaticText->new( $pnlHeader, -1, "Default title" );

	my $pnlSwitch = Wx::Panel->new( $pnlHeader, -1, &Wx::wxDefaultPosition, [ 40, 10 ] );

	$pnlSwitch->SetBackgroundColour( Wx::Colour->new( 237, 28, 36 ) );    # dark red

	Wx::Event::EVT_MOUSE_EVENTS( $pnlSwitch, sub { $self->__Switch( $pnlSwitch, @_ ) } );
	Wx::Event::EVT_MOUSE_EVENTS( $headerTxt, sub { $self->__Switch( $pnlSwitch, @_ ) } );
	Wx::Event::EVT_MOUSE_EVENTS( $pnlHeader, sub { $self->__Switch( $pnlSwitch, @_ ) } );

	$self->{"headerTxt"} = $headerTxt;

	my $pnlBody = Wx::Panel->new( $self, -1 );

	$pnlBody->SetBackgroundColour( Wx::Colour->new( 245, 245, 245 ) );

	print "\n\n -------------- CAN BE TRANSPARENT :" . $pnlBody->SetTransparent(100) . "\n\n";

	my $szBody = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	$self->{"bodySizer"}    = $szBody;
	$self->{"szHeaderBody"} = $szHeaderBody;

	$szHeader->Add( $pnlSwitch, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szHeader->Add( $headerTxt, 1, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$pnlHeader->SetSizer($szHeader);

	$pnlBody->SetSizer($szBody);

	$szHeaderBody->Add( $pnlHeader, 0, &Wx::wxEXPAND );
	$szHeaderBody->Add( $pnlBody,   1, &Wx::wxEXPAND );

	$self->SetSizer($szHeaderBody);

	$self->{"pnlHeader"} = $pnlHeader;
	$self->{"pnlBody"}   = $pnlBody;
	$self->{"pnlSwitch"} = $pnlSwitch;

	#$self->{"pnlBody"}->Refresh();

	#$scrollPnl->SetMaxClientSize([ 300, 150]);

	#$self->SetMinSize([ 300, 300]);

	#$scrollPnl->SetSize(300, 200);

	#$szHeaderBody->Layout();

	#$self->SetMinSize($self->GetSize())

}

sub SetState {
	my $self  = shift;
	my $state = shift;

	$self->{"state"} = $state;

}

sub Refresh {
	my $self = shift;

	if ( $self->{"state"} eq Enums->GroupState_ACTIVEON ) {
		$self->{"pnlSwitch"}->SetBackgroundColour( Wx::Colour->new( 34, 177, 76 ) );    # green
		$self->{"groupBody"}->Enable();

	}
	elsif ( $self->{"state"} eq Enums->GroupState_ACTIVEOFF ) {
		$self->{"pnlSwitch"}->SetBackgroundColour( Wx::Colour->new( 237, 28, 36 ) );    # dark red
		$self->{"groupBody"}->Disable();

	}
	elsif ( $self->{"state"} eq Enums->GroupState_DISABLE ) {
		$self->{"pnlSwitch"}->SetBackgroundColour( Wx::Colour->new( 204, 204, 204 ) );    # grey
		$self->{"groupBody"}->Disable();

	}

	$self->{"groupBody"}->Refresh();
	$self->{"pnlSwitch"}->Refresh();
}

sub __Switch {
	my ( $self, $pnlSwitch, $c, $d ) = @_;

	if (  $d->ButtonDown()  && $self->{"state"} ne Enums->GroupState_DISABLE ) {
 
 
		if ( $self->{"state"} eq Enums->GroupState_ACTIVEON ) {

			$self->{"state"} = Enums->GroupState_ACTIVEOFF;
		}
		else {
			$self->{"state"} = Enums->GroupState_ACTIVEON;
		}
		
		$self->Refresh();

	}


}

sub GetParentForGroup {
	my $self = shift;

	return $self->{"pnlBody"};
}

1;
