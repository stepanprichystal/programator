#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::PlotExport::Presenter::LayerColorPnl;
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
	my $class  = shift;
	my $parent = shift;
	my $layerName  = shift;

	my $self = $class->SUPER::new($parent);

	bless($self);


	$self->__SetLayout( $layerName );

	return $self;
}

sub __SetLayout {
	my $self   = shift;
	my $layer  = shift;
	 

	#define color of panel
	my $color;

 
		if ($layer =~ /^[p][cs]$/ ) {

			$color = Wx::Colour->new( 255, 255, 255 );

		}
		elsif ( /^[m][cs]$/ ) {
			$color = Wx::Colour->new( 0, 164, 123 );

		}
		elsif ( /^[csv]\d*$/) {

			$color = Wx::Colour->new( 251, 197, 77 );

		}
		else{
			$color = Wx::Colour->new( 154, 218, 218 );

		}
		
	$self->SetBackgroundColor($color);
	 

}
 

1;
