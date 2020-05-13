#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::UniTravelerTmpl::BoxBuilders::BuilderInfo;
use base('Packages::CAMJob::Traveler::UniTravelerTmpl::BoxBuilders::BoxBuilderBase');

use Class::Interface;
&implements('Packages::CAMJob::Traveler::UniTravelerTmpl::BoxBuilders::IBoxBuilder');

#3th party library
use utf8;
use strict;
use warnings;
use Time::localtime;
use Storable qw(dclone);
use List::Util qw(first);
use List::MoreUtils qw(uniq);
use POSIX qw(floor ceil);

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Traveler::UniTravelerTmpl::Enums';
use aliased 'Packages::CAMJob::Traveler::UniTravelerTmpl::EnumsStyle';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::TextStyle';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::Color';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::BackgStyle';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::BorderStyle';
use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub Build {
	my $self       = shift;
	my $boxXEndPos = shift;
	my $boxYEndPos = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $tbl         = $self->{"table"};
	my $stackupMngr = $self->{"travelerMngr"};
	my $traveler    = $self->{"traveler"};

	# 1) Define columns
	my $clmnWidth = ( $boxXEndPos - $tbl->GetOrigin()->{"x"} ) - 2 * EnumsStyle->ClmnWidth_margin;
	$tbl->AddColDef( "leftMargin",  EnumsStyle->ClmnWidth_margin );
	$tbl->AddColDef( "leftCol",     $clmnWidth * 1 / 2 );
	$tbl->AddColDef( "rightCol",    $clmnWidth * 1 / 2 );
	$tbl->AddColDef( "rightMargin", EnumsStyle->ClmnWidth_margin );

	# 2) Define styles
	my $txtLCollStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
										EnumsStyle->TxtSize_NORMAL,
										Color->new( 0, 0, 0 ),
										TblDrawEnums->Font_NORMAL, undef,
										TblDrawEnums->TextHAlign_RIGHT,
										TblDrawEnums->TextVAlign_CENTER, 1 );

	my $txtRCollStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
										EnumsStyle->TxtSize_NORMAL,
										Color->new( 0, 0, 0 ),
										TblDrawEnums->Font_NORMAL, undef,
										TblDrawEnums->TextHAlign_LEFT,
										TblDrawEnums->TextVAlign_CENTER, 1 );

	my $txtRCollBStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
										 EnumsStyle->TxtSize_NORMAL,
										 Color->new( 0, 0, 0 ),
										 TblDrawEnums->Font_NORMAL, undef,
										 TblDrawEnums->TextHAlign_LEFT,
										 TblDrawEnums->TextVAlign_CENTER, 1 );

	my $txtLCollBStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
										 EnumsStyle->TxtSize_NORMAL,
										 Color->new( 0, 0, 0 ),
										 TblDrawEnums->Font_BOLD, undef,
										 TblDrawEnums->TextHAlign_RIGHT,
										 TblDrawEnums->TextVAlign_CENTER, 1 );

	my $txtTitStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
									  EnumsStyle->TxtSize_NORMAL,
									  Color->new( 0, 0, 0 ),
									  TblDrawEnums->Font_BOLD, undef,
									  TblDrawEnums->TextHAlign_LEFT,
									  TblDrawEnums->TextVAlign_CENTER, 1 );

	my $borderTitleStyle = BorderStyle->new();
	$borderTitleStyle->AddEdgeStyle( "top", TblDrawEnums->EdgeStyle_SOLIDSTROKE, EnumsStyle->Border_THICK, Color->new( EnumsStyle->Clr_BOXBORDER ) );
	$borderTitleStyle->AddEdgeStyle( "bot", TblDrawEnums->EdgeStyle_SOLIDSTROKE, EnumsStyle->Border_THICK, Color->new( EnumsStyle->Clr_BOXBORDER ) );

	# 2) Add all operations
	my @infoBoxes = $traveler->GetAllInfoBoxes();
	for ( my $i = 0 ; $i < scalar(@infoBoxes) ; $i++ ) {

		my $box = $infoBoxes[$i];

		# 1) Define title cell
		my $BACKtmp = undef;
		my $rowTit = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxInfoRowHeight_TITLE, $BACKtmp, $borderTitleStyle );
		$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ), $tbl->GetRowCnt() - 1, undef, undef, "Info zakázka", $txtTitStyle );

		$tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxHFRowHeight_TITLE );

		# 2) Define info box rows
		my @rows = $box->GetAllItems();

		for ( my $j = 0 ; $j < scalar(@rows) ; $j++ ) {

			my $r = $rows[$j];

			$tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->RowHeight_STD );

			$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ), $tbl->GetRowCnt() - 1, undef, undef, $r->GetText().":", $txtLCollStyle );
			$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("rightCol") ),
						   $tbl->GetRowCnt() - 1,
						   undef, undef, $r->GetValue(), $txtRCollStyle );
		}
		
		$tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxHFRowHeight_TITLE );

	}

	
	
	# Add special row "extender" which stretch table to bottom edge of page
	if ( $tbl->GetOrigin()->{"y"} + $tbl->GetHeight() < $boxYEndPos ) {

		$tbl->AddRowDef( "expander", ( $boxYEndPos - ( $tbl->GetOrigin()->{"y"} + $tbl->GetHeight() ) ) );
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
