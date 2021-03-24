
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
	$self->{"CBMainChangedEvt"}   = Event->new();
	$self->{"CBSizeChangedEvt"}   = Event->new();
	$self->{"CBBorderChangedEvt"} = Event->new();

	return $self;
}

sub GetCreatorKey {
	my $self = shift;

	return $self->{"creatorKey"};
}

sub __Layout {
	my $self = shift;

	#define panels

	my $szMain   = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szCustom = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $sizeStatBox  = $self->__SetLayoutSize($self);
	my $frameStatBox = $self->__SetLayoutFrame($self);

	#$richTxt->Layout();

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	#$szMain->Add( $szStatBox, 0, &Wx::wxEXPAND );

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $szCustom,     0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szMain->Add( $sizeStatBox,  0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szMain->Add( $frameStatBox, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$self->SetSizer($szMain);

	# save control references
	$self->{"szCustomCBMain"} = $szCustom;

}

# Set layout for Quick set box
sub __SetLayoutSize {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Dimension' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# Load data, for filling form by values

	my $szRow0 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);    # row for custom control, which are added by inherit class
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $widthTxt = Wx::StaticText->new( $statBox, -1, "Width:", &Wx::wxDefaultPosition, [ 70, 25 ] );
	my $widthValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 70, 25 ] );

	my $heightTxt = Wx::StaticText->new( $statBox, -1, "Height:", &Wx::wxDefaultPosition, [ 70, 25 ] );
	my $heightValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 70, 25 ] );

	# DEFINE EVENTS
	Wx::Event::EVT_TEXT( $widthValTxt,  -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_TEXT( $heightValTxt, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $widthTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $widthValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow1->Add( 10, 10, 0 );

	$szRow1->Add( $heightTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $heightValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szStatBox->Add( $szRow0, 0, &Wx::wxEXPAND );
	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND );

	# save control references
	$self->{"widthValTxt"}        = $widthValTxt;
	$self->{"heightValTxt"}       = $heightValTxt;
	$self->{"customCBSizeSz"}     = $szRow0;
	$self->{"customCBSizeParent"} = $statBox;

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

	my $szRow0 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);    # row for custom control, which are added by inherit class
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

	$szStatBox->Add( $szRow0, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# save control references
	$self->{"leftValTxt"}          = $leftValTxt;
	$self->{"rightValTxt"}         = $rightValTxt;
	$self->{"topValTxt"}           = $topValTxt;
	$self->{"botValTxt"}           = $botValTxt;
	$self->{"customCBBorderSz"}     = $szRow0;
	$self->{"customCBBorderParent"} = $statBox;

	return $szStatBox;
}

sub _SetLayoutCBMain {
	my $self    = shift;
	my $title   = shift;
	my $choices = shift;

	# DEFINE CONTROLS
	my $mainCbTxt = Wx::StaticText->new( $self, -1, $title, &Wx::wxDefaultPosition, [ -1, 25 ] );
	my $mainCB = Wx::ComboBox->new( $self, -1, $choices->[0], &Wx::wxDefaultPosition, [ -1, 25 ], $choices, &Wx::wxCB_READONLY );

	# DEFINE EVENTS
	Wx::Event::EVT_TEXT( $mainCB, -1, sub { $self->{"CBMainChangedEvt"}->Do($mainCB->GetValue()) } );

	# DEFINE LAYOUT
	$self->{"szCustomCBMain"}->Add( $mainCbTxt, 30, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$self->{"szCustomCBMain"}->Add( $mainCB,    30, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	return $mainCB;
}

sub _SetLayoutCBSize {
	my $self    = shift;
	my $title   = shift;
	my $choices = shift;

	# DEFINE CONTROLS
	my $mainCbTxt = Wx::StaticText->new( $self->{"customCBSizeParent"}, -1, $title, &Wx::wxDefaultPosition, [ -1, 25 ] );
	my $mainCB =  Wx::ComboBox->new( $self->{"customCBSizeParent"}, -1, $choices->[0], &Wx::wxDefaultPosition, [ -1, 25 ], $choices, &Wx::wxCB_READONLY );

	# DEFINE EVENTS
	Wx::Event::EVT_TEXT( $mainCB, -1, sub { $self->{"CBSizeChangedEvt"}->Do($mainCB->GetValue()) } );

	# DEFINE LAYOUT
	$self->{"customCBSizeSz"}->Add( $mainCbTxt, 30, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$self->{"customCBSizeSz"}->Add( $mainCB,    30, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	return $mainCB;
}

sub _SetLayoutCBBorder {
	my $self    = shift;
	my $title   = shift;
	my $choices = shift;

	# DEFINE CONTROLS
	my $mainCbTxt = Wx::StaticText->new( $self->{"customCBBorderParent"}, -1, $title, &Wx::wxDefaultPosition, [ -1, 25 ] );
	my $mainCB =  Wx::ComboBox->new( $self->{"customCBBorderParent"}, -1, $choices->[0], &Wx::wxDefaultPosition, [ -1, 25 ], $choices, &Wx::wxCB_READONLY );

	# DEFINE EVENTS
	Wx::Event::EVT_TEXT( $mainCB, -1, sub { $self->{"CBBorderChangedEvt"}->Do($mainCB->GetValue()) } );

	# DEFINE LAYOUT
	$self->{"customCBBorderSz"}->Add( $mainCbTxt, 30, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$self->{"customCBBorderSz"}->Add( $mainCB,    30, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	return $mainCB;
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

