#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::ScoExport::View::ScoUnitForm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';

#use aliased 'CamHelpers::CamLayer';
#use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamStep';
use aliased 'Packages::Export::ScoreExport::Enums' => "ScoExport";

#use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;

	my $inCAM = shift;
	my $jobId = shift;

	my $self = $class->SUPER::new($parent);

	bless($self);

	$self->{"inCAM"} = $inCAM;
	$self->{"jobId"} = $jobId;

	# Load data

	$self->__SetLayout();

	#$self->__SetName();

	#$self->Disable();

	#$self->SetBackgroundColour($Widgets::Style::clrLightBlue);

	# EVENTS
	$self->{'onCustomerJumpChange'} = Event->new();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	#define panels

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS
	my $settings = $self->__SetLayoutSettings($self);
	my $optimize   = $self->__SetLayoutOptimize($self);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $settings, 0, &Wx::wxEXPAND );
	$szMain->Add( $settings, 0, &Wx::wxEXPAND );

	$self->SetSizer($szMain);

	# save control references

}

# Set layout for Quick set box
sub __SetLayoutSettings {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szRowDetail1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szRowDetail2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $coreThickTxt = Wx::StaticText->new( $statBox, -1, "Core thick", &Wx::wxDefaultPosition, [ 120, 20 ] );
	my $coreThickValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 20, $self->{"rowHeight"} ] );

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT
	$szRowDetail1->Add( $coreThickTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRowDetail1->Add( $coreThickValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szStatBox->Add( $szRowDetail1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# Set References
	$self->{"coreThickValTxt"} = $coreThickValTxt;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutOptimize {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Paste' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szRowMain1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRowMain2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRowMain3 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS

	my $optimizeTxt = Wx::StaticText->new( $statBox, -1, "Optimize",      &Wx::wxDefaultPosition, [ 120, 20 ] );
	my $typeTxt     = Wx::StaticText->new( $statBox, -1, "Type",          &Wx::wxDefaultPosition, [ 120, 20 ] );
	my $jumpTxt     = Wx::StaticText->new( $statBox, -1, "Customer jump", &Wx::wxDefaultPosition, [ 120, 20 ] );

	my @optType = ( "yes", "no", "manual" );
	my @scoreType = ( "classic", "one direction" );

	my $optimizeCb =
	  Wx::ComboBox->new( $statBox, -1, $optType[ scalar(@optType) - 1 ], &Wx::wxDefaultPosition, [ 70, 20 ], \@optType, &Wx::wxCB_READONLY );
	my $scoreTypeCb =
	  Wx::ComboBox->new( $statBox, -1, $scoreType[ scalar(@scoreType) - 1 ], &Wx::wxDefaultPosition, [ 70, 20 ], \@scoreType, &Wx::wxCB_READONLY );
	my $jumpTxtChb = Wx::CheckBox->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 70, 20 ] );

	# SET EVENTS

	Wx::Event::EVT_CHECKBOX( $jumpTxtChb, -1, sub { $self->__OnCustomerJumpChange(@_) } );

	# BUILD STRUCTURE OF LAYOUT

	$szRowMain1->Add( $stepTxt, 0, &Wx::wxALL, 0 );
	$szRowMain1->Add( $stepCb,  0, &Wx::wxALL, 0 );

	$szRowMain2->Add( $notOriTxt, 0, &Wx::wxALL, 0 );
	$szRowMain2->Add( $notOriChb, 0, &Wx::wxALL, 0 );

	$szRowMain3->Add( $profileTxt, 0, &Wx::wxALL, 0 );
	$szRowMain3->Add( $profileChb, 0, &Wx::wxALL, 0 );

	$szStatBox->Add( $szRowMain1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRowMain2, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRowMain3, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# Set References

	$self->{"optimizeCb"}  = $optimizeCb;
	$self->{"scoreTypeCb"} = $scoreTypeCb;
	$self->{"jumpTxtChb"}  = $jumpTxtChb;

	return $szStatBox;
}

sub __OnCustomerJumpChange {
	my $self = shift;

	my $val;

	if ( $self->{"jumpTxtChb"}->IsChecked() ) {
		$val = 1;
	}
	else {
		$val = 0;
	}

	$self->{"onCustomerJumpChange"}->Do($val);

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================
# core thick in mm
sub SetCoreThick {
	my $self  = shift;
	my $value = shift;
	$self->{"coreThickValTxt"}->SetValue($value);
}

sub GetCoreThick {
	my $self = shift;

	my $value = $self->{"coreThickValTxt"}->GetValue();

	$value =~ s/,/\./;

	return $value;
}

# Optimize yes/no/manual
sub SetOptimize {
	my $self = shift;
	my $val  = shift;

	my $valControl;

	if ( $val eq ScoExport->Optimize_YES ) {

		$valControl = "yes";
	}
	elsif ( $val eq ScoExport->Optimize_NO ) {

		$valControl = "no";
	}
	elsif ( $val eq ScoExport->Optimize_MANUAL ) {

		$valControl = "manual";
	}

	$self->{"optimizeCb"}->SetValue($valControl);
}

sub GetOptimize {
	my $self = shift;

	my $valControl = $self->{"optimizeCb"}->GetValue();
	my $val;

	if ( $valControl eq "yes" ) {

		$val = ScoExport->Optimize_YES;
	}
	elsif ( $valControl eq "no" ) {

		$val = ScoExport->Optimize_NO;
	}
	elsif ( $valControl eq "manual" ) {

		$val = ScoExport->Optimize_MANUAL;
	}

	return $val;
}

# Scoring type classic/one direction
sub SetScoringType {
	my $self = shift;
	my $self = shift;
	my $val  = shift;

	my $valControl;

	if ( $val eq ScoExport->Type_ONEDIR ) {

		$valControl = "One direction";
	}
	elsif ( $val eq ScoExport->Type_CLASSIC ) {

		$valControl = "Classic";
	}

	$self->{"scoreTypeCb"}->SetValue($valControl);
}

sub GetScoringType {
	my $self = shift;

	my $valControl = $self->{"scoreTypeCb"}->GetValue();
	my $val;

	if ( $valControl eq "One direction" ) {

		$val = ScoExport->Type_ONEDIR;
	}
	elsif ( $valControl eq "no" ) {

		$val = ScoExport->Type_CLASSIC;
	}

	return $val;
}

# Customer jump scoring
sub SetCustomerJump {
	my $self = shift;
	my $value = shift;
	
	$self->{"jumpTxtChb"}->SetValue($value);
}

sub GetCustomerJump {
	my $self = shift;
 
	if($self->{"jumpTxtChb"}->IsChecked()){
		
		return 1;
	}else{
		
		return 0;
	}
}

1;
