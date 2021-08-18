#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::MDIExport::View::MDIUnitForm;
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
use aliased 'Programs::Exporter::ExportChecker::Groups::MDIExport::View::LayerList::LayerListFrm';
use aliased 'Packages::Gerbers::Mditt::ExportFiles::Helper' => 'MDITTHelper';

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
	my $mdiLayout = $self->__SetMDILayout($self);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $mdiLayout, 1, &Wx::wxEXPAND );

	$self->SetSizer($szMain);

	# save control references

}

# Set layout for Quick set box
sub __SetMDILayout {
	my $self   = shift;
	my $parent = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'MDI TT (both machines)' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	my $szHeader  = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $pnlHeader = Wx::Panel->new( $statBox, -1 );

	# DEFINE CONTROLS
	$pnlHeader->SetBackgroundColour( Wx::Colour->new( 230, 230, 230 ) );

	my $allChb = Wx::CheckBox->new( $statBox, -1, "Select all", &Wx::wxDefaultPosition, [ -1, 20 ] );
	$allChb->SetValue(1);

	my $titleExportTxt    = Wx::StaticText->new( $pnlHeader, -1, "Export",    &Wx::wxDefaultPosition, [ 38, 22 ] );
	my $layerExportTxt    = Wx::StaticText->new( $pnlHeader, -1, "Layer",     &Wx::wxDefaultPosition, [ 58, 22 ] );
	my $rotationExportTxt = Wx::StaticText->new( $pnlHeader, -1, "Ori.",      &Wx::wxDefaultPosition, [ 10, 22 ] );
	my $fiducExportTxt    = Wx::StaticText->new( $pnlHeader, -1, "Fiducials", &Wx::wxDefaultPosition, [ 10, 22 ] );

	my @allCouples = MDITTHelper->GetDefaultLayerCouples( $inCAM, $jobId );
	my $layerList = LayerListFrm->new( $statBox, $self->{"defaultInfo"}->GetLayerCnt(), \@allCouples );

	# SET EVENTS
	Wx::Event::EVT_CHECKBOX( $allChb, -1, sub { $self->__OnSelectAllChangeHandler(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$pnlHeader->SetSizer($szHeader);

	$szHeader->Add( $titleExportTxt,    0,  &Wx::wxEXPAND | &Wx::wxLEFT, 2 );
	$szHeader->Add( $layerExportTxt,    0,  &Wx::wxEXPAND | &Wx::wxLEFT, 2 );
	$szHeader->Add( $rotationExportTxt, 25, &Wx::wxEXPAND | &Wx::wxLEFT, 2 );
	$szHeader->Add( $fiducExportTxt,    75, &Wx::wxEXPAND | &Wx::wxLEFT, 2 );

	$szStatBox->Add( $allChb,    0, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szStatBox->Add( $pnlHeader, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $layerList, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"layerList"} = $layerList;
	$self->{"allChb"}    = $allChb;

	return $szStatBox;
}

# Select/unselect all in plot list
sub __OnSelectAllChangeHandler {
	my $self = shift;
	my $chb  = shift;

	if ( $self->{"allChb"}->IsChecked() ) {

		$self->{"layerList"}->SelectAll(1);
	}
	else {

		$self->{"layerList"}->SelectAll(0);
	}

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
# Layer couples
sub SetLayerCouples {
	my $self           = shift;
	my $allCouplesInfo = shift;

	$self->{"layerList"}->SetCouples2Export($allCouplesInfo);

}

sub GetLayerCouples {
	my $self = shift;

	$self->{"layerList"}->GetCouples2Export();
}

# Settings of each layer
sub SetLayersSettings {
	my $self       = shift;
	my $layersSett = shift;

	$self->{"layerList"}->SetLayerSettings($layersSett);
}

sub GetLayersSettings {
	my $self = shift;

	return $self->{"layerList"}->GetLayerSettings();
}

1;
