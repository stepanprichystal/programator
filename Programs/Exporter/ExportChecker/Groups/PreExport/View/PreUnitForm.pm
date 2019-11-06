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
	#$self->{"onPlotRowChanged"} = Event->new();    # when row changed

	return $self;
}

sub __SetLayout {
	my $self = shift;

	#define panels

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $sigLsettingsStatBox = $self->__SetLayoutSigLayerSett($self);

	#my $otherLsettingsStatBox = $self->__SetLayoutOtherLayerSett($self);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $sigLsettingsStatBox, 1, &Wx::wxEXPAND );

	#$szMain->Add( $otherLsettingsStatBox, 1, &Wx::wxEXPAND );

	$self->SetSizer($szMain);

	# save control references

}

sub __SetLayoutSigLayerSett {
	my $self   = shift;
	my $parent = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	my $szTech = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	# technology

	#	my $technologyCbTxt = Wx::StaticText->new( $statBox, -1, "Technology", &Wx::wxDefaultPosition, [ 80, 20 ] );
	#	my @tech = ( EnumsGeneral->Technology_GALVANICS, EnumsGeneral->Technology_RESIST, EnumsGeneral->Technology_OTHER );
	#	my $technologyCb = Wx::ComboBox->new( $statBox, -1, $tech[0], &Wx::wxDefaultPosition, [ 77, 20 ], \@tech, &Wx::wxCB_READONLY );
	#
	#	my $tentingTxt = Wx::StaticText->new( $statBox, -1, "Tenting (c,s)", &Wx::wxDefaultPosition, [ 80, 20 ] );
	#	my $tentingChb = Wx::CheckBox->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 100, 20 ] );

	my @layers = CamJob->GetBoardBaseLayers( $self->{"inCAM"}, $self->{"jobId"} );

	my @sigLayers =
	  $self->{"defaultInfo"}->GetSignalLayers();

	# Remove layers not to be plotted
	my $procViewer = ProcViewer->new(
		$inCAM, $jobId,
		\@sigLayers,
		$self->{"defaultInfo"}->GetIsFlex(),
		$self->{"defaultInfo"}->GetStackup()
	);

	my $procViewerFrm = $procViewer->BuildForm($statBox);

	# SET EVENTS
	#$sigLayerList->{"onRowChanged"}->Add( sub { $self->{"__OnLayerListRowSettChange"}->Do(@_) } );

	#Wx::Event::EVT_CHECKBOX( $tentingChb, -1, sub { $self->__OnTentingChangeHandler(@_) } );
	#Wx::Event::EVT_COMBOBOX( $technologyCb, -1, sub { $self->__OnTechnologyChangeHandler( @_, $tentingChb ) } );

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

	$self->{"procViewer"} = $procViewer;

	return $szStatBox;

}

sub __SetLayoutOtherLayerSett {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Other layer settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	# DEFINE CONTROLS

	# technology

	my @layers = CamJob->GetBoardBaseLayers( $self->{"inCAM"}, $self->{"jobId"} );

	my @otherLayers = grep {
		     $_->{"gROWlayer_type"} ne "signal"
		  && $_->{"gROWlayer_type"} eq "power_ground"
		  && $_->{"gROWlayer_type"} eq "mixed"
		  && $_->{"gROWlayer_type"} eq "coverlay"
		  && $_->{"gROWlayer_type"} eq "bendarea"
		  && $_->{"gROWlayer_type"} eq "stiffener"
	} @layers;

	my $otherLayerList = PlotList->new( $statBox, $self->{"inCAM"}, $self->{"jobId"}, \@otherLayers );

	# SET EVENTS
	$otherLayerList->{"onRowChanged"}->Add( sub { $self->{"__OnLayerListRowSettChange"}->Do(@_) } );

	# BUILD STRUCTURE OF LAYOUT

	$szStatBox->Add( $otherLayerList, 0, &Wx::wxEXPAND );

	# Set References

	$self->{"otherLayerList"} = $otherLayerList;

	return $szStatBox;
}

# =====================================================================
# HANDLERS CONTROLS
# =====================================================================

sub __OnLayerListRowSettChange {
	my $self    = shift;
	my $plotRow = shift;

	my %lInfo = $plotRow->GetLayerValues();

	$self->{"onLayerSettChange"}->Do( \%lInfo )

}

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

	# disable tenting chb when layercnt <= 1

	if ( $self->{"defaultInfo"}->GetLayerCnt() <= 1 ) {

		$self->{"tentingChb"}->Disable();
		$self->{"technologyCb"}->Disable();
	}

}

# =====================================================================
# HANDLERS - HANDLE EVENTS ANOTHER GROUPS
# =====================================================================

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

# Layers to export ========================================================

# layers
sub SetLayers {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	$self->{"sigLayerList"}->SetLayers( \@layers );

}

sub GetLayers {
	my $self = shift;

	my @layers    = ();
	my @sigRows   = $self->{"sigLayerList"}->GetAllRows();
	my @otherRows = $self->{"otherLayerList"}->GetAllRows();

	foreach my $r ( @sigRows, @otherRows ) {

		my %linfo = $r->GetLayerValues();

		push( @layers, \%linfo );

	}

	return \@layers;
}

sub SetTenting {
	my $self  = shift;
	my $value = shift;
	$self->{"tentingChb"}->SetValue($value);
}

sub GetTenting {
	my $self = shift;
	return $self->{"tentingChb"}->GetValue();
}

sub SetTechnology {
	my $self  = shift;
	my $value = shift;

	my $color = ValueConvertor->GetTechCodeToName($value);
	$self->{"technologyCb"}->SetValue($color);
}

sub GetTechnology {
	my $self  = shift;
	my $color = $self->{"technologyCb"}->GetValue();
	return ValueConvertor->GetTechNameToCode($color);
}

1;
