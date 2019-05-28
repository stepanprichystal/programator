#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::Forms::WizardStep2::GlobalSettFrm;
use base 'Programs::Coupon::CpnWizard::Forms::Settings::SettingBaseFrm';

#3th party librarysss
use strict;
use warnings;
use Wx;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Coupon::CpnWizard::WizardCore::Helper';
use aliased 'Widgets::Forms::MyWxBookCtrlPage';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $class    = shift;
	my $parent   = shift;
	my $settings = shift;
	my $result   = shift;

	my $title     = "Global coupon settings";
	my $dimension = [ 860, 650 ];
	my $flags     = &Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxCLIP_CHILDREN | &Wx::wxRESIZE_BORDER | &Wx::wxMINIMIZE_BOX | &Wx::wxCLOSE_BOX;

	my $self = $class->SUPER::new( $parent, $settings, $title, $dimension, $flags, $result );

	bless($self);

	# Properties

	$self->__SetLayout();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS
	my $nb = Wx::Notebook->new( $self->{"pnlMain"}, -1, &Wx::wxDefaultPosition, &Wx::wxDefaultSize );

	#	General TAB
	my $pageGeneral = MyWxBookCtrlPage->new( $nb, $nb->GetPageCount() );
	$nb->AddPage( $pageGeneral, "General settings", 0, $nb->GetPageCount() );
	my $szGeneral = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	$pageGeneral->SetSizer($szGeneral);

	$szGeneral->Add( $self->__BuildGeneralSett($pageGeneral), 1, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szGeneral->Add( $self->__BuildLayoutSett($pageGeneral),  0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	# info text TAB
	my $pageInfoText = MyWxBookCtrlPage->new( $nb, $nb->GetPageCount() );
	$nb->AddPage( $pageInfoText, "Coupon texts", 0, $nb->GetPageCount() );
	my $szInfoText = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	$pageInfoText->SetSizer($szInfoText);

	$szInfoText->Add( $self->__BuildInfoTextSett($pageInfoText), 50, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szInfoText->Add( $self->__BuildPadTextSett($pageInfoText),  50, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	# Shielding TAB
	my $pageShielding = MyWxBookCtrlPage->new( $nb, $nb->GetPageCount() );
	$nb->AddPage( $pageShielding, "General shielding + guard tracks", 0, $nb->GetPageCount() );
	my $szShielding = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	$pageShielding->SetSizer($szShielding);

	$szShielding->Add( $self->__BuildShieldingSett($pageShielding),   1, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szShielding->Add( $self->__BuildGuardTracksSett($pageShielding), 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	# Logo TAB
	my $pageLogo = MyWxBookCtrlPage->new( $nb, $nb->GetPageCount() );
	$nb->AddPage( $pageLogo, "Logo", 0, $nb->GetPageCount() );
	my $szLogo = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	$pageLogo->SetSizer($szLogo);

	$szLogo->Add( $self->__BuildLogoSett($pageLogo), 50, &Wx::wxEXPAND, 1 );

	# BUILD STRUCTURE OF LAYOUT
	# DEFINE LAYOUT STRUCTURE

	$self->{"szMain"}->Add( $nb, 1, &Wx::wxEXPAND, 1 );

}

#-------------------------------------------------------------------------------------------#
#  General settings
#-------------------------------------------------------------------------------------------#

sub __BuildGeneralSett {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'General + dimension settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	my $pnlRows = Wx::Panel->new( $statBox, -1 );
	my $szRows = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# build rows
	$szStatBox->Add( 1, 5, 0 );
	$szStatBox->Add( $self->__BuildRowUni_TextCtrl( $statBox, "stepName" ), 0 );
	$szStatBox->Add( $self->__BuildRowUni_SpinCtrl( $statBox, "couponMargin",       0, 10000 ), 0, &Wx::wxALL, 1 );
	$szStatBox->Add( $self->__BuildRowUni_SpinCtrl( $statBox, "couponSingleMargin", 0, 10000 ), 0, &Wx::wxALL, 1 );

	# Define disable enable checkbox
	$szStatBox->Add( 1, 10, 0 );
	$szStatBox->Add( $self->_GetSeparateLine($pnlRows), 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szStatBox->Add( $self->__BuildRowUni_CheckBox( $statBox, "countourMech", 0, $pnlRows ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_ComboBox( $pnlRows, "countourTypeX", [ "none", "rout",  "score" ]), 0, &Wx::wxALL, 1 );;
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "countourBridgesCntX",  0, 4 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_ComboBox( $pnlRows, "countourTypeY", [ "none", "rout", "score" ]) , 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "countourBridgesCntY",  0, 4 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "bridgesWidth", 0, 10000 ), 0, &Wx::wxALL, 1 );
	
 
	unless ( $self->{"settings"}->GetCountourMech() ) {
		$pnlRows->Disable();
	}

	# EVENTS
	
	$pnlRows->SetSizer($szRows);
	$szStatBox->Add( $pnlRows, 1, 0 );

	# SAVE REFERENCES

	return $szStatBox;
}

sub __BuildRow_stepName {
	my $self   = shift;
	my $parent = shift;

	# settings key
	my ( $key, $getMethod, $setMethod ) = undef;    # get key from method name
	$self->_SetKey( \$key, \$getMethod, \$setMethod );

	# 1) DEFINE setting controls
	my $control = Wx::TextCtrl->new( $parent, -1, $self->{"settings"}->$getMethod(), &Wx::wxDefaultPosition, [ -1, -1 ] );

	# 2) CONNECT control to setting object
	Wx::Event::EVT_TEXT( $control, -1, sub { $self->{"settings"}->$setMethod( $control->GetValue() ) } );

	# 3) BUILD row layout
	return $self->_GetSettingRow( $parent, $key, $control );
}

#-------------------------------------------------------------------------------------------#
#  Layout settings
#-------------------------------------------------------------------------------------------#

sub __BuildLayoutSett {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Layout settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# build rows
	$szStatBox->Add( 1, 5, 0 );
	$szStatBox->Add( $self->__BuildRowUni_SpinCtrl( $statBox, "maxTrackCnt", 1, 8 ), 0, &Wx::wxALL, 1 );
	$szStatBox->Add( $self->__BuildRowUni_CheckBox( $statBox, "shareGNDPads",   1 ), 0, &Wx::wxALL, 1 );
	$szStatBox->Add( $self->__BuildRowUni_CheckBox( $statBox, "twoEndedDesign", 1 ), 0, &Wx::wxALL, 1 );
	$szStatBox->Add( $self->__BuildRowUni_SpinCtrl( $statBox, "trackPadIsolation", 80, 500 ), 0, &Wx::wxALL, 1 );

	$szStatBox->Add( $self->_GetSeparateLine($statBox), 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szStatBox->Add( Wx::StaticText->new( $statBox, -1, "Choose possible route types:", &Wx::wxDefaultPosition ), 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );

	$szStatBox->Add( $self->__BuildRowUni_CheckBox( $statBox, "routeStraight", 1 ), 0, &Wx::wxALL, 1 );
	$szStatBox->Add( $self->__BuildRowUni_CheckBox( $statBox, "routeAbove",    0 ), 0, &Wx::wxALL, 1 );
	$szStatBox->Add( $self->__BuildRowUni_CheckBox( $statBox, "routeBetween",  0 ), 0, &Wx::wxALL, 1 );
	$szStatBox->Add( $self->__BuildRowUni_CheckBox( $statBox, "routeBelow",    0 ), 0, &Wx::wxALL, 1 );

	# EVENTS

	# SAVE REFERENCES

	return $szStatBox;
}

#-------------------------------------------------------------------------------------------#
#  Info texts settings
#-------------------------------------------------------------------------------------------#

sub __BuildInfoTextSett {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Info texts' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	my $pnlRows = Wx::Panel->new( $statBox, -1 );
	my $szRows = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# build rows

	# Define disable enable checkbox
	$szStatBox->Add( 1, 5, 0 );
	$szStatBox->Add( $self->__BuildRowUni_CheckBox( $statBox, "infoText", 0, $pnlRows ), 0, &Wx::wxALL, 1 );

	$szRows->Add( $self->_GetSeparateLine($pnlRows), 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szRows->Add( $self->__BuildRowUni_CheckBox( $pnlRows, "infoTextUnmask" ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_ComboBox( $pnlRows, "infoTextPosition", [ "right", "top" ] ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->_GetSeparateLine($pnlRows), 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );

	$szRows->Add( Wx::StaticText->new( $pnlRows, -1, "Display property of info text:", &Wx::wxDefaultPosition ), 0, &Wx::wxALL, 4 );
	$szRows->Add( $self->__BuildRowUni_CheckBox( $pnlRows, "infoTextNumber", 1 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_CheckBox( $pnlRows, "infoTextTrackImpedance" ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_CheckBox( $pnlRows, "infoTextTrackWidth" ),     0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_CheckBox( $pnlRows, "infoTextTrackLayer" ),     0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_CheckBox( $pnlRows, "infoTextTrackSpace" ),     0, &Wx::wxALL, 1 );

	$szRows->Add( $self->_GetSeparateLine($pnlRows), 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szRows->Add( Wx::StaticText->new( $pnlRows, -1, "Info text font:", &Wx::wxDefaultPosition ), 0, &Wx::wxALL, 4 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "infoTextWidth",  100, 10000 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "infoTextHeight", 100, 10000 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "infoTextWeight", 100, 1000 ),  0, &Wx::wxALL, 1 );

	$szRows->Add( $self->_GetSeparateLine($pnlRows), 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szRows->Add( Wx::StaticText->new( $pnlRows, -1, "Info text distances:", &Wx::wxDefaultPosition ), 0, &Wx::wxALL, 4 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "padsTopTextDist",      0, 10000 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "infoTextRightCpnDist", 0, 10000 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "infoTextHSpacing",     0, 10000 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "infoTextVSpacing",     0, 10000 ), 0, &Wx::wxALL, 1 );

	unless ( $self->{"settings"}->GetInfoText() ) {
		$pnlRows->Disable();
	}

	$pnlRows->SetSizer($szRows);

	$szStatBox->Add( $pnlRows, 1, 0 );

	# EVENTS
	# EVENTS
	#Wx::Event::EVT_CHECKBOX( $control, -1, sub { $self->__InfoTextDisable($szRows) } );

	# SAVE REFERENCES

	return $szStatBox;
}

#-------------------------------------------------------------------------------------------#
#  Info texts settings
#-------------------------------------------------------------------------------------------#

sub __BuildPadTextSett {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Track pad text' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	my $pnlRows = Wx::Panel->new( $statBox, -1 );
	my $szRows = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# build rows

	# Define disable enable checkbox
	$szStatBox->Add( 1, 5, 0 );
	$szStatBox->Add( $self->__BuildRowUni_CheckBox( $statBox, "padText", 0, $pnlRows ), 0, &Wx::wxALL, 1 );

	$szRows->Add( $self->_GetSeparateLine($pnlRows), 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szRows->Add( $self->__BuildRowUni_CheckBox( $pnlRows, "padTextUnmask" ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "padTextDist", 0, 3000 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->_GetSeparateLine($pnlRows), 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szRows->Add( Wx::StaticText->new( $pnlRows, -1, "Pad text font:", &Wx::wxDefaultPosition ), 0, &Wx::wxALL, 4 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "padTextWidth",  100, 2000 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "padTextHeight", 100, 2000 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "padTextWeight", 100, 1000 ), 0, &Wx::wxALL, 1 );

	unless ( $self->{"settings"}->GetPadText() ) {
		$pnlRows->Disable();
	}

	$pnlRows->SetSizer($szRows);

	$szStatBox->Add( $pnlRows, 1, 0 );

	# EVENTS
	# EVENTS
	#Wx::Event::EVT_CHECKBOX( $control, -1, sub { $self->__InfoTextDisable($szRows) } );

	# SAVE REFERENCES

	return $szStatBox;
}

#-------------------------------------------------------------------------------------------#
#  Info shielding settings
#-------------------------------------------------------------------------------------------#

sub __BuildShieldingSett {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'General shielding' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	my $pnlRows = Wx::Panel->new( $statBox, -1 );
	my $szRows = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# build rows

	# Define disable enable checkbox
	$szStatBox->Add( 1, 5, 0 );
	$szStatBox->Add( $self->__BuildRowUni_CheckBox( $statBox, "shielding", 0, $pnlRows ), 0, &Wx::wxALL, 1 );

	# ----

	$szRows->Add( $self->_GetSeparateLine($pnlRows), 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szRows->Add( $self->__BuildRowUni_ComboBox( $pnlRows, "shieldingType", [ "symbol", "solid" ] ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->_GetSeparateLine($pnlRows), 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szRows->Add( Wx::StaticText->new( $pnlRows, -1, "Definition of shielding symbol:", &Wx::wxDefaultPosition ), 0, &Wx::wxALL, 4 );
	$szRows->Add( $self->__BuildRowUni_TextCtrl( $pnlRows, "shieldingSymbol" ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "shieldingSymbolDX", 100, 10000 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "shieldingSymbolDY", 100, 10000 ), 0, &Wx::wxALL, 1 );

	unless ( $self->{"settings"}->GetShielding() ) {
		$pnlRows->Disable();
	}

	$pnlRows->SetSizer($szRows);

	$szStatBox->Add( $pnlRows, 1, 0 );

	# EVENTS
	# EVENTS
	#Wx::Event::EVT_CHECKBOX( $control, -1, sub { $self->__InfoTextDisable($szRows) } );

	# SAVE REFERENCES

	return $szStatBox;
}

#-------------------------------------------------------------------------------------------#
#  Guard tracks settings
#-------------------------------------------------------------------------------------------#

sub __BuildGuardTracksSett {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Guard tracks' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	my $pnlRows = Wx::Panel->new( $statBox, -1 );
	my $szRows = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# build rows

	# Define disable enable checkbox
	$szStatBox->Add( 1, 5, 0 );
	$szStatBox->Add( $self->__BuildRowUni_CheckBox( $statBox, "guardTracks", 0, $pnlRows ), 0, &Wx::wxALL, 1 );

	# ----

	$szRows->Add( $self->_GetSeparateLine($pnlRows), 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szRows->Add( $self->__BuildRowUni_ComboBox( $pnlRows, "guardTracksType", [ "single_line", "full" ] ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "guardTrackWidth",      50, 5000 ),  0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "guardTrack2TrackDist", 0,  10000 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "guardTrack2PadDist",   0,  10000 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "guardTrack2Shielding", 0,  10000 ), 0, &Wx::wxALL, 1 );

	unless ( $self->{"settings"}->GetGuardTracks() ) {
		$pnlRows->Disable();
	}

	$pnlRows->SetSizer($szRows);

	$szStatBox->Add( $pnlRows, 1, 0 );

	# EVENTS
	# EVENTS
	#Wx::Event::EVT_CHECKBOX( $control, -1, sub { $self->__InfoTextDisable($szRows) } );

	# SAVE REFERENCES

	return $szStatBox;
}

#-------------------------------------------------------------------------------------------#
#  Logo settings
#-------------------------------------------------------------------------------------------#

sub __BuildLogoSett {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Logo title' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	my $pnlRows = Wx::Panel->new( $statBox, -1 );
	my $szRows = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# build rows

	# Define disable enable checkbox
	$szStatBox->Add( 1, 5, 0 );
	$szStatBox->Add( $self->__BuildRowUni_CheckBox( $statBox, "title", 0, $pnlRows ), 0, &Wx::wxALL, 1 );

	# ----

	$szRows->Add( $self->_GetSeparateLine($pnlRows), 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szRows->Add( $self->__BuildRowUni_ComboBox( $pnlRows, "titleType", [ "left", "top" ] ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_CheckBox( $pnlRows, "titleUnMask" ), 0 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "titleMargin",         0, 10000 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "titleLogoJobIdHDist", 0, 10000 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "titleLogoJobIdVDist", 0, 10000 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->_GetSeparateLine($pnlRows), 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szRows->Add( Wx::StaticText->new( $pnlRows, -1, "Logo settings:", &Wx::wxDefaultPosition ), 0, &Wx::wxALL, 4 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "logoWidth",  100, 2000 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "logoHeight", 100, 2000 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_TextCtrl( $pnlRows, "logoSymbol", 1 ), 0 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "logoSymbolWidth",  100, 1000, 1 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "logoSymbolHeight", 100, 1000, 1 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->_GetSeparateLine($pnlRows), 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szRows->Add( Wx::StaticText->new( $pnlRows, -1, "Job id label settings:", &Wx::wxDefaultPosition ), 0, &Wx::wxALL, 4 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "titleTextWidth",  100, 2000 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "titleTextHeight", 100, 2000 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "titleTextWeight", 100, 1000 ), 0, &Wx::wxALL, 1 );

	unless ( $self->{"settings"}->GetTitle() ) {
		$pnlRows->Disable();
	}

	$pnlRows->SetSizer($szRows);

	$szStatBox->Add( $pnlRows, 1, 0 );

	# EVENTS
	# EVENTS
	#Wx::Event::EVT_CHECKBOX( $control, -1, sub { $self->__InfoTextDisable($szRows) } );

	# SAVE REFERENCES

	return $szStatBox;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased "Programs::Coupon::CpnWizard::Forms::WizardStep1::GeneratorFrm";
	#
	#	my @dimension = ( 500, 800 );
	#
	my $test = GeneratorFrm->new(-1);

	#$test->{"mainFrm"}->Show();
	$test->ShowModal();
	#
	#	my $pnl = Wx::Panel->new( $test->{"mainFrm"}, -1, [ -1, -1 ], [ 100, 100 ] );
	#	$pnl->SetBackgroundColour($Widgets::Style::clrLightRed);
	#	$test->AddContent($pnl);
	#
	#	$test->SetButtonHeight(20);
	#
	#	$test->AddButton( "Set", sub { Test(@_) } );
	#	$test->AddButton( "EE",  sub { Test(@_) } );
	#	$test->MainLoop();
}

#sub Test {
#
#	print "yde";
#
#}

1;

