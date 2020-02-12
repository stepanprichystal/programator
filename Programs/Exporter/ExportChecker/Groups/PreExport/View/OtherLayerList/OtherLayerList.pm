#-------------------------------------------------------------------------------------------#
# Description: Responsible for creating "table of column", where GroupWrapperForms are
# placed in. Is responsible for recaltulating "column" layout.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PreExport::View::OtherLayerList::OtherLayerList;
use base qw(Widgets::Forms::CustomControlList::ControlList);

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);


#local library
use aliased 'Packages::Tests::Test';
use Widgets::Style;
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::OtherLayerList::OtherLayerListRow';
use aliased 'Packages::Events::Event';
use aliased 'Packages::Export::PlotExport::FilmCreator::FilmCreators';
use aliased 'Packages::Export::PlotExport::FilmCreator::Helper';
use aliased 'Helpers::GeneralHelper';
use aliased 'Widgets::Forms::CustomControlList::Enums' => 'EnumsList';

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
	my @widths = ( 100,     20, 50,         50, );
	my @titles = ( "Name", "", "Polarity", "Mirror" );

	my $columnCnt    = scalar(@widths);
	my $columnWidths = \@widths;
	my $verticalLine = 1;

	my $self = $class->SUPER::new( $parent, EnumsList->Mode_CHECKBOXLESS, $columnCnt, $columnWidths, $verticalLine, undef, 1 );

	bless($self);

	$self->{"titles"} = \@titles;
	$self->{"inCAM"}  = $inCAM;
	$self->{"jobId"}  = $jobId;
	$self->{"layers"} = $layers;

	$self->__SetLayout();

	# EVENTS

	$self->{"otherLayerSettChangedEvt"} = Event->new();

	return $self;
}

sub SetLayerValues {
	my $self   = shift;
	my $layers = shift;

	foreach my $l ( @{$layers} ) {

		$self->SetLayerValue($l);
	}
}

sub SetLayerValue {
	my $self = shift;
	my $l    = shift;

	my $row = $self->GetRowByText( $l->{"name"} );
	die "Row list was not found by name: " . $l->{"name"} unless ( defined $row );

	$row->SetPolarityVal( $l->{"polarity"} );
	$row->SetMirrorVal( $l->{"mirror"} );
	$row->SetCompVal( $l->{"comp"} );
	$row->SetStretchXVal( $l->{"stretchX"} );
	$row->SetStretchYVal( $l->{"stretchY"} );
}

sub GetLayerValues {
	my $self = shift;

	my @layers = ();

	foreach my $l ( @{ $self->{"layers"} } ) {

		my %linfo = $self->GetLayerValue( $l->{"gROWname"} );

		push( @layers, \%linfo );
	}

	return @layers;
}

sub GetLayerValue {
	my $self  = shift;
	my $lName = shift;

	my $row = $self->GetRowByText($lName);

	my %lInfo = ();

	$lInfo{"name"}     = $lName;
	$lInfo{"polarity"} = $row->GetPolarityVal();
	$lInfo{"mirror"}   = $row->GetMirrorVal();
	$lInfo{"comp"}   = $row->GetCompVal();
	$lInfo{"stretchX"}   = $row->GetStretchXVal();
	$lInfo{"stretchY"}   = $row->GetStretchYVal();
	 
	return %lInfo;
}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __SetLayout {

	my $self = shift;

	# DEFINE SIZERS

	$self->SetHeader( $self->{"titles"} );

	$self->SetVerticalLine( Wx::Colour->new( 206, 206, 206 ) );

	$self->SetHeaderBackgroundColor( Wx::Colour->new( 230, 230, 230 ) );

	#create rows for each laters

	my @layers = @{ $self->{"layers"} };
	foreach my $l (@layers) {

		my $row = OtherLayerListRow->new( $self, $l->{"gROWname"} );

		# zaregistrovat udalost
		#$self->{"onSelectedChanged"}->Add(sub{ $row->PlotSelectionChanged($self, @_) });

		$row->{"otherLayerSettChangedEvt"}->Add( sub { $self->__OnlayerSettChangedHndl(@_) } );

		$self->AddRow($row);

	}

	# REGISTER EVENTS

	# BUILD LAYOUT STRUCTURE

}

sub __OnlayerSettChangedHndl {
	my $self  = shift;
	my $lName = shift;

	# 1) Get current layer value
	my %currLSett = $self->GetLayerValue($lName);

	$self->{"otherLayerSettChangedEvt"}->Do( \%currLSett );

	Diag("Layer name changed: $lName\n");

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

