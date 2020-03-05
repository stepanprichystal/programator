
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb no copper
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::BlockBuilders::BuilderBody;
use base('Packages::CAMJob::Stackup::CustStackup::BlockBuilders::BlockBuilderBase');

use Class::Interface;
&implements('Packages::CAMJob::Stackup::CustStackup::BlockBuilders::IBlockBuilder');

#3th party library
use strict;
use warnings;
use Time::localtime;
use Storable qw(dclone);

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Stackup::CustStackup::Enums';
use aliased 'Packages::CAMJob::Stackup::CustStackup::EnumsStyle';
use aliased 'Packages::Other::TableDrawing::Table::Style::TextStyle';
use aliased 'Packages::Other::TableDrawing::Table::Style::Color';
use aliased 'Packages::Other::TableDrawing::Table::Style::BackgStyle';
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

	$self->__BuildHead();

	$self->__BuildStackup();

}

sub __BuildHead {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# Define first title row
	my $rowBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_HEADSUBBACK ) );
	my $row = $tblMain->AddRowDef( "body_head", EnumsStyle->RowHeight_STANDARD, $rowBackgStyle );

	my $txtStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
								   EnumsStyle->TxtSize_TITLE, Color->new( 0, 0, 0 ),
								   undef, undef,
								   TblDrawEnums->TextHAlign_LEFT,
								   TblDrawEnums->TextVAlign_CENTER );

	# Sec_BEGIN ---------------------------------------------
	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
	if ( $sec_BEGIN->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ), $row->GetIndex(), undef, undef, "Material text", $txtStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "cuUsage" ),  $row->GetIndex(), undef, undef, "Cu usage",      $txtStyle );
	}

	# Sec_A_MAIN ---------------------------------------------
	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
	if ( $sec_A_MAIN->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matType" ),  $row->GetIndex(), undef, undef, "Material",  $txtStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matThick" ), $row->GetIndex(), undef, undef, "Thickness", $txtStyle );

		if ( scalar( $stckpMngr->GetPlatedNC() ) ) {
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "NCStartCol" ), $row->GetIndex(), undef, undef, "Plated drill", $txtStyle );
		}
	}

	# Sec_B_FLEX ---------------------------------------------
	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );
	if ( $sec_B_FLEX->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matType" ),  $row->GetIndex(), undef, undef, "Material",  $txtStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matThick" ), $row->GetIndex(), undef, undef, "Thickness", $txtStyle );
	}

	# Sec_C_RIGIDFLEX ---------------------------------------------
	my $sec_C_RIGIDFLEX = $secMngr->GetSection( Enums->Sec_C_RIGIDFLEX );
	if ( $sec_C_RIGIDFLEX->GetIsActive() ) {

	}

	# Sec_D_FLEXTAIL ---------------------------------------------
	my $sec_D_FLEXTAIL = $secMngr->GetSection( Enums->Sec_D_FLEXTAIL );
	if ( $sec_D_FLEXTAIL->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matType" ),  $row->GetIndex(), undef, undef, "Material",  $txtStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matThick" ), $row->GetIndex(), undef, undef, "Thickness", $txtStyle );
	}

	# Sec_E_STIFFENER ---------------------------------------------
	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );

	if ( $sec_E_STIFFENER->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matType" ),  $row->GetIndex(), undef, undef, "Material",  $txtStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matThick" ), $row->GetIndex(), undef, undef, "Thickness", $txtStyle );
	}

}

sub __BuildStackup {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# Define general styles

	my $txtTitleStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
										EnumsStyle->TxtSize_STANDARD,
										Color->new( 0, 0, 0 ),
										undef, undef,
										TblDrawEnums->TextHAlign_LEFT,
										TblDrawEnums->TextVAlign_CENTER );
	my $txtCuStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
									 EnumsStyle->TxtSize_STANDARD,
									 Color->new( 0, 0, 0 ),
									 TblDrawEnums->Font_BOLD, undef,
									 TblDrawEnums->TextHAlign_LEFT,
									 TblDrawEnums->TextVAlign_CENTER );
	my $txtStandardStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
										   EnumsStyle->TxtSize_STANDARD,
										   Color->new( 255, 255, 255 ),
										   TblDrawEnums->Font_BOLD, undef,
										   TblDrawEnums->TextHAlign_LEFT,
										   TblDrawEnums->TextVAlign_CENTER );

	# 1) Add gap row above stackup
	$tblMain->AddRowDef( "bodyTopGap", EnumsStyle->RowHeight_STANDARD );

	# 2) Add material rows

	# LAYER: Top stiffener + adhesive
	my $stiffTopInfo = {};
	if ( $stckpMngr->GetGetExistStiff( "top", $stiffTopInfo ) ) {

		my $rowStiff    = $tblMain->AddRowDef( "stiffTop",    EnumsStyle->RowHeight_STANDARD );
		my $rowAdhesive = $tblMain->AddRowDef( "adhesiveTop", EnumsStyle->RowHeight_STANDARD );

		$self->__DrawMateriaStiff( $rowStiff, $rowAdhesive,
								   $stiffTopInfo->{"stiffText"},
								   $stiffTopInfo->{"stiffThick"},
								   $stiffTopInfo->{"adhesiveText"},
								   $stiffTopInfo->{"adhesiveThick"},
								   dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}

	# LAYER: Top SM FLEX UV
	if ( $stckpMngr->GetExistSMFlexTop() ) {

		my $row;

		if ( $stckpMngr->GetGetExistStiff("top") ) {
			$row = ( $tblMain->GetRowsDef() )[ $tblMain->GetRowCnt() - 1 ];
		}
		else {
			$row = $tblMain->AddRowDef( "SMFlexTop", EnumsStyle->RowHeight_STANDARD );
		}

		$self->__DrawMateriaSMFlex( $row, $stckpMngr->GetGetExistStiff("top"), dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}

	# LAYER: Top SM
	my $maskTopInfo = {};
	if ( $stckpMngr->GetExistSMTop($maskTopInfo) ) {

		my $row;

		if ( $stckpMngr->GetGetExistStiff("top") || $stckpMngr->GetExistSMFlexTop() ) {
			$row = ( $tblMain->GetRowsDef() )[ $tblMain->GetRowCnt() - 1 ];
		}
		else {
			$row = $tblMain->AddRowDef( "SMTop", EnumsStyle->RowHeight_STANDARD );
		}

		$self->__DrawMaterialSM( $row,
								$stckpMngr->GetGetExistStiff("top"),
								$stckpMngr->GetExistSMTop(),
								dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}

	# 3) Add gap row below stackup
	$tblMain->AddRowDef( "bodyBotGap", EnumsStyle->RowHeight_STANDARD );

}

sub __DrawMateriaStiff {
	my $self             = shift;
	my $rowStif          = shift;
	my $rowStifAdh       = shift;
	my $stiffMatText     = shift;
	my $stiffMatThick    = shift;
	my $adhesMatText     = shift;
	my $adhesMatThick    = shift;
	my $txtTitleStyle    = shift;
	my $txtStandardStyle = shift;

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# 1) Define styles
	$txtStandardStyle->SetColor( Color->new( 0, 0, 0 ) );

	my $stiffBackgStyle    = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_STIFFENER ) );
	my $adhesiveBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_ADHESIVE ) );

	# Sec_BEGIN ---------------------------------------------
	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
	if ( $sec_BEGIN->GetIsActive() ) {

		# stiffener
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ),
						   $rowStif->GetIndex(), undef, undef, $stiffMatText, $txtTitleStyle, $stiffBackgStyle );

		# adhesive
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ),
						   $rowStifAdh->GetIndex(),
						   undef, undef, $adhesMatText, $txtTitleStyle, $adhesiveBackgStyle );
	}

	# Sec_E_STIFFENER ---------------------------------------------
	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );

	if ( $sec_E_STIFFENER->GetIsActive() ) {

		# stiffener
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "Stiffener" ),
						   $rowStif->GetIndex(), undef, undef, "Material", $txtStandardStyle, $stiffBackgStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, $stiffMatThick ),
						   $rowStif->GetIndex(), undef, undef, "Thickness", $txtStandardStyle, $stiffBackgStyle );

		# adhesive
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "Adhesive" ),
						   $rowStifAdh->GetIndex(),
						   undef, undef, "Material", $txtStandardStyle, $adhesiveBackgStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, $adhesMatThick ),
						   $rowStifAdh->GetIndex(),
						   undef, undef, "Thickness", $txtStandardStyle, $adhesiveBackgStyle );

	}

}

sub __DrawMaterialSMFlex {
	my $self             = shift;
	my $row              = shift;
	my $includeStiff     = shift;
	my $txtTitleStyle    = shift;
	my $txtCuLayerStyle  = shift;
	my $txtStandardStyle = shift;

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# 1) Define styles
	$txtStandardStyle->SetColor( Color->new( 0, 0, 0 ) );

	my $matBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_HEADSUBBACK ) );

	# Sec_BEGIN ---------------------------------------------
	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
	if ( $sec_BEGIN->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ), $row->GetIndex(), undef, undef, "Material text", $txtTitleStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "cuUsage" ), $row->GetIndex(), undef, undef, "Cu usage", $txtCuLayerStyle );
	}

	# Sec_A_MAIN ---------------------------------------------
	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
	if ( $sec_A_MAIN->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matType" ),  $row->GetIndex(), undef, undef, "Material",  $txtStandardStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matThick" ), $row->GetIndex(), undef, undef, "Thickness", $txtStandardStyle );

		if ( scalar( $stckpMngr->GetPlatedNC() ) ) {
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "NCStartCol" ),
							   $row->GetIndex(), undef, undef, "Plated drill", $txtStandardStyle );
		}
	}

	# Sec_B_FLEX ---------------------------------------------
	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );
	if ( $sec_B_FLEX->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matType" ),  $row->GetIndex(), undef, undef, "Material",  $txtStandardStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matThick" ), $row->GetIndex(), undef, undef, "Thickness", $txtStandardStyle );
	}

	# Sec_C_RIGIDFLEX ---------------------------------------------
	my $sec_C_RIGIDFLEX = $secMngr->GetSection( Enums->Sec_C_RIGIDFLEX );
	if ( $sec_C_RIGIDFLEX->GetIsActive() ) {

	}

	# Sec_D_FLEXTAIL ---------------------------------------------
	my $sec_D_FLEXTAIL = $secMngr->GetSection( Enums->Sec_D_FLEXTAIL );
	if ( $sec_D_FLEXTAIL->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matType" ),
						   $row->GetIndex(), undef, undef, "Material", $txtStandardStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matThick" ),
						   $row->GetIndex(), undef, undef, "Thickness", $txtStandardStyle );
	}

	# Sec_E_STIFFENER ---------------------------------------------
	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );

	if ( $sec_E_STIFFENER->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matType" ),
						   $row->GetIndex(), undef, undef, "Material", $txtStandardStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matThick" ),
						   $row->GetIndex(), undef, undef, "Thickness", $txtStandardStyle );
	}

}

sub __DrawMaterialSM {
	my $self             = shift;
	my $row              = shift;
	my $includeStiff     = shift;
	my $includeFlexSM    = shift;
	my $txtTitleStyle    = shift;
	my $txtStandardStyle = shift;

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# 1) Define styles
	$txtStandardStyle->SetColor( Color->new( 255, 255, 255 ) );

	my $matBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_SOLDERMASK ) );

	# Sec_BEGIN ---------------------------------------------
	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
	if ( $sec_BEGIN->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ), $row->GetIndex(), undef, undef, "standard", $txtTitleStyle );
	}

	# Sec_A_MAIN ---------------------------------------------
	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
	if ( $sec_A_MAIN->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_A_MAIN, 0, 0 );

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matType" ), $row->GetIndex(), undef, undef, "Solder mask", $txtStandardStyle, $matBackgStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matThick" ), $row->GetIndex(), undef, undef, "25", $txtStandardStyle, $matBackgStyle );
	}

	# Sec_C_RIGIDFLEX ---------------------------------------------
	my $sec_C_RIGIDFLEX = $secMngr->GetSection( Enums->Sec_C_RIGIDFLEX );
	if ( $sec_C_RIGIDFLEX->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_C_RIGIDFLEX, 0, 0 );

	}

	# Sec_E_STIFFENER ---------------------------------------------
	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );

	if ( $sec_E_STIFFENER->GetIsActive() ) {

		if ( !$includeStiff ) {
			$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_E_STIFFENER, 0, 0 );
		}
	}

}

sub __DrawMaterialCu {
	my $self             = shift;
	my $row              = shift;
	my $stackupPos       = shift;
	my $txtTitleStyle    = shift;
	my $txtCuLayerStyle  = shift;
	my $txtStandardStyle = shift;

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# 1) Define styles
	$txtStandardStyle->SetColor( Color->new( 0, 0, 0 ) );

	my $matBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_HEADSUBBACK ) );

	# Sec_BEGIN ---------------------------------------------
	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
	if ( $sec_BEGIN->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ), $row->GetIndex(), undef, undef, "Material text", $txtTitleStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "cuUsage" ), $row->GetIndex(), undef, undef, "Cu usage", $txtCuLayerStyle );
	}

	# Sec_A_MAIN ---------------------------------------------
	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
	if ( $sec_A_MAIN->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matType" ),  $row->GetIndex(), undef, undef, "Material",  $txtStandardStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matThick" ), $row->GetIndex(), undef, undef, "Thickness", $txtStandardStyle );

		if ( scalar( $stckpMngr->GetPlatedNC() ) ) {
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "NCStartCol" ),
							   $row->GetIndex(), undef, undef, "Plated drill", $txtStandardStyle );
		}
	}

	# Sec_B_FLEX ---------------------------------------------
	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );
	if ( $sec_B_FLEX->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matType" ),  $row->GetIndex(), undef, undef, "Material",  $txtStandardStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matThick" ), $row->GetIndex(), undef, undef, "Thickness", $txtStandardStyle );
	}

	# Sec_C_RIGIDFLEX ---------------------------------------------
	my $sec_C_RIGIDFLEX = $secMngr->GetSection( Enums->Sec_C_RIGIDFLEX );
	if ( $sec_C_RIGIDFLEX->GetIsActive() ) {

	}

	# Sec_D_FLEXTAIL ---------------------------------------------
	my $sec_D_FLEXTAIL = $secMngr->GetSection( Enums->Sec_D_FLEXTAIL );
	if ( $sec_D_FLEXTAIL->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matType" ),
						   $row->GetIndex(), undef, undef, "Material", $txtStandardStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matThick" ),
						   $row->GetIndex(), undef, undef, "Thickness", $txtStandardStyle );
	}

	# Sec_E_STIFFENER ---------------------------------------------
	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );

	if ( $sec_E_STIFFENER->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matType" ),
						   $row->GetIndex(), undef, undef, "Material", $txtStandardStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matThick" ),
						   $row->GetIndex(), undef, undef, "Thickness", $txtStandardStyle );
	}

}

sub __FillRowBackg {
	my $self           = shift;
	my $row            = shift;
	my $backgStyle     = shift;
	my $secType        = shift;
	my $startColOffset = shift // 0;    # number of column positive/negative, where background starts by filled
	my $endColOffset   = shift // 0;    # number of column positive/negative, where background starts by filled

	my $tblMain = $self->{"tblMain"};
	my $secMngr = $self->{"sectionMngr"};

	my $sec     = $secMngr->GetSection($secType);
	my @colsDef = $sec->GetAllColumns();

	my $startPos = $secMngr->GetColumnPos( $secType, $colsDef[0]->GetKey() ) + $startColOffset;
	my $endPos   = $secMngr->GetColumnPos( $secType, $colsDef[scalar(@colsDef)-1]->GetKey() ) + $endColOffset;

	for ( my $i = $startPos ; $i <= $endPos ; $i++ ) {

		$tblMain->AddCell( $i, $row->GetIndex(), undef, undef, undef, undef, $backgStyle );

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

