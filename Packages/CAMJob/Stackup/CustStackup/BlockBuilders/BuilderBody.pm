
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
use aliased 'Packages::CAMJob::Stackup::CustStackup::BlockBuilders::BuilderBodyHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"stckpBody"} = BuilderBodyHelper->new( $self->{"tblMain"}, $self->{"stackupMngr"}, $self->{"sectionMngr"} );

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

	# 1) Prepare special outer layers
	# Merge slecial outer layers to same row is it is needed
	my %topOuterRows = $self->{"stckpBody"}->BuildRowsStackupOuter("top");


	# LAYER: Top SM
	my $maskTopInfo = {};
	if ( $stckpMngr->GetExistSM( "top", $maskTopInfo ) ) {

		$self->__DrawMatSM( $topOuterRows{ BuilderBodyHelper->sm }, $maskTopInfo->{"color"}, dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}

	# LAYER: TOP FLEX MASK UV
	my $maskFlexTopInfo = {};
	if ( $stckpMngr->GetExistSMFlex( "top", $maskFlexTopInfo ) ) {

		$self->__DrawMatSMFlex( $topOuterRows{ BuilderBodyHelper->smFlex },
								$maskFlexTopInfo->{"text"},
								$maskFlexTopInfo->{"thick"},
								dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}

	# LAYER: TOP stiffener adhesive
	my $stiffTopInfo = {};
	if ( $stckpMngr->GetExistStiff("top", $stiffTopInfo) ) {

		$self->__DrawMatStiffAdh( $topOuterRows{ BuilderBodyHelper->stiffAdh },
								  $stiffTopInfo->{"adhesiveText"},
								  $stiffTopInfo->{"adhesiveThick"},
								  dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}

	# LAYER: TOP stiffener
	if ( $stckpMngr->GetExistStiff( "top"   ) ) {

		$self->__DrawMatStiff( $topOuterRows{ BuilderBodyHelper->stiff },
							   $stiffTopInfo->{"stiffText"},
							   $stiffTopInfo->{"stiffThick"},
							   dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}

	# LAYER: TOP coverlay adhesive
	my $cvrlOuterTopInfo = {};
	if ( $stckpMngr->GetExistCvrl("top", $cvrlOuterTopInfo) ) {

		$self->__DrawCoverlayAdhOuter( $topOuterRows{ BuilderBodyHelper->cvrlAdh },
									   $cvrlOuterTopInfo->{"adhesiveText"},
									   $cvrlOuterTopInfo->{"adhesiveThick"},
									   $cvrlOuterTopInfo->{"selective"},
									   dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}

	# LAYER: TOP coverlay
	if ( $stckpMngr->GetExistCvrl("top") ) {

		$self->__DrawCoverlayOuter( $topOuterRows{ BuilderBodyHelper->cvrl },
									$cvrlOuterTopInfo->{"cvrlText"},
									$cvrlOuterTopInfo->{"cvrlThick"},
									$cvrlOuterTopInfo->{"selective"},
									dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}

	# 2) Prepare signal layers
	if($stckpMngr->GetLayerCnt() <= 2){
		
		
	}else{
		
	 foreach my $l  ($stckpMngr->GetStackupLayers()){
	 
	 	
	 
	 
	 }	
		
		
	}



	# Prepare special bottom outer layers
	# Merge slecial outer layers to same row is it is needed
	my %botOuterRows = $self->{"stckpBody"}->BuildRowsStackupOuter("bot");

	# LAYER: BOT SM
	my $maskBotInfo = {};
	if ( $stckpMngr->GetExistSM( "bot", $maskBotInfo ) ) {

		$self->__DrawMatSM( $botOuterRows{ BuilderBodyHelper->sm }, $maskBotInfo->{"color"}, dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}

	# LAYER: BOT FLEX MASK UV
	my $maskFlexBotInfo = {};
	if ( $stckpMngr->GetExistSMFlex( "bot", $maskFlexBotInfo ) ) {

		$self->__DrawMatSMFlex( $botOuterRows{ BuilderBodyHelper->smFlex },
								$maskFlexBotInfo->{"text"},
								$maskFlexBotInfo->{"thick"},
								dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}

	# LAYER: BOT stiffener adhesive
	my $stiffBotInfo = {};
	if ( $stckpMngr->GetExistStiff("bot", $stiffBotInfo) ) {

		$self->__DrawMatStiffAdh( $botOuterRows{ BuilderBodyHelper->stiffAdh },
								  $stiffBotInfo->{"adhesiveText"},
								  $stiffBotInfo->{"adhesiveThick"},
								  dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}

	# 2) Add material rows

	# LAYER: BOT stiffener
	if ( $stckpMngr->GetExistStiff( "bot") ) {

		$self->__DrawMatStiff( $botOuterRows{ BuilderBodyHelper->stiff },
							   $stiffBotInfo->{"stiffText"},
							   $stiffBotInfo->{"stiffThick"},
							   dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}
	
	 # LAYER: BOT coverlay adhesive
	my $cvrlOuterBotInfo = {};
	if ( $stckpMngr->GetExistCvrl("bot", $cvrlOuterBotInfo) ) {

		$self->__DrawCoverlayAdhOuter( $botOuterRows{ BuilderBodyHelper->cvrlAdh },
									   $cvrlOuterBotInfo->{"adhesiveText"},
									   $cvrlOuterBotInfo->{"adhesiveThick"},
									   $cvrlOuterBotInfo->{"selective"},
									   dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}

	# LAYER: Top coverlay
	if ( $stckpMngr->GetExistCvrl("bot") ) {

		$self->__DrawCoverlayOuter( $botOuterRows{ BuilderBodyHelper->cvrl },
									$cvrlOuterBotInfo->{"cvrlText"},
									$cvrlOuterBotInfo->{"cvrlThick"},
									$cvrlOuterBotInfo->{"selective"},
									dclone($txtTitleStyle), dclone($txtStandardStyle) );
	}
	

	# 3) Add gap row below stackup
	$tblMain->AddRowDef( "bodyBotGap", EnumsStyle->RowHeight_STANDARD );

}

sub __DrawMatStiff {
	my $self             = shift;
	my $row              = shift;
	my $matText          = shift;
	my $matThick         = shift;
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
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ), $row->GetIndex(), undef, undef, $matText, $txtTitleStyle );
	}

	# Sec_E_STIFFENER ---------------------------------------------
	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );

	if ( $sec_E_STIFFENER->GetIsActive() ) {

		# stiffener
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matType" ),
						   $row->GetIndex(), undef, undef, "Stiffener", $txtStandardStyle, $stiffBackgStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matThick" ),
						   $row->GetIndex(), undef, undef, int($matThick), $txtStandardStyle, $stiffBackgStyle );

	}

}

sub __DrawMatStiffAdh {
	my $self             = shift;
	my $row              = shift;
	my $matText          = shift;
	my $matThick         = shift;
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

		# adhesive
		#$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ), $row->GetIndex(), undef, undef, $matText, $txtTitleStyle );
	}

	# Sec_E_STIFFENER ---------------------------------------------
	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );

	if ( $sec_E_STIFFENER->GetIsActive() ) {

		# adhesive
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matType" ),
						   $row->GetIndex(), undef, undef, "Adhesive", $txtStandardStyle, $adhesiveBackgStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matThick" ),
						   $row->GetIndex(), undef, undef, int($matThick), $txtStandardStyle, $adhesiveBackgStyle );
	}

}

sub __DrawMatSMFlex {
	my $self             = shift;
	my $row              = shift;
	my $matText          = shift;
	my $matThick         = shift;
	my $txtTitleStyle    = shift;
	my $txtStandardStyle = shift;

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# 1) Define styles
	$txtStandardStyle->SetColor( Color->new( 255, 255, 255 ) );

	my $matBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_SOLDERMASKFLEX ) );

	# Sec_B_FLEX ---------------------------------------------
	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );
	if ( $sec_B_FLEX->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_B_FLEX, -1, 1 );

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matType" ),
						   $row->GetIndex(), undef, undef, "Flexible SM", $txtStandardStyle, $matBackgStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matThick" ),
						   $row->GetIndex(), undef, undef, int($matThick), $txtStandardStyle, $matBackgStyle );
	}

	# Sec_D_FLEXTAIL ---------------------------------------------
	my $sec_D_FLEXTAIL = $secMngr->GetSection( Enums->Sec_D_FLEXTAIL );
	if ( $sec_D_FLEXTAIL->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_D_FLEXTAIL, -1, 0 );

	}
}

sub __DrawCoverlayAdhOuter {
	my $self             = shift;
	my $row              = shift;
	my $matText          = shift;
	my $matThick         = shift;
	my $selective        = shift;
	my $txtTitleStyle    = shift;
	my $txtStandardStyle = shift;

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# 1) Define styles
	$txtStandardStyle->SetColor( Color->new( 0, 0, 0 ) );

	my $matBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_ADHESIVE ) );

	# Sec_BEGIN ---------------------------------------------
	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
	if ( $sec_BEGIN->GetIsActive() ) {

		#$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ), $row->GetIndex(), undef, undef, $matText, $txtTitleStyle );
	}

	# Sec_A_MAIN ---------------------------------------------
	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
	if ( $sec_A_MAIN->GetIsActive() && !$selective ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_A_MAIN, 0, 0 );

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matType" ),
						   $row->GetIndex(), undef, undef, "Adhesive", $txtStandardStyle, $matBackgStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matThick" ),
						   $row->GetIndex(), undef, undef, int($matThick), $txtStandardStyle, $matBackgStyle );
	}

	# $sec_B_FLEX ---------------------------------------------
	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );
	if ( $sec_B_FLEX->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_B_FLEX, -1, 1 );
		if ($selective) {
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matType" ),
							   $row->GetIndex(), undef, undef, "Adhesive", $txtStandardStyle, $matBackgStyle );
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matThick" ),
							   $row->GetIndex(), undef, undef, int($matThick), $txtStandardStyle, $matBackgStyle );
		}

	}

	# Sec_C_RIGIDFLEX ---------------------------------------------
	my $sec_C_RIGIDFLEX = $secMngr->GetSection( Enums->Sec_C_RIGIDFLEX );
	if ( $sec_C_RIGIDFLEX->GetIsActive() && !$selective ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_C_RIGIDFLEX, 0, 0 );

	}

	# Sec_D_FLEXTAIL ---------------------------------------------
	my $sec_D_FLEXTAIL = $secMngr->GetSection( Enums->Sec_D_FLEXTAIL );
	if ( $sec_D_FLEXTAIL->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_D_FLEXTAIL, -1, 0 );
		if ($selective) {
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matType" ),
							   $row->GetIndex(), undef, undef, "Adhesive", $txtStandardStyle, $matBackgStyle );
			$tblMain->AddCell(
				$secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matThick" ),
				$row->GetIndex(), undef, undef, int($matThick), $txtStandardStyle, $matBackgStyle );
		}
	}

	# Sec_E_STIFFENER ---------------------------------------------
	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );

	if ( $sec_E_STIFFENER->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_E_STIFFENER, 0, 0 );
	}

}

sub __DrawCoverlayOuter {
	my $self             = shift;
	my $row              = shift;
	my $matText          = shift;
	my $matThick         = shift;
	my $selective        = shift;
	my $txtTitleStyle    = shift;
	my $txtStandardStyle = shift;

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# 1) Define styles
	$txtStandardStyle->SetColor( Color->new( 0, 0, 0 ) );

	my $matBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_COVERLAY ) );

	# Sec_BEGIN ---------------------------------------------
	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
	if ( $sec_BEGIN->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ), $row->GetIndex(), undef, undef, $matText, $txtTitleStyle );
	}

	# Sec_A_MAIN ---------------------------------------------
	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
	if ( $sec_A_MAIN->GetIsActive() && !$selective ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_A_MAIN, 0, 0 );

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matType" ),
						   $row->GetIndex(), undef, undef, "Coverlay", $txtStandardStyle, $matBackgStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matThick" ),
						   $row->GetIndex(), undef, undef, int($matThick), $txtStandardStyle, $matBackgStyle );
	}

	# $sec_B_FLEX ---------------------------------------------
	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );
	if ( $sec_B_FLEX->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_B_FLEX, -1, 1 );
		if ($selective) {
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matType" ),
							   $row->GetIndex(), undef, undef, "Coverlay", $txtStandardStyle, $matBackgStyle );
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matThick" ),
							   $row->GetIndex(), undef, undef, int($matThick), $txtStandardStyle, $matBackgStyle );
		}

	}

	# Sec_C_RIGIDFLEX ---------------------------------------------
	my $sec_C_RIGIDFLEX = $secMngr->GetSection( Enums->Sec_C_RIGIDFLEX );
	if ( $sec_C_RIGIDFLEX->GetIsActive() && !$selective ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_C_RIGIDFLEX, 0, 0 );

	}

	# Sec_D_FLEXTAIL ---------------------------------------------
	my $sec_D_FLEXTAIL = $secMngr->GetSection( Enums->Sec_D_FLEXTAIL );
	if ( $sec_D_FLEXTAIL->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_D_FLEXTAIL, -1, 0 );
		if ($selective) {
			$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matType" ),
							   $row->GetIndex(), undef, undef, "Coverlay", $txtStandardStyle, $matBackgStyle );
			$tblMain->AddCell(
				$secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matThick" ),
				$row->GetIndex(), undef, undef, int($matThick), $txtStandardStyle, $matBackgStyle );
		}
	}

	# Sec_E_STIFFENER ---------------------------------------------
	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );

	if ( $sec_E_STIFFENER->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_E_STIFFENER, 0, 0 );
	}

}

sub __DrawMatSM {
	my $self             = shift;
	my $row              = shift;
	my $matText          = shift;
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

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ), $row->GetIndex(), undef, undef, $matText, $txtTitleStyle );
	}

	# Sec_A_MAIN ---------------------------------------------
	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
	if ( $sec_A_MAIN->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_A_MAIN, 0, 0 );

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matType" ),
						   $row->GetIndex(), undef, undef, "Solder mask", $txtStandardStyle, $matBackgStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matThick" ),
						   $row->GetIndex(), undef, undef, "25", $txtStandardStyle, $matBackgStyle );
	}

	# Sec_C_RIGIDFLEX ---------------------------------------------
	my $sec_C_RIGIDFLEX = $secMngr->GetSection( Enums->Sec_C_RIGIDFLEX );
	if ( $sec_C_RIGIDFLEX->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_C_RIGIDFLEX, 0, 0 );

	}

	# $sec_B_FLEX ---------------------------------------------
	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );
	if ( $sec_B_FLEX->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_B_FLEX, 0, 0 );

	}

	# Sec_D_FLEXTAIL ---------------------------------------------
	my $sec_D_FLEXTAIL = $secMngr->GetSection( Enums->Sec_D_FLEXTAIL );
	if ( $sec_D_FLEXTAIL->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_D_FLEXTAIL, 0, 0 );
	}

	# Sec_E_STIFFENER ---------------------------------------------
	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );

	if ( $sec_E_STIFFENER->GetIsActive() ) {

		$self->__FillRowBackg( $row, $matBackgStyle, Enums->Sec_E_STIFFENER, 0, 0 );
	}

}

sub __DrawMatCu {
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
	my $endPos   = $secMngr->GetColumnPos( $secType, $colsDef[ scalar(@colsDef) - 1 ]->GetKey() ) + $endColOffset;

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

