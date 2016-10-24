#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::PlotExport::View::PlotList::FilmForm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'CamHelpers::CamLayer';
use aliased 'Packages::Export::PlotExport::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class         = shift;
	my $parent        = shift;
	my $ruleResult    = shift;
	my $controlHeight = shift;

	unless ($controlHeight) {
		$controlHeight = -1;
	}

	my $self = $class->SUPER::new( $parent, -1, &Wx::wxDefaultPosition, [ -1, $controlHeight ] );

	bless($self);

	$self->{"ruleResult"} = undef;

	$self->{"notActiveClr"} = Wx::Colour->new( 230, 230, 230 );

	$self->__SetLayout();

	return $self;
}

sub SetRuleSet {
	my $self = shift;

	$self->{"ruleResult"} = shift;

	my $fileName = "";
	my $filmSize = "";

	if ( $self->{"ruleResult"} ) {

		my @layers = $self->{"ruleResult"}->GetLayers();

		foreach my $l (@layers) {

			if ($fileName) {
				$fileName .= " + ";
			}

			$fileName .= $l->{"name"};
		}

		$filmSize = $self->{"ruleResult"}->GetFilmSize();

		if ( $filmSize eq Enums->FilmSize_Small ) {

			$filmSize = "S";
		}
		elsif ( $filmSize eq Enums->FilmSize_Big ) {

			$filmSize = "B";
		}
	}

	$self->{"lNameTxt"}->SetLabel($fileName);
	$self->{"sizeTxt"}->SetLabel($filmSize);
	
	

}

sub PlotSelectChanged {
	my $self     = shift;
	my $selected = shift;

	$self->__Active($selected);
}

sub __SetLayout {
	my $self = shift;

	# DEFINE SIZERS

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $frameSz = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $colorSz = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $infoSz  = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE PANELS

	my $framePnl = Wx::Panel->new( $self, -1, &Wx::wxDefaultPosition );
	$framePnl->SetBackgroundColour( Wx::Colour->new( 200, 200, 200 ) );

	my $colorPnl = Wx::Panel->new( $framePnl, -1, &Wx::wxDefaultPosition );
	$colorPnl->SetBackgroundColour( $self->{"notActiveClr"} );

	my $infoPnl = Wx::Panel->new( $colorPnl, -1, &Wx::wxDefaultPosition );
	$infoPnl->SetBackgroundColour( Wx::Colour->new( 200, 200, 200 ) );

	# DEFINE CONTROLS

	my $fileName = "";
	my $filmSize = "";

	my $lNameTxt = Wx::StaticText->new( $colorPnl, -1, $fileName, &Wx::wxDefaultPosition, [60, 20] );
	my $sizeTxt  = Wx::StaticText->new( $infoPnl,  -1, $filmSize, &Wx::wxDefaultPosition );

	# BUILD LAYOUT STRUCTURE
	$infoSz->Add( $sizeTxt, 1, &Wx::wxEXPAND | &Wx::wxLEFT, 2 );

	$infoPnl->SetSizer($infoSz);
	$colorPnl->SetSizer($colorSz);
	$framePnl->SetSizer($frameSz);
	$self->SetSizer($szMain);

	$colorSz->Add( $lNameTxt, 80, &Wx::wxEXPAND | &Wx::wxLEFT, 4 );
	$colorSz->Add( $infoPnl,  20, &Wx::wxEXPAND | &Wx::wxALL,  0 );
	$frameSz->Add( $colorPnl, 1,  &Wx::wxEXPAND | &Wx::wxALL,  1 );
	$szMain->Add( $framePnl, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# SAVE REFERENCES
	$self->{"colorPnl"} = $colorPnl;
	$self->{"lNameTxt"} = $lNameTxt;
	$self->{"sizeTxt"}  = $sizeTxt;
	$self->{"szMain"}  = $szMain;
	

}

sub __Active {
	my $self     = shift;
	my @selected = @{ shift(@_) };

	unless ( $self->{"ruleResult"} ) {
		return 1;
	}

	my $selected = 1;

	foreach my $plotL ( $self->{"ruleResult"}->GetLayers() ) {

		# find if this layer is selected

		my @exist = grep { $_ eq $plotL->{"name"} } @selected;

		unless ( scalar(@exist) ) {
			$selected = 0;
			last;
		}
	}

	my $filmColor;

	if ($selected) {

		$filmColor = $self->{"ruleResult"}->{"color"};
		$self->{"colorPnl"}->SetBackgroundColour($filmColor);

	}
	else {

		$filmColor = $self->{"ruleResult"}->{"color"};
		$self->{"colorPnl"}->SetBackgroundColour( $self->{"notActiveClr"} );

	}

	$self->{"colorPnl"}->Refresh();

	return 1;

}

1;
