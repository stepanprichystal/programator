#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::GerExport::View::GerUnitForm;
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
	#$self->{'onTentingChange'} = Event->new();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	#define panels

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS
	my $gerbers = $self->__SetLayoutGerbers($self);
	my $paste   = $self->__SetLayoutPaste($self);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $gerbers, 0, &Wx::wxEXPAND );
	$szMain->Add( 15, 15, 0, &Wx::wxEXPAND );
	$szMain->Add( $paste, 0, &Wx::wxEXPAND );

	$self->SetSizer($szMain);

	# save control references

}

# Set layout for Quick set box
sub __SetLayoutGerbers {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Layers' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	# DEFINE CONTROLS

	my $exportChb = Wx::CheckBox->new( $statBox, -1, "Export", &Wx::wxDefaultPosition );

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szStatBox->Add( $exportChb, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"exportLayersChb"} = $exportChb;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutPaste {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Paste' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szRowMain1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRowMain2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $szRowDetail1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRowDetail2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRowDetail3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRowDetail4 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $exportPasteChb = Wx::CheckBox->new( $statBox, -1, "Export", &Wx::wxDefaultPosition );

	my $stepTxt    = Wx::StaticText->new( $statBox, -1, "Step",               &Wx::wxDefaultPosition, [ 120, 20 ] );
	my $notOriTxt  = Wx::StaticText->new( $statBox, -1, "Add Readme.txt",     &Wx::wxDefaultPosition, [ 120, 20 ] );
	my $profileTxt = Wx::StaticText->new( $statBox, -1, "Add profile", &Wx::wxDefaultPosition, [ 120, 20 ] );
	my $zipFileTxt = Wx::StaticText->new( $statBox, -1, "Zip files",          &Wx::wxDefaultPosition, [ 120, 20 ] );

	my @steps = CamStep->GetAllStepNames( $self->{"inCAM"}, $self->{"jobId"} );
	my $last = $steps[ scalar(@steps) - 1 ];

	my $stepCb     = Wx::ComboBox->new( $statBox, -1, $last, &Wx::wxDefaultPosition, [ 70, 20 ], \@steps, &Wx::wxCB_READONLY );
	my $notOriChb  = Wx::CheckBox->new( $statBox, -1, "",    &Wx::wxDefaultPosition, [ 70, 20 ] );
	my $profileChb = Wx::CheckBox->new( $statBox, -1, "",    &Wx::wxDefaultPosition, [ 70, 20 ] );
	my $zipFileChb = Wx::CheckBox->new( $statBox, -1, "",    &Wx::wxDefaultPosition, [ 70, 20 ] );

	# SET EVENTS

	Wx::Event::EVT_CHECKBOX( $exportPasteChb, -1, sub { $self->__OnExportPasteChange(@_) } );

	# BUILD STRUCTURE OF LAYOUT

	$szRowDetail1->Add( $stepTxt, 0, &Wx::wxALL, 0 );
	$szRowDetail1->Add( $stepCb,  0, &Wx::wxALL, 0 );

	$szRowDetail2->Add( $notOriTxt, 0, &Wx::wxALL, 0 );
	$szRowDetail2->Add( $notOriChb, 0, &Wx::wxALL, 0 );

	$szRowDetail3->Add( $profileTxt, 0, &Wx::wxALL, 0 );
	$szRowDetail3->Add( $profileChb, 0, &Wx::wxALL, 0 );

	$szRowDetail4->Add( $zipFileTxt, 0, &Wx::wxALL, 0 );
	$szRowDetail4->Add( $zipFileChb, 0, &Wx::wxALL, 0 );

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

	$self->{"stepCb"}     = $stepCb;
	$self->{"notOriChb"}  = $notOriChb;
	$self->{"profileChb"} = $profileChb;
	$self->{"zipFileChb"} = $zipFileChb;

	return $szStatBox;
}

sub __OnExportPasteChange {
	my $self = shift;

	if ( $self->{"exportPasteChb"}->IsChecked() ) {

		$self->{"stepCb"}->Enable();
		$self->{"notOriChb"}->Enable();
		$self->{"profileChb"}->Enable();
		$self->{"zipFileChb"}->Enable();
	}
	else {

		$self->{"stepCb"}->Disable();
		$self->{"notOriChb"}->Disable();
		$self->{"profileChb"}->Disable();
		$self->{"zipFileChb"}->Disable();
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
	$self->{"zipFileChb"}->SetValue( $info->{"zipFile"} );

	$self->__OnExportPasteChange();

}

sub GetPasteInfo {
	my $self = shift;

	

	my %info = %{$self->{"pasteInfo"}};

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
	my $self = shift;

	$self->{"layers"} = shift;
}

sub GetLayers {
	my $self = shift;

	return $self->{"layers"};
}

1;
