#-------------------------------------------------------------------------------------------#
# Description: Simple list, based on ControlList, which display inner layer spec fill
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::SchemePart::View::Creators::Frm::LayerSpecFillList;
use base qw(Widgets::Forms::CustomControlList::ControlList);

#3th party library
use strict;
use warnings;
use utf8;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);
use List::Util qw[max];

#local library

use Widgets::Style;
use aliased 'Programs::Panelisation::PnlWizard::Parts::SchemePart::View::Creators::Frm::LayerSpecFillRow';
use aliased 'Widgets::Forms::CustomControlList::Enums';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Events::Event';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class  = shift;
	my $parent = shift;
	my @layers = @{ shift(@_) };

	# Specify column widths
	my @widths = ( 70,           70,             70,         70 );
	my @titles = ( "Layer name", "Cu thickness", "Cu usage", "Special panel fill" );

	my $columnCnt    = scalar(@widths);
	my $columnWidths = \@widths;
	my $verticalLine = 1;

	my $self = $class->SUPER::new( $parent, Enums->Mode_CHECKBOXLESS, $columnCnt, $columnWidths, $verticalLine );

	bless($self);

	$self->{"titles"} = \@titles;
	$self->{"layers"} = \@layers;

	$self->__SetLayout();

	# EVENTS

	$self->{"specialFillChangedEvt"} = Event->new();

	return $self;
}

sub SetLayersSpecFill {
	my $self      = shift;
	my $layerFill = shift;    # hash with pairs - layer name => special fill

	foreach my $layerName ( keys %{$layerFill} ) {

		my $row = $self->GetRowById($layerName);

		$row->SetLayerSpecFill( $layerFill->{$layerName} );

	}

}

sub GetLayersSpecFill {
	my $self = shift;

	my %layerFill = ();
	my @rows      = $self->GetAllRows();

	foreach my $row (@rows) {

		my $specFill = $row->GetLayerSpecFill( $row->GetRowText() );
		$layerFill{ $row->GetRowText() } = $specFill;

	}

	return \%layerFill;
}

sub __SetLayout {

	my $self = shift;

	# DEFINE SIZERS

	$self->SetHeader( $self->{"titles"} );

	$self->SetVerticalLine( Wx::Colour->new( 206, 206, 206 ) );

	$self->SetHeaderBackgroundColor( Wx::Colour->new( 240, 240, 240 ) );

	# Define notes

	foreach my $layer ( @{ $self->{"layers"} } ) {
		
		my $row = LayerSpecFillRow->new( $self, $layer->{"name"}, $layer->{"cuThick"}, $layer->{"cuUsage"}   );
		$self->AddRow($row);

		$row->{"specialFillChangedEvt"}->Add( sub { $self->{"specialFillChangedEvt"}->Do() } );
	}

	# REGISTER EVENTS

	# BUILD LAYOUT STRUCTURE

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $test = Programs::Exporter::ExportChecker::Forms::GroupTableForm->new();

	#$test->MainLoop();
}

1;

