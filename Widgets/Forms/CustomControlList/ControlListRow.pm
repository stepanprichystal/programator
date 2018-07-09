#-------------------------------------------------------------------------------------------#
# Description: Represent columnLayout.
# Class keep GroupWrapperForm in Column layout and can move
# GroupWrapperForm to neighbour columns
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Widgets::Forms::CustomControlList::ControlListRow;

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

#local library

use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Widgets::Forms::CustomControlList::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my ( $class, $id, $parent, $text, $rowHeight ) = @_;

	#my $self = $class->SUPER::new( &Wx::wxVERTICAL );

	my $self = {};
	bless($self);

	$self->{"id"} = $id // -1; # defualt id is -1
	$self->{"parent"} = $parent;
	$self->{"text"}   = $text;

	unless ($rowHeight) {
		$rowHeight = -1;
	}

	$self->{"rowHeight"} = $rowHeight;

	#cells
	my @cells = ();
	$self->{"cells"} = \@cells;

	#$self->__SetLayout();

	my @groups = ();
	$self->{"groups"} = \@groups;

	# EVENTS
	$self->{"onSelectedChanged"} = Event->new();

	return $self;
}

sub _AddCell {
	my $self = shift;
	my $cell = shift;

	push( @{ $self->{"cells"} }, $cell );
}

sub GetRowText {
	my $self = shift;

	return $self->{"text"};
}

sub GetRowId {
	my $self = shift;

	return $self->{"id"};
}

sub GetCells {
	my $self = shift;

	return @{ $self->{"cells"} };
}

sub GetCellsByPos {
	my $self = shift;
	my $pos  = shift;
	my @call = @{ $self->{"cells"} };

	return $call[$pos];
}

sub IsSelected {
	my $self = shift;

	return $self->{"mainControl"}->GetValue();
}

sub SetSelected {
	my $self     = shift;
	my $selected = shift;

	$self->{"mainControl"}->SetValue($selected);

	#$self->__OnSelectedChange();

}

sub SetMode {
	my $self     = shift;
	my $listMode = shift;

	my $mainControl;

	if ( $listMode eq Enums->Mode_CHECKBOX ) {

		$mainControl = Wx::CheckBox->new( $self->{"parent"}, -1, $self->{"text"}, [ -1, -1 ], [ -1, $self->{"rowHeight"} ] );

		# SET EVENTS
		Wx::Event::EVT_CHECKBOX( $mainControl, -1, sub { $self->__OnSelectedChange(@_) } );

	}
	elsif ( $listMode eq Enums->Mode_CHECKBOXLESS ) {
		$mainControl = Wx::StaticText->new( $self->{"parent"}, -1, $self->{"text"}, [ -1, -1 ], [ -1, $self->{"rowHeight"} ] );
	}

 	# putt control on first position
	unshift ( @{ $self->{"cells"} }, $mainControl);
	
	$self->{"mainControl"} = $mainControl;

}
 

sub __OnSelectedChange {
	my $self = shift;

	# TODO smazat
	$self->{"onSelectedChanged"}->Do($self);
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

