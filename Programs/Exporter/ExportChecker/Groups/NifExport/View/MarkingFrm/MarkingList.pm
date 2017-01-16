#-------------------------------------------------------------------------------------------#
# Description: Simple list, based on ControlList, which display nif quick note
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NifExport::View::MarkingFrm::MarkingList;
use base qw(Widgets::Forms::CustomControlList::ControlList);

#3th party library
use strict;
use warnings;
use utf8;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

#local library

use Widgets::Style;
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::View::MarkingFrm::MarkingRowBasic';

use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class  = shift;
	my $parent = shift;

	#my $inCAM = shift;
	#my $jobId = shift;

	# Name, Color, Polarity, Mirror, Comp
	my @widths = ( 40,   40,   40,  40,  40,   40 );
	my @titles = ( "pc", "mc", "c", "s", "ms", "ps" );

	my $columnCnt    = scalar(@widths);
	my $columnWidths = \@widths;
	my $verticalLine = 1;

	my $self = $class->SUPER::new( $parent, $columnCnt, $columnWidths, $verticalLine );

	bless($self);

	$self->{"titles"} = \@titles;

	$self->__SetLayout();

	# EVENTS

	return $self;
}

sub SetMarkingData {
	my $self      = shift;
	my @notesData = @{ shift(@_) };

	$self->UnselectAll();

	my @allRows = $self->GetAllRows();

	foreach my $data (@notesData) {

		my $row = ( grep { $_->GetNoteData()->{"id"} == $data->{"id"} } @allRows )[0];

		if ($row) {

			# set row selected
			$row->SetSelected(1);

			# set parameters by data
		}
	}
}

sub SetUlLogo {
	my $self = shift;
	my $data = shift;

	my $row = $self->GetAllRows()[0];
	$row->SetMarkingData($data);
}

sub SetUlLogo {
	my $self = shift;
	my $data = shift;

	my $row = $self->GetAllRows()[0];

	$row->SetMarkingData($data);
}

sub SetDataCode {
	my $self = shift;
	my $data = shift;

	my $row = $self->GetAllRows()[1];

	$row->SetMarkingData($data);
}

sub GetUlLogo {
	my $self = shift;

	my $row = $self->GetAllRows()[0];

	return $row->GetMarkingData();
}

sub GetDataCode {
	my $self = shift;

	my $row = $self->GetAllRows()[1];

	return $row->GetMarkingData();
}

sub __SetLayout {

	my $self = shift;

	# DEFINE SIZERS

	$self->SetHeader( $self->{"titles"} );

	$self->SetVerticalLine( Wx::Colour->new( 206, 206, 206 ) );

	$self->SetHeaderBackgroundColor( Wx::Colour->new( 240, 240, 240 ) );

	# Define notes
	my @notes = ();

	my $rowUl = MarkingRowBasic->new( $self, "UL logo" );

	$self->AddRow($rowUl);

	my $rowDatacode = MarkingRowBasic->new( $self, "Datacode" );
	$self->AddRow($rowDatacode);

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

