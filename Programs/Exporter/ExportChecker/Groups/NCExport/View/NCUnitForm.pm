#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::NCExport::View::NCUnitForm;
use base qw(Wx::Panel);

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

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;

	my $inCAM = shift;
	my $jobId = shift;
	my $title = shift;

	my $self = $class->SUPER::new($parent);

	bless($self);

	$self->{"inCAM"} = $inCAM;
	$self->{"jobId"} = $jobId;

	$self->{"title"} = $title;

	# Load data

	my @plt = CamDrilling->GetPltNCLayers( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"plt"} = \@plt;

	my @nplt = CamDrilling->GetNPltNCLayers( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"nplt"} = \@nplt;

	$self->__SetLayout();

	$self->__SetName();

	#$self->Disable();

	#$self->SetBackgroundColour($Widgets::Style::clrLightBlue);

	# EVENTS
	$self->{'onTentingChange'} = Event->new();

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

sub __SetName {
	my $self = shift;

	$self->{"title"} = "NC group";

}

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

	my $modeStatBox     = $self->__SetLayoutModeBox($self);
	my $settingsStatBox = $self->__SetLayoutSettings($self);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $modeStatBox,     3, &Wx::wxEXPAND );
	$szMain->Add( $settingsStatBox, 7, &Wx::wxEXPAND );

	$self->SetSizer($szMain);

	# save control references

}

sub __SetLayoutModeBox {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Mode' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	my $szCol1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS
	my $rbAll = Wx::RadioButton->new( $statBox, -1, "Export All", &Wx::wxDefaultPosition, [ 110, 20 ], &Wx::wxRB_GROUP );
	my $rbSingle = Wx::RadioButton->new( $statBox, -1, "Export Single", &Wx::wxDefaultPosition, [ 110, 20 ] );

	# SET EVENTS
	Wx::Event::EVT_CHECKBOX( $rbAll,    -1, sub { $self->__OnModeChangeHandler(@_) } );
	Wx::Event::EVT_CHECKBOX( $rbSingle, -1, sub { $self->__OnModeChangeHandler(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$szCol1->Add( $rbAll,    50, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol1->Add( $rbSingle, 50, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szStatBox->Add( $szCol1, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );

	# Set References
	$self->{"rbAll"}    = $rbAll;
	$self->{"rbSingle"} = $rbSingle;

	return $szStatBox;
}

# Set layout for Quick set box
sub __SetLayoutSettings {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxHORIZONTAL );

	my $szCol1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szCol2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS
	my $platedTxt  = Wx::StaticText->new( $statBox, -1, "Plated",     &Wx::wxDefaultPosition, [ 60, 20 ] );
	my $nplatedTxt = Wx::StaticText->new( $statBox, -1, "Non plated", &Wx::wxDefaultPosition, [ 60, 20 ] );

	my @plt  = @{ $self->{"plt"} };
	my @nplt = @{ $self->{"nplt"} };

	@plt  = map { $_->{"gROWname"} } @plt;
	@nplt = map { $_->{"gROWname"} } @nplt;
	my $pltChlb  = Wx::CheckListBox->new( $statBox, -1, &Wx::wxDefaultPosition, &Wx::wxDefaultSize, \@plt );
	my $npltChlb = Wx::CheckListBox->new( $statBox, -1, &Wx::wxDefaultPosition, &Wx::wxDefaultSize, \@nplt );

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT
	$szCol1->Add( $platedTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol1->Add( $pltChlb,   1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szCol2->Add( $nplatedTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol2->Add( $npltChlb,   1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szStatBox->Add( $szCol1, 50, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	$szStatBox->Add( $szCol2, 50, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );

	# Set References
	$self->{"pltChlb"}  = $pltChlb;
	$self->{"npltChlb"} = $npltChlb;

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

				push( @arr, $l );
			}
		}

	}
	else {

		for ( my $i = 0 ; $i < scalar( @{ $self->{"nplt"} } ) ; $i++ ) {

			if ( $self->{"npltChlb"}->IsChecked($i) ) {
				my $l = ${ $self->{"nplt"} }[$i];

				push( @arr, $l );
			}
		}
	}

	return @arr;

}

# Control handlers
sub __OnModeChangeHandler {
	my $self = shift;
	my $chb  = shift;

	$self->{"onTentingChange"}->Do( $chb->GetValue() );
}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

# Dimension ========================================================

# single_x
sub SetExportSingle {
	my $self  = shift;
	my $value = shift;
	$self->{"rbSingle"}->SetValue($value);
}

sub GetExportSingle {
	my $self = shift;
	return $self->{"rbAll"}->GetValue();
}

# single_y
sub SetPltLayers {
	my $self  = shift;
	my $value = shift;

	#$self->{"singleyValTxt"}->SetLabel($value);
}

sub GetPltLayers {
	my $self = shift;

	my @arr = $self->__GetCheckedLayers("plt");

	return \@arr;
}

# panel_x
sub SetNPltLayers {
	my $self  = shift;
	my $value = shift;

	#$self->{"panelxValTxt"}->SetLabel($value);
}

sub GetNPltLayers {
	my $self = shift;
	my @arr  = $self->__GetCheckedLayers("nplt");

	return \@arr;
}

1;