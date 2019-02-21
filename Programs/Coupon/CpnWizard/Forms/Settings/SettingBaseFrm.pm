#-------------------------------------------------------------------------------------------#
# Description: Form, which allow set nif quick notes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::Forms::Settings::SettingBaseFrm;
use base 'Widgets::Forms::StandardModalFrm';

#3th party librarysss
use strict;
use warnings;
use Wx;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Coupon::CpnWizard::WizardCore::Helper';
use aliased 'Programs::Coupon::CpnWizard::Forms::Settings::SettingRow';
use aliased 'Programs::Coupon::CpnWizard::Forms::Settings::SettingsInfo';

#tested form

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $class     = shift;
	my $parent    = shift;
	my $settings  = shift;
	my $title     = shift;
	my $demension = shift;
	my $flags     = shift;
	my $result    = shift;

	my @dimension = ( 800, 700 );

	my $self = $class->SUPER::new( $parent, $title, $demension, $flags );

	bless($self);

	# Properties
	$self->{"result"}   = $result;
	$self->{"settings"} = $settings;
	$self->{"settInfo"} = SettingsInfo->new();

	$self->__SetLayout();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $pnlMain = Wx::Panel->new( $self, -1 );

	# BUILD STRUCTURE OF LAYOUT
	$pnlMain->SetSizer($szMain);    # DEFINE LAYOUT STRUCTURE

	$self->AddContent($pnlMain);

	$self->SetButtonHeight(25);

	$self->AddButton( "Ok", sub { $self->__OkClick(@_) } );

	$self->{"szMain"}  = $szMain;
	$self->{"pnlMain"} = $pnlMain;

}

sub _GetSettingRow {
	my $self        = shift;
	my $parent      = shift;
	my $settingsKey = shift;
	my $controls    = shift;
	
	my $l = $self->{"settInfo"}->GetLabelText();
	my $h = $self->{"settInfo"}->GetHelpText();
	my $u = $self->{"settInfo"}->GetUnitText();
	

	my $row = SettingRow->new( $parent, $self, $settingsKey, $l, $h, $u, $controls );

	return $row->GetRowLayout();
}

sub __BuildRowUni_TextCtrl {
	my $self         = shift;
	my $parent       = shift;
	my $key          = shift;
	my $readOnly     = shift // 0;
	my $controlWidth = shift // 120;

	# settings key
	my $getMethod = "Get" . uc( substr( $key, 0, 1 ) ) . substr( $key, 1, length($key) );
	my $setMethod = "Set" . uc( substr( $key, 0, 1 ) ) . substr( $key, 1, length($key) );

	# 1) DEFINE setting controls
	my $control =
	  Wx::TextCtrl->new( $parent, -1, $self->{"settings"}->$getMethod(), &Wx::wxDefaultPosition, [ $controlWidth, -1 ] );
	if ($readOnly) {
		$control->Disable();
	}

	# 2) CONNECT control to setting object
	Wx::Event::EVT_TEXT( $control, -1, sub { $self->{"settings"}->$setMethod( $control->GetValue() ) } );

	# 3) BUILD row layout
	return $self->_GetSettingRow( $parent, $key, $control );
}

sub __BuildRowUni_SpinCtrl {
	my $self         = shift;
	my $parent       = shift;
	my $key          = shift;
	my $min          = shift // 0;
	my $max          = shift // 0;
	my $readOnly     = shift // 0;
	my $controlWidth = shift // 120;

	# settings key
	my $getMethod = "Get" . uc( substr( $key, 0, 1 ) ) . substr( $key, 1, length($key) );
	my $setMethod = "Set" . uc( substr( $key, 0, 1 ) ) . substr( $key, 1, length($key) );

	# 1) DEFINE setting controls
	my $control = Wx::SpinCtrl->new( $parent, -1, $self->{"settings"}->$getMethod(),
									 &Wx::wxDefaultPosition, [ $controlWidth, -1 ],
									 &Wx::wxSP_ARROW_KEYS, $min, $max );
	if ($readOnly) {
		$control->Disable();
	}

	# 2) CONNECT control to setting object
	Wx::Event::EVT_TEXT( $control, -1, sub { $self->{"settings"}->$setMethod( $control->GetValue() ) } );

	# 3) BUILD row layout
	return $self->_GetSettingRow( $parent, $key, $control );
}

sub __BuildRowUni_CheckBox {
	my $self            = shift;
	my $parent          = shift;
	my $key             = shift;
	my $readOnly        = shift // 0;
	my $disableControls = shift;
	my $controlWidth    = shift // 120;

	# settings key
	my $getMethod = "Get" . uc( substr( $key, 0, 1 ) ) . substr( $key, 1, length($key) );
	my $setMethod = "Set" . uc( substr( $key, 0, 1 ) ) . substr( $key, 1, length($key) );

	# 1) DEFINE setting controls
	my $control = Wx::CheckBox->new( $parent, -1, "", &Wx::wxDefaultPosition, [ $controlWidth, -1 ] );
	$control->SetValue( $self->{"settings"}->$getMethod() );
	if ($readOnly) {
		$control->Disable();
	}

	# 2) CONNECT control to setting object
	Wx::Event::EVT_CHECKBOX(
		$control, -1,
		sub {
			$self->{"settings"}->$setMethod( $control->GetValue() );

			if ($disableControls) {
				$self->__DisableControls( $control, $disableControls );
			}
		}
	);

	#	if ($disableControls) {
	#		Wx::Event::EVT_CHECKBOX( $control, -1, sub { $self->__DisableControls( $control, $disableControls ) } );
	#	}

	# 3) BUILD row layout
	return $self->_GetSettingRow( $parent, $key, $control );
}

sub __BuildRowUni_ComboBox {
	my $self         = shift;
	my $parent       = shift;
	my $key          = shift;
	my $options      = shift;
	my $readOnly     = shift // 0;
	my $controlWidth = shift // 120;

	# settings key
	my $getMethod = "Get" . uc( substr( $key, 0, 1 ) ) . substr( $key, 1, length($key) );
	my $setMethod = "Set" . uc( substr( $key, 0, 1 ) ) . substr( $key, 1, length($key) );

	# 1) DEFINE setting controls
	my @inCamDelay = ( 0.2, 0.5, 1, 2, 5, 10, 20, 40 );
	my $control =
	  Wx::ComboBox->new( $parent, -1, $self->{"settings"}->$getMethod(), [ -1, -1 ], [ $controlWidth, -1 ], $options, &Wx::wxCB_READONLY );

	if ($readOnly) {
		$control->Disable();
	}

	# 2) CONNECT control to setting object
	Wx::Event::EVT_COMBOBOX( $control, -1, sub { $self->{"settings"}->$setMethod( $control->GetValue() ) } );

	# 3) BUILD row layout
	return $self->_GetSettingRow( $parent, $key, $control );
}

#sub __SetMethodWrapper{
#	my $settings = shift;
#	my $settFunc = shift;
#	my $value = shift;
#
#	unless($settings->$settFunc($value)){
#
#
#	}
#}

sub __OkClick {
	my $self = shift;

	${ $self->{"result"} } = 1;

	$self->Destroy();
}

sub __DisableControls {
	my $self       = shift;
	my $checkbox   = shift;
	my $szControls = shift;

	if ( $checkbox->GetValue() eq 1 ) {
		$szControls->Enable();
	}
	else {
		$szControls->Disable();
	}

}

sub _SetKey {
	my $self      = shift;
	my $key       = shift;
	my $getMethod = shift;
	my $setMethod = shift;

	my @test = caller(1);

	($$key) = ( caller(1) )[3] =~ /__BuildRow_(.*)$/i;    # get key from method name
	$$getMethod = "Get" . uc( substr( $$key, 0, 1 ) ) . substr( $$key, 1, length($$key) );
	$$setMethod = "Set" . uc( substr( $$key, 0, 1 ) ) . substr( $$key, 1, length($$key) );

}

sub _GetSeparateLine {
	my $self   = shift;
	my $parent = shift;
	my $thick  = shift // 1;
	my $pnl    = Wx::Panel->new( $parent, -1, &Wx::wxDefaultPosition, [ $thick, -1 ] );
	$pnl->SetBackgroundColour( Wx::Colour->new( 250, 250, 250 ) );

	return $pnl;
}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

#sub SetNotesData {
#	my $self = shift;
#	my $data = shift;
#
#	$self->{"noteList"}->SetNotesData($data);
#
#}
#
#sub GetNotesData {
#	my $self = shift;
#
#	return $self->{"noteList"}->GetNotesData();
#
#}

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

