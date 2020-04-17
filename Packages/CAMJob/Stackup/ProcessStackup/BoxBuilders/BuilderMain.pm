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

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Stackup::ProcessStackup::Enums';
use aliased 'Packages::CAMJob::Stackup::ProcessStackup::EnumsStyle';
use aliased 'Packages::Other::TableDrawing::Table::Style::TextStyle';
use aliased 'Packages::Other::TableDrawing::Table::Style::Color';
use aliased 'Packages::Other::TableDrawing::Table::Style::BackgStyle';
use aliased 'Packages::Other::TableDrawing::Table::Style::BorderStyle';
use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';
use aliased 'Packages::CAMJob::Stackup::ProcessStackup::BoxBuilders::BuilderMain::LamSTIFFPRODUCT';

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
	my $self = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $tbl         = $self->{"table"};
	my $stackupMngr = $self->{"stackupMngr"};

	# 1) Define columns
	$tbl->AddColDef( "leftMargin",     EnumsStyle->BoxMainClmnWidth_MARGIN );
	$tbl->AddColDef( "leftOverlap",    EnumsStyle->BoxMainClmnWidth_STCKOVRLP );
	$tbl->AddColDef( "leftOverlapIn",  EnumsStyle->BoxMainClmnWidth_STCKOVRLPIN );
	$tbl->AddColDef( "matType",        EnumsStyle->BoxMainClmnWidth_TYPE );
	$tbl->AddColDef( "matId",          EnumsStyle->BoxMainClmnWidth_ID );
	$tbl->AddColDef( "rightOverlapIn", EnumsStyle->BoxMainClmnWidth_STCKOVRLP );
	$tbl->AddColDef( "rightOverlap",   EnumsStyle->BoxMainClmnWidth_STCKOVRLPIN );
	$tbl->AddColDef( "middleMargin",   EnumsStyle->BoxMainClmnWidth_MARGIN );
	$tbl->AddColDef( "matKind",        EnumsStyle->BoxMainClmnWidth_KIND );
	$tbl->AddColDef( "matName",        EnumsStyle->BoxMainClmnWidth_NAME );
	$tbl->AddColDef( "matThick",       EnumsStyle->BoxMainClmnWidth_THICK );
	$tbl->AddColDef( "rightMargin",    EnumsStyle->BoxMainClmnWidth_MARGIN );

	# 2) Build title row
	$self->__BuildTitle();

	# 2) Build content
	$self->__BuildBody();

	# 3) Add empty space to fill page
	my $minMainBoxH = 220;    # 220mm
	if ( $tbl->GetHeight() < $minMainBoxH ) {
		$tbl->AddRowDef( "emptySpace", (  $minMainBoxH - $tbl->GetHeight()) );
	}

}

sub __BuildTitle {
	my $self = shift;

	my $tbl = $self->{"table"};

	# Define border style for all tables
	my $borderStyle = BorderStyle->new();
	$borderStyle->AddEdgeStyle( "top",   TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.1, Color->new( EnumsStyle->Clr_BOXBORDER ) );
	$borderStyle->AddEdgeStyle( "bot",   TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.1, Color->new( EnumsStyle->Clr_BOXBORDER ) );
	$borderStyle->AddEdgeStyle( "left",  TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.1, Color->new( EnumsStyle->Clr_BOXBORDER ) );
	$borderStyle->AddEdgeStyle( "right", TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.1, Color->new( EnumsStyle->Clr_BOXBORDER ) );

	# 2) Define ROWS
	my $BACKtmp = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new("255, 100, 50") );
	$tbl->AddRowDef( "title", EnumsStyle->BoxMainRowHeight_TITLE, $BACKtmp, $borderStyle );

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

sub __BuildBody {
	my $self = shift;

	my $tbl       = $self->{"table"};
	my $lam       = $self->{"lamination"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $inCAM     = $self->{"inCAM"};
	my $jobId     = $self->{"jobId"};

	my $bodyBldr = undef;

	if ( $lam->GetLamType() eq Enums->LamType_STIFFPRODUCT ) {

		$bodyBldr = LamSTIFFPRODUCT->new( $inCAM, $jobId, $lam, $stckpMngr, $tbl );
	}
	elsif ( $lam->GetLamType() eq Enums->LamType_CVRLBASE ) {

		$bodyBldr = LamSTIFFPRODUCT->new( $inCAM, $jobId, $lam, $stckpMngr, $tbl );
	}
	elsif ( $lam->GetLamType() eq Enums->LamType_CVRLPRODUCT ) {

		$bodyBldr = LamSTIFFPRODUCT->new( $inCAM, $jobId, $lam, $stckpMngr, $tbl );
	}
	elsif ( $lam->GetLamType() eq Enums->LamType_PRPGBASE ) {

		$bodyBldr = LamSTIFFPRODUCT->new( $inCAM, $jobId, $lam, $stckpMngr, $tbl );
	}
	elsif ( $lam->GetLamType() eq Enums->LamType_FLEXPRPGBASE ) {

		$bodyBldr = LamSTIFFPRODUCT->new( $inCAM, $jobId, $lam, $stckpMngr, $tbl );
	}
	elsif ( $lam->GetLamType() eq Enums->LamType_MULTIBASE ) {

		$bodyBldr = LamSTIFFPRODUCT->new( $inCAM, $jobId, $lam, $stckpMngr, $tbl );
	}
	elsif ( $lam->GetLamType() eq Enums->LamType_MULTIPRODUCT ) {

		$bodyBldr = LamSTIFFPRODUCT->new( $inCAM, $jobId, $lam, $stckpMngr, $tbl );
	}

	$tbl->AddRowDef( "topTitleGap", EnumsStyle->BoxMainRowHeight_TITLEGAP );



	# Define styles
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
	 
	$borderStyle->AddEdgeStyle( "bot",   TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.1, Color->new( EnumsStyle->Clr_BOXBORDERLIGHT ) );


	$bodyBldr->Build($txtStckpStyle, $txtStdStyle, $txtStdBoldStyle, $borderStyle);

	$tbl->AddRowDef( "botTitleGap", EnumsStyle->BoxMainRowHeight_TITLEGAP );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
