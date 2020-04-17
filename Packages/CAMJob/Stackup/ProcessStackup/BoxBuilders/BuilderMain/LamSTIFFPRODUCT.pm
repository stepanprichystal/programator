#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::ProcessStackup::BoxBuilders::BuilderMain::LamSTIFFPRODUCT;
use base('Packages::CAMJob::Stackup::ProcessStackup::BoxBuilders::BuilderMain::BuilderMainBase');

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
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub Build {
	my $self            = shift;
	my $txtStckpStyle   = shift;
	my $txtStdStyle     = shift;
	my $txtStdBoldStyle = shift;
	my $borderStyle     = shift;

	my $inCAM     = $self->{"inCAM"};
	my $jobId     = $self->{"jobId"};
	my $tbl       = $self->{"table"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $lam       = $self->{"lamination"};

	# Define general styles

	# Pad info
	my $presspadInf = $stckpMngr->GetPresspad5500Info();
	my $releaseInf  = $stckpMngr->GetReleaseFilm1500HTInfo();

	# LAYER: Top presspad

	my $rowPaperTop = $tbl->AddRowDef( "paperPadTop", EnumsStyle->BoxMainRowHeight_MATROW );
	$self->_DrawPad( $rowPaperTop,           Enums->LamPad_PADPAPER, $presspadInf->{"text"},   $presspadInf->{"thick"},
					 dclone($txtStckpStyle), dclone($txtStdStyle),   dclone($txtStdBoldStyle), dclone($borderStyle) );

	$tbl->AddRowDef( "padGap1", EnumsStyle->BoxMainRowHeight_MATGAP );

	# LAYER: Top release film

	my $rowFilmTop = $tbl->AddRowDef( "filmTop", EnumsStyle->BoxMainRowHeight_MATROW );
	$self->_DrawPad( $rowFilmTop,            Enums->LamPad_PADFILM, $releaseInf->{"text"},    $releaseInf->{"thick"},
					 dclone($txtStckpStyle), dclone($txtStdStyle),  dclone($txtStdBoldStyle), dclone($borderStyle) );
	$tbl->AddRowDef( "padGap2", EnumsStyle->BoxMainRowHeight_MATGAP );

	# LAYER: Top Stiffener
	my $stiffTopInfo = {};
	if ( $stckpMngr->GetExistStiff( "top", $stiffTopInfo ) ) {

		my $row = $tbl->AddRowDef( "stiffTop", EnumsStyle->BoxMainRowHeight_MATROW );

		$self->_DrawMatStiff( $row,
							  $stiffTopInfo->{"stiffKind"},
							  $stiffTopInfo->{"stiffText"},
							  $stiffTopInfo->{"stiffThick"},
							  dclone($txtStckpStyle), dclone($txtStdStyle), dclone($txtStdBoldStyle),
							  dclone($borderStyle) );
	}

	# LAYER: top Stiffener adhesive
	if ( $stckpMngr->GetExistStiff("top") ) {

		my $row = $tbl->AddRowDef( "stiffAdhTop", EnumsStyle->BoxMainRowHeight_MATROW );

		$self->_DrawMatStiffAdh( $row,
								 $stiffTopInfo->{"adhesiveKind"},
								 $stiffTopInfo->{"adhesiveText"},
								 $stiffTopInfo->{"adhesiveThick"},
								 dclone($txtStckpStyle), dclone($txtStdStyle), dclone($txtStdBoldStyle),
								 dclone($borderStyle) );
	}

	$tbl->AddRowDef( "matGap1", EnumsStyle->BoxMainRowHeight_MATGAP );

	# LAYER: product
	my $pTopLRow = $tbl->AddRowDef( "productTop", EnumsStyle->BoxMainRowHeight_MATROW );
	my $pMidLRow = $tbl->AddRowDef( "product",    EnumsStyle->BoxMainRowHeight_MATROW );
	my $pBotLRow = $tbl->AddRowDef( "productBot", EnumsStyle->BoxMainRowHeight_MATROW );
	$self->_DrawMatProduct(
							[ $pTopLRow, $pMidLRow,   $pBotLRow ],
							[ "TOP",     "Polotovar", "BOT" ],
							[ "",        "",          "" ],
							[ "",        "",          "" ],
							[ "",        "",          "" ],
							[ "",        "",          "" ],
							dclone($txtStckpStyle),
							dclone($txtStdStyle),
							dclone($txtStdBoldStyle),
							dclone($borderStyle)
	);

	$tbl->AddRowDef( "matGap2", EnumsStyle->BoxMainRowHeight_MATGAP );

	# LAYER: top Stiffener adhesive
	my $stiffBotInfo = {};
	if ( $stckpMngr->GetExistStiff( "bot", $stiffBotInfo ) ) {

		my $row = $tbl->AddRowDef( "stiffAdhBot", EnumsStyle->BoxMainRowHeight_MATROW );

		$self->_DrawMatStiffAdh( $row,
								 $stiffBotInfo->{"adhesiveKind"},
								 $stiffBotInfo->{"adhesiveText"},
								 $stiffBotInfo->{"adhesiveThick"},
								 dclone($txtStckpStyle), dclone($txtStdStyle), dclone($txtStdBoldStyle),
								 dclone($borderStyle) );
	}

	# LAYER: Bot Stiffener

	if ( $stckpMngr->GetExistStiff("bot") ) {

		my $row = $tbl->AddRowDef( "stiffBot", EnumsStyle->BoxMainRowHeight_MATROW );

		$self->_DrawMatStiff( $row,
							  $stiffBotInfo->{"stiffKind"},
							  $stiffBotInfo->{"stiffText"},
							  $stiffBotInfo->{"stiffThick"},
							  dclone($txtStckpStyle), dclone($txtStdStyle), dclone($txtStdBoldStyle),
							  dclone($borderStyle) );
	}

	# LAYER: Bot release film

	$tbl->AddRowDef( "padGap3", EnumsStyle->BoxMainRowHeight_MATGAP );

	my $rowFilmBot = $tbl->AddRowDef( "filmBot", EnumsStyle->BoxMainRowHeight_MATROW );
	$self->_DrawPad( $rowFilmBot,            Enums->LamPad_PADFILM, $releaseInf->{"text"},    $releaseInf->{"thick"},
					 dclone($txtStckpStyle), dclone($txtStdStyle),  dclone($txtStdBoldStyle), dclone($borderStyle) );

	$tbl->AddRowDef( "padGap4", EnumsStyle->BoxMainRowHeight_MATGAP );

	# LAYER: Bot presspad

	my $rowPaperBot = $tbl->AddRowDef( "paperPadBot", EnumsStyle->BoxMainRowHeight_MATROW );
	$self->_DrawPad( $rowPaperBot,           Enums->LamPad_PADPAPER, $presspadInf->{"text"},   $presspadInf->{"thick"},
					 dclone($txtStckpStyle), dclone($txtStdStyle),   dclone($txtStdBoldStyle), dclone($borderStyle) );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

