
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
use aliased 'Enums::EnumsGeneral';
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Widgets::Forms::ResultIndicator::ResultIndicator';
use aliased 'Helpers::GeneralHelper';

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

	my $szMain        = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szMainWrapper = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szCustom      = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $sizeStatBox  = $self->__SetLayoutSize($self);
	my $frameStatBox = $self->__SetLayoutFrame($self);

	#$richTxt->Layout();

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	#$szMain->Add( $szStatBox, 0, &Wx::wxEXPAND );

	# BUILD STRUCTURE OF LAYOUT

	$szMainWrapper->Add( $szCustom,     0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szMainWrapper->Add( $sizeStatBox,  0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szMainWrapper->Add( $frameStatBox, 1, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$szMain->Add( $szMainWrapper, 50, &Wx::wxEXPAND, 0 );

	$szMain->AddStretchSpacer(50);

	$self->SetSizer($szMain);

	# save control references
	$self->{"szCustomCBMain"} = $szCustom;
	$self->{"szMain"}         = $szMain;

}

# Set layout for Quick set box
sub __SetLayoutSize {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Dimensions' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# Load data, for filling form by values

	my $szRow0 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);    # row for custom control, which are added by inherit class
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);    # row for custom control, which are added by inherit class
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $widthTxt = Wx::StaticText->new( $statBox, -1, "Width:", &Wx::wxDefaultPosition, [ 10, 23 ] );
	my $widthValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 10, 23 ] );

	Wx::InitAllImageHandlers();
	my $swapPath     = GeneralHelper->Root() . "/Programs/Panelisation/PnlWizard/Resources/swapIcon.png";
	my $swapBtmp     = Wx::Bitmap->new( $swapPath, &Wx::wxBITMAP_TYPE_PNG );
	my $swapStatBtmp = Wx::StaticBitmap->new( $statBox, -1, $swapBtmp );
	$swapStatBtmp->Hide();

	my $heightTxt = Wx::StaticText->new( $statBox, -1, "Height:", &Wx::wxDefaultPosition, [ 10, 23 ] );
	my $heightValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 10, 23 ] );

	# DEFINE EVENTS
	Wx::Event::EVT_LEFT_UP( $swapStatBtmp, sub { $self->__SwapSizeClickHndl() } );
	Wx::Event::EVT_TEXT( $widthValTxt,  -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_TEXT( $heightValTxt, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	# BUILD STRUCTURE OF LAYOUT
	$szRow2->Add( $widthTxt,    23, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $widthValTxt, 23, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow2->AddStretchSpacer(1);
	$szRow2->Add( $swapStatBtmp, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->AddStretchSpacer(1);

	$szRow2->Add( $heightTxt,    23, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $heightValTxt, 23, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szStatBox->Add( $szRow0, 0, &Wx::wxEXPAND );
	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND );
	$szStatBox->AddSpacer(2);
	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND );

	# save control references
	$self->{"widthValTxt"}           = $widthValTxt;
	$self->{"heightValTxt"}          = $heightValTxt;
	$self->{"customISValueSz"}       = $szRow0;
	$self->{"customCBSizeSz"}        = $szRow1;
	$self->{"customLyoutSizeParent"} = $statBox;
	$self->{"swapStatBtmp"}          = $swapStatBtmp;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutFrame {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Borders' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# Load data, for filling form by values

	my $szRow0 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);    # row for custom control, which are added by inherit class
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $leftTxt = Wx::StaticText->new( $statBox, -1, "Left:", &Wx::wxDefaultPosition, [ 10, 23 ] );
	my $leftValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 10, 23 ] );

	my $rightTxt = Wx::StaticText->new( $statBox, -1, "Right:", &Wx::wxDefaultPosition, [ 10, 23 ] );
	my $rightValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 10, 23 ] );

	my $topTxt = Wx::StaticText->new( $statBox, -1, "Top:", &Wx::wxDefaultPosition, [ 10, 23 ] );
	my $topValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 10, 23 ] );

	my $botTxt = Wx::StaticText->new( $statBox, -1, "Bot:", &Wx::wxDefaultPosition, [ 10, 23 ] );
	my $botValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 10, 23 ] );

	# DEFINE EVENTS
	Wx::Event::EVT_TEXT( $leftValTxt,  -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_TEXT( $rightValTxt, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_TEXT( $topValTxt,   -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_TEXT( $botValTxt,   -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $leftTxt,    23, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $leftValTxt, 23, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow1->AddStretchSpacer(6);

	$szRow1->Add( $topTxt,    23, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $topValTxt, 23, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow2->Add( $rightTxt,    23, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $rightValTxt, 23, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow2->AddStretchSpacer(6);

	$szRow2->Add( $botTxt,    23, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $botValTxt, 23, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szStatBox->Add( $szRow0, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->AddSpacer(2);
	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->AddSpacer(2);
	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# save control references
	$self->{"leftValTxt"}           = $leftValTxt;
	$self->{"rightValTxt"}          = $rightValTxt;
	$self->{"topValTxt"}            = $topValTxt;
	$self->{"botValTxt"}            = $botValTxt;
	$self->{"customCBBorderSz"}     = $szRow0;
	$self->{"customCBBorderParent"} = $statBox;

	return $szStatBox;
}

sub _SetLayoutCBMain {
	my $self           = shift;
	my $title          = shift;
	my $choices        = shift;
	my $titWidth       = shift;
	my $controlWidth   = shift;
	my $stretcherWidth = shift // 50;

	# DEFINE CONTROLS
	my $mainCbTxt = Wx::StaticText->new( $self, -1, $title, &Wx::wxDefaultPosition, [ 10, 23 ] );
	my $mainCB = Wx::ComboBox->new( $self, -1, ( defined $choices->[0] ? $choices->[0] : "" ), &Wx::wxDefaultPosition, [ 10, 23 ], $choices,
									&Wx::wxCB_READONLY );

	# DEFINE EVENTS
	Wx::Event::EVT_TEXT( $mainCB, -1, sub { $self->{"CBMainChangedEvt"}->Do( $mainCB->GetValue() ) } );

	# DEFINE LAYOUT
	$self->{"szCustomCBMain"}->Add( $mainCbTxt, $titWidth,     &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$self->{"szCustomCBMain"}->Add( $mainCB,    $controlWidth, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$self->{"szCustomCBMain"}->AddStretchSpacer($stretcherWidth);
	return $mainCB;
}

sub _SetLayoutISSize {
	my $self           = shift;
	my $title          = shift;         #
	my $titWidth       = shift;
	my $controlWidth   = shift;
	my $stretcherWidth = shift // 50;

	# DEFINE CONTROLS
	my $isTxt = Wx::StaticText->new( $self->{"customLyoutSizeParent"}, -1, $title, &Wx::wxDefaultPosition, [ 10, 23 ] );

	my $isIndicator = ResultIndicator->new( $self->{"customLyoutSizeParent"}, 20 );

	$isIndicator->SetStatus( EnumsGeneral->ResultType_NA );

	# DEFINE EVENTS
	#Wx::Event::EVT_TEXT( $mainCB, -1, sub { $self->{"CBSizeChangedEvt"}->Do( $mainCB->GetValue() ) } );

	# DEFINE LAYOUT
	$self->{"customISValueSz"}->Add( $isTxt,       $titWidth,     &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$self->{"customISValueSz"}->Add( $isIndicator, $controlWidth, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$self->{"customISValueSz"}->AddStretchSpacer($stretcherWidth);

	return $isIndicator;
}

sub _SetLayoutCBSize {
	my $self           = shift;
	my $title          = shift;
	my $choices        = shift;
	my $titWidth       = shift;
	my $controlWidth   = shift;
	my $stretcherWidth = shift // 50;

	# DEFINE CONTROLS
	my $mainCbTxt = Wx::StaticText->new( $self->{"customLyoutSizeParent"}, -1, $title, &Wx::wxDefaultPosition, [ 10, 23 ] );
	my $mainCB = Wx::ComboBox->new( $self->{"customLyoutSizeParent"},
									-1, ( defined $choices->[0] ? $choices->[0] : "" ),
									&Wx::wxDefaultPosition, [ 10, 23 ],
									$choices, &Wx::wxCB_READONLY );

	# DEFINE EVENTS
	Wx::Event::EVT_TEXT( $mainCB, -1, sub { $self->{"CBSizeChangedEvt"}->Do( $mainCB->GetValue() ) } );

	# DEFINE LAYOUT
	$self->{"customCBSizeSz"}->Add( $mainCbTxt, $titWidth,     &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$self->{"customCBSizeSz"}->Add( $mainCB,    $controlWidth, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$self->{"customCBSizeSz"}->AddStretchSpacer($stretcherWidth);

	return $mainCB;
}

sub _SetLayoutCBBorder {
	my $self           = shift;
	my $title          = shift;
	my $choices        = shift;
	my $titWidth       = shift;
	my $controlWidth   = shift;
	my $stretcherWidth = shift // 50;

	# DEFINE CONTROLS
	my $mainCbTxt = Wx::StaticText->new( $self->{"customCBBorderParent"}, -1, $title, &Wx::wxDefaultPosition, [ 10, 23 ] );
	my $mainCB = Wx::ComboBox->new( $self->{"customCBBorderParent"},
									-1, ( defined $choices->[0] ? $choices->[0] : "" ),
									&Wx::wxDefaultPosition, [ 10, 23 ],
									$choices, &Wx::wxCB_READONLY );

	# DEFINE EVENTS
	Wx::Event::EVT_TEXT( $mainCB, -1, sub { $self->{"CBBorderChangedEvt"}->Do( $mainCB->GetValue() ) } );

	# DEFINE LAYOUT
	$self->{"customCBBorderSz"}->Add( $mainCbTxt, $titWidth,     &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$self->{"customCBBorderSz"}->Add( $mainCB,    $controlWidth, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$self->{"customCBBorderSz"}->AddStretchSpacer($stretcherWidth);
	return $mainCB;
}

sub _EnableLayoutSize {
	my $self   = shift;
	my $enable = shift;

	if ($enable) {

		$self->{"widthValTxt"}->Enable();
		$self->{"heightValTxt"}->Enable();
	}
	else {

		$self->{"widthValTxt"}->Disable();
		$self->{"heightValTxt"}->Disable();
	}

}

sub _EnableLayoutBorder {
	my $self   = shift;
	my $enable = shift;

	if ($enable) {

		$self->{"leftValTxt"}->Enable();
		$self->{"rightValTxt"}->Enable();
		$self->{"topValTxt"}->Enable();
		$self->{"botValTxt"}->Enable();
	}
	else {
		$self->{"leftValTxt"}->Disable();
		$self->{"rightValTxt"}->Disable();
		$self->{"topValTxt"}->Disable();
		$self->{"botValTxt"}->Disable();
	}

}

sub _ShowSwapSize {
	my $self = shift;
	my $show = shift;

	if ($show) {

		$self->{"swapStatBtmp"}->Show();

	}
	else {

		$self->{"swapStatBtmp"}->Hide();

	}

}

sub _GetPnlWidthControl {
	my $self = shift;

	return $self->{"widthValTxt"};
}

sub _GetPnlHeightControl {
	my $self = shift;

	return $self->{"heightValTxt"};
}

sub _GetPnlBorderLControl {
	my $self = shift;

	return $self->{"leftValTxt"};
}

sub _GetPnlBorderRControl {
	my $self = shift;

	return $self->{"rightValTxt"};
}

sub _GetPnlBorderTControl {
	my $self = shift;

	return $self->{"topValTxt"};
}

sub _GetPnlBorderBControl {
	my $self = shift;

	return $self->{"botValTxt"};
}

sub _GetMainSizer {
	my $self = shift;

	return $self->{"szMain"};
}

sub __SwapSizeClickHndl {
	my $self = shift;

	my $w = $self->GetWidth();
	my $h = $self->GetHeight();
	$self->SetWidth($h);
	$self->SetHeight($w);
}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

sub SetWidth {
	my $self = shift;
	my $val  = shift;

	if ( defined $val && $val ne "" ) {

		$val = sprintf( "%.1f", $val );

		$self->{"widthValTxt"}->SetValue($val);

	}
}

sub GetWidth {
	my $self = shift;

	return $self->{"widthValTxt"}->GetValue();
}

sub SetHeight {
	my $self = shift;
	my $val  = shift;

	if ( defined $val && $val ne "" ) {

		$val = sprintf( "%.1f", $val );
		$self->{"heightValTxt"}->SetValue($val);
	}

}

sub GetHeight {
	my $self = shift;

	return $self->{"heightValTxt"}->GetValue();
}

sub SetBorderLeft {
	my $self = shift;
	my $val  = shift;

	if ( defined $val && $val ne "" ) {

		$val = sprintf( "%.1f", $val );
		$self->{"leftValTxt"}->SetValue($val);
	}

}

sub GetBorderLeft {
	my $self = shift;

	return $self->{"leftValTxt"}->GetValue();
}

sub SetBorderRight {
	my $self = shift;
	my $val  = shift;

	if ( defined $val && $val ne "" ) {

		$val = sprintf( "%.1f", $val );

		$self->{"rightValTxt"}->SetValue($val);

	}
}

sub GetBorderRight {
	my $self = shift;

	return $self->{"rightValTxt"}->GetValue();
}

sub SetBorderTop {
	my $self = shift;
	my $val  = shift;

	if ( defined $val && $val ne "" ) {
		$val = sprintf( "%.1f", $val );

		$self->{"topValTxt"}->SetValue($val);

	}
}

sub GetBorderTop {
	my $self = shift;

	return $self->{"topValTxt"}->GetValue();
}

sub SetBorderBot {
	my $self = shift;
	my $val  = shift;

	if ( defined $val && $val ne "" ) {
		$val = sprintf( "%.1f", $val );

		$self->{"botValTxt"}->SetValue($val);

	}
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

