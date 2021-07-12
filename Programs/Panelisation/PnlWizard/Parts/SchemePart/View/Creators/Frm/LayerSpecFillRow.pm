#-------------------------------------------------------------------------------------------#
# Description: Basic list row
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::SchemePart::View::Creators::Frm::LayerSpecFillRow;
use base qw(Widgets::Forms::CustomControlList::ControlListRow);

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

#local library

use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Enums::EnumsCAM';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $class     = shift;
	my $parent    = shift;
	my $layerName = shift;
	my $cuThick   = shift;
	my $cuUsage   = shift;

	my $rowHeight = 20;

	my $self = $class->SUPER::new( $layerName, $parent, $layerName, $rowHeight );

	bless($self);

	$self->__SetLayout($cuThick, $cuUsage);

	# EVENTS
	$self->{"specialFillChangedEvt"} = Event->new();

	return $self;
}

sub SetLayerSpecFill {
	my $self        = shift;
	my $specialFill = shift;

	my @cells = $self->GetCells();

	$cells[3]->SetValue($specialFill);

}

sub GetLayerSpecFill {
	my $self = shift;

	my $cbSpecFill = $self->GetCellsByPos(3);

	return $cbSpecFill->GetValue();

}

sub __SetLayout {
	my $self = shift;
	my $cuThick   = shift;
	my $cuUsage   = shift;
	

	# DEFINE CELLS

	my $cuThickTxt = Wx::StaticText->new( $self->{"parent"}, -1, $cuThick, [ -1, -1 ], [ -1, $self->{"rowHeight"} ] );
	my $cuUsageTxt = Wx::StaticText->new( $self->{"parent"}, -1, $cuUsage, [ -1, -1 ], [ -1, $self->{"rowHeight"} ] );

	my @options = (
					EnumsCAM->AttSpecLayerFill_NONE,        EnumsCAM->AttSpecLayerFill_EMPTY,
					EnumsCAM->AttSpecLayerFill_SOLID100PCT, EnumsCAM->AttSpecLayerFill_CIRCLE80PCT
	);
	my $specialFillCB =
	  Wx::ComboBox->new( $self->{"parent"}, -1, $options[0], [ -1, -1 ], [ -1, $self->{"rowHeight"} ], \@options, &Wx::wxCB_READONLY );

	Wx::Event::EVT_TEXT( $specialFillCB, -1, sub { $self->{"specialFillChangedEvt"}->Do() } );

	$self->_AddCell($cuThickTxt);
	$self->_AddCell($cuUsageTxt);
	$self->_AddCell($specialFillCB);

	# SET EVENTS

	# SET REFERENCES
}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $test = Programs::Exporter::ExportChecker::Forms::GroupTableForm->new();

	#$test->MainLoop();
}

1;
