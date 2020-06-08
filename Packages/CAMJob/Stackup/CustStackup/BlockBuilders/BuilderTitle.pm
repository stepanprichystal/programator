
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb no copper
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::BlockBuilders::BuilderTitle;
use base('Packages::CAMJob::Stackup::CustStackup::BlockBuilders::BlockBuilderBase');

use Class::Interface;
&implements('Packages::CAMJob::Stackup::CustStackup::BlockBuilders::IBlockBuilder');

#3th party library
use strict;
use warnings;
use Time::localtime;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Stackup::CustStackup::Enums';
use aliased 'Packages::CAMJob::Stackup::CustStackup::EnumsStyle';
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
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	$self->__BuildRow1();

	$self->__BuildRow2();
}

sub __BuildRow1 {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# Define first title row
	
	my $borderStyle = BorderStyle->new();
	$borderStyle->AddEdgeStyle( "top",   TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.2, Color->new( EnumsStyle->Clr_TITLEBACKG ) );
	$borderStyle->AddEdgeStyle( "bot",   TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.2, Color->new( EnumsStyle->Clr_TITLEBACKG ) );
	$borderStyle->AddEdgeStyle( "left",  TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.2, Color->new( EnumsStyle->Clr_TITLEBACKG ) );
	$borderStyle->AddEdgeStyle( "right", TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.2, Color->new( EnumsStyle->Clr_TITLEBACKG ) );
	my $rowTitleBackg = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_TITLEBACKG ) );
	$tblMain->AddRowDef( "row_title", EnumsStyle->RowHeight_TITLE, $rowTitleBackg, $borderStyle );

	# Add title
	my $titleStr = "Type: ";

	my $pcbType = $stckpMngr->GetPcbType();

	if ( $pcbType eq EnumsGeneral->PcbType_NOCOPPER ) {
		$titleStr .= "No copper PCB";
	}

	if ( $pcbType eq EnumsGeneral->PcbType_1V ) {
		$titleStr .= "One sided PCB";
	}

	if ( $pcbType eq EnumsGeneral->PcbType_2V ) {
		$titleStr .= "Double sided PCB";
	}

	if ( $pcbType eq EnumsGeneral->PcbType_1VFLEX ) {
		$titleStr .= "One sided flex";
	}

	if ( $pcbType eq EnumsGeneral->PcbType_2VFLEX ) {
		$titleStr .= "Double sided flex";
	}

	if ( $pcbType eq EnumsGeneral->PcbType_MULTIFLEX ) {
		$titleStr .= "Multilayer flex";
	}

	if ( $pcbType eq EnumsGeneral->PcbType_MULTI ) {
		$titleStr .= "Multi layer PCB";
	}

	if ( $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXO ) {
		$titleStr .= "Outer RigidFlex";
	}

	if ( $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXI ) {
		$titleStr .= "Inner RigidFlex";
	}

	# Add flex type
	if($stckpMngr->GetIsFlex()){
		$titleStr .= " (".$stckpMngr->GetFlexPCBCode().")";
	}


	# Add job Id

	$titleStr .= "; Id: " . uc($jobId);

	# CELL DEF: Add left cell with title

	my $c1TxtStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
									 EnumsStyle->TxtSize_TITLE, Color->new( 255, 255, 255 ),
									 TblDrawEnums->Font_NORMAL, undef,
									 TblDrawEnums->TextHAlign_LEFT,
									 TblDrawEnums->TextVAlign_CENTER, 1 );

	my $secBegin = $secMngr->GetSection( Enums->Sec_BEGIN );

	$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "leftMargin" ), 0, $secBegin->GetColumnCnt() + 1, undef, $titleStr, $c1TxtStyle );

	# CELL DEF: Add right cell with date

	my $c2TxtStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
									 EnumsStyle->TxtSize_TITLE, Color->new( 255, 255, 255 ),
									 TblDrawEnums->Font_NORMAL, undef,
									 TblDrawEnums->TextHAlign_RIGHT,
									 TblDrawEnums->TextVAlign_CENTER, 1 );

	my $c2xStart = $secBegin->GetColumnCnt() + 1;
	my $c2xpos   = $secMngr->GetColumnCnt(1) - $c2xStart;

	my $date = sprintf "%02.f.%02.f.%04.f", localtime->mday(), ( localtime->mon() + 1 ), ( localtime->year() + 1900 );
	my $c2Str = "Date: " . $date;

	$tblMain->AddCell( $c2xStart, 0, $c2xpos, undef, $c2Str, $c2TxtStyle );

}

sub __BuildRow2 {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	my @secLetters = ( 'A', 'B', 'C', 'D', 'E', 'F' );

	my $pcbType = $stckpMngr->GetPcbType();

	# Define first title row

	my $rowStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( 191, 191, 191 ) );
	my $row = $tblMain->AddRowDef( "row_main_head", EnumsStyle->RowHeight_TITLE, $rowStyle );

	my $txtStyleTitle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
										EnumsStyle->TxtSize_MAINHEAD,
										Color->new( 0, 0, 0 ),
										TblDrawEnums->Font_BOLD, undef,
										TblDrawEnums->TextHAlign_LEFT,
										TblDrawEnums->TextVAlign_CENTER, 0.5 );

	my $txtStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
								   EnumsStyle->TxtSize_MAINHEAD,
								   Color->new( 0, 0, 0 ),
								   TblDrawEnums->Font_BOLD, undef,
								   TblDrawEnums->TextHAlign_CENTER,
								   TblDrawEnums->TextVAlign_CENTER, 0.5 );

	my $borderStyle = $self->{"secBorderStyle"};

	# Sec_BEGIN
	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );

	if ( $sec_BEGIN->GetIsActive() ) {

		my $tg = $stckpMngr->GetTG();

		my $txt = $stckpMngr->GetLayerCnt() . " layer stackup" . ( defined $tg ? "; Tg $tg°" : "" );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ), $tblMain->GetRowDefPos($row), undef, undef, $txt, $txtStyleTitle );
	}

	# Sec_A_MAIN
	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );

	if ( $sec_A_MAIN->GetIsActive() ) {

		my $txt = "SECTION ";
		if (    $pcbType eq EnumsGeneral->PcbType_1VFLEX
			 || $pcbType eq EnumsGeneral->PcbType_2VFLEX
			 || $pcbType eq EnumsGeneral->PcbType_MULTIFLEX )
		{

			$txt .= "FLEX";
		}
		else {
			$txt .= "RIGID";
		}
		$txt .= " (" . ( shift @secLetters ) . ")";

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "leftEdge" ),
						   $tblMain->GetRowDefPos($row),
						   $sec_A_MAIN->GetColumnCnt(),
						   undef, $txt, $txtStyle, undef, $borderStyle );

	}

	# Sec_B_FLEX
	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );

	if ( $sec_B_FLEX->GetIsActive() ) {

		my $txt = "SECTION FLEX (" . ( shift @secLetters ) . ")";

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matType" ),
						   $tblMain->GetRowDefPos($row),
						   $sec_B_FLEX->GetColumnCnt(),
						   undef, $txt, $txtStyle, undef, $borderStyle );

	}

	# Sec_C_RIGIDFLEX
	my $sec_C_RIGIDFLEX = $secMngr->GetSection( Enums->Sec_C_RIGIDFLEX );

	if ( $sec_C_RIGIDFLEX->GetIsActive() ) {

		my $txt = "SECTION RIGID (" . ( shift @secLetters ) . ")";

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_C_RIGIDFLEX, "leftEdge" ),
						   $tblMain->GetRowDefPos($row),
						   $sec_C_RIGIDFLEX->GetColumnCnt(),
						   undef, $txt, $txtStyle, undef, $borderStyle );

	}

	# Sec_D_FLEXTAIL
	my $sec_D_FLEXTAIL = $secMngr->GetSection( Enums->Sec_D_FLEXTAIL );

	if ( $sec_D_FLEXTAIL->GetIsActive() ) {

		my $txt = "SECTION FLEXTAIL (" . ( shift @secLetters ) . ")";

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matType" ),
						   $tblMain->GetRowDefPos($row),
						   $sec_D_FLEXTAIL->GetColumnCnt(),
						   undef, $txt, $txtStyle, undef, $borderStyle );

	}

	# Sec_E_STIFFENER
	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );

	if ( $sec_E_STIFFENER->GetIsActive() ) {

		my $txt = "SECTION STIFFENER (" . ( shift @secLetters ) . ")";

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matType" ),
						   $tblMain->GetRowDefPos($row),
						   $sec_E_STIFFENER->GetColumnCnt(),
						   undef, $txt, $txtStyle, undef, $borderStyle );

	}
	
	# Sec_F_STIFFENER
	my $sec_F_STIFFENER = $secMngr->GetSection( Enums->Sec_F_STIFFENER );

	if ( $sec_F_STIFFENER->GetIsActive() ) {

		my $txt = "SECTION STIFFENER (" . ( shift @secLetters ) . ")";

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_F_STIFFENER, "matType" ),
						   $tblMain->GetRowDefPos($row),
						   $sec_F_STIFFENER->GetColumnCnt(),
						   undef, $txt, $txtStyle, undef, $borderStyle );

	}

	# Sec_END
	my $sec_END = $secMngr->GetSection( Enums->Sec_END );

	if ( $sec_END->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_END, "end" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, undef, $txtStyle, undef, $borderStyle );

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

