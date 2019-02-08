#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::ImpExport::View::ImpUnitForm;
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
	my $pdfSettings     = $self->__SetPdfSettings($self);
	my $stackupSettings = $self->__SetStackupSettings($self);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $pdfSettings,     1, &Wx::wxEXPAND );
	$szMain->Add( $stackupSettings, 1, &Wx::wxEXPAND );

	$self->SetSizer($szMain);

	# save control references

}

# Set layout for Quick set box
sub __SetPdfSettings {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Measurement pdf' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	my $szCol1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szCol2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS
	my $exportTxt = Wx::StaticText->new( $parent, -1, "Export", &Wx::wxDefaultPosition, [ 40, 22 ] );
	my $exportMeasurePdfChb = Wx::CheckBox->new( $parent, -1, "", &Wx::wxDefaultPosition, [ 50, 22 ] );

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT
	$szCol1->Add( $exportTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szCol1->Add( 5, 5, 0, &Wx::wxEXPAND );

	$szCol2->Add( $exportMeasurePdfChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szCol2->Add( 5, 5, 0, &Wx::wxEXPAND );

	$szStatBox->Add( $szCol1, 40, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	$szStatBox->Add( $szCol2, 60, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );

	# Set References
	$self->{"exportMeasurePdfChb"} = $exportMeasurePdfChb;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetStackupSettings {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'InStack xml to MultiCal xml' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	my $szCol1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szCol2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS
	my $stackupTxt = Wx::StaticText->new( $parent, -1, "Generate stackup", &Wx::wxDefaultPosition, [ 40, 22 ] );
	my $buildMLStackupChb = Wx::CheckBox->new( $parent, -1, "", &Wx::wxDefaultPosition, [ 50, 22 ] );

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT
	$szCol1->Add( $stackupTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szCol1->Add( 5, 5, 0, &Wx::wxEXPAND );

	$szCol2->Add( $buildMLStackupChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szCol2->Add( 5, 5, 0, &Wx::wxEXPAND );

	$szStatBox->Add( $szCol1, 40, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	$szStatBox->Add( $szCol2, 60, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );

	# Set References
	$self->{"buildMLStackupChb"} = $buildMLStackupChb;

	return $szStatBox;
}

# =====================================================================
# DISABLING CONTROLS
# =====================================================================

sub DisableControls {
	my $self = shift;

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

# Export impedance measurement pdf ====================================

sub SetExportMeasurePdf {
	my $self  = shift;
	my $value = shift;

	$self->{"exportMeasurePdfChb"}->SetValue($value);

}

sub GetExportMeasurePdf {
	my $self = shift;

	if ( $self->{"exportMeasurePdfChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

# # Create MultiCall pdf from InStack =================================

sub SetBuildMLStackup {
	my $self  = shift;
	my $value = shift;

	$self->{"buildMLStackupChb"}->SetValue($value);
}

sub GetBuildMLStackup {
	my $self = shift;

	if ( $self->{"buildMLStackupChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

1;
