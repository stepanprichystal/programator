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
use aliased 'Programs::Exporter::ExportChecker::Groups::PlotExport::View::PlotList::LayerColorPnl';
use aliased 'Programs::Exporter::ExportChecker::Groups::PlotExport::View::PlotList::FilmForm';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;
	my $parent = shift;
	my $layer = shift;
	my $filmResultSet = shift;
	my $rowHeight = 20;
	

	my $self = $class->SUPER::new( $parent, $layer->{"gROWname"}, $rowHeight);
 
	bless($self);
 
 	$self->{"layer"} = $layer;
 	$self->{"rowHeight"} = $rowHeight;
 	
 	$self->{"filmResultSet"} = $filmResultSet;
 
 
 	$self->__SetLayout();
 
	# EVENTS
	$self->{"onSelectedChanged"}->Add(sub {$self->__PlotSelectionChanged(@_)});

	return $self;
}
 

sub __SetLayout {
	my $self = shift;

	# DEFINE CELLS
	

	my $layerColor = LayerColorPnl->new( $self->{"parent"}, $self->{"layer"}->{"gROWname"} );

	my @polar = ( "positive", "negative" );
	my $polarityCb = Wx::ComboBox->new( $self->{"parent"}, -1, $polar[0], &Wx::wxDefaultPosition, [ -1, $self->{"rowHeight"} ], \@polar, &Wx::wxCB_READONLY );

	my $mirrorChb = Wx::CheckBox->new( $self->{"parent"}, -1, "", [ -1, -1 ] , [ -1, $self->{"rowHeight"} ]);

	my $compTxt = Wx::TextCtrl->new(  $self->{"parent"}, -1, "", &Wx::wxDefaultPosition, [ 20, $self->{"rowHeight"} ] );
	
	my $arrowTxt = Wx::StaticText->new($self->{"parent"}, -1, " ==> ", &Wx::wxDefaultPosition, [ 60, 20 ] );
	
	my $film1Frm =  FilmForm->new(  $self->{"parent"}, $self->{"filmResultSet"} );
	
	
	# SET EVENTS
	#Wx::Event::EVT_CHECKBOX( $mainChb, -1, sub { $self->__OnSelectedChange(@_) } );

 
	$self->_AddCell($layerColor);
	$self->_AddCell($polarityCb);
	$self->_AddCell($mirrorChb);
	$self->_AddCell($compTxt);
	$self->_AddCell($arrowTxt);
	$self->_AddCell($film1Frm);
	
	
	# SET REFERENCES
	
	$self->{"film1Frm"} = $film1Frm;
	 

}

sub __PlotSelectionChanged{
	my $self = shift;
	#my $plotList = shift;
	#my $row = shift;
 
	
	my @selectedLayers = ();
	
	foreach my $row ($self->{"parent"}->GetSelectedRows()){
		
		push(@selectedLayers, $row->GetText());
		
	}
	
	$self->{"film1Frm"}->PlotSelectChanged(\@selectedLayers);
	
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

