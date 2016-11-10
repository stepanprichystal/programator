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

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my ( $class, $parent, $text, $rowHeight ) = @_;

	#my $self = $class->SUPER::new( &Wx::wxVERTICAL );

	my $self = {};
	bless($self);

	$self->{"parent"} = $parent;
	$self->{"text"} = $text;
	
	unless($rowHeight){
		$rowHeight = -1;
	}
	
	$self->{"rowHeight"} = $rowHeight;

	#cells
	my @cells = ();
	$self->{"cells"} = \@cells;

	$self->__SetLayout();

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

	return $self->{"mainChb"}->GetValue();
}

sub SetSelected {
	my $self = shift;
	my $selected = shift;
	

	$self->{"mainChb"}->SetValue($selected);
	#$self->__OnSelectedChange();
	
	
}

sub __SetLayout {
	my $self = shift;

	my $mainChb = Wx::CheckBox->new( $self->{"parent"}, -1, $self->{"text"}, [-1,-1], [-1, $self->{"rowHeight"} ] );

	#my $jobIdTxt = Wx::StaticText->new( $self->{"parent"}, -1, "test", [ -1, -1 ] );
	#my $btnProduce = Wx::Button->new( $self->{"parent"}, -1, "Produce", &Wx::wxDefaultPosition, [ 60, 20 ] );

	# SET EVENTS
	Wx::Event::EVT_CHECKBOX( $mainChb, -1, sub { $self->__OnSelectedChange(@_) } );

	$self->_AddCell($mainChb);

	#$self->__AddCell($jobIdTxt);
	#$self->__AddCell($btnProduce);

	$self->{"mainChb"} = $mainChb;

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

