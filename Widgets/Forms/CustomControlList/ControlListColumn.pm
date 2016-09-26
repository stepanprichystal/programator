#-------------------------------------------------------------------------------------------#
# Description: Represent columnLayout.
# Class keep GroupWrapperForm in Column layout and can move
# GroupWrapperForm to neighbour columns
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Widgets::Forms::CustomControlList::ControlListColumn;


#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

#local library

use Widgets::Style;

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	 my  $class = shift;
	 

	#my $self = $class->SUPER::new( &Wx::wxVERTICAL );

	my $self = {};
	bless($self);

	 $self->{"parent"} = shift;
	$self->{"width"} = shift;
	

	

	$self->__SetLayout();

	#$self->{"prevCol"} = undef;
	#$self->{"nextCol"} = undef;

	#my @groups = ();
	#$self->{"groups"} = \@groups;

	return $self;
}


sub GetSizer {
	my $self = shift;

	return $self->{"szMain"};
}

 

# Move last GroupWrapperForm in column to next column
sub MoveNextGroup {
	my $self = shift;

	unless ( $self->{"nextCol"} ) {
		return 0;
	}

	my @childs = $self->{"sizerGroup"}->GetChildren();

	if ( scalar(@childs) <= 1 ) {
		return 0;
	}

	my $lastIdx = scalar(@childs) - 1;

	if ( $lastIdx >= 0 ) {

		my $lastChildItem = $childs[$lastIdx];
		my $lastChild     = $lastChildItem->GetWindow();

		$self->{"sizerGroup"}->Remove($lastIdx);
		$self->{"nextCol"}->InsertNewGroup($lastChild);

		# columns need to be layout
		$self->{"nextCol"}->{"sizerGroup"}->Layout();
		$self->{"sizerGroup"}->Layout();

		$self->{"szMain"}->Layout();
		$self->{"nextCol"}->{"szMain"}->Layout();
	}

	return 1;

}

# Move first GroupWrapperForm in column to preview column
sub MoveBackGroup {
	my $self = shift;

	unless ( $self->{"prevCol"} ) {
		return 0;
	}

	my @childs = $self->{"sizerGroup"}->GetChildren();

	if ( scalar(@childs) < 1 ) {
		return 0;
	}

	my $firstIdx = 0;

	my $firstChildItem = $childs[$firstIdx];
	my $firstChild     = $firstChildItem->GetWindow();
	$self->{"sizerGroup"}->Remove($firstIdx);
	$self->{"prevCol"}->AppendNewGroup($firstChild);

	return 1;

}

# Insert GroupWrapperForm from top
sub InsertNewGroup {
	my $self  = shift;
	my $group = shift;

	$self->{"sizerGroup"}->Prepend( $group, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

}

# Append GroupWrapperForm from bot
sub AppendNewGroup {
	my $self  = shift;
	my $group = shift;

	$self->{"sizerGroup"}->Add( $group, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
}

# Append GroupWrapperForm from bot
sub AddCell {
	my $self  = shift;
	my $cell = shift;

	 

	$self->{"sizerCells"}->Add( $cell, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$self->{"sizerCells"}->Layout();
}


# Return actual height of all GroupWrapperForms (thus whole column)
sub GetHeight {
	my $self = shift;

	$self->{"szMain"}->Layout();
	$self->{"sizerGroup"}->Layout();

	#my ( $w, $colHeight ) = $self->{"sizerGroup"}->GetSize();
	my $s         = $self->{"sizerGroup"}->GetSize();
	my $colHeight = $s->GetHeight();


	return $colHeight;
}


sub __SetLayout {
	my $self = shift;

	# DEFINE SIZERS
	my $szMain     = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szExpander = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szGroups   = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS

	# BUILD LAYOUT STRUCTURE

	# Add expander to column, which keep width
	$szExpander->Add( $self->{"width"}, 1, 0, &Wx::wxEXPAND );

	$szMain->Add( $szExpander, 0, &Wx::wxEXPAND );
	$szMain->Add( $szGroups,   0, &Wx::wxEXPAND );

	# SAVE REFERENCES

	$self->{"sizerCells"} = $szGroups;
	$self->{"szMain"}     = $szMain;

}

sub __GetChildCnt {
	my $self = shift;

	my @childs  = $self->{"sizerGroup"}->GetChildren();
	my $lastIdx = scalar(@childs);

	return $lastIdx;
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

