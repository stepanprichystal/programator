#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::ProcessStackupTmpl::BoxBuilders::BuilderMatList;
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
	my $self      = shift;
	my $boxEndPos = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $tbl         = $self->{"table"};
	my $stackupMngr = $self->{"stackupMngr"};
	my $lam         = $self->{"lamination"};

	# 1) Define columns
	$tbl->AddColDef( "leftMargin",  EnumsStyle->BoxMainClmnWidth_MARGIN );
	$tbl->AddColDef( "matType",     EnumsStyle->BoxMatListClmnWidth_TYPE );
	$tbl->AddColDef( "matRef",      EnumsStyle->BoxMatListClmnWidth_REF );
	$tbl->AddColDef( "matName",     EnumsStyle->BoxMatListClmnWidth_NAME );
	$tbl->AddColDef( "matKind",     EnumsStyle->BoxMatListClmnWidth_KIND );
	$tbl->AddColDef( "matCount",    EnumsStyle->BoxMatListClmnWidth_COUNT );
	$tbl->AddColDef( "rightMargin", EnumsStyle->BoxMainClmnWidth_MARGIN );

	$self->__BuildMatListTitle();

	$self->__BuildMatListBody();

	# Add special row "extender" which stretch table to bottom edge of page
	if ( $tbl->GetOrigin()->{"y"} + $tbl->GetHeight() < $boxEndPos ) {

		$tbl->AddRowDef( "expander", ( $boxEndPos - ( $tbl->GetOrigin()->{"y"} + $tbl->GetHeight() ) ) );
	}

}

sub __BuildMatListTitle {
	my $self = shift;

	my $tbl = $self->{"table"};

	# Define border style for all tables
	my $borderRowStyle = BorderStyle->new();
	$borderRowStyle->AddEdgeStyle( "top",   TblDrawEnums->EdgeStyle_SOLIDSTROKE, EnumsStyle->Border_THICK, Color->new( EnumsStyle->Clr_BOXBORDER ) );
	$borderRowStyle->AddEdgeStyle( "bot",   TblDrawEnums->EdgeStyle_SOLIDSTROKE, EnumsStyle->Border_THICK, Color->new( EnumsStyle->Clr_BOXBORDER ) );
	$borderRowStyle->AddEdgeStyle( "left",  TblDrawEnums->EdgeStyle_SOLIDSTROKE, EnumsStyle->Border_THICK, Color->new( EnumsStyle->Clr_BOXBORDER ) );
	$borderRowStyle->AddEdgeStyle( "right", TblDrawEnums->EdgeStyle_SOLIDSTROKE, EnumsStyle->Border_THICK, Color->new( EnumsStyle->Clr_BOXBORDER ) );

	my $borderCellStyle = BorderStyle->new();
	$borderCellStyle->AddEdgeStyle( "left", TblDrawEnums->EdgeStyle_SOLIDSTROKE, EnumsStyle->Border_THICK, Color->new( EnumsStyle->Clr_BOXBORDER ) );

	# 2) Define ROWS
	#my $BACKtmp = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new("255, 100, 50") );
	my $BACKtmp = undef;
	my $row     = $tbl->AddRowDef( "titleAmounts", EnumsStyle->BoxMainRowHeight_TITLE, $BACKtmp, $borderRowStyle );
	my $rowPos  = $tbl->GetRowDefPos($row);

	# 3) Define cells

	my $txtStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
								   EnumsStyle->TxtSize_NORMAL,
								   Color->new( 0, 0, 0 ),
								   TblDrawEnums->Font_BOLD, undef,
								   TblDrawEnums->TextHAlign_LEFT,
								   TblDrawEnums->TextVAlign_CENTER, 1 );

	# Mat type
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("matType") ), $rowPos, undef, undef, "Typ", $txtStyle );

	# Mat IS number
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("matRef") ), $rowPos, undef, undef, "Sklad", $txtStyle, undef, $borderCellStyle );

	# Mat KIND
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("matKind") ), $rowPos, undef, undef, "Druh", $txtStyle, undef, $borderCellStyle );

	# Mat Name
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("matName") ), $rowPos, undef, undef, "Název", $txtStyle, undef, $borderCellStyle );

	# Mat aMOUNTS
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("matCount") ), $rowPos, undef, undef, "[ks]", $txtStyle, undef, $borderCellStyle );
}

sub __BuildMatListBody {
	my $self = shift;

	my $tbl = $self->{"table"};
	my $lam = $self->{"lamination"};

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 2) Define styles

	my $txtStdStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
									  EnumsStyle->TxtSize_NORMAL,
									  Color->new( 0, 0, 0 ),
									  undef, undef,
									  TblDrawEnums->TextHAlign_LEFT,
									  TblDrawEnums->TextVAlign_CENTER, 0.5 );

	my $borderStyle = BorderStyle->new();
	$borderStyle->AddEdgeStyle( "bot", TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.3, Color->new( EnumsStyle->Clr_BOXBORDERLIGHT ) );

	# 1) Add title TOP GAP
	$tbl->AddRowDef( "titleMatListTopGap", EnumsStyle->BoxHFRowHeight_TITLE );

	# 2) Add material amounts

	my @items = $lam->GetItems();

	# Do not consider outer robber pads
	if ( scalar( $lam->GetOuterPresspads() ) ) {

		if ( $items[0]->GetIsPad() && $items[0]->GetItemType() ne Enums->ItemType_PADSTEEL ) {
			splice @items, 0, 1;
		}

		if ( $items[-1]->GetIsPad() && $items[-1]->GetItemType() ne Enums->ItemType_PADSTEEL ) {
			splice @items, -1, 1;
		}
	}

	# sort pads first
	my @pads      = grep { $_->GetIsPad() } @items;
	my @mats      = grep { !$_->GetIsPad() } @items;
	my @matsChild = grep { defined $_ } map { ( $_->GetChildTop(), $_->GetChildBot() ) } @items;

	@items = ( @pads, @mats, @matsChild );

	# get inique materials (pads first)
	@items = grep {
		     $_->GetItemType() ne Enums->ItemType_PADSTEEL
		  && $_->GetItemType() ne Enums->ItemType_PADFILMGLOSS
		  && $_->GetItemType() ne Enums->ItemType_MATPRODUCTDPS
		  && $_->GetItemType() ne Enums->ItemType_MATCORE
		  && $_->GetItemType() ne Enums->ItemType_MATFLEXCORE
		  && $_->GetItemType() ne Enums->ItemType_MATCUCORE
		  && $_->GetItemType() ne Enums->ItemType_MATCVRLADHESIVE
		  && $_->GetItemType() ne Enums->ItemType_MATPRODUCTDPS
		  && $_->GetItemType() ne Enums->ItemType_MATPRODUCTCORE
		  && $_->GetItemType() ne Enums->ItemType_PADFILMGLOSS
		  && $_->GetItemType() ne Enums->ItemType_PADFILMMATT

	} @items;

	my @uniqItems = do {
		my %seen;
		grep { !$seen{ $_->GetItemId() }++ } @items;
	};

	foreach my $item (@uniqItems) {

		my $row = $tbl->AddRowDef( $tbl->GetRowCnt(), EnumsStyle->BoxMainRowHeight_MATROW );

		# Mat type
		$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("matType") ),
					   $tbl->GetRowDefPos($row),
					   undef, undef, $item->GetValType(), $txtStdStyle, undef, $borderStyle );

		# Mat IS ref
		my $itemId = $item->GetItemId();
		$itemId = "-" if ( $itemId !~ /\d{10}/ );

		$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("matRef") ),
					   $tbl->GetRowDefPos($row),
					   undef, undef, $itemId, $txtStdStyle, undef, $borderStyle );

		# Mat Kind
		my $kindStr = $item->GetValKind();
		$kindStr = "" if ( !defined $kindStr );    # draw border
		$kindStr =~ s/\s*//g;
		$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("matKind") ),
					   $tbl->GetRowDefPos($row),
					   undef, undef, $kindStr, $txtStdStyle, undef, $borderStyle );

		# Mat Text
		my $valStr = $item->GetValText();
		$valStr = "" if ( !defined $valStr );      # draw border
		$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("matName") ),
					   $tbl->GetRowDefPos($row),
					   undef, undef, substr( $item->GetValText(), 0, 25 ),
					   $txtStdStyle, undef, $borderStyle );

		# Mat count
		my $cnt = scalar( grep { $_->GetItemId() eq $item->GetItemId() } @items );

		my $strCnt = Enums->KEYORDEAMOUNTTOT . "($cnt)";
		$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("matCount") ),
					   $tbl->GetRowDefPos($row),
					   undef, undef, $strCnt, $txtStdStyle, undef, $borderStyle );

	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

