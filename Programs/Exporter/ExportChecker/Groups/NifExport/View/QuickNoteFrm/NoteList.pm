#-------------------------------------------------------------------------------------------#
# Description: Simple list, based on ControlList, which display nif quick note
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NifExport::View::QuickNoteFrm::NoteList;
use base qw(Widgets::Forms::CustomControlList::ControlList);

#3th party library
use strict;
use warnings;
use utf8;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

#local library

use Widgets::Style;
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::View::QuickNoteFrm::NoteRowBasic';
use aliased 'Widgets::Forms::CustomControlList::Enums';
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
	my @widths = ( 300,     50 );
	my @titles = ( "Notes", "Params" );

	my $columnCnt    = scalar(@widths);
	my $columnWidths = \@widths;
	my $verticalLine = 1;

	my $self = $class->SUPER::new( $parent, Enums->Mode_CHECKBOX, $columnCnt, $columnWidths, $verticalLine );

	bless($self);

	$self->{"titles"} = \@titles;

	$self->__SetLayout();

	# EVENTS

	return $self;
}

sub SetNotesData {
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

sub GetNotesData {
	my $self = shift;

	my @notesData = ();

	foreach my $r ( $self->GetSelectedRows() ) {

		push( @notesData, $r->GetNoteData() );
	}

	return \@notesData;
}

sub SetLayers {
	my $self   = shift;
	my $layers = shift;

	my %smallLim = ();
	my %bigLim   = ();

	# Get limits of pcb
	my $result = Helper->GetPcbLimits( $self->{"inCAM"}, $self->{"jobId"}, \%smallLim, \%bigLim );
	$self->{"filmCreators"}->Init( $layers, \%smallLim, \%bigLim );

	# Set rule sets for each rows
	foreach my $l ( @{$layers} ) {

		my $row = $self->GetRowByText( $l->{"name"} );

		$row->SetRuleSets( $self->__GetRuleSet( $l->{"name"}, 1 ), $self->__GetRuleSet( $l->{"name"}, 2 ) );
		$row->SetLayerValues($l);

	}

	$self->__OnSelectedChangeHandler();

	$self->{"szMain"}->Layout();
}

sub __SetLayout {

	my $self = shift;

	# DEFINE SIZERS

	$self->SetHeader( $self->{"titles"} );

	$self->SetVerticalLine( Wx::Colour->new( 206, 206, 206 ) );

	$self->SetHeaderBackgroundColor( Wx::Colour->new( 240, 240, 240 ) );

	# Define notes
	my @notes = ();

	my %note1 = ( "id" => 1, "title" => "DPS, obsahuje BGA", "text" => "DPS, obsahuje BGA" );
	my %note2 = (
				  "id"    => 2,
				  "title" => "Maska, maska má malé přesahy.",
				  "text"  => "Maska, maska má malé přesahy."
	);

	my %note3 =
	  ( "id" => 3, "title" => "Drážkování, Prokovy/vodiče blízko drážky", "text" => "Drážkování, Prokovy/vodiče blízko drážky." );
	my %note4 =
	  ( "id" => 4, "title" => "Frézování, Prokovy/vodiče blízko frézování", "text" => "Frézování, Prokovy/vodiče blízko frézování" )
	  ;
	my %note5 =
	  ( "id" => 5, "title" => "Frézování, Časově náročné frézování", "text" => "Frézování, Časově náročné frézování." );
	my %note6 = ( "id" => 6, "title" => "Dps rozlámat a zabrousit můstky", "text" => "Dps rozlámat a zabrousit můstky." );
	my %note7 = ( "id" => 7, "title" => "Dps rozlomit na rozměr",           "text" => "Dps rozlomit na rozměr." );
	my %note8 = ( "id" => 8, "title" => "Dps ponechat v panelu",             "text" => "Dps ponechat v panelu." );

	push( @notes, \%note1 );
	push( @notes, \%note2 );
	push( @notes, \%note3 );
	push( @notes, \%note4 );
	push( @notes, \%note5 );
	push( @notes, \%note6 );
	push( @notes, \%note7 );
	push( @notes, \%note8 );

	foreach my $n (@notes) {

		my $row = NoteRowBasic->new( $self, $n );

		$self->AddRow($row);

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

