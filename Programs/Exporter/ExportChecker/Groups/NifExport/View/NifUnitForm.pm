#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
use Wx;

package Programs::Exporter::ExportChecker::Groups::NifExport::View::NifUnitForm;
use base qw(Wx::Panel);

use Class::Interface;
&implements('Programs::Exporter::ExportChecker::Groups::IUnitForm');

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'CamHelpers::CamLayer';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::View::NifColorCb';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifHelper';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::View::QuickNoteFrm::QuickNoteFrm';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::View::MarkingFrm::MarkingList';
use aliased 'Helpers::ValueConvertor';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;

	my $inCAM       = shift;
	my $jobId       = shift;
	my $defaultInfo = shift;

	my $self = $class->SUPER::new($parent);

	bless($self);

	$self->{"inCAM"}       = $inCAM;
	$self->{"jobId"}       = $jobId;
	$self->{"defaultInfo"} = $defaultInfo;

	#$self->Disable();

	#$self->SetBackgroundColour($Widgets::Style::clrLightBlue);

	# PROPERTIES

	# NIF values passed other group
	$self->{'tentingProp'}     = undef;    # store information about tenting
	$self->{'technologyProp'}  = undef;    # store information about tenting
	$self->{"jumpScoringProp"} = undef;    # store information about tenting

	$self->__SetLayout();

	# EVENTS
	$self->{'onTentingChange'}    = Event->new();
	$self->{'onTechnologyChange'} = Event->new();

	return $self;
}

#sub Init{
#	my $self = shift;
#	my $parent = shift;
#
#	$self->Reparent($parent);
#
#	$self->__SetLayout();
#
#	$self->__SetName();
#}

#sub __SetHeight {
#	my $self = shift;
#	my $height = shift;
#
#	$self->{"groupHeight"} = $height;
#
#}

sub __SetLayout {
	my $self = shift;

	#define panels

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	#my $szRow0 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	#my $settingsStatBox  = $self->__SetGroup1($self);
	#my $settingsStatBox2  = $self->__SetGroup2($self);

	my $settingsStatBox  = $self->__SetLayoutSettings($self);
	my $dimensionStatBox = $self->__SetLayoutDimension($self);
	my $noteStatBox      = $self->__SetLayoutNote($self);

	#$richTxt->Layout();

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	#$szMain->Add( $szStatBox, 0, &Wx::wxEXPAND );

	# BUILD STRUCTURE OF LAYOUT

	$szRow1->Add( $settingsStatBox, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	#$szRow1->Add( $settingsStatBox,  70, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	#$szRow1->Add( $settingsStatBox2,  30, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow2->Add( $noteStatBox,      1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $dimensionStatBox, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	#$szMain->Add( $szRow0, 1, &Wx::wxEXPAND );
	$szMain->Add( $szRow1, 0, &Wx::wxEXPAND );
	$szMain->Add( $szRow2, 1, &Wx::wxEXPAND );

	$self->SetSizer($szMain);

	# save control references

}

sub __SetLayoutSettings {
	my $self   = shift;
	my $parent = shift;

	my @maskColor = NifHelper->GetPcbMaskColors();
	push( @maskColor, "" );
	my @flexMaskColor = ( "", "GreenUVFlex" );

	my @silkColor = NifHelper->GetPcbSilkColors();
	push( @silkColor, "" );

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	my $szCol1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szCol2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szCol3 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szCol4 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS
	my $textWidth = 110;
	my $cbWidth   = 55;

	my $maskaChb        = Wx::CheckBox->new( $statBox, -1, "Mask 100µm",      &Wx::wxDefaultPosition, [ $textWidth, 20 ] );
	my $pressfitChb     = Wx::CheckBox->new( $statBox, -1, "Pressfit (Plt)",   &Wx::wxDefaultPosition, [ $textWidth, 20 ] );
	my $tolMeasureChb   = Wx::CheckBox->new( $statBox, -1, "Tolerance (NPlt)", &Wx::wxDefaultPosition, [ $textWidth, 20 ] );
	my $chamferEdgesChb = Wx::CheckBox->new( $statBox, -1, "Chamfer edge",     &Wx::wxDefaultPosition, [ $textWidth, 20 ] );

	# standard layers
	my @markingL = ();

	foreach my $l ( $self->{"defaultInfo"}->GetBoardBaseLayers() ) {

		if (    $l->{"gROWlayer_type"} =~ /solder_mask/i
			 || $l->{"gROWlayer_type"} =~ /silk_screen/i
			 || ( $l->{"gROWlayer_type"} =~ /signal/i && $l->{"gROWname"} !~ /v/i ) )
		{
			push( @markingL, $l->{"gROWname"} );
		}
	}

	my $markingFrm = MarkingList->new( $statBox, \@markingL );

	my $silkTop2Cb    = NifColorCb->new( $statBox, $self->{"inCAM"}, $self->{"jobId"}, "Silk top 2",    \@silkColor );
	my $silkTopCb     = NifColorCb->new( $statBox, $self->{"inCAM"}, $self->{"jobId"}, "Silk top",      \@silkColor );
	my $maskTopBendCb = NifColorCb->new( $statBox, $self->{"inCAM"}, $self->{"jobId"}, "Mask top flex", \@flexMaskColor );
	my $maskTopCb     = NifColorCb->new( $statBox, $self->{"inCAM"}, $self->{"jobId"}, "Mask top",      \@maskColor );
	my $maskBotCb     = NifColorCb->new( $statBox, $self->{"inCAM"}, $self->{"jobId"}, "Mask bot",      \@maskColor );
	my $maskBotBendCb = NifColorCb->new( $statBox, $self->{"inCAM"}, $self->{"jobId"}, "Mask bot flex", \@flexMaskColor );
	my $silkBotCb     = NifColorCb->new( $statBox, $self->{"inCAM"}, $self->{"jobId"}, "Silk bot",      \@silkColor );
	my $silkBot2Cb    = NifColorCb->new( $statBox, $self->{"inCAM"}, $self->{"jobId"}, "Silk bot 2",    \@silkColor );

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szCol1->Add( $maskaChb,        0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol1->Add( $pressfitChb,     0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol1->Add( $tolMeasureChb,   0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol1->Add( $chamferEdgesChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szCol2->Add( $markingFrm, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szCol4->Add( $silkTop2Cb,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol4->Add( $silkTopCb,     0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol4->Add( $maskTopBendCb, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol4->Add( $maskTopCb,     0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol4->Add( $maskBotCb,     0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol4->Add( $maskBotBendCb, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol4->Add( $silkBotCb,     0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol4->Add( $silkBot2Cb,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	#$szRow1->Add( 10,         10, 1,         &Wx::wxGROW );    #expander

	$szStatBox->Add( $szCol1, 0, &Wx::wxEXPAND | &Wx::wxLEFT, );
	$szStatBox->Add( $szCol2, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 10 );
	$szStatBox->Add( 1,       0, 1 );                                 # Expander
	                                                                  #$szStatBox->Add( $szCol3, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 2 );
	$szStatBox->Add( $szCol4, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 20 );

	# Set References

	$self->{"maskaChb"}        = $maskaChb;
	$self->{"pressfitChb"}     = $pressfitChb;
	$self->{"tolMeasureChb"}   = $tolMeasureChb;
	$self->{"chamferEdgesChb"} = $chamferEdgesChb;

	$self->{"markingFrm"} = $markingFrm;

	$self->{"silkTop2Cb"}    = $silkTop2Cb;
	$self->{"silkTopCb"}     = $silkTopCb;
	$self->{"maskTopBendCb"} = $maskTopBendCb;
	$self->{"maskTopCb"}     = $maskTopCb;
	$self->{"maskBotCb"}     = $maskBotCb;
	$self->{"maskBotBendCb"} = $maskBotBendCb;
	$self->{"silkBotCb"}     = $silkBotCb;
	$self->{"silkBot2Cb"}    = $silkBot2Cb;

	return $szStatBox;

}

# Set layout for Quick set box
sub __SetLayoutNote {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Notes' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# Load data, for filling form by values

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szRow5 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $noteTextTxt  = Wx::StaticText->new( $statBox, -1, "Text",        &Wx::wxDefaultPosition, [ -1, 20 ] );
	my $quickNoteTxt = Wx::StaticText->new( $statBox, -1, "Quick notes", &Wx::wxDefaultPosition, [ -1, 20 ] );
	my $btnSet = Wx::Button->new( $statBox, -1, "Set", &Wx::wxDefaultPosition, [ 40, 22 ] );

	$self->{'quickNoteFrm'} = QuickNoteFrm->new($self);

	my $richTxt = Wx::RichTextCtrl->new( $statBox, -1, 'Notes', &Wx::wxDefaultPosition, [ -1, -1 ], &Wx::wxRE_MULTILINE | &Wx::wxWANTS_CHARS );
	$richTxt->SetEditable(1);
	$richTxt->SetBackgroundColour($Widgets::Style::clrWhite);

	# DEFINE EVENTS
	Wx::Event::EVT_BUTTON( $btnSet, -1, sub { $self->__QuickNotesClick(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $noteTextTxt,  1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $quickNoteTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( 10, 10, 0 );
	$szRow1->Add( $btnSet, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szStatBox->Add( $szRow1,  0, &Wx::wxEXPAND );
	$szStatBox->Add( $richTxt, 1, &Wx::wxEXPAND );

	# save control references
	$self->{"richTxt"} = $richTxt;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutDimension {
	my $self   = shift;
	my $parent = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Panelisation' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	#my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# Load data, for filling form by values

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow4 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow5 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szRow5 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $typeTxt = Wx::StaticText->new( $statBox, -1, "Type:", &Wx::wxDefaultPosition, [ 50, 20 ] );

	my $custPnlExist = $self->{"defaultInfo"}->GetJobAttrByName("customer_panel");    # zakaznicky panel
	my $custSetExist = $self->{"defaultInfo"}->GetJobAttrByName("customer_set");      # zakaznicke sady

	my $type = "Standard";
	if ( $custPnlExist eq "yes" ) {
		$type = "Customer panel";
	}
	elsif ( $custSetExist eq "yes" ) {
		$type = "Customer set";
	}

	my $typeValTxt = Wx::StaticText->new( $statBox, -1, $type, &Wx::wxDefaultPosition, [ 100, 20 ] );

	my $singlexTxt = Wx::StaticText->new( $statBox, -1, "Single X:", &Wx::wxDefaultPosition, [ 50, 20 ] );
	my $singleyTxt = Wx::StaticText->new( $statBox, -1, "Y:",        &Wx::wxDefaultPosition, [ 20, 20 ] );

	my $singlexValTxt = Wx::StaticText->new( $statBox, -1, "0.0", &Wx::wxDefaultPosition, [ 40, 20 ] );
	my $singleyValTxt = Wx::StaticText->new( $statBox, -1, "0.0", &Wx::wxDefaultPosition, [ 40, 20 ] );

	my $panelxTxt = Wx::StaticText->new( $statBox, -1, "Panel  X:", &Wx::wxDefaultPosition, [ 50, 20 ] );
	my $panelyTxt = Wx::StaticText->new( $statBox, -1, "Y:",        &Wx::wxDefaultPosition, [ 20, 20 ] );

	my $panelxValTxt = Wx::StaticText->new( $statBox, -1, "0.0", &Wx::wxDefaultPosition, [ 40, 20 ] );
	my $panelyValTxt = Wx::StaticText->new( $statBox, -1, "0.0", &Wx::wxDefaultPosition, [ 40, 20 ] );

	my $nasobnostPanelTxt = Wx::StaticText->new( $statBox, -1, "Multiplicity panel:", &Wx::wxDefaultPosition, [ 100, 20 ] );
	my $nasobnostPanelValTxt = Wx::StaticText->new( $statBox, -1, "0.0", &Wx::wxDefaultPosition, [ 40, 20 ] );

	my $nasobnostTxt    = Wx::StaticText->new( $statBox, -1, "Multiplicity:", &Wx::wxDefaultPosition, [ 100, 20 ] );
	my $nasobnostValTxt = Wx::StaticText->new( $statBox, -1, "0.0",           &Wx::wxDefaultPosition, [ 40,  20 ] );

	# BUILD STRUCTURE OF LAYOUT

	$szRow1->Add( $typeTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1->Add( $typeValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow2->Add( $singlexTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow2->Add( $singlexValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow2->Add( $singleyTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow2->Add( $singleyValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow3->Add( $panelxTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow3->Add( $panelxValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow3->Add( $panelyTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow3->Add( $panelyValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow4->Add( $nasobnostPanelTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow4->Add( $nasobnostPanelValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow5->Add( $nasobnostTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow5->Add( $nasobnostValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND );
	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND );
	$szStatBox->Add( $szRow3, 0, &Wx::wxEXPAND );
	$szStatBox->Add( $szRow4, 0, &Wx::wxEXPAND );
	$szStatBox->Add( $szRow5, 0, &Wx::wxEXPAND );

	# save control references
	$self->{"singlexValTxt"}        = $singlexValTxt;
	$self->{"singleyValTxt"}        = $singleyValTxt;
	$self->{"panelxValTxt"}         = $panelxValTxt;
	$self->{"panelyValTxt"}         = $panelyValTxt;
	$self->{"nasobnostPanelValTxt"} = $nasobnostPanelValTxt;
	$self->{"nasobnostValTxt"}      = $nasobnostValTxt;

	return $szStatBox;
}

sub __QuickNotesClick {
	my $self = shift;

	$self->{'quickNoteFrm'}->{"mainFrm"}->CentreOnParent(&Wx::wxBOTH);
	$self->{'quickNoteFrm'}->{"mainFrm"}->Show();
}

# =====================================================================
# HANDLERS CONTROLS
# =====================================================================
sub OnPREGroupTentingChangeHandler {
	my $self = shift;
	my $val  = shift;

	$self->{'tentingProp'} = $val;
}

sub OnPREGroupTechnologyChangeHandler {
	my $self = shift;
	my $val  = shift;

	$self->{'technologyProp'} = $val;
}

sub OnSCOGroupChangeCustomerJump {
	my $self          = shift;
	my $isJumpscoring = shift;

	$self->{"jumpScoringProp"} = $isJumpscoring;
}

# =====================================================================
# DISABLING CONTROLS
# =====================================================================

sub DisableControls {
	my $self = shift;

	# Disable layer in marking form
	my @allBaseL = $self->{"defaultInfo"}->GetBoardBaseLayers();
	$self->{"markingFrm"}->DisableControls( \@allBaseL );

	# Show/hide special solder mask and silk screen
	$self->{"silkTop2Cb"}->Hide()    unless ( $self->{"defaultInfo"}->LayerExist("pc2") );
	$self->{"silkTop2Cb"}->Hide()    unless ( $self->{"defaultInfo"}->LayerExist("pc2") );
	$self->{"silkBot2Cb"}->Hide()    unless ( $self->{"defaultInfo"}->LayerExist("ps2") );
	$self->{"maskTopBendCb"}->Hide() unless ( $self->{"defaultInfo"}->LayerExist("mcflex") );
	$self->{"maskBotBendCb"}->Hide() unless ( $self->{"defaultInfo"}->LayerExist("msflex") );

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

# Dimension ========================================================

# single_x
sub SetSingle_x {
	my $self  = shift;
	my $value = shift;
	$self->{"singlexValTxt"}->SetLabel($value);
}

sub GetSingle_x {
	my $self = shift;
	return $self->{"singlexValTxt"}->GetLabel();
}

# single_y
sub SetSingle_y {
	my $self  = shift;
	my $value = shift;
	$self->{"singleyValTxt"}->SetLabel($value);
}

sub GetSingle_y {
	my $self = shift;
	return $self->{"singleyValTxt"}->GetLabel();
}

# panel_x
sub SetPanel_x {
	my $self  = shift;
	my $value = shift;
	$self->{"panelxValTxt"}->SetLabel($value);
}

sub GetPanel_x {
	my $self = shift;
	return $self->{"panelxValTxt"}->GetLabel();
}

# panel_y
sub SetPanel_y {
	my $self  = shift;
	my $value = shift;
	$self->{"panelyValTxt"}->SetLabel($value);
}

sub GetPanel_y {
	my $self = shift;
	return $self->{"panelyValTxt"}->GetLabel();
}

# nasobnost_panelu
sub SetNasobnost_panelu {
	my $self  = shift;
	my $value = shift;
	$self->{"nasobnostPanelValTxt"}->SetLabel($value);
}

sub GetNasobnost_panelu {
	my $self = shift;
	return $self->{"nasobnostPanelValTxt"}->GetLabel();
}

# nasobnost
sub SetNasobnost {
	my $self  = shift;
	my $value = shift;
	$self->{"nasobnostValTxt"}->SetLabel($value);
}

sub GetNasobnost {
	my $self = shift;
	return $self->{"nasobnostValTxt"}->GetLabel();
}

# MASK, SILK color ========================================================

# c_mask_colour
sub SetFlexi_maska {
	my $self  = shift;
	my $value = shift;

	$self->{"maskTopBendCb"}->SetValue("");
	$self->{"maskBotBendCb"}->SetValue("");

	if ( $value =~ /^c$/i ) {
		$self->{"maskTopBendCb"}->SetValue("GreenUVFlex");
	}

	if ( $value =~ /^s$/i ) {
		$self->{"maskBotBendCb"}->SetValue("GreenUVFlex");
	}

	if ( $value =~ /^2$/i ) {
		$self->{"maskTopBendCb"}->SetValue("GreenUVFlex");
		$self->{"maskBotBendCb"}->SetValue("GreenUVFlex");
	}
}

sub GetFlexi_maska {
	my $self = shift;

	my $top = $self->{"maskTopBendCb"}->GetValue();
	my $bot = $self->{"maskBotBendCb"}->GetValue();

	$top = defined $top && $top ne "" ? 1 : 0;
	$bot = defined $bot && $bot ne "" ? 1 : 0;

	my $value = "";    #

	if ( $top && !$bot ) {
		$value = "C";

	}
	elsif ( !$top && $bot ) {
		$value = "S";
	}
	elsif ( $top && $bot ) {
		$value = "2";
	}

	return $value;
}

# c_mask_colour
sub SetC_mask_colour {
	my $self  = shift;
	my $value = shift;

	my $color = ValueConvertor->GetMaskCodeToColor($value);
	$self->{"maskTopCb"}->SetValue($color);
}

sub GetC_mask_colour {
	my $self  = shift;
	my $color = $self->{"maskTopCb"}->GetValue();
	return ValueConvertor->GetMaskColorToCode($color);
}

# s_mask_colour
sub SetS_mask_colour {
	my $self  = shift;
	my $value = shift;

	my $color = ValueConvertor->GetMaskCodeToColor($value);
	$self->{"maskBotCb"}->SetValue($color);
}

sub GetS_mask_colour {
	my $self  = shift;
	my $color = $self->{"maskBotCb"}->GetValue();
	return ValueConvertor->GetMaskColorToCode($color);
}

# Potisk_c_2
sub SetC_silk_screen_colour2 {
	my $self  = shift;
	my $value = shift;

	my $color = ValueConvertor->GetSilkCodeToColor($value);
	$self->{"silkTop2Cb"}->SetValue($color);
}

sub GetC_silk_screen_colour2 {
	my $self  = shift;
	my $color = $self->{"silkTop2Cb"}->GetValue();
	return ValueConvertor->GetSilkColorToCode($color);
}

sub SetS_silk_screen_colour2 {
	my $self  = shift;
	my $value = shift;

	my $color = ValueConvertor->GetSilkCodeToColor($value);
	$self->{"silkBot2Cb"}->SetValue($color);
}

sub GetS_silk_screen_colour2 {
	my $self  = shift;
	my $color = $self->{"silkBot2Cb"}->GetValue();
	return ValueConvertor->GetSilkColorToCode($color);
}

# c_silk_screen_colour
sub SetC_silk_screen_colour {
	my $self  = shift;
	my $value = shift;

	my $color = ValueConvertor->GetSilkCodeToColor($value);
	$self->{"silkTopCb"}->SetValue($color);
}

sub GetC_silk_screen_colour {
	my $self  = shift;
	my $color = $self->{"silkTopCb"}->GetValue();
	return ValueConvertor->GetSilkColorToCode($color);
}

sub SetS_silk_screen_colour {
	my $self  = shift;
	my $value = shift;

	my $color = ValueConvertor->GetSilkCodeToColor($value);
	$self->{"silkBotCb"}->SetValue($color);
}

sub GetS_silk_screen_colour {
	my $self  = shift;
	my $color = $self->{"silkBotCb"}->GetValue();
	return ValueConvertor->GetSilkColorToCode($color);
}

sub SetTenting {
	my $self  = shift;
	my $value = shift;

	$self->{"tentingProp"} = $value;
}

sub GetTenting {
	my $self = shift;

	return $self->{"tentingProp"};
}

sub SetTechnology {
	my $self  = shift;
	my $value = shift;

	$self->{"technologyProp"} = $value;
}

sub GetTechnology {
	my $self = shift;

	return $self->{"technologyProp"};
}

sub SetMaska01 {
	my $self  = shift;
	my $value = shift;
	$self->{"maskaChb"}->SetValue($value);
}

sub GetMaska01 {
	my $self = shift;
	return $self->{"maskaChb"}->GetValue();
}

sub SetPressfit {
	my $self  = shift;
	my $value = shift;

	$self->{"pressfitChb"}->SetValue($value);
}

sub GetPressfit {
	my $self = shift;
	return $self->{"pressfitChb"}->GetValue();
}

sub SetToleranceHole {
	my $self  = shift;
	my $value = shift;

	$self->{"tolMeasureChb"}->SetValue($value);
}

sub GetToleranceHole {
	my $self = shift;
	return $self->{"tolMeasureChb"}->GetValue();
}

# Chamfer edges
sub SetChamferEdges {
	my $self  = shift;
	my $value = shift;

	$self->{"chamferEdgesChb"}->SetValue($value);
}

sub GetChamferEdges {
	my $self = shift;
	return $self->{"chamferEdgesChb"}->GetValue();
}

sub SetNotes {
	my $self  = shift;
	my $value = shift;
	$self->{"richTxt"}->Clear();

	# Temporary set ypracovano v Incamu

	unless ( $value =~ /Zpracovano v InCAMu/i ) {
		$value = "Zpracovano v InCAMu. " . $value;
	}

	if ( $value && $value ne "" ) {

		# Remove duplicate notes (quick note could be already in IS)
		my $notes = $self->{"quickNoteFrm"}->GetNotesData();

		foreach my $text ( map { $_->{"text"} } @{$notes} ) {

			$value =~ s/$text//g;
		}

		$value =~ s/;/\n/g;

		$self->{"richTxt"}->WriteText($value);
	}

}

sub GetNotes {
	my $self = shift;

	my $notes = $self->{"richTxt"}->GetValue();

	$notes =~ s/\n/;/g;

	return $notes;
}

sub SetQuickNotes {
	my $self  = shift;
	my $value = shift;

	$self->{"quickNoteFrm"}->SetNotesData($value);

}

sub GetQuickNotes {
	my $self = shift;

	return $self->{"quickNoteFrm"}->GetNotesData();

}

sub SetDatacode {
	my $self  = shift;
	my $value = shift;

	$self->{"markingFrm"}->SetDataCode($value);
}

sub GetDatacode {
	my $self = shift;

	return $self->{"markingFrm"}->GetDataCode();
}

sub SetUlLogo {
	my $self  = shift;
	my $value = shift;

	$self->{"markingFrm"}->SetUlLogo($value);
}

sub GetUlLogo {
	my $self = shift;

	return $self->{"markingFrm"}->GetUlLogo();
}

sub SetJumpScoring {
	my $self  = shift;
	my $value = shift;

	$self->{"jumpScoringProp"} = $value;

}

sub GetJumpScoring {
	my $self = shift;

	return $self->{"jumpScoringProp"};

}

1;
