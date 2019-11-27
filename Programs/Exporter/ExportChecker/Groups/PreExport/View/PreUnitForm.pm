#-------------------------------------------------------------------------------------------#
# Description: Fake viw class for PRe export
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::PreExport::View::PreUnitForm;
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
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamJob';

use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcViewer';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::OtherLayerList::OtherLayerList';

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

	$self->{"procViewer"} = undef;

	$self->__SetLayout();

	#$self->Disable();

	# EVENTS

	$self->{"technologyChangedEvt"}     = Event->new();    # technology change
	$self->{"tentingChangedEvt"}        = Event->new();    # tentingChange
	$self->{"sigLayerSettChangedEvt"}   = Event->new();    # when signal row changed
	$self->{"otherLayerSettChangedEvt"} = Event->new();    # when other row changed

	return $self;

}

sub __SetLayout {
	my $self = shift;

	#define panels

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $sigLsettingsStatBox   = $self->__SetLayoutSigLayerSett($self);
	my $otherLsettingsStatBox = $self->__SetLayoutOtherLayerSett($self);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $sigLsettingsStatBox, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szMain->Add( 10, 0, 1 );    # Expander
	$szMain->Add( $otherLsettingsStatBox, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$self->SetSizer($szMain);

	# save control references

}

sub __SetLayoutSigLayerSett {
	my $self   = shift;
	my $parent = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Signal layer settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	#my $szTech = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	# technology

	#	my $technologyCbTxt = Wx::StaticText->new( $statBox, -1, "Technology", &Wx::wxDefaultPosition, [ 80, 20 ] );
	#	my @tech = ( EnumsGeneral->Technology_GALVANICS, EnumsGeneral->Technology_RESIST, EnumsGeneral->Technology_OTHER );
	#	my $technologyCb = Wx::ComboBox->new( $statBox, -1, $tech[0], &Wx::wxDefaultPosition, [ 77, 20 ], \@tech, &Wx::wxCB_READONLY );
	#
	#	my $tentingTxt = Wx::StaticText->new( $statBox, -1, "Tenting (c,s)", &Wx::wxDefaultPosition, [ 80, 20 ] );
	#	my $tentingChb = Wx::CheckBox->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 100, 20 ] );

	my @layers = CamJob->GetBoardBaseLayers( $self->{"inCAM"}, $self->{"jobId"} );

	# Remove layers not to be plotted
	$self->{"procViewer"} = ProcViewer->new( $inCAM, $jobId, $self->{"defaultInfo"} );

	my $procViewerFrm = $self->{"procViewer"}->BuildForm($statBox);

	#$procViewerFrm->Fit();

	# SET EVENTS
	#$sigLayerList->{"onRowChanged"}->Add( sub { $self->{"__OnLayerListRowSettChange"}->Do(@_) } );

	$self->{"procViewer"}->{"sigLayerSettChangedEvt"}->Add( sub { $self->{"sigLayerSettChangedEvt"}->Do(@_) } );
	$self->{"procViewer"}->{"technologyChangedEvt"}->Add( sub   { $self->{"technologyChangedEvt"}->Do(@_) } );
	$self->{"procViewer"}->{"tentingChangedEvt"}->Add( sub      { $self->{"tentingChangedEvt"}->Do(@_) } );

	# BUILD STRUCTURE OF LAYOUT

	#	$szTech->Add( $technologyCbTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	#	$szTech->Add( $technologyCb,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	#	$szTech->Add( $tentingTxt,      0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	#	$szTech->Add( $tentingChb,      0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	#$szStatBox->Add( $szTech,       0, &Wx::wxEXPAND );
	$szStatBox->Add( $procViewerFrm, 0, &Wx::wxEXPAND );

	# Set References
	#$self->{"tentingChb"}   = $tentingChb;
	#$self->{"technologyCb"} = $technologyCb;

	#$self->{"procViewer"} = $procViewer;

	return $szStatBox;

}

sub __SetLayoutOtherLayerSett {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Non signal layer settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	# DEFINE CONTROLS

	# technology

	my @layers = CamJob->GetBoardBaseLayers( $self->{"inCAM"}, $self->{"jobId"} );

	my @otherLayers =
	  grep { $_->{"gROWlayer_type"} eq "solder_mask" || $_->{"gROWlayer_type"} eq "silk_screen" || $_->{"gROWname"} =~ /^((gold)|([gl]))[cs]$/ }
	  @layers;

	my $otherLayerList = OtherLayerList->new( $statBox, $self->{"inCAM"}, $self->{"jobId"}, \@otherLayers );

	# SET EVENTS
	$otherLayerList->{"otherLayerSettChangedEvt"}->Add( sub { $self->{"otherLayerSettChangedEvt"}->Do(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$szStatBox->Add( $otherLayerList, 0, &Wx::wxEXPAND | &Wx::wxTOP, 4 );

	# Set References

	$self->{"otherLayerList"} = $otherLayerList;

	return $szStatBox;
}

# =====================================================================
# HANDLERS CONTROLS
# =====================================================================

# Control handlers
sub __OnTentingChangeHandler {
	my $self = shift;
	my $chb  = shift;

	my $val = $chb->GetValue() ? 1 : 0;

	$self->{"onTentingChange"}->Do($val);
}

sub __OnTechnologyChangeHandler {
	my $self       = shift;
	my $cb         = shift;
	my $tentingChb = shift;

	my $tech = $cb->GetValue();

	if ( $tech eq EnumsGeneral->Technology_GALVANICS ) {

		$self->{"tentingChb"}->Enable();

	}
	else {
		$self->{"tentingChb"}->Disable();

	}

	$self->{"onTechnologyChange"}->Do($tech);

}

# =====================================================================
# DISABLING CONTROLS
# =====================================================================

sub DisableControls {
	my $self = shift;

}

# =====================================================================
# HANDLERS - HANDLE EVENTS ANOTHER GROUPS
# =====================================================================

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

# Layers to export ========================================================

# layers
sub SetSignalLayers {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	$self->{"procViewer"}->SetLayerValues( \@layers );

}

sub GetSignalLayers {
	my $self = shift;

	my @layers = $self->{"procViewer"}->GetLayerValues();

	return \@layers;
}

sub SetOtherLayers {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	$self->{"otherLayerList"}->SetLayerValues( \@layers );

}

sub GetOtherLayers {
	my $self = shift;

	my @layers = $self->{"otherLayerList"}->GetLayerValues();

	return \@layers;
}

1;
