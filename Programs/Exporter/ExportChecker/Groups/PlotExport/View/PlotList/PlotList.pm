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
use aliased 'Packages::Export::PlotExport::FilmCreator::FilmCreators';
use aliased 'Packages::Export::PlotExport::FilmCreator::Helper';
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class  = shift;
	my $parent = shift;

	my $inCAM = shift;
	my $jobId = shift;

	my $layers = shift;

	# Name, Color, Polarity, Mirror, Comp
	my @widths = ( 60,     20, 50,         40,       50,     80,      80,       80, );
	my @titles = ( "Name", "", "Polarity", "Mirror", "Comp", "Films", "Merged", "Single" );

	my $columnCnt    = scalar(@widths);
	my $columnWidths = \@widths;
	my $verticalLine = 1;

	my $self = $class->SUPER::new( $parent, $columnCnt, $columnWidths, $verticalLine );

	bless($self);

	$self->{"titles"} = \@titles;
	$self->{"inCAM"}  = $inCAM;
	$self->{"jobId"}  = $jobId;
	$self->{"layers"} = $layers;

	$self->{"filmCreators"} = FilmCreators->new( $self->{"inCAM"}, $self->{"jobId"} );

	$self->__DefineFilmColors();

	$self->__SetLayout();

	# EVENTS

	$self->{"onRowChanged"} = Event->new();

	return $self;
}

sub SetPolarity {
	my $self = shift;
	my $val  = shift;

	my @rows = $self->GetAllRows();

	foreach my $r (@rows) {

		$r->SetPolarity($val);
	}
}

sub SetMirror {
	my $self = shift;
	my $val  = shift;

	my @rows = $self->GetAllRows();

	foreach my $r (@rows) {

		$r->SetMirror($val);
	}
}

sub SetComp {
	my $self = shift;
	my $val  = shift;

	my @rows = $self->GetAllRows();

	foreach my $r (@rows) {

		$r->SetComp($val);
	}
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

	#create rows for each laters

	my @layers = @{ $self->{"layers"} };
	foreach my $l (@layers) {

		my $row = PlotListRow->new( $self, $l );

		# zaregistrovat udalost
		#$self->{"onSelectedChanged"}->Add(sub{ $row->PlotSelectionChanged($self, @_) });

		$row->{"onRowChanged"}->Add( sub { $self->{"onRowChanged"}->Do(@_) } );

		$self->AddRow($row);

	}

	# REGISTER EVENTS

	$self->{"onSelectedChanged"}->Add( sub { $self->__OnSelectedChangeHandler(@_) } );

	# BUILD LAYOUT STRUCTURE

}

sub __OnSelectedChangeHandler {
	my $self = shift;

	my @selectedLayers = ();

	foreach my $row ( $self->GetSelectedRows() ) {

		push( @selectedLayers, $row->GetRowText() );
	}

	my @rows = $self->GetAllRows();

	foreach my $r (@rows) {
		$r->PlotSelectionChanged( \@selectedLayers );
	}

	print STDERR "test";

}

sub __GetRuleSet {
	my $self       = shift;
	my $layerName  = shift;
	my $creatorNum = shift;

	my @ruleSets = $self->{"filmCreators"}->GetRuleSets($creatorNum);

	my $set;

	foreach my $rulSet (@ruleSets) {

		my @ruleLayers = $rulSet->GetLayers();

		my @exist = grep { $_->{"name"} eq $layerName } @ruleLayers;

		if ( scalar(@exist) ) {

			$set = $rulSet;
			last;
		}
	}

	if ( $set && !defined $set->{"color"} ) {

		my @notUsedColor = grep { $_->{"used"} != 1 } @{ $self->{"filmColors"} };
		unless ( scalar(@notUsedColor) ) {

			die "There are no another colors for unit plot";
		}

		foreach my $c ( @{ $self->{"filmColors"} } ) {

			unless ( $c->{"used"} ) {
				$set->{"color"} = $c->{"color"};
				$c->{"used"}    = 1;
				last;
			}
		}
	}

	# If no set exist, create empty result set

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

	#my $test = Programs::Exporter::ExportChecker::Forms::GroupTableForm->new();

	#$test->MainLoop();
}

1;

