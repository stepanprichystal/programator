
#-------------------------------------------------------------------------------------------#
# Description: View form for specific sreator
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::MatrixFrm;
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
use constant SPACE0x0   => "0 x 0mm";
use constant SPACE2x2   => "2 x 2mm";
use constant SPACE45x45 => "4,5 x 4,5mm";
use constant SPACE10x10 => "10 x 10mm";

sub new {
	my $class  = shift;
	my $parent = shift;
	my $inCAM  = shift;
	my $jobId  = shift;

	my $self = $class->SUPER::new( PnlCreEnums->StepPnlCreator_MATRIX, $parent, $inCAM, $jobId );

	bless($self);

	$self->__SetLayout();

	# PROPERTIES
	
		$self->{"pcbStepsList"}      = [];


	# DEFINE EVENTS

	return $self;
}

sub __SetLayout {
	my $self = shift;

	#define panels

	my $szMain   = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szCustom = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $szRow0 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $pcbStepTxt = Wx::StaticText->new( $self, -1, "PCB step:", &Wx::wxDefaultPosition, [ 70, 25 ] );
	my $pcbStepCB = Wx::ComboBox->new( $self, -1, "", &Wx::wxDefaultPosition, [ -1, -1 ], [""], &Wx::wxCB_READONLY );
	 
	my $multiplicityStatBox   = $self->__SetLayoutMultipl($self);
	my $spacesStatBox         = $self->__SetLayoutSpaces($self);
	my $transformationStatBox = $self->__SetLayoutTransformation($self);

	#$richTxt->Layout();

	# SET EVENTS
	Wx::Event::EVT_TEXT( $pcbStepCB, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	# BUILD STRUCTURE OF LAYOUT

	#$szMain->Add( $szStatBox, 0, &Wx::wxEXPAND );

	# BUILD STRUCTURE OF LAYOUT

	$szRow0->Add( $pcbStepTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szRow0->Add( $pcbStepCB, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$szMain->Add( $szRow0, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$szMain->Add( $multiplicityStatBox,   0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szMain->Add( $spacesStatBox,         0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szMain->Add( $transformationStatBox, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$self->SetSizer($szMain);

	# save control references
	$self->{"pcbStepCB"}  = $pcbStepCB;
	$self->{"szCustomCBMain"} = $szCustom;
	$self->{"szCustomCBMain"} = $szCustom;

}

# Set layout for Quick set box
sub __SetLayoutMultipl {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Step multiplicity' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	# Load data, for filling form by values

	# DEFINE CONTROLS

	my $multiXTxt = Wx::StaticText->new( $statBox, -1, "X", &Wx::wxDefaultPosition, [ 70, 25 ] );
	my $multiXValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 70, 25 ] );

	my $multiYTxt = Wx::StaticText->new( $statBox, -1, "Y", &Wx::wxDefaultPosition, [ 70, 25 ] );
	my $multiYValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 70, 25 ] );

	# DEFINE EVENTS
	Wx::Event::EVT_TEXT( $multiXValTxt, -1, sub {   $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_TEXT( $multiYValTxt, -1, sub {   $self->{"creatorSettingsChangedEvt"}->Do() } );

	$szStatBox->Add( $multiXTxt,    1, &Wx::wxEXPAND );
	$szStatBox->Add( $multiXValTxt, 1, &Wx::wxEXPAND );

	$szStatBox->Add( $multiYTxt,    1, &Wx::wxEXPAND );
	$szStatBox->Add( $multiYValTxt, 1, &Wx::wxEXPAND );

	# save control references
	$self->{"multiXValTxt"} = $multiXValTxt;
	$self->{"multiYValTxt"} = $multiYValTxt;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutSpaces {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Step spaces' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# Load data, for filling form by values

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);    # row for custom control, which are added by inherit class
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $choicesTxt = Wx::StaticText->new( $statBox, -1, "Quick choice:", &Wx::wxDefaultPosition, [ 70, 25 ] );
	my @choices = ( SPACE0x0, SPACE2x2, SPACE45x45, SPACE10x10 );
	my $quickSpaceCb =
	  Wx::ComboBox->new( $statBox, -1, $choices[1], &Wx::wxDefaultPosition, [ 50, 25 ], \@choices, &Wx::wxCB_READONLY );

	my $spaceXTxt = Wx::StaticText->new( $statBox, -1, "Space X:", &Wx::wxDefaultPosition, [ 70, 25 ] );
	my $spaceValXTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 70, 25 ] );

	my $spaceYTxt = Wx::StaticText->new( $statBox, -1, "Space Y:", &Wx::wxDefaultPosition, [ 70, 25 ] );
	my $spaceValYTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 70, 25 ] );

	# DEFINE EVENTS
	Wx::Event::EVT_TEXT( $spaceValXTxt, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );
	Wx::Event::EVT_TEXT( $spaceValYTxt, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	Wx::Event::EVT_TEXT( $quickSpaceCb, -1, sub { $self->__OnQuickSpaceChanged( $quickSpaceCb->GetValue() ) } );

	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $choicesTxt,   1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $quickSpaceCb, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow2->Add( $spaceXTxt,    1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $spaceValXTxt, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRow3->Add( $spaceYTxt,    1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow3->Add( $spaceValYTxt, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRow3, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# save control references
	$self->{"spaceValXTxt"} = $spaceValXTxt;
	$self->{"spaceValYTxt"} = $spaceValYTxt;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutTransformation {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Step transformation' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	# Load data, for filling form by values

	# DEFINE CONTROLS

	my $rotationTxt = Wx::StaticText->new( $statBox, -1, "Rotation", &Wx::wxDefaultPosition, [ 70, 25 ] );

	my @choices = ( 0, 90, 180, 270 );
	my $rotationCb =
	  Wx::ComboBox->new( $statBox, -1, $choices[1], &Wx::wxDefaultPosition, [ 50, 25 ], \@choices, &Wx::wxCB_READONLY );

	# DEFINE EVENTS
	Wx::Event::EVT_TEXT( $rotationCb, -1, sub { $self->{"creatorSettingsChangedEvt"}->Do() } );

	$szStatBox->Add( $rotationTxt, 0, &Wx::wxEXPAND );
	$szStatBox->Add( $rotationCb,  0, &Wx::wxEXPAND );

	# save control references

	$self->{"rotationCb"} = $rotationCb;

	return $szStatBox;
}


sub __ActiveAreaChanged {
	my $self = shift;

	if ( defined $self->GetActiveAreaW() && defined $self->GetBorderLeft() && defined $self->GetBorderRight() ) {

		$self->SetWidth( $self->GetActiveAreaW() + $self->GetBorderLeft() + $self->GetBorderRight() );
	}
	if ( defined $self->GetActiveAreaH() && defined $self->GetBorderTop() && defined $self->GetBorderBot() ) {

		$self->SetHeight( $self->GetActiveAreaH() + $self->GetBorderTop() + $self->GetBorderBot() );
	}

}

sub __OnQuickSpaceChanged {
	my $self           = shift;
	my $quickSpaceType = shift;

	if ( $quickSpaceType eq SPACE0x0 ) {

		$self->{"spaceValXTxt"}->SetValue(0);
		$self->{"spaceValYTxt"}->SetValue(0);

	}
	elsif ( $quickSpaceType eq SPACE2x2 ) {

		$self->{"spaceValXTxt"}->SetValue(2);
		$self->{"spaceValYTxt"}->SetValue(2);

	}
	elsif ( $quickSpaceType eq SPACE45x45 ) {

		$self->{"spaceValXTxt"}->SetValue(4.5);
		$self->{"spaceValYTxt"}->SetValue(4.5);

	}
	elsif ( $quickSpaceType eq SPACE10x10 ) {

		$self->{"spaceValXTxt"}->SetValue(10);
		$self->{"spaceValYTxt"}->SetValue(10);

	}

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

sub SetPCBStepsList {
	my $self = shift;
	my $val  = shift;

	$self->{"pcbStepsList"} = $val;

	$self->{"pcbStepCB"}->Clear();

	# Set cb classes
	foreach my $step ( @{ $self->{"pcbStepsList"} } ) {

		$self->{"pcbStepCB"}->Append($step);
	}

}

sub GetPCBStepsList {
	my $self = shift;

	return $self->{"pcbStepsList"};

}



sub SetPCBStep {
	my $self = shift;
	my $val  = shift;

	$self->{"pcbStepCB"}->SetValue($val) if(defined $val);

}

sub GetPCBStep {
	my $self = shift;

	return $self->{"pcbStepCB"}->GetValue();

}

sub SetStepMultiplX {
	my $self = shift;
	my $val  = shift;

	$self->{"multiXValTxt"}->SetValue($val)if(defined $val);;
}

sub GetStepMultiplX {
	my $self = shift;

	return $self->{"multiXValTxt"}->GetValue();
}

sub SetStepMultiplY {
	my $self = shift;
	my $val  = shift;

	$self->{"multiYValTxt"}->SetValue($val)if(defined $val);;
}

sub GetStepMultiplY {
	my $self = shift;

	return $self->{"multiYValTxt"}->GetValue();
}

sub SetStepSpaceX {
	my $self = shift;
	my $val  = shift;

	$self->{"spaceValXTxt"}->SetValue($val) if(defined $val);;
}

sub GetStepSpaceX {
	my $self = shift;

	return $self->{"spaceValXTxt"}->GetValue();
}

sub SetStepSpaceY {
	my $self = shift;
	my $val  = shift;

	$self->{"spaceValYTxt"}->SetValue($val) if(defined $val);;
}

sub GetStepSpaceY {
	my $self = shift;

	return $self->{"spaceValYTxt"}->GetValue();
}

sub SetStepRotation {
	my $self = shift;
	my $val  = shift;

	$self->{"rotationCb"}->SetValue($val) if(defined $val);;
}

sub GetStepRotation {
	my $self = shift;

	return $self->{"rotationCb"}->GetValue();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

