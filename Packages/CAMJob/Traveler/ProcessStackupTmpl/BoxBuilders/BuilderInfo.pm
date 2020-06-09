#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::ProcessStackupTmpl::BoxBuilders::BuilderInfo;
use base('Packages::CAMJob::Traveler::ProcessStackupTmpl::BoxBuilders::BoxBuilderBase');

use Class::Interface;
&implements('Packages::CAMJob::Traveler::ProcessStackupTmpl::BoxBuilders::IBoxBuilder');

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
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::Enums';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::EnumsStyle';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::TextStyle';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::Color';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::BackgStyle';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::BorderStyle';
use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::BoxBuilders::BuilderMainHelper';

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
	my $stackupMngr = $self->{"stackupMngr"};
	my $lam         = $self->{"lamination"};

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

	$self->__BuildMatInfo( $txtTitStyle, $txtLCollStyle, $txtRCollStyle, $txtLCollBStyle, $borderTitleStyle );
	$tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxHFRowHeight_TITLE );

	$self->__BuildOperInfo( $txtTitStyle, $txtLCollStyle, $txtRCollStyle, $borderTitleStyle );
	$tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxHFRowHeight_TITLE );

	$self->__BuildLamInfo( $txtTitStyle, $txtLCollStyle, $txtRCollStyle, $txtRCollBStyle, $borderTitleStyle );
	$tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxHFRowHeight_TITLE );
	$self->__BuildPaketInfo( $txtTitStyle, $txtLCollStyle, $txtRCollStyle, $txtRCollBStyle, $borderTitleStyle );

	$tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxHFRowHeight_TITLE );

	$self->__BuildNoteInfo( $txtTitStyle, $txtLCollStyle, $txtRCollStyle, $borderTitleStyle );

	# Add special row "extender" which stretch table to bottom edge of page
	if ( $tbl->GetOrigin()->{"y"} + $tbl->GetHeight() < $boxYEndPos ) {

		$tbl->AddRowDef( "expander", ( $boxYEndPos - ( $tbl->GetOrigin()->{"y"} + $tbl->GetHeight() ) ) );
	}

}

sub __BuildMatInfo {
	my $self             = shift;
	my $txtTitStyle      = shift;
	my $txtLCollStyle    = shift;
	my $txtRCollStyle    = shift;
	my $txtLCollBStyle   = shift;
	my $borderTitleStyle = shift;

	my $tbl       = $self->{"table"};
	my $stckpMngr = $self->{"stackupMngr"};

	# 1) Define title cell

	#my $BACKtmp = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new("255, 100, 50") );
	my $BACKtmp = undef;
	my $rowTit = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxMainRowHeight_TITLE, $BACKtmp, $borderTitleStyle );
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ), $tbl->GetRowCnt() - 1, undef, undef, "Info zakázka", $txtTitStyle );

	$tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxHFRowHeight_TITLE );

	# DPS type
	my $rowPCBType = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->RowHeight_STD );

	my $pcbType = $stckpMngr->GetISPcbType();
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ),  $tbl->GetRowCnt() - 1, undef, undef, "Typ desky:", $txtLCollStyle );
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("rightCol") ), $tbl->GetRowCnt() - 1, undef, undef, $pcbType,     $txtRCollStyle );

	# Layer count
	my $rowCuCnt = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->RowHeight_STD );

	my $cuStr = $stckpMngr->GetCuLayerCnt();
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ),  $tbl->GetRowCnt() - 1, undef, undef, "Počet vrstev:", $txtLCollStyle );
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("rightCol") ), $tbl->GetRowCnt() - 1, undef, undef, $cuStr,           $txtRCollStyle );

	# Kinds
	my @mats = $stckpMngr->GetBaseMaterialInfo();

	for ( my $i = 0 ; $i < scalar(@mats) ; $i++ ) {

		my $row = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->RowHeight_STD, undef );

		if ( $i == 0 ) {
			$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ), $tbl->GetRowCnt() - 1, undef, undef, "Mat. druh:", $txtLCollStyle );
		}

		my $matStr = $mats[$i]->{"kind"};
		$matStr .= " (" . $mats[$i]->{"tg"} . "°)" if ( defined $mats[$i]->{"tg"} );

		$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("rightCol") ), $tbl->GetRowCnt() - 1, undef, undef, $matStr, $txtRCollStyle );
	}

	# Dimension
	my $rowDim = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->RowHeight_STD );

	my ( $w, $h ) = $stckpMngr->GetPanelSize();
	my $dimStr = int($w) . " x " . int($h) . "mm";
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ),  $tbl->GetRowCnt() - 1, undef, undef, "Rozměr:", $txtLCollStyle );
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("rightCol") ), $tbl->GetRowCnt() - 1, undef, undef, $dimStr,    $txtRCollStyle );

	# Panle amount
	my $rowAmount = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->RowHeight_STD );

	my $amountStr = Enums->KEYORDEAMOUNT;
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ), $tbl->GetRowCnt() - 1, undef, undef, "Počet přířezů:", $txtLCollStyle );
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("rightCol") ), $tbl->GetRowCnt() - 1, undef, undef, $amountStr, $txtRCollStyle );

	# Panle amount extra
	my $rowAmountExt = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->RowHeight_STD );

	my $amountExtraStr = Enums->KEYORDEAMOUNTEXT;
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ), $tbl->GetRowCnt() - 1, undef, undef, "Přířezů navíc:", $txtLCollStyle );
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("rightCol") ), $tbl->GetRowCnt() - 1, undef, undef, $amountExtraStr, $txtRCollStyle );

	# Put info about dodelavka
	$tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->RowHeight_STD );

	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ), $tbl->GetRowCnt() - 1, undef, undef, Enums->KEYEXTRAPRODUC,
				   $txtLCollBStyle );
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("rightCol") ),
				   $tbl->GetRowCnt() - 1,
				   undef, undef, Enums->KEYEXTRAPRODUCVAL, $txtRCollStyle );

}

sub __BuildPaketInfo {
	my $self             = shift;
	my $txtTitStyle      = shift;
	my $txtLCollStyle    = shift;
	my $txtRCollStyle    = shift;
	my $txtRCollBStyle   = shift;
	my $borderTitleStyle = shift;

	my $tbl       = $self->{"table"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $lam       = $self->{"lamination"};

	# 1) Define title cell

	#my $BACKtmp = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new("255, 100, 50") );
	my $BACKtmp = undef;
	my $rowTit = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxMainRowHeight_TITLE, $BACKtmp, $borderTitleStyle );
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ), $tbl->GetRowCnt() - 1, undef, undef, "Paketování", $txtTitStyle );

	$tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxHFRowHeight_TITLE );

	# Mat thickness
	my $rowThick1   = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->RowHeight_STD );
	my $matThick    = $lam->GetPaketThick(0);
	my $matThickStr = sprintf( "%.2fmm", $matThick / 1000 );
	$matThickStr =~ s/\./,/g;

	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ),  $tbl->GetRowCnt() - 1, undef, undef, "Tl. materiál:", $txtLCollStyle );
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("rightCol") ), $tbl->GetRowCnt() - 1, undef, undef, $matThickStr,     $txtRCollStyle );

	# Mat thickness total
	my $rowThick2     = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->RowHeight_STD );
	my $paketThick    = $lam->GetPaketThick(1);
	my $paketThickStr = sprintf( "%.2fmm", $paketThick / 1000 );
	$paketThickStr =~ s/\./,/g;

	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ),  $tbl->GetRowCnt() - 1, undef, undef, "Vč. podložek:", $txtLCollStyle );
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("rightCol") ), $tbl->GetRowCnt() - 1, undef, undef, $paketThickStr,    $txtRCollBStyle );

	$tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxHFRowHeight_TITLE );

	# Amount per press paket
	use constant PAKETHEIGHT  => 20000;    # paket height for pressing 20mm
	use constant INSTEELPLATE => 1000;     # one outer steel plate has 1mm thickness

	my $availableH = PAKETHEIGHT - INSTEELPLATE;    # one extra bottom steel plate

	my @outerPads = $lam->GetOuterPresspads();      # outer pads (top/bot), which are outer of inner steel plates
	if ( scalar(@outerPads) ) {

		my $padsT = 0;
		$padsT += $_->GetValThick() foreach @outerPads;
		$availableH -= $padsT;
	}

	my $amount = $availableH / ( $paketThick + INSTEELPLATE );
	my $amountStr = floor($amount) . "př (" . ( 2 * floor($amount) ) . "př)";
	$amountStr =~ s/\./,/g;
	my $rowAmount = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->RowHeight_STD );

	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ), $tbl->GetRowCnt() - 1, undef, undef, "Přířezů/plotnu:", $txtLCollStyle );
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("rightCol") ), $tbl->GetRowCnt() - 1, undef, undef, $amountStr, $txtRCollStyle );

	# Amount of final packages per whole order

	my $rowFinPackg = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->RowHeight_STD );
	my $totalPackgStr = Enums->KEYTOTALPACKG . "($amount)";
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ),  $tbl->GetRowCnt() - 1, undef, undef, "Plotny/zakázku:", $txtLCollStyle );
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("rightCol") ), $tbl->GetRowCnt() - 1, undef, undef, $totalPackgStr,     $txtRCollStyle );

	# Pins yes or no

	my $rowPins = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->RowHeight_STD );

	my $lamType = $lam->GetLamType();
	my $pinStr  = "Ne";

	if (
		    $lamType eq Enums->LamType_FLEXBASE
		 || $lamType eq Enums->LamType_ORIGIDFLEXFINAL
		 || $lamType eq Enums->LamType_IRIGIDFLEXFINAL
		 || ( $lamType eq Enums->LamType_RIGIDFINAL && $stckpMngr->GetCuLayerCnt() >= 6 )
		 || (    $lamType eq Enums->LamType_RIGIDFINAL
			  && $stckpMngr->GetStackup()->GetCuLayerCnt() >= 4
			  && $stckpMngr->GetStackup()->GetAllCores() > 1 )
	  )
	{
		$pinStr = "Ano";
	}

	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ),  $tbl->GetRowCnt() - 1, undef, undef, "Piny:", $txtLCollStyle );
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("rightCol") ), $tbl->GetRowCnt() - 1, undef, undef, $pinStr, $txtRCollStyle );

}

sub __BuildOperInfo {
	my $self             = shift;
	my $txtTitStyle      = shift;
	my $txtLCollStyle    = shift;
	my $txtRCollStyle    = shift;
	my $borderTitleStyle = shift;

	my $tbl       = $self->{"table"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $lam       = $self->{"lamination"};

	# 1) Define title cell

	#my $BACKtmp = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new("255, 100, 50") );
	my $BACKtmp = undef;
	my $rowTit = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxMainRowHeight_TITLE, $BACKtmp, $borderTitleStyle );
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ), $tbl->GetRowCnt() - 1, undef, undef, "Operace na postupu", $txtTitStyle );

	$tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxHFRowHeight_TITLE );

	my @allLam = $stckpMngr->GetAllLamination();

	for ( my $i = 0 ; $i < scalar(@allLam) ; $i++ ) {

		my $curLam = $allLam[$i];

		$tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxMainRowHeight_TITLE );

		my $txtStyle = $txtRCollStyle;
		if ( $curLam->GetLamOrder() eq $lam->GetLamOrder() ) {

			$txtStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
										EnumsStyle->TxtSize_NORMAL,
										Color->new( 0, 0, 0 ),
										TblDrawEnums->Font_BOLD, undef,
										TblDrawEnums->TextHAlign_LEFT,
										TblDrawEnums->TextVAlign_CENTER, 1 );
		}

		my $textStr = ( $i + 1 ) . ". " . EnumsStyle->GetLamTitle( $curLam->GetLamType() );
		$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ), $tbl->GetRowCnt() - 1, undef, undef, $textStr, $txtStyle );
	}

	# 2) Define operation order

	$tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxHFRowHeight_TITLE );

	$tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->RowHeight_STD );
	my $strOrder = ( $lam->GetLamOrder() + 1 ) . "/" . scalar(@allLam);
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ),  $tbl->GetRowCnt() - 1, undef, undef, "Lisování:", $txtLCollStyle );
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("rightCol") ), $tbl->GetRowCnt() - 1, undef, undef, $strOrder,     $txtRCollStyle );

	# 3) Define semi product, created bz pressing

	#$tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxHFRowHeight_TITLE );

	my $rowProduc = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->RowHeight_STD );

	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ),  $tbl->GetRowCnt() - 1, undef, undef, "Polotovar:",         $txtLCollStyle );
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("rightCol") ), $tbl->GetRowCnt() - 1, undef, undef, $lam->GetProductId(), $txtRCollStyle );

}

sub __BuildLamInfo {
	my $self             = shift;
	my $txtTitStyle      = shift;
	my $txtLCollStyle    = shift;
	my $txtRCollStyle    = shift;
	my $txtRCollBStyle   = shift;
	my $borderTitleStyle = shift;

	my $tbl       = $self->{"table"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $lam       = $self->{"lamination"};

	# 1) Define title cell

	#my $BACKtmp = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new("255, 100, 50") );
	my $BACKtmp = undef;
	my $rowTit = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxMainRowHeight_TITLE, $BACKtmp, $borderTitleStyle );
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ), $tbl->GetRowCnt() - 1, undef, undef, "Lisovací program", $txtTitStyle );

	$tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxHFRowHeight_TITLE );

	my %pInfo = $stckpMngr->GetPressProgramInfo( $lam->GetLamType(), $lam->GetLamData() );

	# Program name
	if ( defined $pInfo{"name"} ) {
		$tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->RowHeight_STD );

		$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ), $tbl->GetRowCnt() - 1, undef, undef, $pInfo{"name"}, $txtRCollBStyle );

	}

	# Program dimension
	if ( defined $pInfo{"dimX"} && defined $pInfo{"dimY"} ) {

		$tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->RowHeight_STD );

		my $dimStr = int( $pInfo{"dimX"} ) . " x " . int( $pInfo{"dimY"} ) . "mm";
		$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ),  $tbl->GetRowCnt() - 1, undef, undef, "Rozměry:", $txtLCollStyle );
		$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("rightCol") ), $tbl->GetRowCnt() - 1, undef, undef, $dimStr,     $txtRCollStyle );
	}
}

sub __BuildNoteInfo {
	my $self             = shift;
	my $txtTitStyle      = shift;
	my $txtLCollStyle    = shift;
	my $txtRCollStyle    = shift;
	my $borderTitleStyle = shift;

	my $tbl       = $self->{"table"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $lam       = $self->{"lamination"};

	# 1) Define title cell

	#my $BACKtmp = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new("255, 100, 50") );
	my $BACKtmp = undef;
	my $rowTit = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxMainRowHeight_TITLE, $BACKtmp, $borderTitleStyle );
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ), $tbl->GetRowCnt() - 1, undef, undef, "Poznámka TPV", $txtTitStyle );

	# Put note about noflow prepreg
	my @noflow = map { $_->GetValExtraId() } grep { $_->GetItemType() eq Enums->ItemType_MATFLEXPREPREG } $lam->GetItems();
	
	if ( scalar( uniq(@noflow) ) ) {

		$tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxHFRowHeight_TITLE );

		$tbl->AddRowDef( $tbl->GetRowCnt(), 5 * EnumsStyle->RowHeight_STD );

		my $txtStyle = TextStyle->new( TblDrawEnums->TextStyle_PARAGRAPH,
									   EnumsStyle->TxtSize_NORMAL,
									   Color->new( 0, 0, 0 ),
									   TblDrawEnums->Font_NORMAL, undef,
									   TblDrawEnums->TextHAlign_LEFT,
									   TblDrawEnums->TextVAlign_CENTER, 1 );

		my $str = "Pozor na správný výběr NoFlow prepregů dle složení ";
		$str .= "(ID: " . join( " vs ", @noflow ) . ")";

		$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ), $tbl->GetRowCnt() - 1, 2, undef, $str, $txtStyle );
	}


	# Put info about program settings
 
	if ($stckpMngr->GetIsFlex() ) {

		$tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxHFRowHeight_TITLE );

		$tbl->AddRowDef( $tbl->GetRowCnt(), 5 * EnumsStyle->RowHeight_STD );

		my $txtStyle = TextStyle->new( TblDrawEnums->TextStyle_PARAGRAPH,
									   EnumsStyle->TxtSize_NORMAL,
									   Color->new( 255, 0, 0 ),
									   TblDrawEnums->Font_NORMAL, undef,
									   TblDrawEnums->TextHAlign_LEFT,
									   TblDrawEnums->TextVAlign_CENTER, 1 );

		my $str = "Pozor, nezapomen, vyplnit: pocet pater + pocet paketu na plotne:\n\n";
		 $str .= " - Quant. of act. openings\n";
		 $str .= " - Amount of press package\n";
 
		$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ), $tbl->GetRowCnt() - 1, 2, undef, $str, $txtStyle );
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
