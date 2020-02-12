#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::NCExport::View::NCLayerList::NCLayerListRow;
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

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class     = shift;
	my $parent    = shift;
	my $layerName = shift;

	my $rowHeight = 20;

	my $self = $class->SUPER::new( -1, $parent, $layerName, $rowHeight );

	bless($self);

	# PROPERTIES

	$self->{"layerName"} = $layerName;
	$self->{"rowHeight"} = $rowHeight;

	# this values are not represented  by controls
	$self->{"comp"}     = undef;
	$self->{"stretchX"} = undef;
	$self->{"stretchY"} = undef;

	$self->__SetLayout();

	# EVENTS
	$self->{"NCLayerSettChangedEvt"} = Event->new();

	return $self;
}

sub SetStretchXVal {
	my $self = shift;
	my $val  = shift;

	$self->{"stretchXTxt"}->SetValue($val);
}

sub GetStretchXVal {
	my $self = shift;

	return $self->{"stretchXTxt"}->GetValue();
}

sub SetStretchYVal {
	my $self = shift;
	my $val  = shift;

	$self->{"stretchYTxt"}->SetValue($val);
}

sub GetStretchYVal {
	my $self = shift;

	return $self->{"stretchYTxt"}->GetValue();
}

sub __SetLayout {
	my $self = shift;

	# DEFINE CELLS

	my $stretchXTxt = Wx::TextCtrl->new( $self->{"parent"}, -1, "undef", &Wx::wxDefaultPosition, [ -10, $self->{"rowHeight"}  ] );
	my $stretchYTxt = Wx::TextCtrl->new( $self->{"parent"}, -1, "undef", &Wx::wxDefaultPosition, [ -10, $self->{"rowHeight"}  ] );
 
	$self->_AddCell($stretchXTxt);
	$self->_AddCell($stretchYTxt);
 

	# SET EVENTS
	Wx::Event::EVT_TEXT( $stretchXTxt, -1, sub { $self->{"NCLayerSettChangedEvt"}->Do( $self->{"layerName"} ) } );
	Wx::Event::EVT_TEXT( $stretchYTxt, -1, sub { $self->{"NCLayerSettChangedEvt"}->Do( $self->{"layerName"} ) } );
	                                                                                                                     # SET REFERENCES

	$self->{"stretchXTxt"} = $stretchXTxt;
	$self->{"stretchYTxt"} = $stretchYTxt;

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

# layers
sub SetLayerValues {
	my $self  = shift;
	my %lInfo = %{ shift(@_) };

 
	$self->{"stretchXTxt"}->SetValue( $lInfo{"stretchX"} );
	$self->{"stretchYTxt"}->SetValue( $lInfo{"stretchX"} );
}

sub GetLayerValues {
	my $self = shift;

	my %lInfo = ();

	$lInfo{"name"} = $self->GetRowText();
 
	$lInfo{"stretchX"} = $self->{"stretchXTxt"}->GetValue();

	$lInfo{"stretchY"} = $self->{"stretchYTxt"}->GetValue();

	return %lInfo;
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

