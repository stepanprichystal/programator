
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
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# Add empty item

	# DEFINE CONTROLS
	my $jobSrcTxt = Wx::StaticText->new( $self, -1, "Source job", &Wx::wxDefaultPosition, [ -1, 25 ] );
	my $jobSrcValTxt = Wx::TextCtrl->new( $self, -1, "", &Wx::wxDefaultPosition, [ -1, 25 ],  &Wx::wxTE_READONLY );

 

	my $pnlPickerTxt = Wx::StaticText->new( $self, -1, "Manual adjustment", &Wx::wxDefaultPosition, [ -1, 25 ] );
	my $pnlPicker = ManualPlacement->new( $self,
										  $self->{"jobId"}, $self->GetStep(), "Adjust panel",
										  "Adjust panel settings.",
										  1, "Clear" );
	

	 

	# DEFINE EVENTS

	$pnlPicker->{"placementEvt"}->Add( sub      { $self->{"manualPlacementEvt"}->Do(@_) } );
	$pnlPicker->{"clearPlacementEvt"}->Add( sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $jobSrcTxt,    1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1->Add( $jobSrcValTxt, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow2->Add( $pnlPickerTxt, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow2->Add( $pnlPicker,    1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szMain->Add( $szRow1, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $szRow2, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$self->SetSizer($szMain);

	# SAVE REFERENCES

	$self->{"pnlPicker"} = $pnlPicker;
	$self->{"jobSrcValTxt"} = $jobSrcValTxt;
	
	
}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

sub SetSrcJobId {
	my $self = shift;
	my $val  = shift;

	$self->{"jobSrcValTxt"}->SetValue($val) if ( defined $val );
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

