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
use aliased 'Packages::Export::PlotExport::FilmCreator::MultiFilmCreator';
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class  = shift;
	my $parent = shift;

	my $inCAM = shift;
	my $jobId = shift;

	# Name, Color, Polarity, Mirror, Comp
	my @widths = ( 50, 20, 100, 50, 50, 100, 100, 100, );

	my $columnCnt    = scalar(@widths);
	my $columnWidths = \@widths;
	my $verticalLine = 1;

	my $self = $class->SUPER::new( $parent, $columnCnt, $columnWidths, $verticalLine );

	bless($self);

	$self->{"inCAM"} = $inCAM;
	$self->{"jobId"} = $jobId;

	my @layers = ();

	my %info1 = ( "gROWname" => "pc" );
	my %info2 = ( "gROWname" => "mc" );
	my %info3 = ( "gROWname" => "c" );
	my %info4 = ( "gROWname" => "s" );
	my %info5 = ( "gROWname" => "ms" );
	my %info6 = ( "gROWname" => "ps" );

	push( @layers, \%info1 );
	push( @layers, \%info2 );
	push( @layers, \%info3 );
	push( @layers, \%info4 );
	push( @layers, \%info5 );
	push( @layers, \%info6 );

	$self->{"layers"} = \@layers;

	my $creator = MultiFilmCreator->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"layers"} );
	my @sets = $creator->GetRuleSets();

	$self->{"ruleSets"} = \@sets;

	$self->__DefineFilmColors();

	$self->__SetLayout();

	return $self;
}

# Create column, for placing GroupWrappersForm
sub __SetLayout {

	my $self = shift;

	# DEFINE SIZERS

	my @titles = ( "Name", "", "Polarity", "Mirror", "Comp" );
	$self->SetHeader( \@titles );

	$self->SetVerticalLine( Wx::Colour->new( 163, 163, 163 ) );

	#create rows for each laters

	my @layers = @{ $self->{"layers"} };
	foreach my $l (@layers) {

		my $row = PlotListRow->new( $self, $l, $self->__GetRuleSet($l) );

		# zaregistrovat udalost
		
		 
		$self->{"onSelectedChanged"}->Add(sub{ $row->PlotSelectionChanged($self, @_) });
		

		$self->AddRow($row);

	}

	# BUILD LAYOUT STRUCTURE

}

sub __GetRuleSet {
	my $self  = shift;
	my $layer = shift;

	my $set;

	foreach my $rulSet ( @{ $self->{"ruleSets"} } ) {

		my @ruleLayers = $rulSet->GetLayers();

		my @exist = grep { $_->{"gROWname"} eq $layer->{"gROWname"} } @ruleLayers;

		if ( scalar(@exist) ) {

			$set = $rulSet;
			last;
		}
	}

	if ($set && !defined $set->{"color"}) {

		foreach my $c ( @{ $self->{"filmColors"} } ) {

			unless ( $c->{"used"} ) {
				$set->{"color"} = $c->{"color"};
				$c->{"used"}    = 1;
				last;
			}
		}
	}

	return $set;

}

sub __DefineFilmColors {
	my $self = shift;

	my @colors = ();

	my $f;

	if ( open( $f, "<" . GeneralHelper->Root() . "\\Resources\\FilmColorList" ) ) {

		while ( my $l = <$f> ) {

			chomp($l);

			if ( $l =~ /#/ || $l =~ /^[\r\n\t]$/ || $l eq "" ) {
				next;
			}

			my %m = ();
			my @vals = split( /,/, $l );

			chomp @vals;
			map { $_ =~ s/[\t\s]//g } @vals;

			$m{"used"} = 0;
			$m{"color"} = Wx::Colour->new( $vals[0], $vals[1], $vals[2] );

			push( @colors, \%m );
		}

		close($f);
	}

	$self->{"filmColors"} = \@colors;

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

