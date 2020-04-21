#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::ProcessStackup::BoxBuilders::BuilderMain;
use base('Packages::CAMJob::Stackup::ProcessStackup::BoxBuilders::BoxBuilderBase');

use Class::Interface;
&implements('Packages::CAMJob::Stackup::ProcessStackup::BoxBuilders::IBoxBuilder');

#3th party library
use utf8;
use strict;
use warnings;
use Time::localtime;
use Storable qw(dclone);
use List::Util qw(first);

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Stackup::ProcessStackup::Enums';
use aliased 'Packages::CAMJob::Stackup::ProcessStackup::EnumsStyle';
use aliased 'Packages::Other::TableDrawing::Table::Style::TextStyle';
use aliased 'Packages::Other::TableDrawing::Table::Style::Color';
use aliased 'Packages::Other::TableDrawing::Table::Style::BackgStyle';
use aliased 'Packages::Other::TableDrawing::Table::Style::BorderStyle';
use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';
use aliased 'Packages::CAMJob::Stackup::ProcessStackup::BoxBuilders::BuilderMainHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"builderHelper"} = BuilderMainHelper->new( $self->{"table"} );

	return $self;
}

sub Build {
	my $self = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $tbl         = $self->{"table"};
	my $stackupMngr = $self->{"stackupMngr"};
	my $lam         = $self->{"lamination"};

	# 1) Define columns
	$tbl->AddColDef( "leftMargin",        EnumsStyle->BoxMainClmnWidth_MARGIN );
	$tbl->AddColDef( "leftOverlapPad",    EnumsStyle->BoxMainClmnWidth_PADOVRLP );
	$tbl->AddColDef( "leftOverlapMat",    EnumsStyle->BoxMainClmnWidth_STCKOVRLP );
	$tbl->AddColDef( "leftOverlapMatIn",  EnumsStyle->BoxMainClmnWidth_STCKOVRLPIN );
	$tbl->AddColDef( "matType",           EnumsStyle->BoxMainClmnWidth_TYPE );
	$tbl->AddColDef( "matId",             EnumsStyle->BoxMainClmnWidth_ID );
	$tbl->AddColDef( "rightOverlapMatIn", EnumsStyle->BoxMainClmnWidth_STCKOVRLP );
	$tbl->AddColDef( "rightOverlapMat",   EnumsStyle->BoxMainClmnWidth_STCKOVRLPIN );
	$tbl->AddColDef( "rightOverlapPad",   EnumsStyle->BoxMainClmnWidth_PADOVRLP );
	$tbl->AddColDef( "middleMargin",      EnumsStyle->BoxMainClmnWidth_MARGIN );
	$tbl->AddColDef( "matKind",           EnumsStyle->BoxMainClmnWidth_KIND );
	$tbl->AddColDef( "matName",           EnumsStyle->BoxMainClmnWidth_NAME );
	$tbl->AddColDef( "matThick",          EnumsStyle->BoxMainClmnWidth_THICK );
	$tbl->AddColDef( "rightMargin",       EnumsStyle->BoxMainClmnWidth_MARGIN );

	# 2) Build title row
	$self->__BuildStckpTitle();

	$self->__BuildStckpBody();

 

}

sub __BuildStckpTitle {
	my $self = shift;

	my $tbl = $self->{"table"};

	# Define border style for all tables
	my $borderStyle = BorderStyle->new();
	$borderStyle->AddEdgeStyle( "left",  TblDrawEnums->EdgeStyle_SOLIDSTROKE, EnumsStyle->Border_THICK, Color->new( EnumsStyle->Clr_BOXBORDER ) );
	
	my $borderRowStyle = BorderStyle->new();
	$borderRowStyle->AddEdgeStyle( "bot",  TblDrawEnums->EdgeStyle_SOLIDSTROKE, EnumsStyle->Border_THICK, Color->new( EnumsStyle->Clr_BOXBORDER ) );
 

	# 2) Define ROWS
	#my $BACKtmp = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new("255, 100, 50") );
	my $BACKtmp = undef;
	$tbl->AddRowDef( "titleBody", EnumsStyle->BoxMainRowHeight_TITLE, $BACKtmp, $borderRowStyle );

	# 3) Define cells

	my $txtStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
								   EnumsStyle->TxtSize_NORMAL,
								   Color->new( 0, 0, 0 ),
								   TblDrawEnums->Font_NORMAL, undef,
								   TblDrawEnums->TextHAlign_LEFT,
								   TblDrawEnums->TextVAlign_CENTER, 1 );

	# Mat type
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("matType") ), 0, undef, undef, "TYP", $txtStyle );

	# Mat ID
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("matId") ), 0, undef, undef, "ID", $txtStyle, undef, $borderStyle );

	# Mat Kind
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("matKind") ), 0, undef, undef, "DRUH", $txtStyle, undef, $borderStyle );

	# Mat Name
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("matName") ), 0, undef, undef, "NÁZEV", $txtStyle, undef, $borderStyle );

	# Mat Thickness
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("matThick") ), 0, undef, undef, "[µm]", $txtStyle, undef, $borderStyle );
}

sub __BuildStckpBody {
	my $self = shift;

	my $tbl = $self->{"table"};
	my $lam = $self->{"lamination"};

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 2) Define styles
	my $txtStckpStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
										EnumsStyle->TxtSize_NORMAL,
										Color->new( 255, 255, 255 ),
										undef, undef,
										TblDrawEnums->TextHAlign_LEFT,
										TblDrawEnums->TextVAlign_CENTER, 0.5 );
	my $txtStdStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
									  EnumsStyle->TxtSize_NORMAL,
									  Color->new( 0, 0, 0 ),
									  undef, undef,
									  TblDrawEnums->TextHAlign_LEFT,
									  TblDrawEnums->TextVAlign_CENTER, 0.5 );
	my $txtStdBoldStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
										  EnumsStyle->TxtSize_NORMAL,
										  Color->new( 0, 0, 0 ),
										  TblDrawEnums->Font_BOLD, undef,
										  TblDrawEnums->TextHAlign_LEFT,
										  TblDrawEnums->TextVAlign_CENTER, 0.5 );

	my $borderStyle = BorderStyle->new();
	$borderStyle->AddEdgeStyle( "bot", TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.3, Color->new( EnumsStyle->Clr_BOXBORDERLIGHT ) );

	# 1) Add title TOP GAP
	$tbl->AddRowDef( "titleTopGap", EnumsStyle->BoxHFRowHeight_TITLE );

	foreach my $item ( $lam->GetItems() ) {

		my $topItem = $item->GetChildTop();
		my $botItem = $item->GetChildBot();

		if ( defined $topItem ) {
			$self->__DrawItem( $topItem, dclone($txtStckpStyle), dclone($txtStdStyle), dclone($txtStdBoldStyle) );
		}

		$self->__DrawItem( $item, dclone($txtStckpStyle), dclone($txtStdStyle),
						   dclone($txtStdBoldStyle),
						   ( !defined $botItem ? dclone($borderStyle) : undef ) );

		if ( defined $botItem ) {
			$self->__DrawItem( $botItem, dclone($txtStckpStyle), dclone($txtStdStyle), dclone($txtStdBoldStyle), dclone($borderStyle) );
		}

		$tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxMainRowHeight_MATGAP );

	}

	# ) Add title BOT GAP
	$tbl->AddRowDef( "titleBotGap", EnumsStyle->BoxHFRowHeight_TITLE );

}

sub __DrawItem {
	my $self            = shift;
	my $item            = shift;
	my $txtStckpStyle   = shift;
	my $txtStdStyle     = shift;
	my $txtStdBoldStyle = shift;
	my $borderStyle     = shift;

	my $tbl = $self->{"table"};

	my $itemType       = $item->GetItemType();
	my $itemValType    = $item->GetValType();
	my $itemValExtraId = $item->GetValExtraId();
	my $itemValKind    = $item->GetValKind();
	my $itemValText    = $item->GetValText();
	my $itemValThick   = $item->GetValThick();

	# Drawing pads

	if ( $itemType eq Enums->ItemType_PADSTEEL ) {

		my $row = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxMainRowHeight_STEELPADROW );
		$self->{"builderHelper"}->DrawSteelPlate($row);
	}

	if ( $itemType eq Enums->ItemType_PADPAPER ) {

		my $row = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxMainRowHeight_MATROW );
		$self->{"builderHelper"}->DrawPad( $row,          $itemType,      $itemValType, $itemValExtraId,  $itemValText,
										   $itemValThick, $txtStckpStyle, $txtStdStyle, $txtStdBoldStyle, $borderStyle );
	}

	if ( $itemType eq Enums->ItemType_PADRUBBER ) {

		my $row = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxMainRowHeight_MATROW );
		$self->{"builderHelper"}->DrawPad( $row,          $itemType,      $itemValType, $itemValExtraId,  $itemValText,
										   $itemValThick, $txtStckpStyle, $txtStdStyle, $txtStdBoldStyle, $borderStyle );
	}

	if ( $itemType eq Enums->ItemType_PADFILM ) {

		my $row = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxMainRowHeight_MATROW );
		$self->{"builderHelper"}->DrawPad( $row,          $itemType,      $itemValType, $itemValExtraId,  $itemValText,
										   $itemValThick, $txtStckpStyle, $txtStdStyle, $txtStdBoldStyle, $borderStyle );
	}

	if ( $itemType eq Enums->ItemType_PADFILMSHINE ) {

		my $row = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxMainRowHeight_MATROW );
		$self->{"builderHelper"}->DrawPad( $row,          $itemType,      $itemValType, $itemValExtraId,  $itemValText,
										   $itemValThick, $txtStckpStyle, $txtStdStyle, $txtStdBoldStyle, $borderStyle );
	}

	# Drawing stackup material

	if ( $itemType eq Enums->ItemType_MATSTIFFENER ) {

		my $row = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxMainRowHeight_MATROW );
		$self->{"builderHelper"}->DrawMatStiff( $row,           $itemValType, $itemValKind,     $itemValText, $itemValThick,
												$txtStckpStyle, $txtStdStyle, $txtStdBoldStyle, $borderStyle );
	}

	if ( $itemType eq Enums->ItemType_MATADHESIVE ) {

		my $row = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxMainRowHeight_MATROW );
		$self->{"builderHelper"}->DrawMatAdhesive( $row,           $itemValType, $itemValKind,     $itemValText, $itemValThick,
												   $txtStckpStyle, $txtStdStyle, $txtStdBoldStyle, $borderStyle );
	}

	if ( $itemType eq Enums->ItemType_MATPRODUCT ) {

		my $row = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxMainRowHeight_MATROW );
		$self->{"builderHelper"}->DrawMatProduct( $row,          $itemValType,   $itemValExtraId, $itemValKind,     $itemValText,
												  $itemValThick, $txtStckpStyle, $txtStdStyle,    $txtStdBoldStyle, $borderStyle );
	}

}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

