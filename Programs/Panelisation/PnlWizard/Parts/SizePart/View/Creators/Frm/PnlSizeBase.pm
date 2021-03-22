
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::SizePart::View::Creators::Frm::PnlSizeBase;
use base qw(Programs::Panelisation::PnlWizard::Forms::CreatorFrmBase);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class      = shift;
	my $creatorKey = shift;
	my $parent     = shift;
	my $jobId      = shift;

	my $self = $class->SUPER::new( $creatorKey, $parent, $jobId );
	bless($self);

	$self->__Layout();

	#

	# DEFINE EVENTS

	return $self;
}

sub GetCreatorKey {
	my $self = shift;

	return $self->{"creatorKey"};
}

sub __Layout {
	my $self = shift;

	#define panels

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS

	my $sizeStatBox  = $self->__SetLayoutSize($self);
	my $frameStatBox = $self->__SetLayoutFrame($self);

	#$richTxt->Layout();

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	#$szMain->Add( $szStatBox, 0, &Wx::wxEXPAND );

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $sizeStatBox,  0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szMain->Add( $frameStatBox, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$self->SetSizer($szMain);

	# save control references

}

# Set layout for Quick set box
sub __SetLayoutSize {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Dimension' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	# Load data, for filling form by values

	#my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $widthTxt = Wx::StaticText->new( $statBox, -1, "Width:", &Wx::wxDefaultPosition, [ 70, 25 ] );
	my $widthValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 70, 25 ] );

	my $heightTxt = Wx::StaticText->new( $statBox, -1, "Height:", &Wx::wxDefaultPosition, [ 70, 25 ] );
	my $heightValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 70, 25 ] );

	# DEFINE EVENTS
	Wx::Event::EVT_TEXT( $widthValTxt,  -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_TEXT( $heightValTxt, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	# BUILD STRUCTURE OF LAYOUT
	$szStatBox->Add( $widthTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $widthValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szStatBox->Add( 10, 10, 0 );

	$szStatBox->Add( $heightTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $heightValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# save control references
	$self->{"widthValTxt"}  = $widthValTxt;
	$self->{"heightValTxt"} = $heightValTxt;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutFrame {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Border' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# Load data, for filling form by values

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $leftTxt = Wx::StaticText->new( $statBox, -1, "Left:", &Wx::wxDefaultPosition, [ 70, 25 ] );
	my $leftValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 70, 25 ] );

	my $rightTxt = Wx::StaticText->new( $statBox, -1, "Right:", &Wx::wxDefaultPosition, [ 70, 25 ] );
	my $rightValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 70, 25 ] );

	my $topTxt = Wx::StaticText->new( $statBox, -1, "Top:", &Wx::wxDefaultPosition, [ 70, 25 ] );
	my $topValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 70, 25 ] );

	my $botTxt = Wx::StaticText->new( $statBox, -1, "Bot:", &Wx::wxDefaultPosition, [ 70, 25 ] );
	my $botValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 70, 25 ] );

	# DEFINE EVENTS
	Wx::Event::EVT_TEXT( $leftValTxt,  -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_TEXT( $rightValTxt, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_TEXT( $topValTxt,   -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_TEXT( $botValTxt,   -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $leftTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $leftValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow1->Add( 10, 10, 0 );

	$szRow1->Add( $topTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $topValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow2->Add( $rightTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $rightValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow2->Add( 10, 10, 0 );

	$szRow2->Add( $botTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $botValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# save control references
	$self->{"leftValTxt"}  = $leftValTxt;
	$self->{"rightValTxt"} = $rightValTxt;
	$self->{"topValTxt"}   = $topValTxt;
	$self->{"botValTxt"}   = $botValTxt;

	return $szStatBox;
}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

sub SetWidth {
	my $self = shift;
	my $val  = shift;

	$val = sprintf( "%.1f", $val ) if ( defined $val && $val ne "" );

	$self->{"widthValTxt"}->SetValue($val);
}

sub GetWidth {
	my $self = shift;

	return $self->{"widthValTxt"}->GetValue();
}

sub SetHeight {
	my $self = shift;
	my $val  = shift;

	$val = sprintf( "%.1f", $val ) if ( defined $val && $val ne "" );

	$self->{"heightValTxt"}->SetValue($val);
}

sub GetHeight {
	my $self = shift;

	return $self->{"heightValTxt"}->GetValue();
}

sub SetBorderLeft {
	my $self = shift;
	my $val  = shift;

	$val = sprintf( "%.1f", $val ) if ( defined $val && $val ne "" );

	$self->{"leftValTxt"}->SetValue($val);
}

sub GetBorderLeft {
	my $self = shift;

	return $self->{"leftValTxt"}->GetValue();
}

sub SetBorderRight {
	my $self = shift;
	my $val  = shift;

	$val = sprintf( "%.1f", $val ) if ( defined $val && $val ne "" );

	$self->{"rightValTxt"}->SetValue($val);
}

sub GetBorderRight {
	my $self = shift;

	return $self->{"rightValTxt"}->GetValue();
}

sub SetBorderTop {
	my $self = shift;
	my $val  = shift;

	$val = sprintf( "%.1f", $val ) if ( defined $val && $val ne "" );

	$self->{"topValTxt"}->SetValue($val);
}

sub GetBorderTop {
	my $self = shift;

	return $self->{"topValTxt"}->GetValue();
}

sub SetBorderBot {
	my $self = shift;
	my $val  = shift;

	$val = sprintf( "%.1f", $val ) if ( defined $val && $val ne "" );

	$self->{"botValTxt"}->SetValue($val);
}

sub GetBorderBot {
	my $self = shift;

	return $self->{"botValTxt"}->GetValue();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

