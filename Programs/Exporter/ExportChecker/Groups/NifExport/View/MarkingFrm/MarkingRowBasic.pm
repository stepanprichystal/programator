#-------------------------------------------------------------------------------------------#
# Description: Basic list row, which show only checkbutton + text.
# Used for notes, which has no another parameters - only text
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportChecker::Groups::NifExport::View::MarkingFrm::MarkingRowBasic;
use base qw(Widgets::Forms::CustomControlList::ControlListRow);

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

#local library

use Widgets::Style;
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $class       = shift;
	my $parent      = shift;
	my $markingName = shift;

	my $rowHeight = 20;

	my $self = $class->SUPER::new( $parent, $markingName, $rowHeight );

	bless($self);

	$self->{"markingName"} = $markingName;

	my @l = ();
	$self->{"layers"} = \@l;

	$self->__SetLayout();

	# EVENTS

	return $self;
}

sub SetMarkingData {
	my $self = shift;
	my $data = shift;
	
	my @layerNames = split(",", $data);
	
 	chomp (@layerNames);
 
	foreach my $inf ( @{ $self->{"layers"} } ) {
		
		my $lExist = scalar( grep { $_ eq $inf->{"name"} } @layerNames );
		
		if($lExist){
			
			$inf->{"chb"}->SetValue(1);
		}
	}
}

sub GetMarkingData {
	my $self = shift;

	my @layers = "";

	foreach my $inf ( @{ $self->{"layers"} } ) {

		if ( $inf->{"chb"}->IsChecked() ) {

			push( @layers, $inf->{"name"} );
		}
	}

	return join( ",", @layers );
}

sub DisableControls {
	my $self      = shift;
	my @allLayers = shift;

	foreach my $inf ( @{ $self->{"layers"} } ) {

		my $lExist = scalar( grep { $_->{"gROWname"} eq $inf->{"name"} } @allLayers );

		unless ($lExist) {

			$inf->{"chb"}->Disable();
		}
	}
}

sub __SetLayout {
	my $self = shift;

	# DEFINE CELLS

	my @arr = ( "pc", "mc", "c", "s", "ms", "ps" );

	foreach my $l (@arr) {

		my $chb = Wx::CheckBox->new( $self->{"parent"}, -1, $l, [ -1, -1 ], [ -1, $self->{"rowHeight"} ] );
		$self->_AddCell($chb);

		my %inf = ( "name" => $l, "chb" => $chb );

		push( @{ $self->{"layers"} }, \%inf );

	}

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
