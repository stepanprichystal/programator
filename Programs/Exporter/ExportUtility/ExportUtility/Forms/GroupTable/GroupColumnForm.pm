#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportUtility::ExportUtility::Forms::GroupTable::GroupColumnForm;

#use base('Wx::BoxSizer');

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

	my ( $class, $parent ) = @_;

	#my $self = $class->SUPER::new( &Wx::wxVERTICAL );

	my $self = {};
	bless($self);

	$self->{"parent"} = $parent;

	$self->__SetLayout();

	$self->{"prevCol"} = undef;
	$self->{"nextCol"} = undef;

	my @groups = ();
	$self->{"groups"} = \@groups;

	return $self;
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
	$szExpander->Add( 1, 1, 0, &Wx::wxEXPAND );

	$szMain->Add( $szExpander, 0, &Wx::wxEXPAND );
	$szMain->Add( $szGroups,   0, &Wx::wxEXPAND );

	# SAVE REFERENCES

	$self->{"sizerGroup"} = $szGroups;
	$self->{"szMain"}     = $szMain;

}

sub GetSizer {
	my $self = shift;

	return $self->{"szMain"};
}

sub Init {
	my $self    = shift;
	my $prevCol = shift;
	my $nextCol = shift;

	$self->{"prevCol"} = $prevCol;
	$self->{"nextCol"} = $nextCol;

}

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

	# columns need to be layout
	#$self->{"prevCol"}->{"sizerGroup"}->Layout();
	#$self->{"prevCol"}->{"sizerGroup"}->Fit();
	#$self->{"prevCol"}->{"sizerGroup"}->FitInside();
	
	#$self->{"sizerGroup"}->Layout();
	#$self->{"sizerGroup"}->Layout();
	#$self->{"szMain"}->Layout();
	#$self->{"prevCol"}->{"szMain"}->Layout();

	return 1;

}

sub InsertNewGroup {
	my $self  = shift;
	my $group = shift;

	$self->{"sizerGroup"}->Prepend( $group, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	#$group->{"column"} = $self;

}

sub AppendNewGroup {
	my $self  = shift;
	my $group = shift;

	$self->{"sizerGroup"}->Add( $group, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	#$group->{"column"} = $self;
}
 


sub GetHeight {
	my $self = shift;

	#$self->{"sizerGroup"}->Layout();
	#$self->{"parent"}->Layout();
	#$self->{"parent"}->FitInside();
	#$self->{"parent"}->Layout();
	$self->{"szMain"}->Layout();
	$self->{"sizerGroup"}->Layout();

	#my ( $w, $colHeight ) = $self->{"sizerGroup"}->GetSize();
	my $s         = $self->{"sizerGroup"}->GetSize();
	my $colHeight = $s->GetHeight();
	
	#my @childs = $self->{"sizerGroup"}->GetChildren();

	return $colHeight;
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

