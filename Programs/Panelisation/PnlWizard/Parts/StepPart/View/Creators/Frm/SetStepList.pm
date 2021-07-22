#-------------------------------------------------------------------------------------------#
# Description: Simple list, based on ControlList, which display inner layer spec fill
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::Frm::SetStepList;
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
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::Frm::SetStepRow';
use aliased 'Widgets::Forms::CustomControlList::Enums';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class  = shift;
	my $parent = shift;
	my @steps  = @{ shift(@_) };

	# Specify column widths
	my @widths = ( 149, 149 );
	my @titles = ( "Step name", "Step amount in one set" );

	my $columnCnt    = scalar(@widths);
	my $columnWidths = \@widths;
	my $verticalLine = 1;

	my $self = $class->SUPER::new( $parent, Enums->Mode_CHECKBOXLESS, $columnCnt, $columnWidths, $verticalLine, 1, 1 );
 
	bless($self);

	$self->{"titles"} = \@titles;
	$self->{"steps"}  = \@steps;

	$self->__SetLayout();

	# EVENTS

	$self->{"stepCountChangedEvt"} = Event->new();

	return $self;
}

sub SetStepCounts {
	my $self       = shift;
	my $stepCounts = shift;    # hash with pairs - layer name => special fill

	foreach my $stepCount ( @{$stepCounts} ) {

		my $row = $self->GetRowById( $stepCount->{"stepName"} );

		$row->SetStepCount( $stepCount->{"stepCount"} );

	}

}

sub GetStepCounts {
	my $self = shift;

	my @stepCounts = ();
	my @rows       = $self->GetAllRows();

	foreach my $row (@rows) {

		push( @stepCounts, { "stepName" => $row->GetRowId(), "stepCount" => $row->GetStepCount() } );

	}

	return \@stepCounts;
}

sub __SetLayout {

	my $self = shift;

	# DEFINE SIZERS

	$self->SetHeader( $self->{"titles"} );

	$self->SetVerticalLine( Wx::Colour->new( 206, 206, 206 ) );

	$self->SetHeaderBackgroundColor( Wx::Colour->new( 240, 240, 240 ) );

	# Define notes

	foreach my $stepName ( @{ $self->{"steps"} } ) {

		my $row = SetStepRow->new( $self, $stepName );
		$self->AddRow($row);

		$row->{"stepCountChangedEvt"}->Add( sub { $self->{"stepCountChangedEvt"}->Do() } );
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

