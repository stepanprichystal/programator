
#-------------------------------------------------------------------------------------------#
# Description: View form for specific sreator
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::AutoUserFrm;
use base qw(Programs::Panelisation::PnlWizard::Forms::CreatorFrmBase);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $jobId  = shift;

	my $self = $class->SUPER::new( PnlCreEnums->StepPnlCreator_AUTOUSER , $parent, $jobId );

	bless($self);

	$self->__SetLayout();

	# DEFINE EVENTS

	return $self;
}

# Do specific layout settings for creator
sub __SetLayout {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# Add empty item

	# DEFINE CONTROLS
	my $widthTxt = Wx::StaticText->new( $self, -1, "Width:", &Wx::wxDefaultPosition, [ 70, 22 ] );
	my $widthValTxt = Wx::TextCtrl->new( $self, -1, "", &Wx::wxDefaultPosition );

	my $heightTxt = Wx::StaticText->new( $self, -1, "Height:", &Wx::wxDefaultPosition, [ 70, 22 ] );
	my $heightValTxt = Wx::TextCtrl->new( $self, -1, "", &Wx::wxDefaultPosition );

	# DEFINE EVENTS
	Wx::Event::EVT_TEXT( $widthValTxt, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_TEXT( $heightValTxt, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	

	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $widthTxt,    1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1->Add( $widthValTxt, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow2->Add( $heightTxt,    1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow2->Add( $heightValTxt, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szMain->Add( $szRow1, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $szRow2, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$self->SetSizer($szMain);

	# SAVE REFERENCES

	$self->{"widthValTxt"}  = $widthValTxt;
	$self->{"heightValTxt"} = $heightValTxt;

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

sub SetWidth {
	my $self = shift;
	my $val  = shift;

	$self->{"widthValTxt"}->SetValue($val);

}

sub GetWidth {
	my $self = shift;

	return $self->{"widthValTxt"}->GetValue();

}

sub SetHeight {
	my $self = shift;
	my $val  = shift;

	$self->{"heightValTxt"}->SetValue($val);

}

sub GetHeight {
	my $self = shift;

	return $self->{"heightValTxt"}->GetValue();

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

