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
	my $class   = shift;
	my $parent  = shift;
	my $ruleResult = shift;

	my $self = $class->SUPER::new( $parent, -1, &Wx::wxDefaultPosition );

	bless($self);

	$self->{"ruleResult"} = $ruleResult;

	$self->{"notActiveClr"} = Wx::Colour->new( 200, 200, 200 );

	$self->__SetLayout();

	return $self;
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
	$framePnl->SetBackgroundColour( Wx::Colour->new( 150, 150, 150 ) );

	my $colorPnl = Wx::Panel->new( $framePnl, -1, &Wx::wxDefaultPosition );
	my $filmColor = $self->{"ruleResult"}->{"color"};
	$colorPnl->SetBackgroundColour($filmColor);

	my $infoPnl = Wx::Panel->new( $colorPnl, -1, &Wx::wxDefaultPosition );
	$infoPnl->SetBackgroundColour( Wx::Colour->new( 223, 223, 223 ) );

	# DEFINE CONTROLS
	
	my @layers = $self->{"ruleResult"}->GetLayers();
	my $fileName;
	
	
	foreach my $l (@layers){
		
		if($fileName){
			$fileName .= " + ";
		}
		
		$fileName .= $l->{"gROWname"};
	}
	
	my $filmSize = $self->{"ruleResult"}->GetFilmSize();
 
	if ( $filmSize eq Enums->FilmSize_Small ) {

		 $filmSize = "B";
	}
	elsif ( $filmSize eq Enums->FilmSize_Big ) {

		  $filmSize = "S";
	}
	
	my $lNameTxt    = Wx::StaticText->new( $colorPnl, -1, $fileName, &Wx::wxDefaultPosition );
	my $sizeTxt     = Wx::StaticText->new( $infoPnl,   -1, $filmSize, &Wx::wxDefaultPosition );
	my $polarityTxt = Wx::StaticText->new( $infoPnl,   -1, "+", &Wx::wxDefaultPosition );
	
	

	# BUILD LAYOUT STRUCTURE
	$infoSz->Add( $sizeTxt,     1, &Wx::wxEXPAND | &Wx::wxLEFT, 2 );
	$infoSz->Add( $polarityTxt, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );



	$infoPnl->SetSizer($infoSz);
	$colorPnl->SetSizer($colorSz);
	$framePnl->SetSizer($frameSz);
	$self->SetSizer($szMain);
	
	$colorSz->Add( $lNameTxt, 70, &Wx::wxEXPAND | &Wx::wxLEFT, 2 );
	$colorSz->Add( $infoPnl,   30, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$frameSz->Add( $colorPnl, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $framePnl, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# SAVE REFERENCES
	$self->{"colorPnl"} = $colorPnl;

}

sub __Active {
	my $self     = shift;
	my @selected = @{ shift(@_) };

	my $selected = 1;

	foreach my $plotL ( $self->{"ruleResult"}->GetLayers() ) {

		# find if this layer is selected

		my @exist = grep { $_ eq $plotL->{"gROWname"} } @selected;

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

}

1;
