
#-------------------------------------------------------------------------------------------#
# Description: View form for specific sreator
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::PreviewFrm;
use base qw(Programs::Panelisation::PnlWizard::Forms::CreatorFrmBase);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::Frm::ManualPlacement';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $inCAM  = shift;
	my $jobId  = shift;

	my $self = $class->SUPER::new( PnlCreEnums->StepPnlCreator_PREVIEW, $parent, $inCAM, $jobId );

	bless($self);

	$self->__SetLayout();

	# Properties

	$self->{"panelJSON"} = undef;

	# DEFINE EVENTS
	$self->{"manualPlacementEvt"} = Event->new();

	return $self;
}

# Do specific layout settings for creator
sub __SetLayout {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# Add empty item

	# DEFINE CONTROLS
	my $layoutSteps = $self->__SetLayoutSteps($self);

	# DEFINE EVENTS

	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $layoutSteps, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1->AddStretchSpacer(1);

	$szMain->Add( $szRow1, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$self->SetSizer($szMain);

	# SAVE REFERENCES

}

# Set layout for Quick set box
sub __SetLayoutSteps {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Step settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# Load data, for filling form by values

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);    # row for custom control, which are added by inherit class
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $jobSrcTxt = Wx::StaticText->new( $statBox, -1, "Source job:", &Wx::wxDefaultPosition, [ 10, 23 ] );
	my $jobSrcValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 10, 23 ] , &Wx::wxTE_READONLY );

	my $pnlPickerTxt = Wx::StaticText->new( $statBox, -1, "Panel adjust:", &Wx::wxDefaultPosition, [ 10, 23 ] );
	my $pnlPicker = ManualPlacement->new( $statBox, $self->{"jobId"}, $self->GetStep(), "Adjust", "Adjust panel settings.", 1, "Clear" );

	# DEFINE EVENTS
	$pnlPicker->{"placementEvt"}->Add( sub      { $self->{"manualPlacementEvt"}->Do(@_) } );
	$pnlPicker->{"clearPlacementEvt"}->Add( sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $jobSrcTxt,    30, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1->Add( $jobSrcValTxt, 70, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow2->Add( $pnlPickerTxt, 30, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow2->Add( $pnlPicker,    70, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow2->Add( 1,40,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 ); # expander 40px heigh of panel picker
	

	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->AddSpacer(5);
	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->AddStretchSpacer(1);

	# save control references
	$self->{"pnlPicker"}    = $pnlPicker;
	$self->{"jobSrcValTxt"} = $jobSrcValTxt;

	return $szStatBox;
}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

sub SetSrcJobId {
	my $self = shift;
	my $val  = shift;

	$self->{"jobSrcValTxt"}->SetValue($val) if ( defined $val && $val ne "" );
}

sub GetSrcJobId {
	my $self = shift;

	return $self->{"jobSrcValTxt"}->GetValue();
}

sub SetPanelJSON {
	my $self = shift;
	my $val  = shift;

	$self->{"panelJSON"} = $val;

}

sub GetPanelJSON {
	my $self = shift;

	return $self->{"panelJSON"};

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

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

