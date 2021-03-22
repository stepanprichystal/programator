
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

BEGIN {
	eval { require Wx::BitmapComboBox; };
}

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Widgets::Forms::ResultIndicator::ResultIndicator';
use aliased 'Widgets::Forms::CustomNotebook::CustomNotebook';
use aliased 'Programs::Panelisation::PnlWizard::Enums';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'Packages::CAM::PanelClass::Enums' => 'PnlClassEnums';

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

	my $szRow1  = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2  = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szClmn1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szClmn2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS

	my $pcbStepTxt = Wx::StaticText->new( $self, -1, "PCB step:", &Wx::wxDefaultPosition, [ 70, 25 ] );
	my $pcbStepValTxt = Wx::TextCtrl->new( $self, -1, "", &Wx::wxDefaultPosition, [ 70, 25 ] );

	my $placementStatBox = $self->__SetLayoutPlacement($self);
	my $spacingStatBox   = $self->__SetLayoutSpacing($self);
	my $amountStatBox    = $self->__SetLayoutAmount($self);
	my $createPnlStatBox = $self->__SetLayoutCreatePnl($self);

	#$richTxt->Layout();

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	#$szMain->Add( $szStatBox, 0, &Wx::wxEXPAND );

	# BUILD STRUCTURE OF LAYOUT

	$szClmn1->Add( $placementStatBox, 1, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szClmn1->Add( $spacingStatBox,   1, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$szClmn2->Add( $amountStatBox,    1, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szClmn2->Add( $createPnlStatBox, 1, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$szRow1->Add( $pcbStepTxt,    1, &Wx::wxEXPAND );
	$szRow1->Add( $pcbStepValTxt, 1, &Wx::wxEXPAND );

	$szRow2->Add( $szClmn1, 1, &Wx::wxEXPAND );
	$szRow2->Add( $szClmn2, 1, &Wx::wxEXPAND );

	$szMain->Add( $szRow1, 0, &Wx::wxEXPAND );
	$szMain->Add( $szRow2, 1, &Wx::wxEXPAND );

	$self->SetSizer($szMain);

	# save control references
	$self->{"pcbStepValTxt"} = $pcbStepValTxt;

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

	my $rbPlacementRot = Wx::RadioButton->new( $statBox, -1, "Rotation", &Wx::wxDefaultPosition, &Wx::wxDefaultSize, &Wx::wxRB_GROUP );
	my $rbPlacementPatt = Wx::RadioButton->new( $statBox, -1, "Pattern", &Wx::wxDefaultPosition, &Wx::wxDefaultSize );

	my $notebook = CustomNotebook->new( $statBox, -1 );
	my $placementRotPage  = $notebook->AddPage( 1, 0 ); 
	my $placementPattPage = $notebook->AddPage( 2, 0 );

	

#	my @rotType =
#	  ( PnlCreEnums->PnlClassRotation_0DEG, PnlCreEnums->PnlClassRotation_90DEG, PnlCreEnums->PnlClassRotation_UNIFORM, PnlCreEnums->PnlClassRotation_ANY );
##	my $rotTypeCb =
##	  Wx::ComboBox->new( $placementRotPage->GetParent(), -1, $rotType[0], &Wx::wxDefaultPosition, [ -1, -1 ], \@rotType, &Wx::wxCB_READONLY );
#
#	my $pnlRotPage = Wx::Panel->new($placementRotPage->GetParent());
#	my $szRotPage = Wx::BoxSizer->new(&Wx::wxVERTICAL);
#	
#	
#	
#	#my $rotTypeCb = Wx::ComboBox->new( $pnlRotPage, -1, $rotType[0], &Wx::wxDefaultPosition, [ -1, -1 ], \@rotType );
	my $rotTypeCb = Wx::ComboBox->new( $placementRotPage->GetParent(), -1, "", &Wx::wxDefaultPosition, [ -1, -1 ] );
	
	#$pnlRotPage->SetSizer($szRotPage);
	
	
	#$szRotPage->Add( $rotTypeCb, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	#$szRotPage->Add(  Wx::TextCtrl->new( $pnlRotPage, -1, $rotType[0], &Wx::wxDefaultPosition, [ -1, -1 ] ) ,0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	

	my @pattType = (
					 PnlClassEnums->PnlClassPattern_NO_PATTERN,     PnlClassEnums->PnlClassPattern_ALTERNATE_ROW,
					 PnlClassEnums->PnlClassPattern_ALTERNATE_COL, PnlClassEnums->PnlClassPattern_ALTERNATE_ROW_COL,
					 PnlClassEnums->PnlClassPattern_TOP_HALF,      PnlClassEnums->PnlClassPattern_BOTTOM_HALF,
					 PnlClassEnums->PnlClassPattern_RIGHT_HALF,    PnlClassEnums->PnlClassPattern_LEFT_HALF
	);

	#my $pattTypeCb = Wx::ComboBox->new( $allPage->GetParent(), -1, $rotType[0], &Wx::wxDefaultPosition, [ 50, 25 ], \@rotType, &Wx::wxCB_READONLY );

	#my $pattTypeCb = Wx::BitmapComboBox->new( $placementPattPage->GetParent(), -1, $pattType[0], &Wx::wxDefaultPosition, [ 50, 25 ],  \@pattType, );
	my $pattTypeCb =
	  Wx::ComboBox->new( $placementPattPage->GetParent(), -1, $pattType[0], &Wx::wxDefaultPosition, [ -1, -1 ], \@pattType, &Wx::wxCB_READONLY );

	$placementRotPage->AddContent($rotTypeCb);
 

	$placementPattPage->AddContent($pattTypeCb);

	$notebook->ShowPage(1);

	# Row 2

	my $interlockTxt = Wx::StaticText->new( $statBox, -1, "Interlock:", &Wx::wxDefaultPosition, [ 70, 25 ] );
	my @interlockType = ( PnlClassEnums->PnlClassInterlock_NONE, PnlClassEnums->PnlClassInterlock_SIMPLE, PnlClassEnums->PnlClassInterlock_SLIDING );
	my $interlockCb =
	  Wx::ComboBox->new( $statBox, -1, $interlockType[0], &Wx::wxDefaultPosition, [ 50, 25 ], \@interlockType, &Wx::wxCB_READONLY );

	# SET EVENTS
	Wx::Event::EVT_RADIOBUTTON( $rbPlacementRot,  -1, sub { $notebook->ShowPage(1) } );
	Wx::Event::EVT_RADIOBUTTON( $rbPlacementPatt, -1, sub { $notebook->ShowPage(2) } );

	# BUILD STRUCTURE OF LAYOUT
	$szRow1Col1->Add( $rbPlacementRot,  1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1Col1->Add( $rbPlacementPatt, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow1Col2->Add( $notebook, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow1->Add( $szRow1Col1, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $szRow1Col2, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow2->Add( $interlockTxt, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $interlockCb,  1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szStatBox->Add( $szRow1, 1, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );

	# save control references
	$self->{"rotTypeCb"}         = $rotTypeCb;
	$self->{"pattTypeCb"}        = $pattTypeCb;
	$self->{"rbPlacementRot"}    = $rbPlacementRot;
	$self->{"rbPlacementPatt"}   = $rbPlacementPatt;
	$self->{"interlockCb"}       = $interlockCb;
	$self->{"notebookPlacement"} = $notebook;

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

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $spaceXTxt = Wx::StaticText->new( $statBox, -1, "Space X:", &Wx::wxDefaultPosition, [ 70, 25 ] );
	my $spaceXValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 70, 25 ] );

	my $spaceYTxt = Wx::StaticText->new( $statBox, -1, "Space Y", &Wx::wxDefaultPosition, [ 70, 25 ] );
	my $spaceYValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 70, 25 ] );

	my $spacingTypeTxt = Wx::StaticText->new( $statBox, -1, "Space Y", &Wx::wxDefaultPosition, [ 70, 25 ] );
	my @spacingType = ( PnlClassEnums->PnlClassSpacingAlign_KEEP_IN_CENTER, PnlClassEnums->PnlClassSpacingAlign_SPACE_EVENLY );
	my $spacingTypeCb =
	  Wx::ComboBox->new( $statBox, -1, $spacingType[0], &Wx::wxDefaultPosition, [ 50, 25 ], \@spacingType, &Wx::wxCB_READONLY );

	# DEFINE EVENTS

	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $spaceXTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $spaceXValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow2->Add( $spaceYTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $spaceYValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow3->Add( $spacingTypeTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow3->Add( $spacingTypeCb,  0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRow3, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# save control references

	$self->{"spaceXValTxt"}  = $spaceXValTxt;
	$self->{"spaceYValTxt"}  = $spaceXValTxt;
	$self->{"spacingTypeCb"} = $spacingTypeCb;

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

	my $exactValTxt = Wx::TextCtrl->new( $amountExactPage->GetParent(), -1, "", &Wx::wxDefaultPosition, [ 70, 25 ] );
	my $maxValTxt   = Wx::TextCtrl->new( $amountMaxPage->GetParent(),   -1, "", &Wx::wxDefaultPosition, [ 70, 25 ] );

	$amountExactPage->AddContent($exactValTxt);
	$amountMaxPage->AddContent($maxValTxt);

	#$placementPattPage->AddContent($pattTypeCb);

	$notebook->ShowPage(1);

	# DEFINE EVENTS
	Wx::Event::EVT_RADIOBUTTON( $rbAmountExact, -1, sub { $notebook->ShowPage(1) } );
	Wx::Event::EVT_RADIOBUTTON( $rbAmountMax,   -1, sub { $notebook->ShowPage(2) } );
	Wx::Event::EVT_RADIOBUTTON( $rbAmountAuto,  -1, sub { $notebook->ShowPage(3) } );

	#	Wx::Event::EVT_TEXT( $leftValTxt,  -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	#	Wx::Event::EVT_TEXT( $rightValTxt, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	#	Wx::Event::EVT_TEXT( $topValTxt,   -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	#	Wx::Event::EVT_TEXT( $botValTxt,   -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	# BUILD STRUCTURE OF LAYOUT
	$szRow1Col1->Add( $rbAmountExact, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1Col1->Add( $rbAmountMax,   0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1Col1->Add( $rbAmountAuto,  0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow1Col2->Add( $notebook, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow1->Add( $szRow1Col1, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $szRow1Col2, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szStatBox->Add( $szRow1, 1, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );

	#$szStatBox->Add( $szRow2, 1, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	# save control references

	$self->{"rbAmountExact"}  = $rbAmountExact;
	$self->{"rbAmountMax"}    = $rbAmountMax;
	$self->{"rbAmountAuto"}   = $rbAmountAuto;
	$self->{"notebookAmount"} = $notebook;

	$self->{"exactValTxt"} = $exactValTxt;
	$self->{"maxValTxt"}   = $maxValTxt;

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

	my $rbPlacementAuto = Wx::RadioButton->new( $statBox, -1, "Auto Best", &Wx::wxDefaultPosition, &Wx::wxDefaultSize, &Wx::wxRB_GROUP );
	my $rbPlacementManual = Wx::RadioButton->new( $statBox, -1, "Manual pick", &Wx::wxDefaultPosition, &Wx::wxDefaultSize );

	my $notebook = CustomNotebook->new( $statBox, -1 );
	my $placementAutoPage   = $notebook->AddPage( 1, 0 );
	my $placementManualPage = $notebook->AddPage( 2, 0 );

	my $szManual        = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $manualPlacBtn   = Wx::Button->new( $placementManualPage->GetParent(), -1, "Prepare", &Wx::wxDefaultPosition, [ 40, 22 ] );
	my $manualIndicator = ResultIndicator->new( $placementManualPage->GetParent(), 20 );

	$szManual->Add( $manualPlacBtn,   1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szManual->Add( $manualIndicator, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$placementManualPage->AddContent($szManual);

	my $minUtilTxt = Wx::StaticText->new( $statBox, -1, "Min utilization:", &Wx::wxDefaultPosition, [ 70, 25 ] );
	my $minUtilValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 70, 25 ] );

	$notebook->ShowPage(1);

	# DEFINE EVENTS
	Wx::Event::EVT_RADIOBUTTON( $rbPlacementAuto,   -1, sub { $notebook->ShowPage(1) } );
	Wx::Event::EVT_RADIOBUTTON( $rbPlacementManual, -1, sub { $notebook->ShowPage(2) } );

	#	Wx::Event::EVT_TEXT( $leftValTxt,  -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	#	Wx::Event::EVT_TEXT( $rightValTxt, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	#	Wx::Event::EVT_TEXT( $topValTxt,   -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	#	Wx::Event::EVT_TEXT( $botValTxt,   -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	# BUILD STRUCTURE OF LAYOUT

	$szRow1->Add( $minUtilTxt,    1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $minUtilValTxt, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow2->Add( $szRow2Col1, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $szRow2Col2, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow2Col1->Add( $rbPlacementAuto,   1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow2Col1->Add( $rbPlacementManual, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow2Col2->Add( $notebook, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szStatBox->Add( $szRow1, 1, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	$szStatBox->Add( $szRow2, 1, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );

	#$szStatBox->Add( $szRow2, 1, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	# save control references

	$self->{"minUtilValTxt"}     = $minUtilValTxt;
	$self->{"rbPlacementAuto"}   = $rbPlacementAuto;
	$self->{"rbPlacementManual"} = $rbPlacementManual;
	$self->{"manualPlacBtn"}     = $manualPlacBtn;
	$self->{"manualIndicator"}   = $manualIndicator;
	$self->{"notebookCreatePnl"} = $notebook;

	return $szStatBox;
}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

sub SetPCBStep {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"pcbStepValTxt"} = $val;

}

sub GetPCBStep {
	my $self = shift;

	return $self->{"settings"}->{"pcbStepValTxt"};

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
		$val = PnlClassEnums->StepPlacement_PATTERN;
	}
	else {

		die "Wrong placement type";
	}

	return $val;

}

sub SetRotationType {
	my $self = shift;
	my $val  = shift;

	$self->{"rotTypeCb"}->SetValue($val);
}

sub GetRotationType {
	my $self = shift;

	return $self->{"rotTypeCb"}->GetValue();
}

sub SetPatternType {
	my $self = shift;
	my $val  = shift;

	$self->{"pattTypeCb"}->SetValue($val);
}

sub GetPatternType {
	my $self = shift;

	return $self->{"pattTypeCb"}->GetValue();
}

sub SetInterlockType {
	my $self = shift;
	my $val  = shift;

	$self->{"interlockCb"}->SetValue($val);
}

sub GetInterlockType {
	my $self = shift;

	return $self->{"interlockCb"}->GetValue();
}

# Space settings

sub SetSpaceX {
	my $self = shift;
	my $val  = shift;

	$self->{"spaceXValTxt"}->SetValue($val)

}

sub GetSpaceX {
	my $self = shift;

	return $self->{"spaceXValTxt"}->GetValue();

}

sub SetSpaceY {
	my $self = shift;
	my $val  = shift;

	$self->{"spaceYValTxt"}->SetValue($val);
}

sub GetSpaceY {
	my $self = shift;

	return $self->{"spaceYValTxt"}->GetValue();
}

sub SetAlignType {
	my $self = shift;
	my $val  = shift;

	$self->{"spacingTypeCb"}->SetValue($val);

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

	if ( $self->{"rbPlacementAuto"}->GetValue() ) {

		$val = PnlCreEnums->StepPlacementMode_AUTO;
		$self->{"notebookCreatePnl"}->ShowPage(1);
	}
	elsif ( $self->{"rbPlacementManual"}->GetValue() ) {
		$val = PnlCreEnums->StepPlacementMode_MANUAL;
		$self->{"notebookCreatePnl"}->ShowPage(2);
	}

	else {

		die "Wrong action type: $val";
	}

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

sub SetJSONStepPlacement {
	my $self = shift;
	my $val  = shift;

	$self->{" JSONStepPlacement "} = $val;

}

sub GetJSONStepPlacement {
	my $self = shift;

	return $self->{" JSONStepPlacement "};

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

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, " f13610 " );
#
#	$test->MainLoop();

1;

