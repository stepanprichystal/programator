#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::ETExport::View::ETUnitForm;
use base qw(Wx::Panel);

use Class::Interface;
&implements('Programs::Exporter::ExportChecker::Groups::IUnitForm');

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

#use aliased 'CamHelpers::CamLayer';
#use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamStep';

#use aliased 'CamHelpers::CamJob';

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

	# Load data

	$self->__SetLayout();

	# EVENTS

	return $self;
}

sub __SetLayout {
	my $self = shift;

	#define panels

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS
	my $settings = $self->__SetLayoutSettings($self);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $settings, 1, &Wx::wxEXPAND );

	$self->SetSizer($szMain);

	# save control references

}

# Set layout for Quick set box
sub __SetLayoutSettings {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	my $szCol1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szCol2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS
	my $stepTxt = Wx::StaticText->new( $parent, -1, "Original step", &Wx::wxDefaultPosition, [ 50, 22 ] );

	my @steps = CamStep->GetAllStepNames( $self->{"inCAM"}, $self->{"jobId"} );
	@steps =  grep { $_ !~ /et_/} @steps;
	my $last = $steps[ scalar(@steps) - 1 ];

	my $stepCb = Wx::ComboBox->new( $parent, -1, $last, &Wx::wxDefaultPosition, [ 50, 22 ], \@steps, &Wx::wxCB_READONLY );

	my $createStepTxt = Wx::StaticText->new( $parent, -1, "Create \"et_".$stepCb->GetValue()."\"", &Wx::wxDefaultPosition, [ 50, 22 ] );
	my $createStepChb = Wx::CheckBox->new( $parent, -1, "", &Wx::wxDefaultPosition, [ 50, 22 ] );
	 

	# SET EVENTS
	Wx::Event::EVT_COMBOBOX( $stepCb, -1, sub { $self->__OnStepChange(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$szCol1->Add( $stepTxt,       0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szCol1->Add( $createStepTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szCol1->Add( 5,5, 1, &Wx::wxEXPAND );

	$szCol2->Add( $stepCb,        0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szCol2->Add( $createStepChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szCol2->Add( 5,100, 1, &Wx::wxEXPAND );

	$szStatBox->Add( $szCol1, 50, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	$szStatBox->Add( $szCol2, 50, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );

	# Set References
	$self->{"stepCb"}        = $stepCb;
	$self->{"createStepChb"} = $createStepChb;
	$self->{"createStepTxt"} = $createStepTxt;
	
	return $szStatBox;
}

# When change steps
sub __OnStepChange {
	my $self = shift;
	
	$self->{"createStepTxt"}->SetLabel("Create  \"et_".$self->{"stepCb"}->GetValue()."\"");

	# disable "create et step" if doesnt exist
	$self->DisableControls();
}

# =====================================================================
# DISABLING CONTROLS
# =====================================================================

sub DisableControls {
	my $self = shift;

	# disable "create et step" if doesnt exist
	my $actualStep = $self->{"stepCb"}->GetValue();
	unless ( $self->{"defaultInfo"}->StepExist( "et_" . $actualStep ) ) {

		$self->{"createStepChb"}->Disable();
		$self->{"createStepChb"}->SetValue(1);

	}
	else {
		$self->{"createStepChb"}->Enable();
	}
 
}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

# Step to test ========================================================

sub SetStepToTest {
	my $self  = shift;
	my $value = shift;

	$self->{"stepCb"}->SetValue($value);
	$self->__OnStepChange();
	
}

sub GetStepToTest {
	my $self = shift;
	return $self->{"stepCb"}->GetValue();
}

# Create ET step ========================================================

sub SetCreateEtStep {
	my $self = shift;
	my $value = shift;

	$self->{"createStepChb"}->SetValue($value);
}

sub GetCreateEtStep {
	my $self = shift;

	if ( $self->{"createStepChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

1;
