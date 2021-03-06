
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::Frm::PnlStepAutoBase;
use base qw(Programs::Panelisation::PnlWizard::Forms::CreatorFrmBase);

#3th party library
use strict;
use warnings;
use Wx;
use List::Util qw(first);

BEGIN {
	eval { require Wx::BitmapComboBox; };
}

#local library
use Widgets::Style;
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Events::Event';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Widgets::Forms::ResultIndicator::ResultIndicator';
use aliased 'Widgets::Forms::CustomNotebook::CustomNotebook';
use aliased 'Programs::Panelisation::PnlWizard::Enums';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'Packages::CAM::PanelClass::Enums'          => 'PnlClassEnums';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::Frm::ManualPlacement';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class      = shift;
	my $creatorKey = shift;
	my $parent     = shift;
	my $inCAM      = shift;
	my $jobId      = shift;

	my $self = $class->SUPER::new( $creatorKey, $parent, $inCAM, $jobId );
	bless($self);

	$self->__Layout();

	# PROPERTIES
	$self->{"pcbStepsList"} = [];

	# DEFINE EVENTS
	$self->{"manualPlacementEvt"} = Event->new();

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

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow4 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $pcbStepTxt = Wx::StaticText->new( $self, -1, "PCB step:", &Wx::wxDefaultPosition, [ 10, 23 ] );
	my $pcbStepCB = Wx::ComboBox->new( $self, -1, "", &Wx::wxDefaultPosition, [ 10, 23 ], [""], &Wx::wxCB_READONLY );

	my $pnlClassTxt = Wx::StaticText->new( $self, -1, "Panel class:", &Wx::wxDefaultPosition, [ 10, 23 ] );
	my $pnlClassCB = Wx::ComboBox->new( $self, -1, "123", &Wx::wxDefaultPosition, [ 10, 23 ], [ "123", "123", "123" ], &Wx::wxCB_READONLY );

	my $stepProfileTxt = Wx::StaticText->new( $self, -1, "Profile:", &Wx::wxDefaultPosition, [ 10, 23 ] );

	my @profile = ("Standard");

	push( @profile, "Coverlay pins" ) if ( CamHelper->LayerExists( $self->{"inCAM"}, $self->{"jobId"}, "cvrlpins" ) );

	my $pcbStepProfileCB = Wx::ComboBox->new( $self, -1, $profile[0], &Wx::wxDefaultPosition, [ 10, 23 ], \@profile, &Wx::wxCB_READONLY );

	my $placementStatBox = $self->__SetLayoutPlacement($self);
	my $spacingStatBox   = $self->__SetLayoutSpacing($self);
	my $amountStatBox    = $self->__SetLayoutAmount($self);
	my $createPnlStatBox = $self->__SetLayoutCreatePnl($self);

	#$richTxt->Layout();

	# SET EVENTS

	Wx::Event::EVT_TEXT( $pcbStepCB,        -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_TEXT( $pcbStepProfileCB, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_TEXT( $pnlClassCB, -1, sub { $self->__OnPnlClassChanged( $pnlClassCB->GetValue(), $self->{"creatorSettingsChangedEvt"}->Do() ) } );

	#Wx::Event::EVT_TEXT( $pnlClassCB, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	# BUILD STRUCTURE OF LAYOUT

	#$szMain->Add( $szStatBox, 0, &Wx::wxEXPAND );

	# BUILD STRUCTURE OF LAYOUT

	$szRow1->Add( $pnlClassTxt, 15, &Wx::wxEXPAND );
	$szRow1->Add( $pnlClassCB,  35, &Wx::wxEXPAND );
	$szRow1->AddStretchSpacer(2);

	$szRow1->Add( $pcbStepTxt, 10, &Wx::wxEXPAND );
	$szRow1->Add( $pcbStepCB,  14, &Wx::wxEXPAND );
	$szRow1->AddStretchSpacer(2);

	$szRow1->Add( $stepProfileTxt,   10, &Wx::wxEXPAND );
	$szRow1->Add( $pcbStepProfileCB, 14, &Wx::wxEXPAND );

	$szRow3->Add( $placementStatBox, 50, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szRow3->Add( $amountStatBox,    50, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$szRow4->Add( $spacingStatBox,   50, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szRow4->Add( $createPnlStatBox, 50, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$szMain->Add( $szRow1, 0, &Wx::wxEXPAND );
	$szMain->AddSpacer(5);
	$szMain->Add( $szRow2, 0, &Wx::wxEXPAND );
	$szMain->AddSpacer(2);
	$szMain->Add( $szRow3, 0, &Wx::wxEXPAND );
	$szMain->AddSpacer(2);
	$szMain->Add( $szRow4, 1, &Wx::wxEXPAND );

	$self->SetSizer($szMain);

	# save control references
	$self->{"pcbStepCB"}        = $pcbStepCB;
	$self->{"pcbStepProfileCB"} = $pcbStepProfileCB;
	$self->{"pnlClassCB"}       = $pnlClassCB;

}

# Set layout for Quick set box
sub __SetLayoutPlacement {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Placement settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# Load data, for filling form by values

	my $szRow1     = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow1Col1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRow1Col2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	# Row 1

	my $rbPlacementRot = Wx::RadioButton->new( $statBox, -1, "Rotation", &Wx::wxDefaultPosition, [ 10, 23 ], &Wx::wxRB_GROUP );
	my $rbPlacementPatt = Wx::RadioButton->new( $statBox, -1, "Pattern", &Wx::wxDefaultPosition, [ 10, 23 ] );

	my $notebook = CustomNotebook->new( $statBox, -1 );
	my $placementRotPage  = $notebook->AddPage( 1, 0 );
	my $placementPattPage = $notebook->AddPage( 2, 0 );

	my @rotType = (
					PnlClassEnums->PnlClassRotation_0DEG,    PnlClassEnums->PnlClassRotation_90DEG,
					PnlClassEnums->PnlClassRotation_UNIFORM, PnlClassEnums->PnlClassRotation_ANY
	);
	my $rotTypeCb =
	  Wx::ComboBox->new( $placementRotPage->GetParent(), -1, $rotType[0], &Wx::wxDefaultPosition, [ 10, 23 ], \@rotType, &Wx::wxCB_READONLY );
	#
	#	my $pnlRotPage = Wx::Panel->new($placementRotPage->GetParent());
	#	my $szRotPage = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	#
	#
	#
	#	#my $rotTypeCb = Wx::ComboBox->new( $pnlRotPage, -1, $rotType[0], &Wx::wxDefaultPosition, [ -1, -1 ], \@rotType );
	#my $rotTypeCb = Wx::ComboBox->new( $placementRotPage->GetParent(), -1, "", &Wx::wxDefaultPosition, [ -1, -1 ] );

	#$pnlRotPage->SetSizer($szRotPage);

	#$szRotPage->Add( $rotTypeCb, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	#$szRotPage->Add(  Wx::TextCtrl->new( $pnlRotPage, -1, $rotType[0], &Wx::wxDefaultPosition, [ -1, -1 ] ) ,0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	my @pattType = (
					 PnlClassEnums->PnlClassPattern_NO_PATTERN,    PnlClassEnums->PnlClassPattern_ALTERNATE_ROW,
					 PnlClassEnums->PnlClassPattern_ALTERNATE_COL, PnlClassEnums->PnlClassPattern_ALTERNATE_ROW_COL,
					 PnlClassEnums->PnlClassPattern_TOP_HALF,      PnlClassEnums->PnlClassPattern_BOTTOM_HALF,
					 PnlClassEnums->PnlClassPattern_RIGHT_HALF,    PnlClassEnums->PnlClassPattern_LEFT_HALF
	);

	#my $pattTypeCb = Wx::ComboBox->new( $allPage->GetParent(), -1, $rotType[0], &Wx::wxDefaultPosition, [ 50, 25 ], \@rotType, &Wx::wxCB_READONLY );

	#my $pattTypeCb = Wx::BitmapComboBox->new( $placementPattPage->GetParent(), -1, $pattType[0], &Wx::wxDefaultPosition, [ 50, 25 ],  \@pattType, );
	my $pattTypeCb =
	  Wx::ComboBox->new( $placementPattPage->GetParent(), -1, $pattType[0], &Wx::wxDefaultPosition, [ 10, 23 ], \@pattType, &Wx::wxCB_READONLY );

	$placementRotPage->AddContent($rotTypeCb);

	$placementPattPage->AddContent($pattTypeCb);

	$notebook->ShowPage(1);

	# Row 2

	my $interlockTxt = Wx::StaticText->new( $statBox, -1, "Interlock:", &Wx::wxDefaultPosition, [ 10, 23 ] );
	my @interlockType = ( PnlClassEnums->PnlClassInterlock_NONE, PnlClassEnums->PnlClassInterlock_SIMPLE, PnlClassEnums->PnlClassInterlock_SLIDING );
	my $interlockCb =
	  Wx::ComboBox->new( $statBox, -1, $interlockType[0], &Wx::wxDefaultPosition, [ 10, 23 ], \@interlockType, &Wx::wxCB_READONLY );

	# SET EVENTS
	Wx::Event::EVT_RADIOBUTTON( $rbPlacementRot,  -1, sub { $notebook->ShowPage(1); $self->{"creatorSettingsChangedEvt"}->Do(); } );
	Wx::Event::EVT_RADIOBUTTON( $rbPlacementPatt, -1, sub { $notebook->ShowPage(2); $self->{"creatorSettingsChangedEvt"}->Do(); } );

	Wx::Event::EVT_TEXT( $rotTypeCb,   -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_TEXT( $pattTypeCb,  -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_TEXT( $interlockCb, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	# BUILD STRUCTURE OF LAYOUT
	$szRow1Col1->Add( $rbPlacementRot,  1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1Col1->Add( $rbPlacementPatt, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow1Col2->Add( $notebook, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow1->Add( $szRow1Col1, 50, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $szRow1Col2, 50, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow2->Add( $interlockTxt, 50, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $interlockCb,  50, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szStatBox->Add( $szRow1, 1, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	$szStatBox->AddSpacer(2);
	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );

	# save control references
	$self->{"rotTypeCb"}         = $rotTypeCb;
	$self->{"pattTypeCb"}        = $pattTypeCb;
	$self->{"rbPlacementRot"}    = $rbPlacementRot;
	$self->{"rbPlacementPatt"}   = $rbPlacementPatt;
	$self->{"interlockCb"}       = $interlockCb;
	$self->{"notebookPlacement"} = $notebook;

	$self->{"placementStatBox"} = $statBox;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutSpacing {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Spacing settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# Load data, for filling form by values

	my $szRow0 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $pnlClassSpaceTxt = Wx::StaticText->new( $statBox, -1, "Class space:", &Wx::wxDefaultPosition, [ 10, 23 ] );
	my $pnlClassSpaceCB = Wx::ComboBox->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 10, 23 ], [""], &Wx::wxCB_READONLY );

	my $spaceXTxt = Wx::StaticText->new( $statBox, -1, "Space X:", &Wx::wxDefaultPosition, [ 10, 23 ] );
	my $spaceXValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 10, 23 ] );

	my $spaceYTxt = Wx::StaticText->new( $statBox, -1, "Space Y:", &Wx::wxDefaultPosition, [ 10, 23 ] );
	my $spaceYValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 10, 23 ] );

	my $spacingTypeTxt = Wx::StaticText->new( $statBox, -1, "Space align:", &Wx::wxDefaultPosition, [ 10, 23 ] );
	my @spacingType = ( PnlClassEnums->PnlClassSpacingAlign_KEEP_IN_CENTER, PnlClassEnums->PnlClassSpacingAlign_SPACE_EVENLY );
	my $spacingTypeCb =
	  Wx::ComboBox->new( $statBox, -1, $spacingType[0], &Wx::wxDefaultPosition, [ 10, 23 ], \@spacingType, &Wx::wxCB_READONLY );

	# DEFINE EVENTS
	Wx::Event::EVT_TEXT( $pnlClassSpaceCB, -1, sub { $self->__OnPnlClassSpacingChanged( $pnlClassSpaceCB->GetValue() ) } );

	#Wx::Event::EVT_TEXT( $pnlClassSpaceCB, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_TEXT( $spaceXValTxt,  -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_TEXT( $spaceYValTxt,  -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_TEXT( $spacingTypeCb, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	# BUILD STRUCTURE OF LAYOUT
	$szRow0->Add( $pnlClassSpaceTxt, 50, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow0->Add( $pnlClassSpaceCB,  50, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow1->Add( $spaceXTxt,    50, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $spaceXValTxt, 50, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow2->Add( $spaceYTxt,    50, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $spaceYValTxt, 50, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow3->Add( $spacingTypeTxt, 50, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow3->Add( $spacingTypeCb,  50, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szStatBox->Add( $szRow0, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->AddSpacer(2);
	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->AddSpacer(2);
	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->AddSpacer(2);
	$szStatBox->Add( $szRow3, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# save control references

	$self->{"spaceXValTxt"}    = $spaceXValTxt;
	$self->{"spaceYValTxt"}    = $spaceYValTxt;
	$self->{"spacingTypeCb"}   = $spacingTypeCb;
	$self->{"pnlClassSpaceCB"} = $pnlClassSpaceCB;

	$self->{"spacingStatBox"} = $statBox;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutAmount {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Amount' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# Load data, for filling form by values

	#	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $szRow0     = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow1     = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow1Col1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRow1Col2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS

	# Row 1

	my $rbAmountExact = Wx::RadioButton->new( $statBox, -1, "Exact", &Wx::wxDefaultPosition, &Wx::wxDefaultSize, &Wx::wxRB_GROUP );
	my $rbAmountMax   = Wx::RadioButton->new( $statBox, -1, "Max",   &Wx::wxDefaultPosition, &Wx::wxDefaultSize );
	my $rbAmountAuto  = Wx::RadioButton->new( $statBox, -1, "Auto",  &Wx::wxDefaultPosition, &Wx::wxDefaultSize );

	my $notebook = CustomNotebook->new( $statBox, -1 );
	my $amountExactPage = $notebook->AddPage( 1, 0 );
	my $amountMaxPage   = $notebook->AddPage( 2, 0 );
	my $amountAutoPage  = $notebook->AddPage( 3, 0 );

	my $exactValTxt = Wx::TextCtrl->new( $amountExactPage->GetParent(), -1, "", &Wx::wxDefaultPosition, [ 10, 23 ] );
	my $maxValTxt   = Wx::TextCtrl->new( $amountMaxPage->GetParent(),   -1, "", &Wx::wxDefaultPosition, [ 10, 23 ] );

	$amountExactPage->AddContent($exactValTxt);
	$amountMaxPage->AddContent($maxValTxt);

	#$placementPattPage->AddContent($pattTypeCb);

	$notebook->ShowPage(1);

	# DEFINE EVENTS
	Wx::Event::EVT_RADIOBUTTON( $rbAmountExact, -1, sub { $notebook->ShowPage(1); $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_RADIOBUTTON( $rbAmountMax,   -1, sub { $notebook->ShowPage(2); $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_RADIOBUTTON( $rbAmountAuto,  -1, sub { $notebook->ShowPage(3); $self->{"creatorSettingsChangedEvt"}->Do() } );

	Wx::Event::EVT_TEXT( $exactValTxt, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_TEXT( $maxValTxt,   -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	#	Wx::Event::EVT_TEXT( $leftValTxt,  -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	#	Wx::Event::EVT_TEXT( $rightValTxt, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	#	Wx::Event::EVT_TEXT( $topValTxt,   -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	#	Wx::Event::EVT_TEXT( $botValTxt,   -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	# BUILD STRUCTURE OF LAYOUT
	$szRow1Col1->Add( $rbAmountExact, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1Col1->Add( $rbAmountMax,   1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1Col1->Add( $rbAmountAuto,  1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow1Col2->Add( $notebook, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow1->Add( $szRow1Col1, 50, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $szRow1Col2, 50, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szStatBox->Add( $szRow0, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	$szStatBox->AddSpacer(2);
	$szStatBox->Add( $szRow1, 1, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );

	#$szStatBox->Add( $szRow2, 1, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	# save control references

	$self->{"rbAmountExact"}  = $rbAmountExact;
	$self->{"rbAmountMax"}    = $rbAmountMax;
	$self->{"rbAmountAuto"}   = $rbAmountAuto;
	$self->{"notebookAmount"} = $notebook;

	$self->{"exactValTxt"} = $exactValTxt;
	$self->{"maxValTxt"}   = $maxValTxt;

	$self->{"customLayoutAmountParent"} = $statBox;
	$self->{"customLayoutSz"}           = $szRow0;

	$self->{"amountStatBox"} = $statBox;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutCreatePnl {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Create panel' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# Load data, for filling form by values

	#	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $szRow1     = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2     = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2Col1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRow2Col2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS

	# Row 1

	my $rbPlacementAuto = Wx::RadioButton->new( $statBox, -1, "Best solution", &Wx::wxDefaultPosition, &Wx::wxDefaultSize, &Wx::wxRB_GROUP );
	my $rbPlacementManual = Wx::RadioButton->new( $statBox, -1, "Manual selection", &Wx::wxDefaultPosition, &Wx::wxDefaultSize );

	my $notebook = CustomNotebook->new( $statBox, -1 );
	my $placementAutoPage   = $notebook->AddPage( 1, 0 );
	my $placementManualPage = $notebook->AddPage( 2, 0 );

	my $szManual = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $pnlPicker = ManualPlacement->new( $placementManualPage->GetParent(),
										  $self->{"jobId"}, $self->GetStep(), "Select panel",
										  "Accept best panel (+ adjust if needed) and press Continue.",
										  1, "Clear" );

	$szManual->Add( $pnlPicker, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$placementManualPage->AddContent($szManual);

	my $minUtilTxt = Wx::StaticText->new( $statBox, -1, "Min utilization[%]:", &Wx::wxDefaultPosition, [ 10, 23 ] );
	my $minUtilValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 10, 23 ] );

	$notebook->ShowPage(1);

	# DEFINE EVENTS
	Wx::Event::EVT_RADIOBUTTON( $rbPlacementAuto, -1,
								sub { $self->_EnableSettings(), $notebook->ShowPage(1); $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_RADIOBUTTON( $rbPlacementManual, -1,
								sub { $self->_EnableSettings(), $notebook->ShowPage(2); $self->{"creatorSettingsChangedEvt"}->Do() } );

	#	Wx::Event::EVT_RADIOBUTTON( $rbPlacementAuto,  -1, sub {  } );
	#	Wx::Event::EVT_RADIOBUTTON( $rbPlacementManual,  -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_TEXT( $minUtilValTxt, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	$pnlPicker->{"placementEvt"}->Add( sub      { $self->{"manualPlacementEvt"}->Do(@_) } );
	$pnlPicker->{"clearPlacementEvt"}->Add( sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	#	Wx::Event::EVT_TEXT( $leftValTxt,  -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	#	Wx::Event::EVT_TEXT( $rightValTxt, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	#	Wx::Event::EVT_TEXT( $topValTxt,   -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	#	Wx::Event::EVT_TEXT( $botValTxt,   -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	# BUILD STRUCTURE OF LAYOUT

	$szRow1->Add( $minUtilTxt,    1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $minUtilValTxt, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow2->Add( $szRow2Col1, 50, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $szRow2Col2, 50, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow2Col1->Add( $rbPlacementAuto,   1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow2Col1->Add( $rbPlacementManual, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow2Col2->Add( $notebook, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	$szStatBox->AddSpacer(2);
	$szStatBox->Add( $szRow2, 1, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );

	#$szStatBox->Add( $szRow2, 1, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	# save control references

	$self->{"minUtilValTxt"}     = $minUtilValTxt;
	$self->{"rbPlacementAuto"}   = $rbPlacementAuto;
	$self->{"rbPlacementManual"} = $rbPlacementManual;

	$self->{"pnlPicker"}         = $pnlPicker;
	$self->{"notebookCreatePnl"} = $notebook;

	return $szStatBox;
}

sub _SetLayoutISMultipl {
	my $self  = shift;
	my $title = shift;    #

	# DEFINE CONTROLS
	my $isTxt = Wx::StaticText->new( $self->{"customLayoutAmountParent"}, -1, $title, &Wx::wxDefaultPosition, [ 10, 23 ] );

	my $isIndicator = ResultIndicator->new( $self->{"customLayoutAmountParent"}, 20 );

	$isIndicator->SetStatus( EnumsGeneral->ResultType_NA );

	# DEFINE EVENTS
	#Wx::Event::EVT_TEXT( $mainCB, -1, sub { $self->{"CBSizeChangedEvt"}->Do( $mainCB->GetValue() ) } );

	# DEFINE LAYOUT
	$self->{"customLayoutSz"}->Add( $isTxt, 50, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$self->{"customLayoutSz"}->Add( $isIndicator, 50, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	return $isIndicator;
}

sub _EnableLayoutAmount {
	my $self   = shift;
	my $enable = shift;

	if ($enable) {

		$self->{"rbAmountExact"}->Enable();
		$self->{"rbAmountMax"}->Enable();
		$self->{"rbAmountAuto"}->Enable();
		$self->{"notebookAmount"}->Enable();
		$self->{"exactValTxt"}->Enable();
		$self->{"maxValTxt"}->Enable();

	}
	else {

		$self->{"rbAmountExact"}->Disable();
		$self->{"rbAmountMax"}->Disable();
		$self->{"rbAmountAuto"}->Disable();
		$self->{"notebookAmount"}->Disable();
		$self->{"exactValTxt"}->Disable();
		$self->{"maxValTxt"}->Disable();
	}

}

sub __OnPnlClassChanged {
	my $self      = shift;
	my $className = shift;

	return 0 unless ( scalar( @{ $self->{"classes"} } ) );

	my $class = first { $_->GetName() eq $className } @{ $self->{"classes"} };

	# Set cb classes size
	$self->{"pnlClassSpaceCB"}->Freeze();

	$self->{"pnlClassSpaceCB"}->Clear();

	my @spacings = $class->GetAllClassSpacings();

	@spacings = sort { $a->GetSpaceX() <=> $b->GetSpaceX() } @spacings;

	foreach my $classSpace (@spacings) {

		$self->{"pnlClassSpaceCB"}->Append( $classSpace->GetName() );
	}

	$self->{"pnlClassSpaceCB"}->Thaw();

	if ( scalar(@spacings) ) {

		my $spaceName = $spacings[0]->GetName();
		$self->{"pnlClassSpaceCB"}->SetValue($spaceName);
		$self->__OnPnlClassSpacingChanged($spaceName);
	}

}

sub __OnPnlClassSpacingChanged {
	my $self           = shift;
	my $classSpaceName = shift;

	return 0 unless ( scalar( @{ $self->{"classes"} } ) );

	my $class      = first { $_->GetName() eq $self->{"pnlClassCB"}->GetValue() } @{ $self->{"classes"} };
	my $classSpace = first { $_->GetName() eq $classSpaceName } $class->GetAllClassSpacings();

	# Change dimension
	if ( defined $classSpace ) {
		$self->SetSpaceX( $classSpace->GetSpaceX() );
		$self->SetSpaceY( $classSpace->GetSpaceY() );

	}

}

sub DisplayCvrlpinLayer {
	my $self = shift;

	my $type = $self->GetPCBStepProfile();

	if ( $type eq PnlCreEnums->PCBStepProfile_CVRLPINS ) {

		CamLayer->DisplayLayers( $self->{"inCAM"}, ["cvrlpins"], 1, 0 );
		$self->{"inCAM"}->COM( "display_sr", "display" => "yes" );

	}
	else {

		CamLayer->DisplayLayers( $self->{"inCAM"}, ["cvrlpins"], 0, 0 );
	}
}

sub _EnableSettings {
	my $self = shift;

	if ( $self->{"rbPlacementAuto"}->GetValue() ) {

		$self->{"placementStatBox"}->Enable();
		$self->{"spacingStatBox"}->Enable();
		$self->{"amountStatBox"}->Enable();

	}
	elsif ( $self->{"rbPlacementManual"}->GetValue() ) {
		$self->{"placementStatBox"}->Disable();
		$self->{"spacingStatBox"}->Disable();
		$self->{"amountStatBox"}->Disable();
	}

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

sub SetPnlClasses {
	my $self    = shift;
	my $classes = shift;

	$self->{"classes"} = $classes;

	$self->{"pnlClassCB"}->Freeze();

	$self->{"pnlClassCB"}->Clear();

	# Set cb classes
	foreach my $class ( @{$classes} ) {

		$self->{"pnlClassCB"}->Append( $class->GetName() );
	}

	$self->{"pnlClassCB"}->Thaw();

}

sub GetPnlClasses {
	my $self = shift;

	return $self->{"classes"};
}

sub SetDefPnlClass {
	my $self = shift;
	my $val  = shift;

	$self->{"pnlClassCB"}->SetValue($val) if ( defined $val && $val ne "" );

	$self->__OnPnlClassChanged($val) if ( defined $val && $val ne "" );
}

sub GetDefPnlClass {
	my $self = shift;

	return $self->{"pnlClassCB"}->GetValue();
}

sub SetDefPnlSpacing {
	my $self = shift;
	my $val  = shift;

	$self->{"pnlClassSpaceCB"}->SetValue($val) if ( defined $val && $val ne "" );

	$self->__OnPnlClassSpacingChanged($val) if ( defined $val && $val ne "" );
}

sub GetDefPnlSpacing {
	my $self = shift;

	return $self->{"pnlClassSpaceCB"}->GetValue();
}

sub SetPCBStepsList {
	my $self = shift;
	my $val  = shift;

	$self->{"pcbStepsList"} = $val;

	$self->{"pcbStepCB"}->Freeze();

	$self->{"pcbStepCB"}->Clear();

	# Set cb classes
	foreach my $step ( @{ $self->{"pcbStepsList"} } ) {

		$self->{"pcbStepCB"}->Append($step);
	}

	$self->{"pcbStepCB"}->Thaw();

}

sub GetPCBStepsList {
	my $self = shift;

	return $self->{"pcbStepsList"};

}

sub SetPCBStep {
	my $self = shift;
	my $val  = shift;

	$self->{"pcbStepCB"}->SetValue($val) if ( defined $val && $val ne "" );

}

sub GetPCBStep {
	my $self = shift;

	return $self->{"pcbStepCB"}->GetValue();

}

sub SetPCBStepProfile {
	my $self = shift;
	my $val  = shift;

	if ( defined $val && $val ne "" ) {
		my $cbValue = undef;

		if ( $val eq PnlCreEnums->PCBStepProfile_STANDARD ) {

			$self->{"pcbStepProfileCB"}->SetValue("Standard");

		}
		elsif ( $val eq PnlCreEnums->PCBStepProfile_CVRLPINS ) {

			$self->{"pcbStepProfileCB"}->SetValue("Coverlay pins");

		}

	}

}

sub GetPCBStepProfile {
	my $self = shift;

	my $val = undef;

	if ( $self->{"pcbStepProfileCB"}->GetValue() eq "Standard" ) {

		$val = PnlCreEnums->PCBStepProfile_STANDARD;

	}
	elsif ( $self->{"pcbStepProfileCB"}->GetValue() eq "Coverlay pins" ) {
		$val = PnlCreEnums->PCBStepProfile_CVRLPINS;

	}

	return $val;

}

# Placement settings

sub SetPlacementType {
	my $self = shift;
	my $val  = shift;

	if ( $val eq PnlClassEnums->PnlClassTransform_ROTATION ) {

		$self->{"rbPlacementRot"}->SetValue(1);
		$self->{"notebookPlacement"}->ShowPage(1);

	}
	elsif ( $val eq PnlClassEnums->StepPlacement_PATTERN ) {

		$self->{"rbPlacementPatt"}->SetValue(1);
		$self->{"notebookPlacement"}->ShowPage(2);
	}
	else {

		die "Wrong placement type value: $val";
	}

}

sub GetPlacementType {
	my $self = shift;

	my $val = undef;

	if ( $self->{"rbPlacementRot"}->GetValue() ) {

		$val = PnlClassEnums->PnlClassTransform_ROTATION;
	}
	elsif ( $self->{"rbPlacementPatt"}->GetValue() ) {
		$val = PnlClassEnums->PnlClassTransform_PATTERN;
	}
	else {

		die "Wrong placement type";
	}

	return $val;

}

sub SetRotationType {
	my $self = shift;
	my $val  = shift;

	$self->{"rotTypeCb"}->SetValue($val) if ( defined $val && $val ne "" );
}

sub GetRotationType {
	my $self = shift;

	return $self->{"rotTypeCb"}->GetValue();
}

sub SetPatternType {
	my $self = shift;
	my $val  = shift;

	$self->{"pattTypeCb"}->SetValue($val) if ( defined $val && $val ne "" );
}

sub GetPatternType {
	my $self = shift;

	return $self->{"pattTypeCb"}->GetValue();
}

sub SetInterlockType {
	my $self = shift;
	my $val  = shift;

	$self->{"interlockCb"}->SetValue($val) if ( defined $val && $val ne "" );
}

sub GetInterlockType {
	my $self = shift;

	return $self->{"interlockCb"}->GetValue();
}

# Space settings

sub SetSpaceX {
	my $self = shift;
	my $val  = shift;

	$self->{"spaceXValTxt"}->SetValue( sprintf( "%.1f", $val ) )

}

sub GetSpaceX {
	my $self = shift;

	return $self->{"spaceXValTxt"}->GetValue();

}

sub SetSpaceY {
	my $self = shift;
	my $val  = shift;

	$self->{"spaceYValTxt"}->SetValue( sprintf( "%.1f", $val ) ) if ( defined $val && $val ne "" );
}

sub GetSpaceY {
	my $self = shift;

	return $self->{"spaceYValTxt"}->GetValue();
}

sub SetAlignType {
	my $self = shift;
	my $val  = shift;

	$self->{"spacingTypeCb"}->SetValue($val) if ( defined $val && $val ne "" );

}

sub GetAlignType {
	my $self = shift;

	return $self->{"spacingTypeCb"}->GetValue();

}

# Amount settings

sub SetAmountType {
	my $self = shift;
	my $val  = shift;

	if ( $val eq PnlCreEnums->StepAmount_EXACT ) {

		$self->{"rbAmountExact"}->SetValue(1);
		$self->{"notebookAmount"}->ShowPage(1);

	}
	elsif ( $val eq PnlCreEnums->StepAmount_MAX ) {

		$self->{"rbAmountMax"}->SetValue(1);
		$self->{"notebookAmount"}->ShowPage(2);
	}
	elsif ( $val eq PnlCreEnums->StepAmount_AUTO ) {

		$self->{"rbAmountAuto"}->SetValue(1);
		$self->{"notebookAmount"}->ShowPage(3);
	}
	else {

		die "Wrong quantity type value: $val";
	}

}

sub GetAmountType {
	my $self = shift;

	my $val = undef;

	if ( $self->{"rbAmountExact"}->GetValue() ) {

		$val = PnlCreEnums->StepAmount_EXACT;
	}
	elsif ( $self->{"rbAmountMax"}->GetValue() ) {
		$val = PnlCreEnums->StepAmount_MAX;
	}
	elsif ( $self->{"rbAmountAuto"}->GetValue() ) {
		$val = PnlCreEnums->StepAmount_AUTO;
	}
	else {

		die "Wrong quantity type";
	}

	return $val;

}

sub SetExactQuantity {
	my $self = shift;
	my $val  = shift;

	$self->{"exactValTxt"}->SetValue($val);

}

sub GetExactQuantity {
	my $self = shift;

	return $self->{"exactValTxt"}->GetValue();

}

sub SetMaxQuantity {
	my $self = shift;
	my $val  = shift;

	$self->{"maxValTxt"}->SetValue($val);

}

sub GetMaxQuantity {
	my $self = shift;

	return $self->{"maxValTxt"}->GetValue();

}

# Panelisation

sub SetActionType {
	my $self = shift;
	my $val  = shift;

	if ( $val eq PnlCreEnums->StepPlacementMode_AUTO ) {
 
 		$self->{"rbPlacementAuto"}->SetValue(1);
		$self->{"notebookCreatePnl"}->ShowPage(1);
	}
	elsif ( $val eq PnlCreEnums->StepPlacementMode_MANUAL ) {
	 
	 	$self->{"rbPlacementManual"}->SetValue(1);
		$self->{"notebookCreatePnl"}->ShowPage(2);
	}
	else {

		die "Wrong action type: $val";
	}

	$self->_EnableSettings();

}

sub GetActionType {
	my $self = shift;

	my $val = undef;

	if ( $self->{"rbPlacementAuto"}->GetValue() ) {

		$val = PnlCreEnums->StepPlacementMode_AUTO;
	}
	elsif ( $self->{"rbPlacementManual"}->GetValue() ) {
		$val = PnlCreEnums->StepPlacementMode_MANUAL;
	}
	else {

		die "Wrong action type";
	}

	return $val;

}

sub SetManualPlacementJSON {
	my $self = shift;
	my $val  = shift;

	$self->{"pnlPicker"}->SetManualPlacementJSON($val);

}

sub GetManualPlacementJSON {
	my $self = shift;

	return $self->{"pnlPicker"}->GetManualPlacementJSON();

}

sub SetManualPlacementStatus {
	my $self = shift;
	my $val  = shift;

	$self->{"pnlPicker"}->SetManualPlacementStatus($val);
}

sub GetManualPlacementStatus {
	my $self = shift;

	return $self->{"pnlPicker"}->GetManualPlacementStatus();
}

sub SetMinUtilization {
	my $self = shift;
	my $val  = shift;

	$self->{"minUtilValTxt"}->SetValue($val);

}

sub GetMinUtilization {
	my $self = shift;

	return $self->{"minUtilValTxt"}->GetValue();

}

# Panel dimension settings

#sub SetWidth {
#	my $self = shift;
#	my $val  = shift;
#
#	$self->{"pnl_width"} = $val;
#}
#
#sub GetWidth {
#	my $self = shift;
#
#	return $self->{"pnl_width"};
#}
#
#sub SetHeight {
#	my $self = shift;
#	my $val  = shift;
#
#	$self->{"pnl_height"} = $val;
#}
#
#sub GetHeight {
#	my $self = shift;
#
#	return $self->{"pnl_height"};
#}
#
#sub SetBorderLeft {
#	my $self = shift;
#	my $val  = shift;
#
#	$self->{"pnl_borderLeft"} = $val;
#}
#
#sub GetBorderLeft {
#	my $self = shift;
#
#	return $self->{"pnl_borderLeft"};
#}
#
#sub SetBorderRight {
#	my $self = shift;
#	my $val  = shift;
#
#	$self->{"pnl_borderRight"} = $val;
#}
#
#sub GetBorderRight {
#	my $self = shift;
#
#	return $self->{"pnl_borderRight"};
#}
#
#sub SetBorderTop {
#	my $self = shift;
#	my $val  = shift;
#
#	$self->{"pnl_borderTop"} = $val;
#}
#
#sub GetBorderTop {
#	my $self = shift;
#
#	return $self->{"pnl_borderTop"};
#}
#
#sub SetBorderBot {
#	my $self = shift;
#	my $val  = shift;
#
#	$self->{"pnl_borderBot"} = $val;
#}
#
#sub GetBorderBot {
#	my $self = shift;
#
#	return $self->{"pnl_borderBot"};
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, " f13610 " );
#
#	$test->MainLoop();

1;

