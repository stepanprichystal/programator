#-------------------------------------------------------------------------------------------#
# Description: Basic list row, which show name of marikings + checkbox for each marking layer
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

	my $class         = shift;
	my $parent        = shift;
	my $markingName   = shift;
	my $markingLayers = shift;

	my $rowHeight = 20;

	my $self = $class->SUPER::new( $parent, $markingName, $rowHeight );

	bless($self);

	$self->{"markingName"} = $markingName;

	# init marking layers
	my @l = ();

	foreach my $l ( @{$markingLayers} ) {

		# couple layer name + checkbox
		my %inf = ( "name" => $l, "chb" => undef );
		push( @l, \%inf );
	}

	$self->{"layers"} = \@l;

	$self->__SetLayout();

	# EVENTS

	return $self;
}

sub SetMarkingData {
	my $self = shift;
	my $data = shift;
	
	# remove whitespaces, convert to lower
	$data =~ s/\s//g;
	$data = lc($data);

	my @layerNames = split( ",", $data );
 
	foreach my $inf ( @{ $self->{"layers"} } ) {

		my $lExist = scalar( grep { $_ eq $inf->{"name"} } @layerNames );

		if ($lExist) {

			$inf->{"chb"}->SetValue(1);
		}
	}
}

sub GetMarkingData {
	my $self = shift;

	my @layers = ();

	foreach my $inf ( @{ $self->{"layers"} } ) {

		if ( $inf->{"chb"}->IsChecked() ) {

			push( @layers, $inf->{"name"} );
		}
	}

	my $str = join( ",", @layers );
	$str = uc($str);

	return $str;
}

sub DisableControls {
	my $self          = shift;
	my @disableLayers = @{shift(@_)};

	foreach my $lName (@disableLayers) {

		my $lInfo = ( grep { $_->{"name"} eq $lName } @{ $self->{"layers"} } )[0];

		$lInfo->{"chb"}->Disable();
	}
}

sub __SetLayout {
	my $self = shift;

	# DEFINE CELLS

	foreach my $l ( @{ $self->{"layers"} } ) {

		my $chb = Wx::CheckBox->new( $self->{"parent"}, -1, "", [ -1, -1 ], [ -1, $self->{"rowHeight"} ] );
		$self->_AddCell($chb);

		$l->{"chb"} = $chb;

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
