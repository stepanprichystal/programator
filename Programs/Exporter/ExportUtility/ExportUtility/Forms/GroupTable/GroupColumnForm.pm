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

	my $box = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	$self->{"parent"} = $parent;
	$self->{"sizer"}  = $box;

	$self->{"nextCol"} = undef;

	my @groups = ();
	$self->{"groups"} = \@groups;

	return $self;
}

sub Init {
	my $self = shift;

	my $nextCol = shift;

	$self->{"nextCol"} = $nextCol;

}

sub MoveLastGroup {
	my $self = shift;

	unless ( $self->{"nextCol"} ) {
		return 0;
	}

	my @childs  = $self->{"sizer"}->GetChildren();
	my $lastIdx = scalar(@childs) - 1;

	if ( $lastIdx >= 0 ) {

		my $lastChildItem = $childs[$lastIdx];
		my $lastChild     = $lastChildItem->GetWindow();

		$self->{"sizer"}->Remove($lastIdx);
		$self->{"nextCol"}->InsertNewGroup($lastChild);
		
		# columns need to be layout
		#$self->{"nextCol"}->{"sizer"}->Layout();
		#$self->{"sizer"}->Layout();
	}

}

 



sub InsertNewGroup {
	my $self  = shift;
	my $group = shift;

	$self->{"sizer"}->Prepend( $group, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

}

sub GetHeight {
	my $self = shift;
$self->{"sizer"}->Layout();
	 $self->{"parent"}->Layout();
	$self->{"parent"}->FitInside();
	 $self->{"parent"}->Layout();
	$self->{"sizer"}->Layout();
	#my ( $w, $colHeight ) = $self->{"sizer"}->GetSize();
	my $s         = $self->{"sizer"}->GetSize();
	my $colHeight = $s->GetHeight();

	return $colHeight;
}

sub __GetChildCnt {
	my $self = shift;

	my @childs  = $self->{"sizer"}->GetChildren();
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

