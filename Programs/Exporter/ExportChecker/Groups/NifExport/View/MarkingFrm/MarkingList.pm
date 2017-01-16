#-------------------------------------------------------------------------------------------#
# Description: Simple list, based on ControlList, which display layers for markings in pcb
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

	my @layers = ( "pc", "mc", "c", "s", "ms", "ps" );    # layers, where marking can be present

	# Name, Color, Polarity, Mirror, Comp
	my @widths = ( 65, 18, 18, 18, 18, 18, 18 );
	my @titles = ( "Marking", @layers );

	my $columnCnt    = scalar(@widths);
	my $columnWidths = \@widths;
	my $verticalLine = 1;

	my $self = $class->SUPER::new( $parent, Enums->Mode_CHECKBOXLESS, $columnCnt, $columnWidths, $verticalLine );

	bless($self);

	$self->{"titles"} = \@titles;
	$self->{"layers"} = \@layers;

	$self->__SetLayout();

	# EVENTS

	return $self;
}

sub SetDataCode {
	my $self = shift;
	my $data = shift;

	my $row = ($self->GetAllRows())[0];

	$row->SetMarkingData($data);
}

sub GetDataCode {
	my $self = shift;

	my $row = ($self->GetAllRows())[0];

	return $row->GetMarkingData();
}


sub SetUlLogo {
	my $self = shift;
	my $data = shift;

	my $row = ($self->GetAllRows())[1];
	$row->SetMarkingData($data);
}

sub GetUlLogo {
	my $self = shift;

	my $row = ($self->GetAllRows())[1];

	return $row->GetMarkingData();
}


# Disable layers, which are not in matrix
sub DisableControls {
	my $self      = shift;
	my @allLayers = @{shift(@_)};

	my @disableLayer = ();

	foreach my $l ( @{ $self->{"layers"} } ) {

		my $lExist = scalar( grep { $_->{"gROWname"} eq $l } @allLayers );

		unless ($lExist) {
			push( @disableLayer, $l );
		}
	}

	foreach my $row ( $self->GetAllRows() ) {

		$row->DisableControls(\@disableLayer);
	}

}

sub __SetLayout {

	my $self = shift;

	# DEFINE SIZERS

	$self->SetHeader( $self->{"titles"} );

	$self->SetVerticalLine( Wx::Colour->new( 206, 206, 206 ) );

	$self->SetHeaderBackgroundColor( Wx::Colour->new( 240, 240, 240 ) );

	# Define notes
	my @notes = ();

	my $rowDatacode = MarkingRowBasic->new( $self, "Datacode", $self->{"layers"} );
	$self->AddRow($rowDatacode);

	my $rowUl = MarkingRowBasic->new( $self, "UL logo", $self->{"layers"} );
	$self->AddRow($rowUl);

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

