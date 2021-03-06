#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::PlotExport::View::PlotList::LayerColorPnl;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:richtextctrl :textctrl :font);

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'CamHelpers::CamLayer';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $parent    = shift;
	my $layerName = shift;
	my $controlHeight = shift;
	
	unless($controlHeight){
		$controlHeight = -1;
	}

	my $self = $class->SUPER::new( $parent, -1, &Wx::wxDefaultPosition,  [-1, $controlHeight]);

	bless($self);

	$self->__SetLayout($layerName);

	return $self;
}

sub __SetLayout {
	my $self  = shift;
	my $layer = shift;

	#define color of panel
	my $color;

	if ( $layer =~ /^p[cs]2?$/ ) {
		
		$color = Wx::Colour->new( 255, 255, 255 );

	}
	elsif ($layer =~ /^m[cs]2?(flex)?$/) {
		
		$color = Wx::Colour->new( 0, 164, 123 );

	}
	elsif ($layer =~ /^(outer)?[csv]\d*$/) {

		$color = Wx::Colour->new( 251, 197, 77 );

	}elsif ($layer =~ /^gold[cs]$/) {

		$color = Wx::Colour->new( 255, 225, 74 );

	}elsif ($layer =~ /^plg[csv]\d*$/) {

		$color = Wx::Colour->new( 0, 105, 156 );

	}elsif ($layer =~ /^l[cs]\d*$/) {

		$color = Wx::Colour->new( 13, 225, 133 );

	}
	elsif ($layer =~ /^g[cs]\d*$/) {

		$color = Wx::Colour->new( 100, 100, 100 );

	}
	else {
		$color = Wx::Colour->new( 154, 218, 218 );

	}

	$self->SetBackgroundColour($color);

}

1;
