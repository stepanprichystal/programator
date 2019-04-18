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
use aliased 'Packages::ETesting::BasicHelper::Helper' => 'ETHelper';
use aliased 'CamHelpers::CamStepRepeat';

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
	my $IPCfile  = $self->__SetLayoutIPCFile($self);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $settings, 0, &Wx::wxEXPAND );
	$szMain->Add( $IPCfile,  0, &Wx::wxEXPAND );

	$self->SetSizer($szMain);

	# save control references

}

# Set layout for Quick set box
sub __SetLayoutSettings {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Export settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $rbCreateStep = Wx::RadioButton->new( $statBox, -1, "Create ET step", &Wx::wxDefaultPosition, &Wx::wxDefaultSize, &Wx::wxRB_GROUP );
	my $rbCustomStep = Wx::RadioButton->new( $statBox, -1, "Custom ET step", &Wx::wxDefaultPosition, &Wx::wxDefaultSize );

	my $fromStepTxt = Wx::StaticText->new( $parent, -1, "From step", &Wx::wxDefaultPosition, [ 120, 22 ] );
	my @steps = CamStep->GetAllStepNames( $self->{"inCAM"}, $self->{"jobId"} );
	@steps = grep { $_ !~ /et_/ } @steps;
	my $last = $steps[ scalar(@steps) - 1 ];
	my $fromStepCb = Wx::ComboBox->new( $parent, -1, $last, &Wx::wxDefaultPosition, [ 50, 22 ], \@steps, &Wx::wxCB_READONLY );

	my $keepProfilesTxt = Wx::StaticText->new( $parent, -1, "Keep profiles", &Wx::wxDefaultPosition, [ 120, 22 ] );
	my $keepProfilesChb = Wx::CheckBox->new( $parent, -1, "", &Wx::wxDefaultPosition, [ 50, 22 ] );

	my $customStepTxt = Wx::StaticText->new( $parent, -1, "From step", &Wx::wxDefaultPosition, [ 120, 22 ] );
	my @etSteps = CamStep->GetAllStepNames( $self->{"inCAM"}, $self->{"jobId"} );
	@etSteps = sort { $a cmp $b } grep { $_ =~ /et_/ } @etSteps;
	my $customStepCb =
	  Wx::ComboBox->new( $parent, -1, ( scalar(@etSteps) ? $etSteps[0] : 0 ),
						 &Wx::wxDefaultPosition, [ 50, 22 ],
						 \@etSteps, &Wx::wxCB_READONLY );

	# SET EVENTS
	Wx::Event::EVT_RADIOBUTTON( $rbCreateStep, -1, sub { $self->__OnModeChangeHandler(@_) } );
	Wx::Event::EVT_RADIOBUTTON( $rbCustomStep, -1, sub { $self->__OnModeChangeHandler(@_) } );
	Wx::Event::EVT_COMBOBOX( $fromStepCb, -1, sub { $self->__OnStepFromChange(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $fromStepTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1->Add( $fromStepCb,  1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow2->Add( $keepProfilesTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow2->Add( $keepProfilesChb, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow3->Add( $customStepTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow3->Add( $customStepCb,  1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	#$szRow2->Add( $createStepChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	#$szRow2->Add( 5,100, 1, &Wx::wxEXPAND );

	$szStatBox->Add( $rbCreateStep, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( 4, 4, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( 5, 5, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $rbCustomStep, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( 4, 4, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRow3, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	#$szStatBox->Add( $szRow3, 50, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );

	# Set References
	$self->{"fromStepCb"}      = $fromStepCb;
	$self->{"customStepCb"}    = $customStepCb;
	$self->{"keepProfilesChb"} = $keepProfilesChb;
	$self->{"rbCreateStep"}    = $rbCreateStep;
	$self->{"rbCustomStep"}    = $rbCustomStep;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutIPCFile {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'IPC file' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	my $szCol1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szCol2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS
	my $localCopyTxt = Wx::StaticText->new( $parent, -1, "Local copy", &Wx::wxDefaultPosition, [ 120, 22 ] );
	my $localCopyChb = Wx::CheckBox->new( $parent, -1, "", &Wx::wxDefaultPosition, [ 50, 22 ] );

	my $serverCopyTxt = Wx::StaticText->new( $parent, -1, "Sent to server", &Wx::wxDefaultPosition, [ 120, 22 ] );
	my $serverCopyChb = Wx::CheckBox->new( $parent, -1, "", &Wx::wxDefaultPosition, [ 50, 22 ] );
	$serverCopyChb->Disable();

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT
	$szCol1->Add( $localCopyTxt,  0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szCol1->Add( $serverCopyTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szCol2->Add( $localCopyChb,  0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szCol2->Add( $serverCopyChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szStatBox->Add( $szCol1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szCol2, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	#$szStatBox->Add( $szRow3, 50, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );

	# Set References
	$self->{"localCopyChb"}  = $localCopyChb;
	$self->{"serverCopyChb"} = $serverCopyChb;
	return $szStatBox;
}

# Change export mode
sub __OnModeChangeHandler {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $createStep = $self->{"rbCreateStep"}->GetValue();

	if ( defined $createStep && $createStep == 1 ) {

		$self->{"fromStepCb"}->Enable();
		$self->{"customStepCb"}->Disable();

		my $keepProfiles = ETHelper->KeepProfilesAllowed( $inCAM, $jobId, $self->{"fromStepCb"}->GetValue() );

		# Set sent to server checkbox
		if ( $keepProfiles || !CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $self->{"fromStepCb"}->GetValue() ) ) {
			$self->{"serverCopyChb"}->SetValue(1);
		}
		else {
			$self->{"serverCopyChb"}->SetValue(0);
		}

	}
	else {

		$self->{"fromStepCb"}->Disable();
		$self->{"customStepCb"}->Enable();

		$self->{"localCopyChb"}->SetValue(1);
		$self->{"serverCopyChb"}->SetValue(0);
	}

	# Disable keep profile checkbox
	$self->__UpdateKeepProfile();
}

# Change export from step
sub __OnStepFromChange {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	$self->__UpdateKeepProfile();

}

# Update checkbox keep profile
sub __UpdateKeepProfile {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $createStep = $self->{"rbCreateStep"}->GetValue();

	if ( defined $createStep && $createStep == 1 && ETHelper->KeepProfilesAllowed( $inCAM, $jobId, $self->{"fromStepCb"}->GetValue() ) ) {

		$self->{"keepProfilesChb"}->Enable();
		$self->{"keepProfilesChb"}->SetValue(1);
	}
	else {
		$self->{"keepProfilesChb"}->Disable();
		$self->{"keepProfilesChb"}->SetValue(0);
	}

}

# =====================================================================
# DISABLING CONTROLS
# =====================================================================

sub DisableControls {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Disable controls by ET mode

	my $createStep = $self->{"rbCreateStep"}->GetValue();

	if ( defined $createStep && $createStep == 1 ) {
		$self->{"fromStepCb"}->Enable();
		$self->{"customStepCb"}->Disable();
	}
	else {

		$self->{"fromStepCb"}->Disable();
		$self->{"customStepCb"}->Enable();
	}

	# Disable keep profile checkbox
	#$self->__UpdateKeepProfile();
}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

# Step to test ========================================================

sub SetStepToTest {
	my $self       = shift;
	my $stepToTest = shift;
	my $createStep = shift;

	if ($createStep) {
		$self->{"fromStepCb"}->SetValue($stepToTest);
	}
	else {
		$self->{"customStepCb"}->SetValue($stepToTest);
	}

	#$self->__OnStepChange();

}

sub GetStepToTest {
	my $self = shift;

	if ( $self->{"rbCreateStep"}->GetValue() ) {

		return $self->{"fromStepCb"}->GetValue();
	}
	else {

		return $self->{"customStepCb"}->GetValue();
	}
}

# Create ET step ========================================================

sub SetCreateEtStep {
	my $self  = shift;
	my $value = shift;

	if ($value) {

		$self->{"rbCreateStep"}->SetValue(1);
	}
	else {

		$self->{"rbCustomStep"}->SetValue(1);
	}
}

sub GetCreateEtStep {
	my $self = shift;

	if ( $self->{"rbCreateStep"}->GetValue() ) {

		return 1;
	}
	else {

		return 0;
	}
}

# Keep step profiles ========================================================

sub SetKeepProfiles {
	my $self  = shift;
	my $value = shift;

	$self->{"keepProfilesChb"}->SetValue($value);
}

sub GetKeepProfiles {
	my $self = shift;

	if ( $self->{"keepProfilesChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

# Server copy profiles ========================================================

sub SetLocalCopy {
	my $self  = shift;
	my $value = shift;

	$self->{"localCopyChb"}->SetValue($value);
}

sub GetLocalCopy {
	my $self = shift;

	if ( $self->{"localCopyChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

# Local copy profiles ========================================================

sub SetServerCopy {
	my $self  = shift;
	my $value = shift;

	$self->{"serverCopyChb"}->SetValue($value);
}

sub GetServerCopy {
	my $self = shift;

	if ( $self->{"serverCopyChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

1;
