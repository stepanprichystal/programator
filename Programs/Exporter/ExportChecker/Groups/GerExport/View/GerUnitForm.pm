#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::GerExport::View::GerUnitForm;
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
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Gerbers::Jetprint::Enums' => "EnumsJet";

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

	# GER values passed from other group
	$self->{'layers'} = [];    # store information about layers

	# EVENTS
	#$self->{'onTentingChange'} = Event->new();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	#define panels

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $szRow1     = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);


	# DEFINE CONTROLS
	my $gerbers = $self->__SetLayoutGerbers($self);
	my $jetPrint = $self->__SetLayoutJetprint($self);
	my $paste    = $self->__SetLayoutPaste($self);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szRow1->Add( $jetPrint, 50, &Wx::wxEXPAND | &Wx::wxLEFT, 2 );
	$szRow1->Add( $gerbers, 50, &Wx::wxEXPAND | &Wx::wxLEFT, 2 );

	$szMain->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szMain->Add( $paste, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$self->SetSizer($szMain);

	# save control references

}

# Set layout for Quick set box
sub __SetLayoutGerbers {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Single layers' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# DEFINE CONTROLS

	my $exportChb = Wx::CheckBox->new( $statBox, -1, "Export", &Wx::wxDefaultPosition );

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szStatBox->Add( $exportChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( 5, 5, 1, &Wx::wxEXPAND );

	# Set References
	$self->{"exportLayersChb"} = $exportChb;

	return $szStatBox;
}

# Set layout for Jetprint
sub __SetLayoutJetprint {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Jetprint data' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# DEFINE CONTROLS

	my $exportChb = Wx::CheckBox->new( $statBox, -1, "Export", &Wx::wxDefaultPosition );

	my $fiducSunRb = Wx::RadioButton->new( $statBox, -1, "Fiduc:Sun 5mm", &Wx::wxDefaultPosition, &Wx::wxDefaultSize, &Wx::wxRB_GROUP );
	my $fiducHoleRb = Wx::RadioButton->new( $statBox, -1, "Fiduc:OLEC 3mm", &Wx::wxDefaultPosition, &Wx::wxDefaultSize );

	my $rotationChb = Wx::CheckBox->new( $statBox, -1, "Rotate 90°", &Wx::wxDefaultPosition );

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szStatBox->Add( $exportChb,   1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $rotationChb, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $fiducSunRb,  1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $fiducHoleRb, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"exportJetprintChb"} = $exportChb;
	$self->{"fiducSunRb"}        = $fiducSunRb;
	$self->{"fiducHoleRb"}       = $fiducHoleRb;
	$self->{"rotationChb"}       = $rotationChb;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutPaste {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Paste data' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szRowMain1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRowMain2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $szRowDetail1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRowDetail2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRowDetail3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRowDetail4 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $exportPasteChb = Wx::CheckBox->new( $statBox, -1, "Export", &Wx::wxDefaultPosition, [ 10, 20 ]  );

	my $stepTxt = Wx::StaticText->new( $statBox, -1, "Step", &Wx::wxDefaultPosition, [ 10, 20 ] );
	my @steps = CamStep->GetAllStepNames( $self->{"inCAM"}, $self->{"jobId"} );
	my $last = $steps[ scalar(@steps) - 1 ];

	my $stepCb           = Wx::ComboBox->new( $statBox, -1, $last,             &Wx::wxDefaultPosition, [ 10, 20 ], \@steps, &Wx::wxCB_READONLY );
	my $notOriChb        = Wx::CheckBox->new( $statBox, -1, "Readme.txt",      &Wx::wxDefaultPosition, [ 10, 20 ] );
	my $profileChb       = Wx::CheckBox->new( $statBox, -1, "Add outer prof.", &Wx::wxDefaultPosition, [ 10, 20 ] );
	my $singleProfileChb = Wx::CheckBox->new( $statBox, -1, "Add inner prof.", &Wx::wxDefaultPosition, [ 10, 20 ] );
	my $addFiducialChb   = Wx::CheckBox->new( $statBox, -1, "Add fiducials",   &Wx::wxDefaultPosition, [ 10, 20 ] );
	my $zipFileChb       = Wx::CheckBox->new( $statBox, -1, "Zip files",       &Wx::wxDefaultPosition, [ 10, 20 ] );

	# SET EVENTS

	Wx::Event::EVT_CHECKBOX( $exportPasteChb, -1, sub { $self->__OnExportPasteChange(@_) } );
	Wx::Event::EVT_COMBOBOX( $stepCb, -1, sub { $self->__OnStepChange(@_) } );

	# BUILD STRUCTURE OF LAYOUT

	$szRowDetail1->Add( $stepTxt, 50, &Wx::wxALL, 0 );
	$szRowDetail1->Add( $stepCb,  50, &Wx::wxALL, 0 );

	$szRowDetail2->Add( $profileChb, 50, &Wx::wxALL, 0 );
	$szRowDetail2->Add( $notOriChb,  50, &Wx::wxALL, 0 );

	$szRowDetail3->Add( $singleProfileChb, 50, &Wx::wxALL, 0 );
	$szRowDetail3->Add( $zipFileChb,       50, &Wx::wxALL, 0 );

	$szRowDetail4->Add( $addFiducialChb, 50, &Wx::wxALL, 0 );
	$szRowDetail4->Add( 5, 5, 50, &Wx::wxALL, 0 );

	$szRowMain1->Add( $exportPasteChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRowMain2->Add( $szRowDetail1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRowMain2->Add( $szRowDetail2, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRowMain2->Add( $szRowDetail3, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRowMain2->Add( $szRowDetail4, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szStatBox->Add( $szRowMain1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( 10, 10, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRowMain2, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# Set References
	$self->{"exportPasteChb"} = $exportPasteChb;

	$self->{"stepCb"}           = $stepCb;
	$self->{"notOriChb"}        = $notOriChb;
	$self->{"profileChb"}       = $profileChb;
	$self->{"singleProfileChb"} = $singleProfileChb;
	$self->{"addFiducialChb"}   = $addFiducialChb;
	$self->{"zipFileChb"}       = $zipFileChb;

	return $szStatBox;
}

sub __OnExportPasteChange {
	my $self = shift;

	if ( $self->{"exportPasteChb"}->IsChecked() ) {

		$self->{"stepCb"}->Enable();
		$self->{"notOriChb"}->Enable();
		$self->{"profileChb"}->Enable();
		$self->{"zipFileChb"}->Enable();
		$self->{"singleProfileChb"}->Enable();
		$self->{"addFiducialChb"}->Enable();
	}
	else {

		$self->{"stepCb"}->Disable();
		$self->{"notOriChb"}->Disable();
		$self->{"profileChb"}->Disable();
		$self->{"zipFileChb"}->Disable();
		$self->{"singleProfileChb"}->Disable();
		$self->{"addFiducialChb"}->Disable();

	}

}

# When change steps
sub __OnStepChange {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $stepName    = $self->{"stepCb"}->GetValue();
	my $srExist     = CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $stepName );
	my $mpanelExist = $self->{"defaultInfo"}->StepExist("mpanel");

	unless ( $srExist && $mpanelExist ) {
		$self->{"singleProfileChb"}->Disable();
		$self->{"singleProfileChb"}->SetValue(0);
		$self->{"addFiducialChb"}->Disable();
		$self->{"addFiducialChb"}->SetValue(0);
	}
	else {
		$self->{"singleProfileChb"}->Enable();
		$self->{"addFiducialChb"}->Enable();
	}

}

sub OnPREGroupLayerSettChanged {
	my $self  = shift;
	my $layer = shift;

	my $l = ( grep { $_->{"name"} eq $layer->{"name"} } @{ $self->{"layers"} } )[0];

	#die "Layer was not found by layer name:" . $layer->{"name"};

	if ( defined $l ) {

		foreach my $key ( keys %{$layer} ) {

			$l->{$key} = $layer->{$key};
		}
	}
}

# =====================================================================
# DISABLING CONTROLS
# =====================================================================

sub DisableControls {
	my $self = shift;

	my $defaultInfo = $self->{"defaultInfo"};

	# JETPRINT Gerbers

	if ( !$defaultInfo->LayerExist("pc") && !$defaultInfo->LayerExist("ps") ) {
		$self->{"exportJetprintChb"}->Disable();
		$self->{"fiducSunRb"}->Disable();
		$self->{"fiducHoleRb"}->Disable();
		$self->{"rotationChb"}->Disable();
	}

	# PASTE FILES
	my $mpanelExist = $defaultInfo->StepExist("mpanel");

	unless ($mpanelExist) {
		$self->{"singleProfileChb"}->Disable();
		$self->{"addFiducialChb"}->Disable();
	}

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

# Paste file info ========================================================

sub SetPasteInfo {
	my $self = shift;
	my $info = shift;

	# save all info
	$self->{"pasteInfo"} = $info;

	$self->{"exportPasteChb"}->SetValue( $info->{"export"} );
	$self->{"stepCb"}->SetValue( $info->{"step"} );
	$self->{"notOriChb"}->SetValue( $info->{"notOriginal"} );
	$self->{"profileChb"}->SetValue( $info->{"addProfile"} );
	$self->{"singleProfileChb"}->SetValue( $info->{"addSingleProfile"} );
	$self->{"addFiducialChb"}->SetValue( $info->{"addFiducial"} );
	$self->{"zipFileChb"}->SetValue( $info->{"zipFile"} );

	$self->__OnExportPasteChange();

}

sub GetPasteInfo {
	my $self = shift;

	my %info = %{ $self->{"pasteInfo"} };

	if ( $self->{"exportPasteChb"}->IsChecked() ) {
		$info{"export"} = 1;
	}
	else {
		$info{"export"} = 0;
	}

	if ( $self->{"notOriChb"}->IsChecked() ) {
		$info{"notOriginal"} = 1;
	}
	else {
		$info{"notOriginal"} = 0;
	}

	if ( $self->{"profileChb"}->IsChecked() ) {
		$info{"addProfile"} = 1;
	}
	else {
		$info{"addProfile"} = 0;
	}

	if ( $self->{"singleProfileChb"}->IsChecked() ) {
		$info{"addSingleProfile"} = 1;
	}
	else {
		$info{"addSingleProfile"} = 0;
	}

	if ( $self->{"addFiducialChb"}->IsChecked() ) {
		$info{"addFiducial"} = 1;
	}
	else {
		$info{"addFiducial"} = 0;
	}

	if ( $self->{"zipFileChb"}->IsChecked() ) {
		$info{"zipFile"} = 1;
	}
	else {
		$info{"zipFile"} = 0;
	}

	$info{"step"} = $self->{"stepCb"}->GetValue();

	return \%info;
}

# Export layers ===========================================================

sub SetExportLayers {
	my $self = shift;
	my $val  = shift;

	$self->{"exportLayersChb"}->SetValue($val);
}

sub GetExportLayers {
	my $self = shift;

	if ( $self->{"exportLayersChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

# Layers to export ========================================================

sub SetLayers {
	my $self   = shift;
	my $layers = shift;

	$self->{"layers"} = $layers;
}

sub GetLayers {
	my $self = shift;

	return $self->{"layers"};
}

# Export jetprint gerbers =========================================================

sub SetJetprintInfo {
	my $self = shift;
	my $info = shift;

	$self->{"exportJetprintChb"}->SetValue( $info->{"exportGerbers"} );

	if ( $info->{"fiducType"} eq EnumsJet->Fiducials_SUN5 ) {

		$self->{"fiducSunRb"}->SetValue(1);
	}
	elsif ( $info->{"fiducType"} eq EnumsJet->Fiducials_HOLE3 ) {

		$self->{"fiducHoleRb"}->SetValue(1);
	}
	else {
		die "Ilegal fiduc type:" . $info->{"fiducType"};
	}

	$self->{"rotationChb"}->SetValue( $info->{"rotation"} );
}

sub GetJetprintInfo {
	my $self = shift;

	my %info = ();

	if ( $self->{"exportJetprintChb"}->IsChecked() ) {
		$info{"exportGerbers"} = 1;
	}
	else {
		$info{"exportGerbers"} = 0;
	}

	if ( $self->{"fiducSunRb"}->GetValue() ) {

		$info{"fiducType"} = EnumsJet->Fiducials_SUN5;

	}
	elsif ( $self->{"fiducHoleRb"}->GetValue() ) {

		$info{"fiducType"} = EnumsJet->Fiducials_HOLE3;
	}
	else {

		die "Ilegal fiduc type";
	}

	if ( $self->{"rotationChb"}->IsChecked() ) {
		$info{"rotation"} = 1;
	}
	else {
		$info{"rotation"} = 0;
	}

	return \%info;
}

1;
