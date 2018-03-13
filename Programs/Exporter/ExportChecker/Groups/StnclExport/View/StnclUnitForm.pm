#-------------------------------------------------------------------------------------------#
# Description: Score export GUI
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::StnclExport::View::StnclUnitForm;
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
use aliased 'CamHelpers::CamStep';
use aliased 'Programs::Stencil::StencilCreator::Helpers::Helper';
use aliased 'Programs::Stencil::StencilCreator::Enums' => 'StnclEnums';

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

	my %stencilInfo = Helper->GetStencilInfo( $self->{"jobId"} );
	$self->{"stencilInfo"} = \%stencilInfo;

	# Load data

	$self->__SetLayout();

	# EVENTS

	return $self;
}

sub __SetLayout {
	my $self = shift;

	#define panels

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $settings  = $self->__SetLayoutSettings($self);
	my $fiducials = $self->__SetLayoutFiducials($self);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $settings, 1, &Wx::wxEXPAND );
	$szMain->Add( 5, 5, 0, &Wx::wxEXPAND );
	$szMain->Add( $fiducials, 1, &Wx::wxEXPAND );

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

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow4 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow5 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow6 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szRowDetail2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $typeTxt = Wx::StaticText->new( $statBox, -1, "Technology", &Wx::wxDefaultPosition, [ 120, 20 ] );
	my $typeValTxt = Wx::StaticText->new( $statBox, -1, $self->{"stencilInfo"}->{"tech"}, &Wx::wxDefaultPosition, [ 90, 20 ] );

	my $nifTxt = Wx::StaticText->new( $statBox, -1, "Export nif", &Wx::wxDefaultPosition, [ 120, 20 ] );
	my $nifChb = Wx::CheckBox->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 90, 22 ] );

	my $str = "";
	if ( $self->{"stencilInfo"}->{"tech"} eq StnclEnums->Technology_DRILL ) {
		$str = "Export NC data";
	}
	elsif ( $self->{"stencilInfo"}->{"tech"} eq StnclEnums->Technology_LASER || $self->{"stencilInfo"}->{"tech"} eq StnclEnums->Technology_ETCH ) {
		$str = "Export gerber data";
	}

	my $dataTxt = Wx::StaticText->new( $statBox, -1, $str, &Wx::wxDefaultPosition, [ 120, 20 ] );
	my $dataChb = Wx::CheckBox->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 90, 22 ] );

	my $pdfTxt = Wx::StaticText->new( $statBox, -1, "Export pdf", &Wx::wxDefaultPosition, [ 120, 20 ] );
	my $pdfChb = Wx::CheckBox->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 90, 22 ] );
	
	my $measureDataTxt = Wx::StaticText->new( $statBox, -1, "Export \"pad info\"", &Wx::wxDefaultPosition, [ 120, 20 ] );
	my $measureDataChb = Wx::CheckBox->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 90, 22 ] );

	my $thickTxt = Wx::StaticText->new( $statBox, -1, "Thickness [mm]", &Wx::wxDefaultPosition, [ 120, 20 ] );
 
	my @thick = ( 0.10, 0.120, 0.125, 0.150, 0.175, 2.0, 2.5 );
	
	if( $self->{"stencilInfo"}->{"tech"} eq StnclEnums->Technology_LASER){
		@thick =  ( 0.10, 0.120, 0.130, 0.150, 0.180, 2.0, 2.50 );
	}
	
	my $thickValCb = Wx::ComboBox->new( $statBox, -1, "0", &Wx::wxDefaultPosition, [ 120, 22 ], \@thick, &Wx::wxCB_READONLY );

	# SET EVENTS
 

	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $typeTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1->Add( $typeValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow2->Add( $nifTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow2->Add( $nifChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow3->Add( $dataTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow3->Add( $dataChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow4->Add( $pdfTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow4->Add( $pdfChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	
	$szRow5->Add( $measureDataTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow5->Add( $measureDataChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow6->Add( $thickTxt,   0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow6->Add( $thickValCb, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRow3, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRow4, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRow5, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szStatBox->Add( $szRow6, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# Set References
	$self->{"typeValTxt"} = $typeValTxt;
	$self->{"nifChb"}     = $nifChb;
	$self->{"dataChb"}    = $dataChb;
	$self->{"pdfChb"}     = $pdfChb;
	$self->{"measureDataChb"}     = $measureDataChb;
	$self->{"thickValCb"} = $thickValCb;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutFiducials {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Fiducials' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# DEFINE CONTROLS

	my $str = "Half-drilled fiducials";
	if ( $self->{"stencilInfo"}->{"tech"} eq StnclEnums->Technology_LASER ) {

		$str = "Half-lasered fiducials";

	}
	elsif ( $self->{"stencilInfo"}->{"tech"} eq StnclEnums->Technology_ETCH ) {

		$str = "Half-etched fiducials";
	}

	my $halfFiducChb = Wx::CheckBox->new( $statBox, -1, $str, &Wx::wxDefaultPosition, [ 200, 20 ] );

	my $rbReadable    = Wx::RadioButton->new( $statBox, -1, "From readable side",     &Wx::wxDefaultPosition, [ 200, 20 ] );
	my $rbNonReadable = Wx::RadioButton->new( $statBox, -1, "From NON readable side", &Wx::wxDefaultPosition, [ 200, 20 ] );
	$rbReadable->Disable();
	$rbNonReadable->Disable();

	# SET EVENTS

	Wx::Event::EVT_CHECKBOX( $halfFiducChb, -1, sub { $self->__OnFiducChanged(@_) } );

	# BUILD STRUCTURE OF LAYOUT

	$szStatBox->Add( $halfFiducChb,  0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $rbReadable,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $rbNonReadable, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"halfFiducChb"}  = $halfFiducChb;
	$self->{"rbReadable"}    = $rbReadable;
	$self->{"rbNonReadable"} = $rbNonReadable;

	return $szStatBox;
}

sub __OnFiducChanged {
	my $self = shift;

	$self->DisableControls();
}

# =====================================================================
# DISABLING CONTROLS
# =====================================================================

sub DisableControls {
	my $self = shift;

	my $thick = $self->{"thickValCb"}->GetValue();

	# if default thick is not known, enable
	if ( !defined $thick  || $thick eq "" || $thick == 0 ) {
		$self->{"thickValCb"}->Enable();
	}
	else {
		$self->{"thickValCb"}->Disable();
	}

	if ( $self->{"stencilInfo"}->{"tech"} eq StnclEnums->Technology_DRILL ) {

		$self->{"measureDataChb"}->Disable();
		$self->{"halfFiducChb"}->Disable();

	}
	else {

		$self->{"measureDataChb"}->Enable();
		$self->{"halfFiducChb"}->Enable();
		

		if ( $self->{"halfFiducChb"}->GetValue() == 1 ) {

			$self->{"rbReadable"}->Enable();
			$self->{"rbNonReadable"}->Enable();
		}
		else {

			$self->{"rbReadable"}->Disable();
			$self->{"rbNonReadable"}->Disable();
		}
	}
}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================
# Stencil thickness
sub SetThickness {
	my $self  = shift;
	my $value = shift;

	$self->{"thickValCb"}->SetValue($value);
}

sub GetThickness {
	my $self = shift;

	my $value = $self->{"thickValCb"}->GetValue();

	$value =~ s/,/\./;

	return $value;
}

# Export nif file
sub SetExportNif {
	my $self  = shift;
	my $value = shift;

	$self->{"nifChb"}->SetValue($value);
}

sub GetExportNif {
	my $self = shift;

	if ( $self->{"nifChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

# Export data files (gerbers, nc programs)
sub SetExportData {
	my $self  = shift;
	my $value = shift;

	$self->{"dataChb"}->SetValue($value);
}

sub GetExportData {
	my $self = shift;

	if ( $self->{"dataChb"}->IsChecked() ) {
		return 1;
	}
	else {
		return 0;
	}
}

# Export pdf file
sub SetExportPdf {
	my $self  = shift;
	my $value = shift;

	$self->{"pdfChb"}->SetValue($value);
}

sub GetExportPdf {
	my $self = shift;

	if ( $self->{"pdfChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

# Export measure data file
sub SetExportMeasureData {
	my $self  = shift;
	my $value = shift;

	$self->{"measureDataChb"}->SetValue($value);
}

sub GetExportMeasureData {
	my $self = shift;

	if ( $self->{"measureDataChb"}->IsChecked() ) {

		return 1;
	}
	else {

		return 0;
	}
}

# Fiducial info
sub SetFiducialInfo {
	my $self = shift;
	my $inf  = shift;

	if ( $inf->{"halfFiducials"} ) {

		$self->{"halfFiducChb"}->SetValue(1);

		if ( defined $inf->{"fiducSide"} && $inf->{"fiducSide"} ne "" ) {

			if ( $inf->{"fiducSide"} eq "readable" ) {
				$self->{"rbReadable"}->SetValue(1);
			}
			elsif ( $inf->{"fiducSide"} eq "nonreadable" ) {
				$self->{"rbNonReadable"}->SetValue(1);
			}
		}
	}
	else {
		$self->{"halfFiducChb"}->SetValue(0);
	}
}

sub GetFiducialInfo {
	my $self = shift;

	my %inf = ();

	if ( $self->{"halfFiducChb"}->IsChecked() ) {

		$inf{"halfFiducials"} = 1;
	}
	else {

		$inf{"halfFiducials"} = 0;
	}

	if ( $self->{"rbReadable"}->GetValue() == 1 ) {

		$inf{"fiducSide"} = "readable";
	}
	elsif ( $self->{"rbNonReadable"}->GetValue() == 1 ) {

		$inf{"fiducSide"} = "nonreadable";
	}
	else {
		$inf{"fiducSide"} = "";
	}
	
	return \%inf;
}

1;
