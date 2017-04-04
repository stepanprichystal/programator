#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::OutExport::View::OutUnitForm;
use base qw(Wx::Panel);

use Class::Interface;
&implements('Programs::Exporter::ExportChecker::Groups::IUnitForm');

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';

#use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamStepRepeat';
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

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $cooper  = $self->__SetLayoutCooper($self);
	my $control = $self->__SetLayoutControl($self);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $cooper, 0, &Wx::wxEXPAND );
	$szMain->Add( 10, 10, 0, &Wx::wxEXPAND );
	$szMain->Add( $control, 0, &Wx::wxEXPAND );

	$self->SetSizer($szMain);

	# save control references

}

# Set layout for Quick set box
sub __SetLayoutCooper {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Cooperation data' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szRowMain1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRowMain2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRowMain3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $exportCooperChb = Wx::CheckBox->new( $statBox, -1, "Export", &Wx::wxDefaultPosition );

	my $cooperStepTxt = Wx::StaticText->new( $statBox, -1, "Step",      &Wx::wxDefaultPosition );
	my $exportEtTxt   = Wx::StaticText->new( $statBox, -1, "Export ET", &Wx::wxDefaultPosition );

	my $exportETChb = Wx::CheckBox->new( $statBox, -1, "", &Wx::wxDefaultPosition );

	my @steps        = CamStep->GetAllStepNames( $self->{"inCAM"}, $self->{"jobId"} );
	my $last         = $steps[ scalar(@steps) - 1 ];
	my $cooperStepCb = Wx::ComboBox->new( $statBox, -1, $last, &Wx::wxDefaultPosition, [ 70, 22 ], \@steps, &Wx::wxCB_READONLY );

	# SET EVENTS

	Wx::Event::EVT_CHECKBOX( $exportCooperChb, -1, sub { $self->__OnExportCoopChange(@_) } );

	# BUILD STRUCTURE OF LAYOUT

	$szRowMain1->Add( $exportCooperChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRowMain2->Add( $cooperStepTxt, 50, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRowMain2->Add( $cooperStepCb,  50, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRowMain3->Add( $exportEtTxt, 50, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRowMain3->Add( $exportETChb, 50, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szStatBox->Add( $szRowMain1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( 10, 10, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRowMain2, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRowMain3, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# Set References
	$self->{"exportCooperChb"} = $exportCooperChb;
	$self->{"exportETChb"}     = $exportETChb;
	$self->{"cooperStepCb"}    = $cooperStepCb;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutControl {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Control data' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szRowMain1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRowMain2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $exportControlChb = Wx::CheckBox->new( $statBox, -1, "Export", &Wx::wxDefaultPosition );

	my $controlStepTxt = Wx::StaticText->new( $statBox, -1, "Step", &Wx::wxDefaultPosition );

	my @steps         = CamStep->GetAllStepNames( $self->{"inCAM"}, $self->{"jobId"} );
	my $last          = $steps[ scalar(@steps) - 1 ];
	my $controlStepCb = Wx::ComboBox->new( $statBox, -1, $last, &Wx::wxDefaultPosition, [ 70, 22 ], \@steps, &Wx::wxCB_READONLY );

	# SET EVENTS

	Wx::Event::EVT_CHECKBOX( $exportControlChb, -1, sub { $self->__OnExportControlChange(@_) } );

	# BUILD STRUCTURE OF LAYOUT

	$szRowMain1->Add( $exportControlChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRowMain2->Add( $controlStepTxt, 50, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRowMain2->Add( $controlStepCb,  50, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szStatBox->Add( $szRowMain1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( 10, 10, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRowMain2, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# Set References
	$self->{"exportControlChb"} = $exportControlChb;
	$self->{"controlStepCb"}    = $controlStepCb;
	return $szStatBox;
}

sub __OnExportCoopChange {
	my $self = shift;

	$self->DisableControls();

	if ( $self->{"exportCooperChb"}->IsChecked() ) {
		$self->{"exportETChb"}->SetValue(1);
	}else{
		$self->{"exportETChb"}->SetValue(0);
	}
}

sub __OnExportControlChange {
	my $self = shift;

	$self->DisableControls();
}

# =====================================================================
# DISABLING CONTROLS
# =====================================================================

sub DisableControls {
	my $self = shift;

	my $defaultInfo = $self->{"defaultInfo"};

 

	if ( $self->{"exportControlChb"}->IsChecked() ) {

		$self->{"controlStepCb"}->Enable();
	}
	else {

		$self->{"controlStepCb"}->Disable();
	}

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

# Export kooperace ===========================================================

sub SetExportCooper {
	my $self = shift;
	my $val  = shift;

	$self->{"exportCooperChb"}->SetValue($val);
}

sub GetExportCooper {
	my $self = shift;

	if ( $self->{"exportCooperChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

# Cooperation step ===========================================================

sub SetCooperStep {
	my $self = shift;
	my $val  = shift;

	$self->{"cooperStepCb"}->SetValue($val);

}

sub GetCooperStep {
	my $self = shift;

	return $self->{"cooperStepCb"}->GetValue();
}

# Export ET ===========================================================

sub SetExportET {
	my $self = shift;
	my $val  = shift;

	$self->{"exportETChb"}->SetValue($val);
}

sub GetExportET {
	my $self = shift;

	if ( $self->{"exportETChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

# Export control ===========================================================

sub SetExportControl {
	my $self = shift;
	my $val  = shift;

	$self->{"exportControlChb"}->SetValue($val);
}

sub GetExportControl {
	my $self = shift;

	if ( $self->{"exportControlChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

# Cooperation step ===========================================================

sub SetControlStep {
	my $self = shift;
	my $val  = shift;

	$self->{"controlStepCb"}->SetValue($val);

}

sub GetControlStep {
	my $self = shift;

	return $self->{"controlStepCb"}->GetValue();
}

1;
