
#-------------------------------------------------------------------------------------------#
# Description: Special notes regarding stackup
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::BlockBuilders::BuilderNote;
use base('Packages::CAMJob::Stackup::CustStackup::BlockBuilders::BlockBuilderBase');

use Class::Interface;
&implements('Packages::CAMJob::Stackup::CustStackup::BlockBuilders::IBlockBuilder');

#3th party library
use strict;
use warnings;

#use File::Copy;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Stackup::CustStackup::Enums';
use aliased 'Packages::CAMJob::Stackup::CustStackup::EnumsStyle';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::TextStyle';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::Color';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::BackgStyle';
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
	$self->__BuildHeadRow();

	$self->__BuildNotesStiffRow();

}

sub __BuildHeadRow {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# Define first title row
	my $rowGap = $tblMain->AddRowDef( "note_gap",   EnumsStyle->RowHeight_BLOCKGAP );
	my $rowBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_HEADSUBBACK ) );
	my $row = $tblMain->AddRowDef( "note_head", EnumsStyle->RowHeight_STANDARD, $rowBackgStyle );

	my $txtStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
								   EnumsStyle->TxtSize_TITLE, Color->new( 0, 0, 0 ),
								   undef, undef,
								   TblDrawEnums->TextHAlign_LEFT,
								   TblDrawEnums->TextVAlign_CENTER );

	my $borderStyle = $self->{"secBorderStyle"};

	# Sec_BEGIN ---------------------------------------------
	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
	if ( $sec_BEGIN->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, "Special notes",
						   $txtStyle, undef );
	}

	# Sec_A_MAIN ---------------------------------------------
	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
	if ( $sec_A_MAIN->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "leftEdge" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, undef, undef, undef, $borderStyle );
	}

	# Sec_B_FLEX ---------------------------------------------
	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );
	if ( $sec_B_FLEX->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matType" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, undef, undef, undef, $borderStyle );

	}

	# Sec_C_RIGIDFLEX ---------------------------------------------
	my $sec_C_RIGIDFLEX = $secMngr->GetSection( Enums->Sec_C_RIGIDFLEX );
	if ( $sec_C_RIGIDFLEX->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_C_RIGIDFLEX, "leftEdge" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, undef, undef, undef, $borderStyle );

	}

	# Sec_D_FLEXTAIL ---------------------------------------------
	my $sec_D_FLEXTAIL = $secMngr->GetSection( Enums->Sec_D_FLEXTAIL );
	if ( $sec_D_FLEXTAIL->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matType" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, undef, undef, undef, $borderStyle );

	}

	# Sec_E_STIFFENER ---------------------------------------------
	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );

	if ( $sec_E_STIFFENER->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matType" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, undef, undef, undef, $borderStyle );

	}

	# Sec_END
	my $sec_END = $secMngr->GetSection( Enums->Sec_END );

	if ( $sec_END->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_END, "end" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, undef, $txtStyle, undef, $borderStyle );

	}

}

sub __BuildNotesStiffRow {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	my @allStiffThickness = $stckpMngr->GetAllRequestedStiffThick();

	# Define first title row

	my $txt = "List of all customer requested final thickness\non different stiffener areas: ";
	$txt.= "\n" if(scalar(@allStiffThickness) > 2);
	$txt .= join( "; ", map { $_."µm"} @allStiffThickness );
 

	my $rowBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_HEADSUBBACK ) );
	my $row = $tblMain->AddRowDef( "stiff_pcb_thick", (scalar(@allStiffThickness) > 2? 3 : 2) * EnumsStyle->RowHeight_STANDARD );
	my $txtStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
								   EnumsStyle->TxtSize_TITLE, Color->new( 0, 0, 0 ),
								   undef, undef,
								   TblDrawEnums->TextHAlign_LEFT,
								   TblDrawEnums->TextVAlign_CENTER );

	# Sec_BEGIN ---------------------------------------------
	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
	if ( $sec_BEGIN->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, "* Note", $txtStyle );

	}

	# Sec_A_MAIN ---------------------------------------------
	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
	if ( $sec_A_MAIN->GetIsActive() ) {

		my $posX = $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matType" );
		my $cellLen = $secMngr->GetColumnCnt(1) - $posX - 1;

		my $NCTextStyle = TextStyle->new( TblDrawEnums->TextStyle_MULTILINE,
										  EnumsStyle->TxtSize_STANDARD,
										  Color->new( 0, 0, 0 ),
										  undef, undef,
										  TblDrawEnums->TextHAlign_LEFT,
										  TblDrawEnums->TextVAlign_CENTER );

		$tblMain->AddCell( $posX, $tblMain->GetRowDefPos($row), $cellLen, undef, $txt, $NCTextStyle );
	}
 
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

