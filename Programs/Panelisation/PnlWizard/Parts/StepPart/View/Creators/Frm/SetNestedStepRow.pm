#-------------------------------------------------------------------------------------------#
# Description: Basic list row
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::Frm::SetNestedStepRow;
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

	my $class    = shift;
	my $parent   = shift;
	my $stepName = shift;

	my $rowHeight = 20;

	my $self = $class->SUPER::new( $stepName, $parent, $stepName );

	bless($self);

	$self->__SetLayout();

	# EVENTS
	$self->{"stepCountChangedEvt"} = Event->new();

	return $self;
}

sub SetStepCount {
	my $self        = shift;
	my $stepCount = shift;

	my @cells = $self->GetCells();

	$cells[1]->SetValue($stepCount);

}

sub GetStepCount {
	my $self = shift;

	my $cell = $self->GetCellsByPos(1);

	return $cell->GetValue();

}

sub __SetLayout {
	my $self    = shift;
	my $cuThick = shift;
	my $cuUsage = shift;

	# DEFINE CELLS

	my $stepCount = Wx::TextCtrl->new( $self->{"parent"}, -1, $cuThick, [ -1, -1 ], [ 10, $self->{"rowHeight"} ] );

	Wx::Event::EVT_TEXT( $stepCount, -1, sub { $self->{"stepCountChangedEvt"}->Do() } );

	$self->_AddCell($stepCount);

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
