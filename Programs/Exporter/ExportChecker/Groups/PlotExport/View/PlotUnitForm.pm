#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
use Wx;

package Programs::Exporter::ExportChecker::Groups::PlotExport::View::PlotUnitForm;
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
use aliased 'CamHelpers::CamJob';
use aliased 'Programs::Exporter::ExportChecker::Groups::PlotExport::View::PlotList::PlotList';
use aliased 'Enums::EnumsGeneral';

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

	$self->__SetLayout();

	#$self->Disable();

	# EVENTS
	$self->{"onPlotRowChanged"} = Event->new();    # when row changed

	return $self;
}

sub __SetLayout {
	my $self = shift;

	#define panels

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	#my $szRow0 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $settingsStatBox = $self->__SetLayoutQuickSettings($self);
	my $optionsStatBox  = $self->__SetLayoutOptions($self);
	my $layersStatBox   = $self->__SetLayoutControlList($self);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	# BUILD STRUCTURE OF LAYOUT

	$szRow1->Add( $settingsStatBox, 70, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $optionsStatBox,  30, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow2->Add( $layersStatBox,   1,  &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szMain->Add( $szRow1, 0, &Wx::wxEXPAND );
	$szMain->Add( $szRow2, 1, &Wx::wxEXPAND );

	$self->SetSizer($szMain);

	# save control references

}

sub __SetLayoutQuickSettings {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Quick settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	# DEFINE CONTROLS
	my $allChb = Wx::CheckBox->new( $statBox, -1, "All", &Wx::wxDefaultPosition, [ 70, 20 ] );
	my $enableEditChb = Wx::CheckBox->new( $statBox, -1, "Enable editing", &Wx::wxDefaultPosition, [ 100, 20 ] );
	# SET EVENTS
	Wx::Event::EVT_CHECKBOX( $allChb, -1, sub { $self->__OnSelectAllChangeHandler(@_) } );
	Wx::Event::EVT_CHECKBOX( $enableEditChb, -1, sub { $self->__OnEnableEditChangeHandler(@_) } );
	
	# BUILD STRUCTURE OF LAYOUT
	$szStatBox->Add( $allChb, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 2 );
	$szStatBox->Add( $enableEditChb, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 2 );

	# Set References
	$self->{"allChb"} = $allChb;
	$self->{"enableEditChb"} = $enableEditChb;

	return $szStatBox;
}

sub __SetLayoutOptions {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Options' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	# DEFINE CONTROLS
	my $plotterChb = Wx::CheckBox->new( $statBox, -1, "Send to plotter", &Wx::wxDefaultPosition );

	# SET EVENTS
	#Wx::Event::EVT_CHECKBOX( $plotterChb, -1, sub { $self->__OnSelectAllChangeHandler(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$szStatBox->Add( $plotterChb, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"plotterChb"} = $plotterChb;

	return $szStatBox;
}

sub __SetLayoutControlList {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Layers' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	# DEFINE CONTROLS

	# init layers
	my @layers = ();
	push( @layers, $self->{"defaultInfo"}->GetSignalLayers() );
	push( @layers, $self->{"defaultInfo"}->GetSignalExtLayers() );
	@layers = () if ( $self->{"defaultInfo"}->GetPcbType() eq EnumsGeneral->PcbType_NOCOPPER );

	my @otherLayer =
	  grep { $_->{"gROWlayer_type"} eq "solder_mask" || $_->{"gROWlayer_type"} eq "silk_screen" || $_->{"gROWname"} =~ /^((gold)|([gl]))[cs]$/ }
	  $self->{"defaultInfo"}->GetBoardBaseLayers();
	push( @layers, @otherLayer );
	
	@layers = sort{$a->{"gROWrow"} <=> $b->{"gROWrow"}} @layers;
	
	my $plotList = PlotList->new( $statBox, $self->{"inCAM"}, $self->{"jobId"}, \@layers );

	# SET EVENTS
	$plotList->{"onRowChanged"}->Add( sub { $self->{"onPlotRowChanged"}->Do(@_) } );

	#Wx::Event::EVT_CHECKBOX( $allChb, -1, sub { $self->__OnSelectAllChangeHandler(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$szStatBox->Add( $plotList, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"plotList"} = $plotList;

	return $szStatBox;
}

# Select/unselect all in plot list
sub __OnSelectAllChangeHandler {
	my $self = shift;
	my $chb  = shift;

	if ( $self->{"allChb"}->IsChecked() ) {

		$self->{"plotList"}->SelectAll();
	}
	else {

		$self->{"plotList"}->UnselectAll();
	}

}

# Enable/disable editing of plot rows
sub __OnEnableEditChangeHandler {
	my $self = shift;
	my $chb  = shift;

	if ( $self->{"enableEditChb"}->IsChecked() ) {

		$self->{"plotList"}->EnableEditing(1);
	}
	else {

		$self->{"plotList"}->EnableEditing(0);
	}

}
 
# =====================================================================
# HANDLERS CONTROLS
# =====================================================================
sub OnPREGroupLayerSettChanged {
	my $self  = shift;
	my $layer = shift;

	my $row = $self->{"plotList"}->GetRowByText( $layer->{"name"} );

	die "Plot list row was not found by layer name:" . $layer->{"name"} unless(defined $row);

	$row->SetPolarity( $layer->{"polarity"} );
	$row->SetMirror( $layer->{"mirror"} );
	$row->SetComp( $layer->{"comp"} );
	$row->SetShrinkX( $layer->{"shrinkX"} );
	$row->SetShrinkY( $layer->{"shrinkY"} );

}

# =====================================================================
# DISABLING CONTROLS
# =====================================================================

sub DisableControls {

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

# sendtToPlotter
sub SetSendToPlotter {
	my $self = shift;
	my $val  = shift;
	$self->{"plotterChb"}->SetValue($val);
}

sub GetSendToPlotter {
	my $self = shift;
	return $self->{"plotterChb"}->GetValue();
}

# layers
sub SetLayers {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	$self->{"plotList"}->SetLayers( \@layers );

	my $allChecked = 1;
	foreach my $l (@layers) {

		unless ( $l->{"plot"} ) {
			$allChecked = 0;
		}
	}

	$self->{"allChb"}->SetValue($allChecked);
}

sub GetLayers {
	my $self = shift;

	my @layers = ();
	my @rows   = $self->{"plotList"}->GetAllRows();

	foreach my $r (@rows) {

		my %linfo = $r->GetLayerValues();

		push( @layers, \%linfo );

	}

	return \@layers;
}

1;
