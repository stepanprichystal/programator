#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::ExportUtility::Forms::GroupTableForm;
use base qw(Wx::Panel);

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

	my $self = $class->SUPER::new( $parent, -1 );

	bless($self);

	$self->{"columnNumber"} = 3;

	$self->__SetLayout();

	#$self->SetBackgroundColour($Widgets::Style::clrBlack);

	return $self;
}

sub InitGroupTable {
	my $self  = shift;
	my $units = shift;
	my $inCAM = shift;

	$self->__FillColums($units);

}

sub __SetLayout {

	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	$self->SetBackgroundColour( Wx::Colour->new( 255, 255, 255 ) );

	# DEFINE SIZERS
	my @columns = ();
	$self->{"columns"} = \@columns;

	# init columns
	for ( my $i = 0 ; $i < $self->{"columnNumber"} ; $i++ ) {

		push( @{ $self->{"columns"} }, Wx::BoxSizer->new(&Wx::wxVERTICAL) );
	}

	# BUILD LAYOUT STRUCTURE

	#set sizers
	my $colCnt       = scalar( @{ $self->{"columns"} } );
	my $percentWidth = int( 100 / $colCnt ) - $colCnt * 2;

	for ( my $i = 0 ; $i < $colCnt ; $i++ ) {
		my $clmSz = ${ $self->{"columns"} }[$i];

		# add column separator
		if ( $i > 0 ) {

			my $sepSz = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
			my $sepPnl = Wx::Panel->new( $self, -1 );
			$sepPnl->SetBackgroundColour( Wx::Colour->new( 200, 200, 200 ) );
			$sepPnl->SetSizer($sepSz);
			$szMain->Add( $sepPnl, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

		}

		$szMain->Add( $clmSz, $percentWidth, &Wx::wxEXPAND );

	}

	$self->SetSizer($szMain);

}

sub __FillColums {
	my $self  = shift;
	my $units = shift;



	# first column
	my $actualCol = ${ $self->{"columns"} }[0];

	# init unit form

	foreach my $unit ( @{$units} ) {
		$unit->Init($self);
	}
	
	# get height of all groups
	my $totalHeight       = 0;
	foreach my $unit ( @{$units} ) {

		my $form = $unit->{"form"};
		$actualCol->Add( $form, 0 );
		$self->FitInside();
		$self->Layout();
		my ( $w, $groupHeight ) = $form->GetSizeWH();
		$totalHeight += $groupHeight;
	}
	my @childs2  = $actualCol->GetChildren();
	for ( my $i = 0 ; $i < scalar( @{$units}) ; $i++ ) {
		$actualCol->Remove( 0);
		#@childs2  = $actualCol->GetChildren();
	}
	
	
	# Avarage height of column could be 
	my $colHeight = int($totalHeight/3);
	$colHeight += int($colHeight*0.2);

	my $actualColId = 0;
	my $total       = 0;
	$actualCol = ${ $self->{"columns"} }[$actualColId];
	my @childs1  = $actualCol->GetChildren();
	foreach my $unit ( @{$units} ) {

		my $form = $unit->{"form"};
		$actualCol->Add( $form, 0,  &Wx::wxEXPAND | &Wx::wxALL, 2 );

		#push group tu actual column

		$self->FitInside();
		$self->Layout();

		my ( $w, $groupHeight ) = $form->GetSizeWH();

		print $groupHeight. "\n";

		if ( $total + $groupHeight > $colHeight && $actualColId+1 <  $self->{"columnNumber"}) {

			my @childs  = $actualCol->GetChildren();
			my $lastIdx = scalar(@childs);

			$actualCol->Remove( $lastIdx - 1 );
			$actualColId++;
			$total     = 0;
			$actualCol = ${ $self->{"columns"} }[$actualColId];
			$actualCol->Add( $form, 0,  &Wx::wxEXPAND | &Wx::wxALL, 2 );
		}

		$total += $groupHeight;
	}
}

# ================= NEW ===========================

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

