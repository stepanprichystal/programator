#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::Forms::WizardStep2::StripSettFrm;
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
	my $isGlobal = shift;    # reference whe will be stored if settings is global for all strips

	my $title     = "Coupon microstrip settings";
	my $dimension = [ 440, 300 ];
	my $flags     = &Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxCLIP_CHILDREN | &Wx::wxRESIZE_BORDER | &Wx::wxMINIMIZE_BOX | &Wx::wxCLOSE_BOX;

	my $self = $class->SUPER::new( $parent, $settings, $title, $dimension, $flags, $result );

	bless($self);

	# Properties

	$self->__SetLayout($isGlobal);

	return $self;
}

sub __SetLayout {
	my $self     = shift;
	my $isGlobal = shift;

	# DEFINE CONTROLS

	$self->{"szMain"}->Add( $self->__BuildLayoutSett( $self->{"pnlMain"}, $isGlobal ), 50, &Wx::wxEXPAND, 1 );

	$self->{"szMain"}->Add( 1, 5, 1 );
	my $overWriteChb = Wx::CheckBox->new( $self->{"pnlMain"}, -1, "Set same settings for all microstrips", &Wx::wxDefaultPosition );
	$overWriteChb->SetForegroundColour( Wx::Colour->new( 255, 0, 0 ) );
	$self->{"szMain"}->Add( $overWriteChb, 0, &Wx::wxALL, 4 );

	# EVENTS
	# EVENTS
	Wx::Event::EVT_CHECKBOX(
		$overWriteChb, -1,

		sub {
			my $chb = shift;
			$$isGlobal = defined $chb->GetValue() && $chb->GetValue() ? 1 : 0;
		}
	);

	# BUILD STRUCTURE OF LAYOUT

	# DEFINE LAYOUT STRUCTURE

}

#-------------------------------------------------------------------------------------------#
#  Layout settings
#-------------------------------------------------------------------------------------------#

sub __BuildLayoutSett {
	my $self     = shift;
	my $parent   = shift;
 

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Track settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	my $pnlRows = Wx::Panel->new( $statBox, -1 );
	my $szRows = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# build rows

	# Define disable enable checkbox
	$szStatBox->Add( 1, 5, 0 );

	#$szStatBox->Add( $self->__BuildRowUni_CheckBox( $statBox, "guardTracks", 0, $pnlRows ), 0, &Wx::wxALL, 1 );
	# ----

	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "pad2GND",       50, 1000 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "trackToCopper", 50, 1000 ), 0, &Wx::wxALL, 1 );
	$szRows->Add( $self->__BuildRowUni_SpinCtrl( $pnlRows, "padClearance",  0,  200 ),  0, &Wx::wxALL, 1 );

	$pnlRows->SetSizer($szRows);
	$szStatBox->Add( $pnlRows, 1, 0 );

	# EVENTS

	# SAVE REFERENCES

	return $szStatBox;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

#sub Test {
#
#	print "yde";
#
#}

1;

