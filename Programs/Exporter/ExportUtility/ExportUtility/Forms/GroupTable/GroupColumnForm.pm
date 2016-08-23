#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::ExportUtility::Forms::GroupTable::GroupColumnForm;
use base('Wx::BoxSizer');
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

	my $self = $class->SUPER::new(&Wx::wxVERTICAL)

	bless($self);

	$self->{"parent"} = shift;
	#$self->{"sizer"}  = shift;

	$self->{"prevCol"} = undef;
	$self->{"nextCol"} = undef;

	my @groups = ();
	$self->{"groups"} = \@groups;

	return $self;
}

sub Init {
	my $self    = shift;
	my $prevCol = shift;
	my $nextCol = shift;

	$self->{"prevCol"} = $prevCol;
	$self->{"nextCol"} = $nextCol;

}

sub MoveLastGroup {
	my $self = shift;

	my @childs  = $self->GetChildren();
	my $lastIdx = scalar(@childs) - 1;

	my $lastChild = $childs[$lastIdx];

	if ( $lastIdx >= 0 ) {
		$self->Remove($lastIdx);
	}

	if ( $self->{"nextCol"} ) {
		$self->{"nextCol"}->InsertNewGroup( $lastChild);
	}

}

sub InsertNewGroup {
	my $self  = shift;
	my $group = shift;

	$self->Prepend( $group, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

}

sub GetHeight {
	my $self = shift;

	# $self->FitInside();
	# $self->Layout();
	my ( $w, $colHeight ) = $self->GetSizeWH();
	return $colHeight;
}

sub __GetChildCnt {
	my $self = shift;

	my @childs  = $self->GetChildren();
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

