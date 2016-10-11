#-------------------------------------------------------------------------------------------#
# Description: Responsible for creating "table of column", where GroupWrapperForms are
# placed in. Is responsible for recaltulating "column" layout.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PlotExport::View::PlotList::PlotList;
use base qw(Widgets::Forms::CustomControlList::ControlList);

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

#local library

use Widgets::Style;
use aliased 'Programs::Exporter::ExportChecker::Groups::PlotExport::View::PlotList::PlotListRow';
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class  = shift;
	my $parent = shift;

	my @widths = (100, 100,100,100,100,100,);

	my $columnCnt    = scalar(@widths);
	my $columnWidths = \@widths;
	my $verticalLine = 1;

	my $self = $class->SUPER::new( $parent, $columnCnt, $columnWidths, $verticalLine );

	bless($self);

	my @layers = ( );
	
	my %info1 = ("gROWname" => "pc");
	my %info2 = ("gROWname" => "mc");
	my %info3 = ("gROWname" => "c");
	my %info4 = ("gROWname" => "s");
	my %info5 = ("gROWname" => "ms");
	my %info6 = ("gROWname" => "ps");

	push(@layers, \%info1);
	push(@layers, \%info2);
	push(@layers, \%info3);
	push(@layers, \%info4);
	push(@layers, \%info5);
	push(@layers, \%info6);

	
	$self->{"layers"} = \@layers;

	$self->__SetLayout();

	return $self;
}

# Create column, for placing GroupWrappersForm
sub __SetLayout {

	my $self = shift;

	# DEFINE SIZERS

	#create rows for each laters

	my @layers = @{ $self->{"layers"} };
	foreach my $l (@layers){

		my $row = PlotListRow->new( $self, $l );
		  $self->AddRow($row);

	  }

	  # BUILD LAYOUT STRUCTURE

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

