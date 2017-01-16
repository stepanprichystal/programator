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
use aliased 'Helpers::ValueConvertor';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;

	my $inCAM = shift;
	my $jobId = shift;

	my $self = $class->SUPER::new($parent);

	bless($self);

	$self->{"inCAM"} = $inCAM;
	$self->{"jobId"} = $jobId;


	

	 

	#$self->Disable();

	#$self->SetBackgroundColour($Widgets::Style::clrLightBlue);

	# PROPERTIES
	
	$self->{'quickNoteFrm'} = undef; # window where quick notes are showed
	$self->{'jumpScoringProp'} = undef; # store information about cust jumpscoring
	
	$self->__SetLayout();
	
	
	# EVENTS
	$self->{'onTentingChange'} = Event->new();

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
	my $noteStatBox = $self->__SetLayoutNote($self);
	
	 
	#$richTxt->Layout();

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	#$szMain->Add( $szStatBox, 0, &Wx::wxEXPAND );

	# BUILD STRUCTURE OF LAYOUT

	$szRow1->Add( $settingsStatBox,  1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	

	#$szRow1->Add( $settingsStatBox,  70, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	#$szRow1->Add( $settingsStatBox2,  30, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow2->Add( $noteStatBox, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
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

	my @markingLayer = CamLayer->GetMarkingLayers( $self->{"inCAM"}, $self->{"jobId"} );
	my @markingLNames = map { uc( $_->{"gROWname"} ) } @markingLayer;
	push( @markingLNames, "" );

	my @maskColor = NifHelper->GetPcbMaskColors();
	push( @maskColor, "" );

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
	my $textWidth = 90;
	my $cbWidth   = 55;

	my $tentingChb     = Wx::CheckBox->new( $statBox, -1, "Tenting (c,s)",      &Wx::wxDefaultPosition, [ $textWidth, 20 ] );
	my $maskaChb       = Wx::CheckBox->new( $statBox, -1, "Mask 100µm",  &Wx::wxDefaultPosition, [ $textWidth, 20 ] );
	my $pressfitChb    = Wx::CheckBox->new( $statBox, -1, "Pressfit",     &Wx::wxDefaultPosition, [ $textWidth, 20 ] );
	#my $jumpscoringChb = Wx::CheckBox->new( $statBox, -1, "Jump scoring", &Wx::wxDefaultPosition, [ $textWidth, 20 ] );

	my $datacodeCb =
	  Wx::ComboBox->new( $statBox, -1, $markingLNames[0], &Wx::wxDefaultPosition, [ $cbWidth, 20 ], \@markingLNames, &Wx::wxCB_READONLY );
	my $ulLogoCb =
	  Wx::ComboBox->new( $statBox, -1, $markingLNames[0], &Wx::wxDefaultPosition, [ $cbWidth, 20 ], \@markingLNames, &Wx::wxCB_READONLY );

	my $datacodeTxt = Wx::StaticText->new( $statBox, -1, "Data code", &Wx::wxDefaultPosition, [ 60, 20 ] );
	my $ulLogoTxt   = Wx::StaticText->new( $statBox, -1, "UL logo",   &Wx::wxDefaultPosition, [ 60, 20 ] );

	my $silkTopCb = NifColorCb->new( $statBox, $self->{"inCAM"}, $self->{"jobId"}, "Silk top",        \@silkColor );
	my $maskTopCb = NifColorCb->new( $statBox, $self->{"inCAM"}, $self->{"jobId"}, "Mask top", \@maskColor );
	my $maskBotCb = NifColorCb->new( $statBox, $self->{"inCAM"}, $self->{"jobId"}, "Mask bot", \@maskColor );
	my $silkBotCb = NifColorCb->new( $statBox, $self->{"inCAM"}, $self->{"jobId"}, "Silk bot",        \@silkColor );

	# SET EVENTS
	Wx::Event::EVT_CHECKBOX( $tentingChb, -1, sub { $self->__OnTentingChangeHandler(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$szCol1->Add( $tentingChb,     0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol1->Add( $maskaChb,       0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol1->Add( $pressfitChb,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	#$szCol1->Add( $jumpscoringChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szCol2->Add( $datacodeTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol2->Add( $ulLogoTxt,   0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szCol3->Add( $datacodeCb, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol3->Add( $ulLogoCb,   0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szCol4->Add( $silkTopCb, 0, &Wx::wxALL,                 1 );
	$szCol4->Add( $maskTopCb, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol4->Add( $maskBotCb, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol4->Add( $silkBotCb, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	#$szRow1->Add( 10,         10, 1,         &Wx::wxGROW );    #expander

	$szStatBox->Add( $szCol1, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 0  );
	$szStatBox->Add( $szCol2, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 40 );
	$szStatBox->Add( $szCol3, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 2 );
	$szStatBox->Add( $szCol4, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 40 );
	
	
	# Set References
	$self->{"tentingChb"} = $tentingChb;
	$self->{"maskaChb"} = $maskaChb;
	$self->{"pressfitChb"} = $pressfitChb;
	#$self->{"jumpscoringChb"} = $jumpscoringChb;
	$self->{"datacodeCb"} = $datacodeCb;
	$self->{"ulLogoCb"} = $ulLogoCb;
	
	$self->{"silkTopCb"} = $silkTopCb;
	$self->{"maskTopCb"} = $maskTopCb;
	$self->{"maskBotCb"} = $maskBotCb;
	$self->{"silkBotCb"} = $silkBotCb;
	

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
 
 	my $noteTextTxt = Wx::StaticText->new( $statBox, -1, "Text", &Wx::wxDefaultPosition, [ -1, 20 ] );
	my $quickNoteTxt = Wx::StaticText->new( $statBox, -1, "Quick notes", &Wx::wxDefaultPosition, [ -1, 20 ] );
 	my $btnSet = Wx::Button->new( $statBox, -1, "Set", &Wx::wxDefaultPosition,  [ 40, 22 ] );
 	
 	$self->{'quickNoteFrm'} = QuickNoteFrm->new($self);
 
 
 
	my $richTxt = Wx::RichTextCtrl->new( $statBox, -1, 'Notes', &Wx::wxDefaultPosition, [ 100, 90 ], &Wx::wxRE_MULTILINE | &Wx::wxWANTS_CHARS );
	$richTxt->SetEditable(1);
	$richTxt->SetBackgroundColour($Widgets::Style::clrWhite);
	
	
	# DEFINE EVENTS
	Wx::Event::EVT_BUTTON( $btnSet, -1, sub { $self->__QuickNotesClick(@_)} );
	

	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $noteTextTxt,    1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $quickNoteTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( 10,10, 0);
	$szRow1->Add( $btnSet,    0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	 

	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND  );
	$szStatBox->Add( $richTxt, 0 , &Wx::wxEXPAND );
	 
	# save control references
	 $self->{"richTxt"} = $richTxt;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutDimension {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Dimension' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	#my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# Load data, for filling form by values

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow4 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szRow5 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $singlexTxt = Wx::StaticText->new( $statBox, -1, "Single X:", &Wx::wxDefaultPosition, [ 50, 20 ] );
	my $singleyTxt = Wx::StaticText->new( $statBox, -1, "Y:",        &Wx::wxDefaultPosition, [ 20, 20 ] );

	my $singlexValTxt = Wx::StaticText->new( $statBox, -1, "0.0" , &Wx::wxDefaultPosition, [ 40, 20 ]);
	my $singleyValTxt = Wx::StaticText->new( $statBox, -1, "0.0" , &Wx::wxDefaultPosition, [ 40, 20 ]);

	my $panelxTxt = Wx::StaticText->new( $statBox, -1, "Panel X:", &Wx::wxDefaultPosition, [ 50, 20 ] );
	my $panelyTxt = Wx::StaticText->new( $statBox, -1, "Y:",       &Wx::wxDefaultPosition, [ 20, 20 ] );

	my $panelxValTxt = Wx::StaticText->new( $statBox, -1, "0.0" , &Wx::wxDefaultPosition, [ 40, 20 ]);
	my $panelyValTxt = Wx::StaticText->new( $statBox, -1, "0.0" , &Wx::wxDefaultPosition, [ 40, 20 ]);

	my $nasobnostPanelTxt = Wx::StaticText->new( $statBox, -1, "Nasobnost panel:", &Wx::wxDefaultPosition, [100, 20 ] );
	my $nasobnostPanelValTxt = Wx::StaticText->new( $statBox, -1, "0.0" , &Wx::wxDefaultPosition, [ 40, 20 ]);

	my $nasobnostTxt = Wx::StaticText->new( $statBox, -1, "Nasobnost:", &Wx::wxDefaultPosition, [ 100, 20 ] );
	my $nasobnostValTxt = Wx::StaticText->new( $statBox, -1, "0.0", &Wx::wxDefaultPosition, [ 40, 20 ] );

	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $singlexTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1->Add( $singlexValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1->Add( $singleyTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1->Add( $singleyValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow2->Add( $panelxTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow2->Add( $panelxValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow2->Add( $panelyTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow2->Add( $panelyValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow3->Add( $nasobnostPanelTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow3->Add( $nasobnostPanelValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow4->Add( $nasobnostTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow4->Add( $nasobnostValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND  );
	$szStatBox->Add( $szRow2, 0 , &Wx::wxEXPAND );
	$szStatBox->Add( $szRow3, 0 , &Wx::wxEXPAND );
	$szStatBox->Add( $szRow4, 0 , &Wx::wxEXPAND );

	# save control references
	$self->{"singlexValTxt"}        = $singlexValTxt;
	$self->{"singleyValTxt"}        = $singleyValTxt;
	$self->{"panelxValTxt"}         = $panelxValTxt;
	$self->{"panelyValTxt"}         = $panelyValTxt;
	$self->{"nasobnostPanelValTxt"} = $nasobnostPanelValTxt;
	$self->{"nasobnostValTxt"}      = $nasobnostValTxt;

	return $szStatBox;
}

sub __QuickNotesClick{
	my $self = shift;

	
	$self->{'quickNoteFrm'}->{"mainFrm"}->CentreOnParent(&Wx::wxBOTH);
	$self->{'quickNoteFrm'}->{"mainFrm"}->Show();
}

# Control handlers
sub __OnTentingChangeHandler {
	my $self = shift;
	my $chb  = shift;
	
	my $val = $chb->GetValue() ? 1 : 0;

	$self->{"onTentingChange"}->Do( $val );
}

# =====================================================================
# DISABLING CONTROLS
# =====================================================================

sub DisableControls{
	
	
}


# =====================================================================
# HANDLERS - HANDLE EVENTS ANOTHER GROUPS
# =====================================================================

sub ChangeCustomerJump{
	my $self  = shift;
	my $isJumpscoring = shift;
	
	$self->{"jumpScoringProp"} = $isJumpscoring;
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
	$self->{"tentingChb"}->SetValue($value);
}

sub GetTenting {
	my $self = shift;
	return $self->{"tentingChb"}->GetValue();
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

sub SetNotes {
	my $self  = shift;
	my $value = shift;
	$self->{"richTxt"}->Clear();
	
	# Temporary set ypracovano v Incamu
	
	unless($value =~ /Zpracovano v InCAMu/i){
		$value = "Zpracovano v InCAMu. ".$value;
	}
	 
	if($value && $value ne ""){
		
		
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
	$self->{"datacodeCb"}->SetValue($value);
}

sub GetDatacode {
	my $self = shift;
	
	return $self->{"datacodeCb"}->GetValue();
}

sub SetUlLogo {
	my $self  = shift;
	my $value = shift;
	$self->{"ulLogoCb"}->SetValue($value);
}

sub GetUlLogo {
	my $self = shift;
	
	return $self->{"ulLogoCb"}->GetValue();
}

sub SetJumpScoring {
	my $self  = shift;
	my $value = shift;
	
	$self->{"jumpScoringProp"} = $value;
	
	#$self->{"jumpscoringChb"}->SetValue($value);
}

sub GetJumpScoring {
	my $self = shift;
	
	return $self->{"jumpScoringProp"};
	
	#$self->{"jumpscoringChb"}->GetValue();
}

1;
