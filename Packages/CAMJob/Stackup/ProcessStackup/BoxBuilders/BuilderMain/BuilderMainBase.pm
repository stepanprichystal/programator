#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::ProcessStackup::BoxBuilders::BuilderMain::BuilderMainBase;

#3th party library
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

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}       = shift;
	$self->{"jobId"}       = shift;
	$self->{"lamination"}  = shift;
	$self->{"stackupMngr"} = shift;
	$self->{"table"}       = shift;

	return $self;
}

sub _DrawMatStiff {
	my $self            = shift;
	my $row             = shift;
	my $matKind         = shift;
	my $matText         = shift;
	my $matThick        = shift;
	my $txtStckpStyle   = shift;
	my $txtStdStyle     = shift;
	my $txtStdBoldStyle = shift;
	my $borderStyle     = shift;

	my $tab       = $self->{"table"};
	my $stckpMngr = $self->{"stackupMngr"};

	# 1) Define styles
	$txtStckpStyle->SetColor( Color->new( 0, 0, 0 ) );

	my $backgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_STIFFENER ) );

	# Fill background
	$self->_FillRowBackg( $row, $backgStyle, "leftOverlap", "rightOverlap" );

	# Mat type ----------------
	$tab->AddCell( $tab->GetCollDefPos( $tab->GetCollByKey("matType") ),
				   $tab->GetRowDefPos($row),
				   undef, undef, "Stiffener", $txtStckpStyle, $backgStyle );

	# Mat Id

	# Mat Kind
	$tab->AddCell( $tab->GetCollDefPos( $tab->GetCollByKey("matKind") ),
				   $tab->GetRowDefPos($row),
				   undef, undef, $matKind, $txtStdStyle, undef, $borderStyle );

	# Mat Type
	$tab->AddCell( $tab->GetCollDefPos( $tab->GetCollByKey("matName") ),
				   $tab->GetRowDefPos($row),
				   undef, undef, $matText, $txtStdBoldStyle, undef, $borderStyle );

	# Mat Thick
	$tab->AddCell( $tab->GetCollDefPos( $tab->GetCollByKey("matThick") ),
				   $tab->GetRowDefPos($row),
				   undef, undef, $matThick, $txtStdStyle, undef, $borderStyle );

}

sub _DrawMatStiffAdh {
	my $self            = shift;
	my $row             = shift;
	my $matKind         = shift;
	my $matText         = shift;
	my $matThick        = shift;
	my $txtStckpStyle   = shift;
	my $txtStdStyle     = shift;
	my $txtStdBoldStyle = shift;
	my $borderStyle     = shift;

	my $tab       = $self->{"table"};
	my $stckpMngr = $self->{"stackupMngr"};

	# 1) Define styles
	$txtStckpStyle->SetColor( Color->new( 0, 0, 0 ) );

	my $backgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_ADHESIVE ) );

	# Fill background
	$self->_FillRowBackg( $row, $backgStyle, "leftOverlap", "rightOverlap" );

	# Mat type ----------------
	$tab->AddCell( $tab->GetCollDefPos( $tab->GetCollByKey("matType") ),
				   $tab->GetRowDefPos($row),
				   undef, undef, "Lepidlo", $txtStckpStyle, $backgStyle );

	# Mat Id

	# Mat Kind
	$tab->AddCell( $tab->GetCollDefPos( $tab->GetCollByKey("matKind") ),
				   $tab->GetRowDefPos($row),
				   undef, undef, $matKind, $txtStdStyle, undef, $borderStyle );

	# Mat Type
	$tab->AddCell( $tab->GetCollDefPos( $tab->GetCollByKey("matName") ),
				   $tab->GetRowDefPos($row),
				   undef, undef, $matText, $txtStdBoldStyle, undef, $borderStyle );

	# Mat Thick
	$tab->AddCell( $tab->GetCollDefPos( $tab->GetCollByKey("matThick") ),
				   $tab->GetRowDefPos($row),
				   undef, undef, $matThick, $txtStdStyle, undef, $borderStyle );

}

sub _DrawMatProduct {
	my $self            = shift;
	my @row             = @{ shift(@_) };
	my @matType         = @{ shift(@_) };
	my @matId           = @{ shift(@_) };
	my @matKind         = @{ shift(@_) };
	my @matText         = @{ shift(@_) };
	my @matThick        = @{ shift(@_) };
	my $txtStckpStyle   = shift;
	my $txtStdStyle     = shift;
	my $txtStdBoldStyle = shift;
	my $borderStyle     = shift;

	my $tab       = $self->{"table"};
	my $stckpMngr = $self->{"stackupMngr"};

	# 1) Define styles

	my $backgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_PRODUCT ) );

	for ( my $i = scalar(@row) - 1 ; $i >= 0 ; $i-- ) {

		# Fill background
		$self->_FillRowBackg( $row[$i], $backgStyle, "leftOverlap", "rightOverlap" );

		my $pBorderStyle = $i == scalar(@row) - 1 ? $borderStyle : undef;

		# Mat type
		if ( defined $matType[$i] ) {
			$tab->AddCell( $tab->GetCollDefPos( $tab->GetCollByKey("matType") ),
						   $tab->GetRowDefPos( $row[$i] ),
						   undef, undef, $matType[$i], $txtStckpStyle, $backgStyle );
		}

		# Mat Id
		if ( defined $matId[$i] ) {
			$tab->AddCell( $tab->GetCollDefPos( $tab->GetCollByKey("matId") ),
						   $tab->GetRowDefPos( $row[0] ),
						   undef, undef, $matId[$i], $txtStckpStyle, $backgStyle );
		}

		# Mat Kind
		if ( defined $matKind[$i] ) {
			$tab->AddCell( $tab->GetCollDefPos( $tab->GetCollByKey("matKind") ),
						   $tab->GetRowDefPos( $row[$i] ),
						   undef, undef, $matKind[$i], $txtStdStyle, undef, $pBorderStyle );
		}

		# Mat Type
		if ( defined $matText[$i] ) {
			$tab->AddCell( $tab->GetCollDefPos( $tab->GetCollByKey("matName") ),
						   $tab->GetRowDefPos( $row[$i] ),
						   undef, undef, $matText[$i], $txtStdBoldStyle, undef, $pBorderStyle );
		}

		# Mat Thick
		if ( defined $matThick[$i] ) {
			$tab->AddCell( $tab->GetCollDefPos( $tab->GetCollByKey("matThick") ),
						   $tab->GetRowDefPos( $row[$i] ),
						   undef, undef, $matThick[$i], $txtStdStyle, undef, $pBorderStyle );
		}
	}

}

sub _DrawPad {
	my $self            = shift;
	my $row             = shift;
	my $padType         = shift;
	my $padText         = shift;
	my $padThick        = shift;
	my $txtStckpStyle   = shift;
	my $txtStdStyle     = shift;
	my $txtStdBoldStyle = shift;
	my $borderStyle     = shift;

	my $tab       = $self->{"table"};
	my $stckpMngr = $self->{"stackupMngr"};

	# 1) Define styles
	$txtStckpStyle->SetColor( Color->new( 0, 0, 0 ) );

	my $clr = undef;
	my $padTypeName = undef;
	if ( $padType eq Enums->LamPad_PADPAPER ) {
		
		$clr = EnumsStyle->Clr_PADPAPER;
		$padTypeName = "Papírová podložka";
	}
	elsif ( $padType eq Enums->LamPad_PADRUBBER ) {
		
		$clr = EnumsStyle->Clr_PADRUBBER;
		$padTypeName = "Gumová podložka";
	}
	elsif ( $padType eq Enums->LamPad_PADFILM ) {
		
		$clr = EnumsStyle->Clr_PADFILM;
		$padTypeName = "Separaèní fólie";
	}

	my $backgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new($clr) );

	 

	# Fill background
	$self->_FillRowBackg( $row, $backgStyle, "leftOverlap", "rightOverlap" );

	# Mat type ----------------
	$tab->AddCell( $tab->GetCollDefPos( $tab->GetCollByKey("matType") ),
				   $tab->GetRowDefPos($row),
				   undef, undef, $padTypeName, $txtStckpStyle, $backgStyle );

	# Mat Id

	# Mat Kind

	# Mat Type
	$tab->AddCell( $tab->GetCollDefPos( $tab->GetCollByKey("matName") ),
				   $tab->GetRowDefPos($row),
				   undef, undef, $padText, $txtStdBoldStyle, undef, $borderStyle );

	# Mat Thick
	$tab->AddCell( $tab->GetCollDefPos( $tab->GetCollByKey("matThick") ),
				   $tab->GetRowDefPos($row),
				   undef, undef, $padThick, $txtStdStyle, undef, $borderStyle );

}

sub _FillRowBackg {
	my $self       = shift;
	my $row        = shift;
	my $backgStyle = shift;
	my $startCol   = shift;
	my $endCol     = shift;

	my $tab = $self->{"table"};

	my $startPos = $tab->GetCollDefPos( $tab->GetCollByKey($startCol) );
	my $endPos   = $tab->GetCollDefPos( $tab->GetCollByKey($endCol) );

	for ( my $i = $startPos ; $i <= $endPos ; $i++ ) {

		$tab->AddCell( $i, $tab->GetRowDefPos($row), undef, undef, undef, undef, $backgStyle );

	}

}
#
#sub _DrawMatStiffAdh {
#	my $self             = shift;
#	my $row              = shift;
#	my $matText          = shift;
#	my $matThick         = shift;
#	my $txtTitleStyle    = shift;
#	my $txtStandardStyle = shift;
#
#	my $tblMain   = $self->{"tblMain"};
#	my $stckpMngr = $self->{"stackupMngr"};
#	my $secMngr   = $self->{"sectionMngr"};
#
#	# 1) Define styles
#	$txtStandardStyle->SetColor( Color->new( 0, 0, 0 ) );
#
#	my $stiffBackgStyle    = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_STIFFENER ) );
#	my $adhesiveBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_ADHESIVE ) );
#
#	# Sec_BEGIN ---------------------------------------------
#	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
#	if ( $sec_BEGIN->GetIsActive() ) {
#
#		# Check if there isn't already some material title (mask/flexmask)
#		unless ( defined $tblMain->GetCellByPos( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ), $tblMain->GetRowDefPos($row) ) ) {
#
#			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ),
#							   $tblMain->GetRowDefPos($row),
#							   undef, undef, $matText, $txtTitleStyle );
#		}
#
#	}
#
#	# Sec_E_STIFFENER ---------------------------------------------
#	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );
#
#	if ( $sec_E_STIFFENER->GetIsActive() ) {
#
#		# adhesive
#		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matType" ),
#						   $tblMain->GetRowDefPos($row),
#						   undef, undef, "Adhesive", $txtStandardStyle, $adhesiveBackgStyle );
#		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matThick" ),
#						   $tblMain->GetRowDefPos($row),
#						   undef, undef, int($matThick), $txtStandardStyle, $adhesiveBackgStyle );
#	}
#
#}
#
#sub _DrawMatSMFlex {
#	my $self             = shift;
#	my $row              = shift;
#	my $matText          = shift;
#	my $matThick         = shift;
#	my $txtTitleStyle    = shift;
#	my $txtStandardStyle = shift;
#
#	my $tblMain   = $self->{"tblMain"};
#	my $stckpMngr = $self->{"stackupMngr"};
#	my $secMngr   = $self->{"sectionMngr"};
#
#	# 1) Define styles
#	$txtStandardStyle->SetColor( Color->new( 255, 255, 255 ) );
#
#	my $matBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_SOLDERMASKFLEX ) );
#
#	# Sec_B_FLEX ---------------------------------------------
#	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );
#	if ( $sec_B_FLEX->GetIsActive() ) {
#
#		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_B_FLEX, -1, 1 );
#
#		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matType" ),
#						   $tblMain->GetRowDefPos($row),
#						   undef, undef, "Flexible SM", $txtStandardStyle, $matBackgStyle );
#		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matThick" ),
#						   $tblMain->GetRowDefPos($row),
#						   undef, undef, int($matThick), $txtStandardStyle, $matBackgStyle );
#	}
#
#	# Sec_D_FLEXTAIL ---------------------------------------------
#	my $sec_D_FLEXTAIL = $secMngr->GetSection( Enums->Sec_D_FLEXTAIL );
#	if ( $sec_D_FLEXTAIL->GetIsActive() ) {
#
#		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_D_FLEXTAIL, -1, 0 );
#
#	}
#}
#
#sub _DrawMatCoverlayAdhOuter {
#	my $self             = shift;
#	my $row              = shift;
#	my $matText          = shift;
#	my $matThick         = shift;
#	my $selective        = shift;
#	my $txtTitleStyle    = shift;
#	my $txtStandardStyle = shift;
#
#	my $tblMain   = $self->{"tblMain"};
#	my $stckpMngr = $self->{"stackupMngr"};
#	my $secMngr   = $self->{"sectionMngr"};
#
#	# 1) Define styles
#	$txtStandardStyle->SetColor( Color->new( 0, 0, 0 ) );
#
#	my $matBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_ADHESIVE ) );
#
#	# Sec_BEGIN ---------------------------------------------
#	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
#	if ( $sec_BEGIN->GetIsActive() ) {
#
#   #$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ), $tblMain->GetRowDefPos($row), undef, undef, $matText, $txtTitleStyle );
#	}
#
#	# Sec_A_MAIN ---------------------------------------------
#	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
#	if ( $sec_A_MAIN->GetIsActive() && !$selective ) {
#
#		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_A_MAIN, 0, 0 );
#
#		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matType" ),
#						   $tblMain->GetRowDefPos($row),
#						   undef, undef, "Adhesive", $txtStandardStyle, $matBackgStyle );
#		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matThick" ),
#						   $tblMain->GetRowDefPos($row),
#						   undef, undef, int($matThick), $txtStandardStyle, $matBackgStyle );
#	}
#
#	# $sec_B_FLEX ---------------------------------------------
#	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );
#	if ( $sec_B_FLEX->GetIsActive() ) {
#
#		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_B_FLEX, -1, 1 );
#		if ($selective) {
#			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matType" ),
#							   $tblMain->GetRowDefPos($row),
#							   undef, undef, "Adhesive", $txtStandardStyle, $matBackgStyle );
#			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matThick" ),
#							   $tblMain->GetRowDefPos($row),
#							   undef, undef, int($matThick), $txtStandardStyle, $matBackgStyle );
#		}
#
#	}
#
#	# Sec_C_RIGIDFLEX ---------------------------------------------
#	my $sec_C_RIGIDFLEX = $secMngr->GetSection( Enums->Sec_C_RIGIDFLEX );
#	if ( $sec_C_RIGIDFLEX->GetIsActive() && !$selective ) {
#
#		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_C_RIGIDFLEX, 0, 0 );
#
#	}
#
#	# Sec_D_FLEXTAIL ---------------------------------------------
#	my $sec_D_FLEXTAIL = $secMngr->GetSection( Enums->Sec_D_FLEXTAIL );
#	if ( $sec_D_FLEXTAIL->GetIsActive() ) {
#
#		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_D_FLEXTAIL, -1, 0 );
#		if ($selective) {
#			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matType" ),
#							   $tblMain->GetRowDefPos($row),
#							   undef, undef, "Adhesive", $txtStandardStyle, $matBackgStyle );
#			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matThick" ),
#							   $tblMain->GetRowDefPos($row),
#							   undef, undef, int($matThick), $txtStandardStyle, $matBackgStyle );
#		}
#	}
#
#	# Sec_E_STIFFENER ---------------------------------------------
#	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );
#
#	if ( $sec_E_STIFFENER->GetIsActive() ) {
#
#		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_E_STIFFENER, 0, 0 );
#	}
#
#}
#
#sub _DrawMatCoverlayOuter {
#	my $self             = shift;
#	my $row              = shift;
#	my $matText          = shift;
#	my $matThick         = shift;
#	my $selective        = shift;
#	my $txtTitleStyle    = shift;
#	my $txtStandardStyle = shift;
#
#	my $tblMain   = $self->{"tblMain"};
#	my $stckpMngr = $self->{"stackupMngr"};
#	my $secMngr   = $self->{"sectionMngr"};
#
#	# 1) Define styles
#	$txtStandardStyle->SetColor( Color->new( 0, 0, 0 ) );
#
#	my $matBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_COVERLAY ) );
#
#	# Sec_BEGIN ---------------------------------------------
#	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
#	if ( $sec_BEGIN->GetIsActive() ) {
#
#		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ),
#						   $tblMain->GetRowDefPos($row),
#						   undef, undef, $matText, $txtTitleStyle );
#	}
#
#	# Sec_A_MAIN ---------------------------------------------
#	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
#	if ( $sec_A_MAIN->GetIsActive() && !$selective ) {
#
#		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_A_MAIN, 0, 0 );
#
#		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matType" ),
#						   $tblMain->GetRowDefPos($row),
#						   undef, undef, "Coverlay", $txtStandardStyle, $matBackgStyle );
#		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matThick" ),
#						   $tblMain->GetRowDefPos($row),
#						   undef, undef, int($matThick), $txtStandardStyle, $matBackgStyle );
#	}
#
#	# $sec_B_FLEX ---------------------------------------------
#	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );
#	if ( $sec_B_FLEX->GetIsActive() ) {
#
#		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_B_FLEX, -1, 1 );
#		if ($selective) {
#			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matType" ),
#							   $tblMain->GetRowDefPos($row),
#							   undef, undef, "Coverlay", $txtStandardStyle, $matBackgStyle );
#			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matThick" ),
#							   $tblMain->GetRowDefPos($row),
#							   undef, undef, int($matThick), $txtStandardStyle, $matBackgStyle );
#		}
#
#	}
#
#	# Sec_C_RIGIDFLEX ---------------------------------------------
#	my $sec_C_RIGIDFLEX = $secMngr->GetSection( Enums->Sec_C_RIGIDFLEX );
#	if ( $sec_C_RIGIDFLEX->GetIsActive() && !$selective ) {
#
#		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_C_RIGIDFLEX, 0, 0 );
#
#	}
#
#	# Sec_D_FLEXTAIL ---------------------------------------------
#	my $sec_D_FLEXTAIL = $secMngr->GetSection( Enums->Sec_D_FLEXTAIL );
#	if ( $sec_D_FLEXTAIL->GetIsActive() ) {
#
#		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_D_FLEXTAIL, -1, 0 );
#		if ($selective) {
#			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matType" ),
#							   $tblMain->GetRowDefPos($row),
#							   undef, undef, "Coverlay", $txtStandardStyle, $matBackgStyle );
#			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matThick" ),
#							   $tblMain->GetRowDefPos($row),
#							   undef, undef, int($matThick), $txtStandardStyle, $matBackgStyle );
#		}
#	}
#
#	# Sec_E_STIFFENER ---------------------------------------------
#	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );
#
#	if ( $sec_E_STIFFENER->GetIsActive() ) {
#
#		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_E_STIFFENER, 0, 0 );
#	}
#
#}
#
#sub _DrawMatSM {
#	my $self             = shift;
#	my $row              = shift;
#	my $matText          = shift;
#	my $matThick         = shift;
#	my $coverFlexCore    = shift;    # indicate if solder mask is directly on flex core
#	my $txtTitleStyle    = shift;
#	my $txtStandardStyle = shift;
#
#	my $tblMain   = $self->{"tblMain"};
#	my $stckpMngr = $self->{"stackupMngr"};
#	my $secMngr   = $self->{"sectionMngr"};
#
#	# 1) Define styles
#	$txtStandardStyle->SetColor( Color->new( 255, 255, 255 ) );
#
#	my $matBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_SOLDERMASK ) );
#
#	# Sec_BEGIN ---------------------------------------------
#	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
#	if ( $sec_BEGIN->GetIsActive() ) {
#
#		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ),
#						   $tblMain->GetRowDefPos($row),
#						   undef, undef, $matText, $txtTitleStyle );
#	}
#
#	# Sec_A_MAIN ---------------------------------------------
#	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
#	if ( $sec_A_MAIN->GetIsActive() ) {
#
#		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_A_MAIN, 0, 0 );
#
#		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matType" ),
#						   $tblMain->GetRowDefPos($row),
#						   undef, undef, "Solder mask", $txtStandardStyle, $matBackgStyle );
#		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matThick" ),
#						   $tblMain->GetRowDefPos($row),
#						   undef, undef, $matThick, $txtStandardStyle, $matBackgStyle );
#	}
#
#	# $sec_B_FLEX ---------------------------------------------
#	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );
#	if ( $sec_B_FLEX->GetIsActive() ) {
#		if ($coverFlexCore) {
#			$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_B_FLEX, 0, 0 );
#		}
#
#	}
#
#	# Sec_C_RIGIDFLEX ---------------------------------------------
#	my $sec_C_RIGIDFLEX = $secMngr->GetSection( Enums->Sec_C_RIGIDFLEX );
#	if ( $sec_C_RIGIDFLEX->GetIsActive() ) {
#
#		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_C_RIGIDFLEX, 0, 0 );
#
#	}
#
#	# Sec_D_FLEXTAIL ---------------------------------------------
#	my $sec_D_FLEXTAIL = $secMngr->GetSection( Enums->Sec_D_FLEXTAIL );
#	if ( $sec_D_FLEXTAIL->GetIsActive() ) {
#
#		if ($coverFlexCore) {
#			$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_D_FLEXTAIL, 0, 0 );
#		}
#	}
#
#	# Sec_E_STIFFENER ---------------------------------------------
#	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );
#
#	if ( $sec_E_STIFFENER->GetIsActive() ) {
#
#		if ($coverFlexCore) {
#			$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_E_STIFFENER, 0, 0 );
#		}
#	}
#
#}
#
#sub _DrawMatCopper {
#	my $self             = shift;
#	my $row              = shift;
#	my $matText          = shift;
#	my $matThick         = shift;
#	my $isPlated         = shift;
#	my $lNumber          = shift;
#	my $cuUssage         = shift;
#	my $foil             = shift;
#	my $flex             = shift;
#	my $txtTitleStyle    = shift;
#	my $txtCuStyle       = shift;
#	my $txtStandardStyle = shift;
#
#	my $tblMain   = $self->{"tblMain"};
#	my $stckpMngr = $self->{"stackupMngr"};
#	my $secMngr   = $self->{"sectionMngr"};
#
#	# 1) Define styles
#	$txtStandardStyle->SetColor( Color->new( 255, 255, 255 ) );
#
#	my $matBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_COPPER ) );
#	my $matCoreBackgStyle =
#	  BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( $flex ? EnumsStyle->Clr_COREFLEX : EnumsStyle->Clr_CORERIGID ) );
#
#	# Sec_BEGIN ---------------------------------------------
#	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
#	if ( $sec_BEGIN->GetIsActive() ) {
#
#		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ),
#						   $tblMain->GetRowDefPos($row),
#						   undef, undef, $matText, $txtTitleStyle );
#
#		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "cuUsage" ),
#						   $tblMain->GetRowDefPos($row),
#						   undef, undef, "L" . $lNumber . ( defined $cuUssage ? " (" . int($cuUssage) . "%)" : "" ), $txtCuStyle );
#	}
#
#	# Sec_A_MAIN ---------------------------------------------
#	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
#	if ( $sec_A_MAIN->GetIsActive() ) {
#
#		if ( !defined $cuUssage || $cuUssage > 0 ) {
#
#			$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_A_MAIN, 0, 0 );
#
#			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matType" ),
#							   $tblMain->GetRowDefPos($row),
#							   undef, undef, "Copper" . ( $foil ? " foil" : "" ),
#							   $txtStandardStyle, $matBackgStyle );
#			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matThick" ),
#							   $tblMain->GetRowDefPos($row),
#							   undef, undef, $matThick . ( $isPlated ? "+25 Plt" : "" ),
#							   $txtStandardStyle, $matBackgStyle );
#
#		}
#		else {
#			$self->__FillRowBackg( $row, $matBackgStyle,     Enums->Sec_A_MAIN, 0,  0 );
#			$self->__FillRowBackg( $row, $matCoreBackgStyle, Enums->Sec_A_MAIN, +1, -1 );
#		}
#	}
#
#	# $sec_B_FLEX ---------------------------------------------
#	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );
#	if ( $sec_B_FLEX->GetIsActive() ) {
#
#		if ( !defined $cuUssage || $cuUssage > 0 ) {
#			if ($flex) {
#				$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_B_FLEX, 0, 0 );
#			}
#		}
#	}
#
#	# Sec_C_RIGIDFLEX ---------------------------------------------
#	my $sec_C_RIGIDFLEX = $secMngr->GetSection( Enums->Sec_C_RIGIDFLEX );
#	if ( $sec_C_RIGIDFLEX->GetIsActive() ) {
#
#		if ( !defined $cuUssage || $cuUssage > 0 ) {
#			$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_C_RIGIDFLEX, 0, 0 );
#		}
#		else {
#			$self->__FillRowBackg( $row, $matBackgStyle,     Enums->Sec_C_RIGIDFLEX, 0,  0 );
#			$self->__FillRowBackg( $row, $matCoreBackgStyle, Enums->Sec_C_RIGIDFLEX, +1, -1 );
#		}
#
#	}
#
#	# Sec_D_FLEXTAIL ---------------------------------------------
#	my $sec_D_FLEXTAIL = $secMngr->GetSection( Enums->Sec_D_FLEXTAIL );
#	if ( $sec_D_FLEXTAIL->GetIsActive() ) {
#
#		if ( !defined $cuUssage || $cuUssage > 0 ) {
#
#			if ($flex) {
#				$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_D_FLEXTAIL, 0, 0 );
#			}
#
#		}
#	}
#
#	# Sec_E_STIFFENER ---------------------------------------------
#	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );
#
#	if ( $sec_E_STIFFENER->GetIsActive() ) {
#
#		if ( !defined $cuUssage || $cuUssage > 0 ) {
#			if ($flex) {
#				$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_E_STIFFENER, 0, 0 );
#			}
#		}
#	}
#
#}
#
#sub _DrawMatPrepreg {
#	my $self             = shift;
#	my $row              = shift;
#	my $matText          = shift;
#	my $matThick         = shift;
#	my $isNoFLow         = shift;
#	my $noFlowType       = shift;
#	my $displayType      = shift;
#	my $txtTitleStyle    = shift;
#	my $txtStandardStyle = shift;
#
#	my $tblMain   = $self->{"tblMain"};
#	my $stckpMngr = $self->{"stackupMngr"};
#	my $secMngr   = $self->{"sectionMngr"};
#
#	# 1) Define styles
#	$txtStandardStyle->SetColor( Color->new( 255, 255, 255 ) );
#
#	my $matBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_PREPREG ) );
#
#	# Sec_BEGIN ---------------------------------------------
#	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
#	if ( $sec_BEGIN->GetIsActive() ) {
#
#		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ),
#						   $tblMain->GetRowDefPos($row),
#						   undef, undef, $matText, $txtTitleStyle );
#	}
#
#	# Sec_A_MAIN ---------------------------------------------
#	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
#	if ( $sec_A_MAIN->GetIsActive() ) {
#
#		my $stdVV = $stckpMngr->GetPcbType() eq EnumsGeneral->PcbType_MULTI || $stckpMngr->GetPcbType() eq EnumsGeneral->PcbType_MULTIFLEX ? 1 : 0;
#
#		# clear marigns of prepreg when standard multilayer
#		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_A_MAIN, $stdVV ? 1 : 0, $stdVV ? -1 : 0 );
#		my $typeTxt = ( $isNoFLow ? "NoFlow prepreg " . ( $noFlowType eq StackEnums->NoFlowPrepreg_P1 ? "1" : "2" ) : "Prepreg" );
#
#		if ($displayType) {
#
#			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matType" ),
#							   $tblMain->GetRowDefPos($row),
#							   undef, undef, $typeTxt, $txtStandardStyle, $matBackgStyle );
#			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matThick" ),
#							   $tblMain->GetRowDefPos($row),
#							   undef, undef, int($matThick), $txtStandardStyle, $matBackgStyle );
#
#		}
#	}
#
#	# Sec_C_RIGIDFLEX ---------------------------------------------
#	my $sec_C_RIGIDFLEX = $secMngr->GetSection( Enums->Sec_C_RIGIDFLEX );
#	if ( $sec_C_RIGIDFLEX->GetIsActive() ) {
#
#		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_C_RIGIDFLEX, 0, 0 );
#
#	}
#
#}
#
#sub _DrawMatCore {
#	my $self             = shift;
#	my $row              = shift;
#	my $matText          = shift;
#	my $matThick         = shift;
#	my $isFlex           = shift;
#	my $core             = shift;
#	my $txtTitleStyle    = shift;
#	my $txtStandardStyle = shift;
#
#	my $tblMain   = $self->{"tblMain"};
#	my $stckpMngr = $self->{"stackupMngr"};
#	my $secMngr   = $self->{"sectionMngr"};
#
#	# 1) Define styles
#	$txtStandardStyle->SetColor( $isFlex ? Color->new( 0, 0, 0 ) : Color->new( 255, 255, 255 ) );
#
#	my $matBackgStyle =
#	  BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( $isFlex ? EnumsStyle->Clr_COREFLEX : EnumsStyle->Clr_CORERIGID ) );
#
#	# Sec_BEGIN ---------------------------------------------
#	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
#	if ( $sec_BEGIN->GetIsActive() ) {
#
#		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ),
#						   $tblMain->GetRowDefPos($row),
#						   undef, undef, $matText, $txtTitleStyle );
#	}
#
#	# Sec_A_MAIN ---------------------------------------------
#	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
#	if ( $sec_A_MAIN->GetIsActive() ) {
#
#		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_A_MAIN, 0, 0 );
#
#		my $text = ( $isFlex ? "Flex" : "Rigid" );
#		$text .= ( $core ? " core" : " laminate" );
#
#		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matType" ),
#						   $tblMain->GetRowDefPos($row),
#						   undef, undef, $text, $txtStandardStyle, $matBackgStyle );
#		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matThick" ),
#						   $tblMain->GetRowDefPos($row),
#						   undef, undef, $matThick, $txtStandardStyle, $matBackgStyle );
#	}
#
#	# $sec_B_FLEX ---------------------------------------------
#	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );
#	if ( $sec_B_FLEX->GetIsActive() ) {
#
#		if ($isFlex) {
#			$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_B_FLEX, 0, 0 );
#		}
#
#	}
#
#	# Sec_C_RIGIDFLEX ---------------------------------------------
#	my $sec_C_RIGIDFLEX = $secMngr->GetSection( Enums->Sec_C_RIGIDFLEX );
#	if ( $sec_C_RIGIDFLEX->GetIsActive() ) {
#
#		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_C_RIGIDFLEX, 0, 0 );
#
#	}
#
#	# Sec_D_FLEXTAIL ---------------------------------------------
#	my $sec_D_FLEXTAIL = $secMngr->GetSection( Enums->Sec_D_FLEXTAIL );
#	if ( $sec_D_FLEXTAIL->GetIsActive() ) {
#
#		if ($isFlex) {
#			$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_D_FLEXTAIL, 0, 0 );
#		}
#	}
#
#	# Sec_E_STIFFENER ---------------------------------------------
#	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );
#
#	if ( $sec_E_STIFFENER->GetIsActive() ) {
#
#		if ($isFlex) {
#			$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_E_STIFFENER, 0, 0 );
#		}
#	}
#
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

