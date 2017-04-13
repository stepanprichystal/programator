#-------------------------------------------------------------------------------------------#
# Description: Responsible for creating "table of column", where GroupWrapperForms are
# placed in. Is responsible for recaltulating "column" layout.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AbstractQueue::AbstractQueue::Forms::GroupTable::GroupTableForm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

#local library

use Widgets::Style;
use aliased 'Managers::AbstractQueue::AbstractQueue::Forms::GroupTable::GroupColumnForm';
use aliased 'Managers::AbstractQueue::AppConf';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my ( $class, $parent ) = @_;

	my $self = $class->SUPER::new( $parent, -1 );

	bless($self);

	$self->{"columnNumber"} = 3;
	$self->{"parent"}       = $parent;
 

	return $self;
}


sub InitGroupTable {
	my $self  = shift;
	my $units = shift;
	my $inCAM = shift;

	$self->__SetLayout($units);
}


# Recompute layout. Measure height of each GroupWrapperForm and
# move them to next column if it is necessery
sub RearrangeGroups {
	my $self      = shift;
	my $page      = shift;
	my $pageHight = shift;
	my $recursive = shift;

	$self->{"pageHeight"} = $pageHight;

	my $height;

	# Define new height of table for groups
	# Height is avaage height of column + 40%
	my $avg = $self->__GetColumnAvgHeight();
	$avg = $avg * 1.4;

	if ( $avg < $pageHight ) {
		$height = $pageHight;
	}
	else {
		$height = $avg;
	}

	print "Height = $height, Page height is: $pageHight \n";

	my $colCnt = scalar( @{ $self->{"columns"} } );

	#move group back, untill column height < then table height

	for ( my $i = 0 ; $i < $colCnt ; $i++ ) {

		$self->Layout();
		$self->FitInside();

		my $column    = ${ $self->{"columns"} }[$i];
		my $colHeight = $column->GetHeight();

		my $colorder = $i + 1;

		print " Column " . $colorder . " :\n";

		while ( $colCnt != $i + 1 && $colHeight >= $height ) {

			# If nothing to move, exit from loop
			unless ( $column->MoveNextGroup() ) {
				last;
			}

			$self->Layout();
			$self->FitInside();

			$colHeight = $column->GetHeight();

			print "- Loop, Column height: $colHeight \n";
		}
	}

	unless ($recursive) {

		# Reset group layout and do rearrange,
		# only if last reset was 3 secundes before
		my $diff = undef;
		my $last = $self->{"lastRearrange"};

		if ( defined $last ) {
			$diff = time() - $last;
		}

		if ( !defined $last || ( defined $last && $diff > 3 ) ) {

			my $maxHeight = $self->__GetMaxColumnHeight();

			# get height for last colum

			my $lastCol       = ${ $self->{"columns"} }[ $colCnt - 1 ];
			my $lastColHeight = $lastCol->GetHeight();

			if ( $lastColHeight - $maxHeight > 200 ) {

				#print "Resize and REARANGE\n";

				$self->__ResetRearrange( $page, $pageHight );

			}
		}
	}
}
 


# Create column, for placing GroupWrappersForm
sub __SetLayout {

	my $self  = shift;
	my $units = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	$self->SetBackgroundColour( AppConf->GetColor("clrGroupTableBackg") );

	# DEFINE SIZERS
	my @columns = ();
	$self->{"columns"} = \@columns;

	# init columns
	for ( my $i = 0 ; $i < $self->{"columnNumber"} ; $i++ ) {

		my $col = GroupColumnForm->new($self);
		push( @{ $self->{"columns"} }, $col );
	}

	for ( my $i = 0 ; $i < $self->{"columnNumber"} ; $i++ ) {

		my $col     = ${ $self->{"columns"} }[$i];
		my $nextCol = undef;
		my $prevCol = undef;

		if ( $i > 0 ) {
			$prevCol = ${ $self->{"columns"} }[ $i - 1 ];
		}

		if ( $i < $self->{"columnNumber"} - 1 ) {
			$nextCol = ${ $self->{"columns"} }[ $i + 1 ];
		}

		$col->Init( $prevCol, $nextCol );
	}

	# Init, columns - tie them together

	# BUILD LAYOUT STRUCTURE

	# add groups to first column, by order

	my $firstCol = @{ $self->{"columns"} }[0];
	foreach my $unit ( @{$units} ) {

		$unit->InitForm($self);
		$firstCol->InsertNewGroup( $unit->{"form"} );
	}

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
			$sepSz->Add( 2, 2, 0, &Wx::wxEXPAND );

			$szMain->Add( $sepPnl, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );    #

		}

		print "pecent width: $percentWidth\n";
		$szMain->Add( $clmSz->GetSizer(), $percentWidth );

	}

	$self->SetSizer($szMain);

	$self->{"szMain"} = $szMain;

}


sub __ResetRearrange {
	my $self       = shift;
	my $page       = shift;
	my $pageHeight = shift;

	$self->{"lastRearrange"} = time();

	#move alll group to first column and do new rearange

	my $colCnt = scalar( @{ $self->{"columns"} } );
	for ( my $i = $colCnt - 2 ; $i >= 0 ; $i-- ) {

		while (1) {
			my $columnNext = ${ $self->{"columns"} }[ $i + 1 ];

			# If nothing to move, exit from loop
			unless ( $columnNext->MoveBackGroup() ) {
				last;
			}
		}
	}

	$self->RearrangeGroups( $page, $pageHeight, 1 );

}


# Return max column height, last col is not count!
sub __GetMaxColumnHeight {
	my $self = shift;

	my $colCnt = scalar( @{ $self->{"columns"} } );

	#move group back, untill column height < then table height

	my $max = 0;
	for ( my $i = 0 ; $i < $colCnt - 1 ; $i++ ) {
		my $column    = ${ $self->{"columns"} }[$i];
		my $colHeight = $column->GetHeight();

		if ( $colHeight > $max ) {

			$max = $colHeight;

		}
	}

	return $max;

}

sub __GetColumnAvgHeight {
	my $self = shift;

	my $colCnt = scalar( @{ $self->{"columns"} } );

	#move group back, untill column height < then table height

	my $total = 0;
	for ( my $i = 0 ; $i < $colCnt ; $i++ ) {
		my $column    = ${ $self->{"columns"} }[$i];
		my $colHeight = $column->GetHeight();

		$total += $colHeight;

	}

	return int( $total / $colCnt );

}
 
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {
 
}

1;

1;

