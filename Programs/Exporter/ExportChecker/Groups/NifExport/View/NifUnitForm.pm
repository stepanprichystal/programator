#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::NifExport::View::NifUnitForm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:richtextctrl :textctrl :font);

BEGIN {
	eval { require Wx::RichText; };
}

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'CamHelpers::CamLayer';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::View::NifColorCb';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::Helper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;

	my $inCAM = shift;
	my $jobId = shift;
	my $title = shift;

	my $self = $class->SUPER::new($parent);

	bless($self);

	$self->{"inCAM"} = $inCAM;
	$self->{"jobId"} = $jobId;

	$self->{"title"} = $title;

	$self->__SetLayout();

	$self->__SetName();

	#$self->Disable();

	#$self->SetBackgroundColour($Widgets::Style::clrLightBlue);

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

sub __SetName {
	my $self = shift;

	$self->{"title"} = "Nif group";

}

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



	
	
	

	 


	my $szRow0 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $settingsStatBox  = $self->__SetLayoutSettings($self);
	#my $dimensionStatBox = $self->__SetLayoutDimension($self);

	my $richTxt = Wx::RichTextCtrl->new( $self, -1, 'Notes', &Wx::wxDefaultPosition, [ 100, 120 ], &Wx::wxRE_MULTILINE | &Wx::wxWANTS_CHARS );
	$richTxt->SetEditable(1);
	$richTxt->SetBackgroundColour($Widgets::Style::clrWhite);
	$richTxt->Layout();

	# SET EVENTS

	
	
	
	
	
	
	
	
	
		# first stat box
	my $statBox1 = Wx::StaticBox->new( $self, -1, 'Dimension' );
	my $szStatBox1 = Wx::StaticBoxSizer->new( $statBox1, &Wx::wxVERTICAL );
	my $szMain1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	
	my $singlexTxt1 = Wx::StaticText->new( $statBox1, -1, "Single x", &Wx::wxDefaultPosition, [ 70, 20 ] );
	$szMain1->Add( $singlexTxt1, 1, &Wx::wxEXPAND );
	
	$szStatBox1->Add( $szMain1, 1, &Wx::wxEXPAND );

	
	# second stat box
	my $statBox2 = Wx::StaticBox->new( $self, -1, 'Dimension' );
	my $szStatBox2 = Wx::StaticBoxSizer->new( $statBox2, &Wx::wxVERTICAL );
	my $szMain2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	
	my $singlexTxt2 = Wx::StaticText->new( $statBox2, -1, "Single x", &Wx::wxDefaultPosition, [ 70, 20 ] );
	$szMain2->Add( $singlexTxt2, 1, &Wx::wxEXPAND );
	
	$szStatBox2->Add( $szMain2, 1, &Wx::wxEXPAND );
	
	$szRow0->Add( $szStatBox1,  50, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow0->Add( $szStatBox2,  50, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	
	
	
	
	
	
	
	
	
	
	
	
	



	# BUILD STRUCTURE OF LAYOUT
	 

 
	
	#$szMain->Add( $szStatBox, 0, &Wx::wxEXPAND );
	
	
	
	
	
	
	
	# BUILD STRUCTURE OF LAYOUT
	
	$szRow1->Add( $settingsStatBox,  50, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	#$szRow1->Add( $dimensionStatBox, 50, &Wx::wxEXPAND | &Wx::wxALL, 1 );
    #$szRow1->Add( $szStatBox, 50, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	
	

	$szRow2->Add( $richTxt, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	
	$szMain->Add( $szRow0, 1, &Wx::wxEXPAND );
	$szMain->Add( $szRow1, 1, &Wx::wxEXPAND );
	$szMain->Add( $szRow2, 1, &Wx::wxEXPAND );
	

	$self->SetSizer($szMain);
	
	 

	# save control references
	$self->{"richTxt"} = $richTxt;

}

# Set layout for Quick set box
	my $self   = shift;
sub __SetLayoutSettings {
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# Load data, for filling form by values
	my @markingLayer = CamLayer->GetMarkingLayers( $self->{"inCAM"}, $self->{"jobId"} );
	my @markingLNames = map { uc( $_->{"gROWname"} ) } @markingLayer;
	push( @markingLNames, "" );

	my @maskColor = Helper->GetPcbMaskColors();
	push( @maskColor, "" );

	my @silkColor = Helper->GetPcbSilkColors();
	push( @silkColor, "" );

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow4 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szRow5 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $tentingChb     = Wx::CheckBox->new( $statBox, -1, "Tenting",      &Wx::wxDefaultPosition, &Wx::wxDefaultSize );
	my $maskaChb       = Wx::CheckBox->new( $statBox, -1, "Mask 100µm",  &Wx::wxDefaultPosition, &Wx::wxDefaultSize );
	my $pressfitChb    = Wx::CheckBox->new( $statBox, -1, "Pressfit",     &Wx::wxDefaultPosition, &Wx::wxDefaultSize );
	my $jumpscoringChb = Wx::CheckBox->new( $statBox, -1, "Jump scoring", &Wx::wxDefaultPosition, &Wx::wxDefaultSize );

	my $datacodeCb = Wx::ComboBox->new( $statBox, -1, $markingLNames[0], &Wx::wxDefaultPosition, [ 70, 20 ], \@markingLNames, &Wx::wxCB_READONLY );
	my $ulLogoCb   = Wx::ComboBox->new( $statBox, -1, $markingLNames[0], &Wx::wxDefaultPosition, [ 70, 20 ], \@markingLNames, &Wx::wxCB_READONLY );

	my $datacodeTxt = Wx::StaticText->new( $statBox, -1, "Data code" );
	my $ulLogoTxt   = Wx::StaticText->new( $statBox, -1, "UL logo" );

	my $silkTopCb = NifColorCb->new( $statBox, $self->{"inCAM"}, $self->{"jobId"}, "Silk top",        \@silkColor );
	my $maskTopCb = NifColorCb->new( $statBox, $self->{"inCAM"}, $self->{"jobId"}, "Solder mask top", \@maskColor );
	my $maskBotCb = NifColorCb->new( $statBox, $self->{"inCAM"}, $self->{"jobId"}, "Solder mask bot", \@maskColor );
	my $silkBotCb = NifColorCb->new( $statBox, $self->{"inCAM"}, $self->{"jobId"}, "Silk bot",        \@silkColor );

	# SET EVENTS
	Wx::Event::EVT_CHECKBOX( $tentingChb, -1, sub { $self->__OnTentingChangeHandler(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $tentingChb,  30, &Wx::wxEXPAND | &Wx::wxALL,               1 );
	$szRow1->Add( $datacodeCb,  10, &Wx::wxEXPAND | &Wx::wxALL,               1 );
	$szRow1->Add( $datacodeTxt, 20, &Wx::wxEXPAND | &Wx::wxALL | &Wx::wxLEFT, 2 );
	$szRow1->Add( $silkTopCb,   10, &Wx::wxEXPAND | &Wx::wxALL,               1 );

	#$szRow1->Add( 10, 10, 40, &Wx::wxGROW ); #expander

	$szRow2->Add( $maskaChb,  30, &Wx::wxEXPAND | &Wx::wxALL,               1 );
	$szRow2->Add( $ulLogoCb,  10, &Wx::wxEXPAND | &Wx::wxALL,               1 );
	$szRow2->Add( $ulLogoTxt, 20, &Wx::wxEXPAND | &Wx::wxALL | &Wx::wxLEFT, 2 );
	$szRow2->Add( $maskTopCb, 10, &Wx::wxEXPAND | &Wx::wxALL,               1 );

	#$szRow2->Add( 10, 10, 40, &Wx::wxGROW ); #expander

	$szRow3->Add( $pressfitChb, 30, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow3->Add( $maskBotCb,   10, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow4->Add( $jumpscoringChb, 30, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow4->Add( $silkBotCb,      10, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szMain->Add( $szRow1, 0, &Wx::wxEXPAND );
	$szMain->Add( $szRow2, 0, &Wx::wxEXPAND );
	$szMain->Add( $szRow3, 0, &Wx::wxEXPAND );
	$szMain->Add( $szRow4, 0, &Wx::wxEXPAND );
	
	
	
	
	
	
	
	
	
	
	$szStatBox->Add( $szMain, 1, &Wx::wxEXPAND );

	#$szMain->Add( $szRow5, 0, &Wx::wxEXPAND );

	# save control references
	$self->{"tentingChb"}     = $tentingChb;
	$self->{"maskaChb"}       = $maskaChb;
	$self->{"ulLogoCb"}       = $ulLogoCb;
	$self->{"pressfitChb"}    = $pressfitChb;
	$self->{"jumpscoringChb"} = $jumpscoringChb;
	$self->{"datacodeCb"}     = $datacodeCb;
	$self->{"ulLogoCb"}       = $ulLogoCb;

	return $szStatBox;

}




 







# Set layout for Quick set box
sub __SetLayoutDimension {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Dimension' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# Load data, for filling form by values

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow4 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szRow5 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $singlexTxt = Wx::StaticText->new( $statBox, -1, "Single x", &Wx::wxDefaultPosition, [ 70, 20 ] );
#	my $singleyTxt = Wx::StaticText->new( $statBox, -1, "Single y", &Wx::wxDefaultPosition, [ 70, 20 ] );
#
#	my $singlexValTxt = Wx::StaticText->new( $statBox, -1, "0.0" );
#	my $singleyValTxt = Wx::StaticText->new( $statBox, -1, "0.0" );
#
#	my $panelxTxt = Wx::StaticText->new( $statBox, -1, "Panel x", &Wx::wxDefaultPosition, [ 70, 20 ] );
#	my $panelyTxt = Wx::StaticText->new( $statBox, -1, "Panel y", &Wx::wxDefaultPosition, [ 70, 20 ] );
#
#	my $panelxValTxt = Wx::StaticText->new( $statBox, -1, "0.0" );
#	my $panelyValTxt = Wx::StaticText->new( $statBox, -1, "0.0" );
#
#	my $nasobnostPanelTxt    = Wx::StaticText->new( $statBox, -1, "Nasobnost panel", &Wx::wxDefaultPosition, [ 70, 20 ] );
#	my $nasobnostPanelValTxt = Wx::StaticText->new( $statBox, -1, "0.0" );
#
#	my $nasobnostTxt    = Wx::StaticText->new( $statBox, -1, "Nasobnost" , &Wx::wxDefaultPosition, [ 70, 20 ]);
#	my $nasobnostValTxt = Wx::StaticText->new( $statBox, -1, "0.0" );

	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $singlexTxt,    25, &Wx::wxEXPAND | &Wx::wxALL,               1 );
#	$szRow1->Add( $singlexValTxt, 25, &Wx::wxEXPAND | &Wx::wxALL,               1 );
#	$szRow1->Add( $singleyTxt,    25, &Wx::wxEXPAND | &Wx::wxALL ,               1 );
#	$szRow1->Add( $singleyValTxt, 25, &Wx::wxEXPAND | &Wx::wxALL,               1 );
#
#	$szRow2->Add( $panelxTxt,    25, &Wx::wxEXPAND | &Wx::wxALL,               1 );
#	$szRow2->Add( $panelxValTxt, 25, &Wx::wxEXPAND | &Wx::wxALL,               1 );
#	$szRow2->Add( $panelyTxt,    25, &Wx::wxEXPAND | &Wx::wxALL ,               1 );
#	$szRow2->Add( $panelyValTxt, 25, &Wx::wxEXPAND | &Wx::wxALL,               1 );
#
#	$szRow3->Add( $nasobnostPanelTxt,    25, &Wx::wxEXPAND | &Wx::wxALL, 1 );
#	$szRow3->Add( $nasobnostPanelValTxt, 25, &Wx::wxEXPAND | &Wx::wxALL, 1 );
#
#	$szRow4->Add( $nasobnostTxt,    25, &Wx::wxEXPAND | &Wx::wxALL, 1 );
#	$szRow4->Add( $nasobnostValTxt, 25, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szMain->Add( $szRow1, 1, &Wx::wxEXPAND );
#	$szMain->Add( $szRow2, 1, &Wx::wxEXPAND );
#	$szMain->Add( $szRow3, 1, &Wx::wxEXPAND );
#	$szMain->Add( $szRow4, 1, &Wx::wxEXPAND );
#	
	$szStatBox->Add( $szMain, 1, &Wx::wxEXPAND );

	# save control references
#	$self->{"singlexValTxt"}        = $singlexValTxt;
#	$self->{"singleyValTxt"}        = $singleyValTxt;
#	$self->{"panelxValTxt"}         = $panelxValTxt;
#	$self->{"panelyValTxt"}         = $panelyValTxt;
#	$self->{"nasobnostPanelValTxt"} = $nasobnostPanelValTxt;
#	$self->{"nasobnostValTxt"}      = $nasobnostValTxt;

	return $szStatBox;
}

# Control handlers
sub __OnTentingChangeHandler {
	my $self = shift;
	my $chb  = shift;

	$self->{"onTentingChange"}->Do( $chb->GetValue() );
}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

# Dimension ========================================================

# single_x
sub SetSingle_x {
	my $self  = shift;
	my $value = shift;
	$self->{"singlexValTxt"}->SetValue($value);
}

sub GetSingle_x {
	my $self = shift;
	return $self->{"singlexValTxt"}->GetValue();
}

# single_y
sub SetSingle_y {
	my $self  = shift;
	my $value = shift;
	$self->{"singleyValTxt"}->SetValue($value);
}

sub GetSingle_y {
	my $self = shift;
	return $self->{"singleyValTxt"}->GetValue();
}

# panel_x
sub SetPanel_x {
	my $self  = shift;
	my $value = shift;
	$self->{"panelxValTxt"}->SetValue($value);
}

sub GetPanel_x {
	my $self = shift;
	return $self->{"panelxValTxt"}->GetValue();
}

# panel_y
sub SetPanel_y {
	my $self  = shift;
	my $value = shift;
	$self->{"panelyValTxt"}->SetValue($value);
}

sub GetPanel_y {
	my $self = shift;
	return $self->{"panelyValTxt"}->GetValue();
}

# nasobnost_panelu
sub SetNasobnost_panelu {
	my $self  = shift;
	my $value = shift;
	$self->{"nasobnostPanelValTxt"}->SetValue($value);
}

sub GetNasobnost_panelu {
	my $self = shift;
	return $self->{"nasobnostPanelValTxt"}->GetValue();
}

# nasobnost
sub SetNasobnost {
	my $self  = shift;
	my $value = shift;
	$self->{"nasobnostValTxt"}->SetValue($value);
}

sub GetNasobnost {
	my $self = shift;
	return $self->{"nasobnostValTxt"}->GetValue();
}

# MASK, SILK color ========================================================

# c_mask_colour
sub SetC_mask_colour {
	my $self  = shift;
	my $value = shift;

	my $color = Helper->GetMaskCodeToColor($value);
	$self->{"maskTopCb"}->SetValue($color);
}

sub GetC_mask_colour {
	my $self  = shift;
	my $color = $self->{"maskTopCb"}->GetValue();
	return Helper->GetMaskColorToCode($color);
}

# s_mask_colour
sub SetS_mask_colour {
	my $self  = shift;
	my $value = shift;

	my $color = Helper->GetMaskCodeToColor($value);
	$self->{"maskBotCb"}->SetValue($color);
}

sub GetS_mask_colour {
	my $self  = shift;
	my $color = $self->{"maskBotCb"}->GetValue();
	return Helper->GetMaskColorToCode($color);
}

# c_silk_screen_colour
sub SetC_silk_screen_colour {
	my $self  = shift;
	my $value = shift;

	my $color = Helper->GetSilkCodeToColor($value);
	$self->{"silkTopCb"}->SetValue($color);
}

sub GetC_silk_screen_colour {
	my $self  = shift;
	my $color = $self->{"silkTopCb"}->GetValue();
	return Helper->GetSilkColorToCode($color);
}

sub SetS_silk_screen_colour {
	my $self  = shift;
	my $value = shift;

	my $color = Helper->GetSilkCodeToColor($value);
	$self->{"silkBotCb"}->SetValue($color);
}

sub GetS_silk_screen_colour {
	my $self  = shift;
	my $color = $self->{"silkBotCb"}->GetValue();
	return Helper->GetSilkColorToCode($color);
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
	$self->{"richTxt"}->WriteText($value);
}

sub GetNotes {
	my $self = shift;
	$self->{"richTxt"}->GetValue();
}

sub SetDatacode {
	my $self  = shift;
	my $value = shift;
	$self->{"datacodeCb"}->SetValue($value);
}

sub GetDatacode {
	my $self = shift;
	$self->{"datacodeCb"}->GetValue();
}

sub SetUlLogo {
	my $self  = shift;
	my $value = shift;
	$self->{"ulLogoCb"}->SetValue($value);
}

sub GetUlLogo {
	my $self = shift;
	$self->{"ulLogoCb"}->GetValue();
}

sub SetJumpScoring {
	my $self  = shift;
	my $value = shift;
	$self->{"jumpscoringChb"}->SetValue($value);
}

sub GetJumpScoring {
	my $self = shift;
	$self->{"jumpscoringChb"}->GetValue();
}

1;
