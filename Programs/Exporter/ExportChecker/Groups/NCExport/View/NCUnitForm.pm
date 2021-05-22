#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::NCExport::View::NCUnitForm;
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
use aliased 'CamHelpers::CamLayer';
use aliased 'Programs::Exporter::ExportChecker::Groups::NCExport::Presenter::NCHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Programs::Exporter::ExportChecker::Groups::NCExport::View::NCLayerList::NCLayerList';
use aliased 'Widgets::Forms::CustomNotebook::CustomNotebook';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Export::NCExport::Enums' => 'EnumsNC';
use aliased 'CamHelpers::CamStep';

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

	my @plt = CamDrilling->GetPltNCLayers( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"plt"} = \@plt;

	my @nplt = CamDrilling->GetNPltNCLayers( $self->{"inCAM"}, $self->{"jobId"} );

	@nplt = grep { $_->{"gROWname"} !~ /score/ } @nplt;

	$self->{"nplt"} = \@nplt;

	$self->__SetLayout();

	#$self->Disable();

	#$self->SetBackgroundColour($Widgets::Style::clrLightBlue);

	# EVENTS
	$self->{'layerScaleSettChangedEvt'} = Event->new();

	return $self;
}

#sub Init{
#	my $self = shift;
#	my $parent = shift;
#
#	$self->Reparent($parent);
#
#	$self->__SetLayout();
#
#	$self->__SetName();
#}

#sub __SetHeight {
#	my $self = shift;
#	my $height = shift;
#
#	$self->{"groupHeight"} = $height;
#
#}

sub __SetLayout {
	my $self = shift;

	#define panels

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szRow0 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	#my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	#my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $modeStatBox = $self->__SetLayoutModeBox($self);

	my $notebook = CustomNotebook->new( $self, -1 );

	my $singlePage = $notebook->AddPage( 1, 0 );
	my $singleModeSettStatBox = $self->__SetLayoutSingleMode( $singlePage->GetParent() );
	$singlePage->AddContent($singleModeSettStatBox);

	my $allPage = $notebook->AddPage( 2, 0 );
	my $allModeSettStatBox = $self->__SetLayoutAllMode( $allPage->GetParent() );
	$allPage->AddContent($allModeSettStatBox);

	$notebook->ShowPage(2);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $modeStatBox, 0, &Wx::wxEXPAND );
	$szMain->Add( $notebook,    0, &Wx::wxEXPAND );

	#$szMain->Add( $allModeSettStatBox, 80, &Wx::wxEXPAND );

	$self->SetSizer($szMain);

	# save control references
	$self->{"notebook"} = $notebook;
}

sub __SetLayoutModeBox {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Mode' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	my $szCol1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS
	my $rbAll = Wx::RadioButton->new( $statBox, -1, "All", &Wx::wxDefaultPosition, &Wx::wxDefaultSize, &Wx::wxRB_GROUP );
	my $rbSingle = Wx::RadioButton->new( $statBox, -1, "Single", &Wx::wxDefaultPosition, &Wx::wxDefaultSize );

	# SET EVENTS
	Wx::Event::EVT_RADIOBUTTON( $rbAll,    -1, sub { $self->__OnModeChangeHandler(@_) } );
	Wx::Event::EVT_RADIOBUTTON( $rbSingle, -1, sub { $self->__OnModeChangeHandler(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$szCol1->Add( $rbAll,    50, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol1->Add( $rbSingle, 50, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szStatBox->Add( $szCol1, 1, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );

	# Set References
	$self->{"rbAll"}    = $rbAll;
	$self->{"rbSingle"} = $rbSingle;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutSingleMode {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Single mode settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	my $szCol1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szCol2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS
	my $platedTxt  = Wx::StaticText->new( $statBox, -1, "Plated",     &Wx::wxDefaultPosition, [ 40, 20 ] );
	my $nplatedTxt = Wx::StaticText->new( $statBox, -1, "Non plated", &Wx::wxDefaultPosition, [ 40, 20 ] );

	my @plt  = @{ $self->{"plt"} };
	my @nplt = @{ $self->{"nplt"} };

	@plt  = map { $_->{"gROWname"} } @plt;
	@nplt = map { $_->{"gROWname"} } @nplt;
	my $pltChlb  = Wx::CheckListBox->new( $statBox, -1, &Wx::wxDefaultPosition, [ 40, 40 ], \@plt );
	my $npltChlb = Wx::CheckListBox->new( $statBox, -1, &Wx::wxDefaultPosition, [ 40, 40 ], \@nplt );

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT
	$szCol1->Add( $platedTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol1->Add( $pltChlb,   1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szCol2->Add( $nplatedTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol2->Add( $npltChlb,   1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szStatBox->Add( $szCol1, 50, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	$szStatBox->Add( $szCol2, 50, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );

	# Set References
	$self->{"pltChlb"}       = $pltChlb;
	$self->{"npltChlb"}      = $npltChlb;
	$self->{"szStatBox"}     = $szStatBox;
	$self->{"statBoxSingle"} = $statBox;
	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutAllMode {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'All mode settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $exportPnlLayersChb = Wx::CheckBox->new( $statBox, -1, "Main NC programs", &Wx::wxDefaultPosition );

	my @NC = ( @{ $self->{"plt"} }, @{ $self->{"nplt"} } );
	my $NCLayerList = NCLayerList->new( $statBox, $self->{"inCAM"}, $self->{"jobId"}, \@NC );

	my $exportPnlCpnLayersChb = Wx::CheckBox->new( $statBox, -1, "Z-axis coupon programs", &Wx::wxDefaultPosition );

	# SET EVENTS
	$NCLayerList->{"NCLayerSettChangedEvt"}->Add( sub { $self->{"layerScaleSettChangedEvt"}->Do(@_) } );

	Wx::Event::EVT_CHECKBOX( $exportPnlLayersChb, -1, sub { $self->__OnExportPnlLayersChange(@_) } );
	Wx::Event::EVT_COMBOBOX( $exportPnlCpnLayersChb, -1, sub { $self->__OnStepChange(@_) } );

	# BUILD STRUCTURE OF LAYOUT

	$szStatBox->Add( $exportPnlLayersChb,    0, &Wx::wxEXPAND | &Wx::wxTOP, 2 );
	$szStatBox->Add( $NCLayerList,           0, &Wx::wxEXPAND | &Wx::wxTOP, 4 );
	$szStatBox->Add( $exportPnlCpnLayersChb, 1, &Wx::wxEXPAND | &Wx::wxTOP, 10 );

	$self->{"exportPnlLayersChb"}    = $exportPnlLayersChb;
	$self->{"NCLayerList"}           = $NCLayerList;
	$self->{"exportPnlCpnLayersChb"} = $exportPnlCpnLayersChb;
	$self->{"statBoxAll"}            = $statBox;

	return $szStatBox;
}

sub __GetCheckedLayers {
	my $self = shift;
	my $type = shift;

	my @arr = ();

	if ( $type eq "plt" ) {

		for ( my $i = 0 ; $i < scalar( @{ $self->{"plt"} } ) ; $i++ ) {

			if ( $self->{"pltChlb"}->IsChecked($i) ) {
				my $l = ${ $self->{"plt"} }[$i];

				push( @arr, $l->{"gROWname"} );
			}
		}

	}
	else {

		for ( my $i = 0 ; $i < scalar( @{ $self->{"nplt"} } ) ; $i++ ) {

			if ( $self->{"npltChlb"}->IsChecked($i) ) {
				my $l = ${ $self->{"nplt"} }[$i];

				push( @arr, $l->{"gROWname"} );
			}
		}
	}

	return @arr;

}

# Control handlers
sub __OnModeChangeHandler {
	my $self = shift;

	my $val = $self->{"rbSingle"}->GetValue();

	if ( !defined $val || $val eq "" ) {

		$self->{"notebook"}->ShowPage(2);
	}
	else {
		$self->{"notebook"}->ShowPage(1);

	}
}

sub __OnExportPnlLayersChange {
	my $self = shift;

	if ( $self->{"exportPnlLayersChb"}->IsChecked() ) {

		$self->{"NCLayerList"}->Enable();

	}
	else {

		$self->{"NCLayerList"}->Disable();

	}

}

# =====================================================================
# DISABLING CONTROLS
# =====================================================================

sub DisableControls {
	my $self = shift;

	my $cpnName = EnumsGeneral->Coupon_ZAXIS;
	my @steps = grep { $_ =~ /$cpnName/ } CamStep->GetAllStepNames( $self->{"inCAM"}, $self->{"jobId"} );

	if ( scalar(@steps) > 0 ) {

		$self->{"exportPnlCpnLayersChb"}->Enable();
	}
	else {
		
		$self->{"exportPnlCpnLayersChb"}->Disable();
	}

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

# Dimension ========================================================

# single_x
sub SetExportMode {
	my $self  = shift;
	my $value = shift;

	if ( $value eq EnumsNC->ExportMode_SINGLE ) {
		$self->{"rbSingle"}->SetValue(1);
		$self->{"rbAll"}->SetValue(0);
	}
	elsif ( $value eq EnumsNC->ExportMode_ALL ) {
		$self->{"rbSingle"}->SetValue(0);
		$self->{"rbAll"}->SetValue(1);
	}

	$self->__OnModeChangeHandler();

}

sub GetExportMode {
	my $self = shift;

	my $mode = undef;

	if ( $self->{"rbSingle"}->GetValue() ) {
		$mode = EnumsNC->ExportMode_SINGLE;
	}
	else {
		$mode = EnumsNC->ExportMode_ALL;
	}

	return $mode;
}

sub GetAllModeExportPnl {
	my $self = shift;

	my $export = undef;

	if ( $self->{"exportPnlLayersChb"}->IsChecked() ) {
		$export = 1;
	}
	else {
		$export = 0;
	}

	return $export;
}

sub SetAllModeExportPnlCpn {
	my $self   = shift;
	my $export = shift;

	$self->{"exportPnlCpnLayersChb"}->SetValue($export);

	$self->__OnExportPnlLayersChange();
}

sub GetAllModeExportPnlCpn {
	my $self   = shift;
	my $export = undef;

	if ( $self->{"exportPnlCpnLayersChb"}->IsChecked() ) {
		$export = 1;
	}
	else {
		$export = 0;
	}

	return $export;
}

sub SetAllModeExportPnl {
	my $self   = shift;
	my $export = shift;

	$self->{"exportPnlLayersChb"}->SetValue($export);
}

sub GetAllModeLayers {
	my $self = shift;

	my @layers = $self->{"NCLayerList"}->GetLayerValues();

	return \@layers;
}

sub SetAllModeLayers {
	my $self   = shift;
	my $layers = shift;

	$self->{"NCLayerList"}->SetLayerValues($layers);
}

# single_y
sub SetSingleModePltLayers {
	my $self  = shift;
	my $value = shift;

	#$self->{"singleyValTxt"}->SetLabel($value);
}

sub GetSingleModePltLayers {
	my $self = shift;

	my @arr = $self->__GetCheckedLayers("plt");

	return \@arr;
}

# panel_x
sub SetSingleModeNPltLayers {
	my $self  = shift;
	my $value = shift;

	#$self->{"panelxValTxt"}->SetLabel($value);
}

sub GetSingleModeNPltLayers {
	my $self = shift;
	my @arr  = $self->__GetCheckedLayers("nplt");

	return \@arr;
}

1;
