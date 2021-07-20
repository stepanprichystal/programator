
#-------------------------------------------------------------------------------------------#
# Description: View form for specific sreator
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::SetFrm;
use base qw(Programs::Panelisation::PnlWizard::Forms::CreatorFrmBase);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::Frm::SetStepList';
use aliased 'Programs::Panelisation::PnlCreator::Helpers::Helper' => "PnlCreHelper";
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::Frm::ManualPlacement';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $inCAM  = shift;
	my $jobId  = shift;

	my $self = $class->SUPER::new( PnlCreEnums->StepPnlCreator_SET, $parent, $inCAM, $jobId );

	bless($self);

	$self->__SetLayout();

	# DEFINE EVENTS
	$self->{"manualPlacementEvt"} = Event->new();

	return $self;
}

# Do specific layout settings for creator
sub __SetLayout {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $setLayout = $self->__SetLayoutSetSettings($self);

	# EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szRow1->Add( $setLayout, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1->AddStretchSpacer(1);

	$szMain->Add( $szRow1, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$self->SetSizer($szMain);

	# SAVE REFERENCES

}

#
sub __SetLayoutSetSettings {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Multiplicity of steps' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	my $szManual = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# Load data, for filling form by values

	# DEFINE CONTROLS
	my @editSteps = PnlCreHelper->GetEditSteps( $self->{"inCAM"}, $self->{"jobId"} );
	my $stepList = SetStepList->new( $statBox, \@editSteps );
	my $pnlPicker = ManualPlacement->new( $statBox, $self->{"jobId"}, $self->GetStep(), "Adjust panel", "Adjust panel settings.", 1, "Clear" );

	# EVENTS
	$stepList->{"stepCountChangedEvt"}->Add( sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	$pnlPicker->{"placementEvt"}->Add( sub       { $self->{"manualPlacementEvt"}->Do(@_) } );
	$pnlPicker->{"clearPlacementEvt"}->Add( sub  { $self->{"creatorSettingsChangedEvt"}->Do() } );

	# BUILD STRUCTURE OF LAYOUT
	$szStatBox->Add( $stepList,  0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->AddSpacer(10);
	$szManual->Add( $pnlPicker, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szManual->Add( 1,40,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 ); # expander 40px heigh of panel picker
	$szStatBox->Add( $szManual, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	
	$szStatBox->AddStretchSpacer(1);

	# SAVE REFERENCES

	$self->{"pnlPicker"} = $pnlPicker;
	$self->{"stepList"}  = $stepList;

	return $szStatBox;
}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

sub SetStepList {
	my $self       = shift;
	my $stepCounts = shift;

	$self->{"stepList"}->SetStepCounts($stepCounts);

}

sub GetStepList {
	my $self = shift;

	return $self->{"stepList"}->GetStepCounts();

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

