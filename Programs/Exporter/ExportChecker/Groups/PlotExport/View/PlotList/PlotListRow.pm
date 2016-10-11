#-------------------------------------------------------------------------------------------#
# Description: Represent columnLayout.
# Class keep GroupWrapperForm in Column layout and can move
# GroupWrapperForm to neighbour columns
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::PlotExport::View::PlotList::PlotListRow;
use base qw(Widgets::Forms::CustomControlList::ControlListRow);
#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

#local library

use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Programs::Exporter::ExportChecker::Groups::PlotExport::Presenter::LayerColorPnl';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;
	my $parent = shift;
	my $layer = shift;

	my $self = $class->SUPER::new( $parent, $layer->{"gROWname"});
 
	bless($self);
 
 	$self->{"layer"} = $layer;
 
 
 	$self->__SetLayout();
 
	# EVENTS
	#$self->{"onSelectedChanged"} = Event->new();

	return $self;
}
 

sub __SetLayout {
	my $self = shift;

	# DEFINE CELLS
	
	my $mainChb = Wx::CheckBox->new( $self->{"parent"}, -1, $self->{"text"}, [ -1, -1 ] );

	my $layerColor = LayerColorPnl->new( $self->{"parent"}, $self->{"layer"}->{"gROWname"} );

	my @polar = ( "positive", "negative" );
	my $polarityCb = Wx::ComboBox->new( $self, -1, $polar[0], &Wx::wxDefaultPosition, [ 70, 20 ], \@polar, &Wx::wxCB_READONLY );

	my $mirrorChb = Wx::CheckBox->new( $self->{"parent"}, -1, "Mirror", [ -1, -1 ] );

	# SET EVENTS
	Wx::Event::EVT_CHECKBOX( $mainChb, -1, sub { $self->__OnSelectedChange(@_) } );

	$self->_AddCell($mainChb);
	$self->_AddCell($layerColor);
	$self->_AddCell($polarityCb);
	$self->_AddCell($mirrorChb);

	 

	$self->{"mainChb"} = $mainChb;

}

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {
	my $test = Programs::Exporter::ExportChecker::Forms::GroupTableForm->new();

	$test->MainLoop();
}

1;

1;

