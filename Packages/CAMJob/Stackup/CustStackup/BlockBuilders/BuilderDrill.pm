
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::BlockBuilders::BuilderDrill;
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
use aliased 'Packages::Other::TableDrawing::Table::Style::TextStyle';
use aliased 'Packages::Other::TableDrawing::Table::Style::Color';
use aliased 'Packages::Other::TableDrawing::Table::Style::BackgStyle';
use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';
use aliased 'Packages::CAMJob::Stackup::CustStackup::BlockBuilders::BuilderThickHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"helper"} = BuilderThickHelper->new( $self->{"stackupMngr"}, $self->{"sectionMngr"} );

	return $self;
}

sub Build {
	my $self = shift;
	$self->__BuildHeadRow();

	$self->__BuildDrillRow();

}

sub __BuildHeadRow {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# Define first title row
	my $rowBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_HEADSUBBACK ) );
	my $row = $tblMain->AddRowDef( "drill_head", EnumsStyle->RowHeight_STANDARD, $rowBackgStyle );

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
						   undef, undef, "Plated drill", $txtStyle, undef );
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

sub __BuildDrillRow {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	my @NC = $stckpMngr->GetPlatedNC();

	# Define first title row
	my $rowBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_HEADSUBBACK ) );
	my $row = $tblMain->AddRowDef( "drill_layers", ( scalar(@NC) / 3 + 1 ) * EnumsStyle->RowHeight_STANDARD );
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
						   undef, undef, "Description", $txtStyle );

	}

	# Sec_A_MAIN ---------------------------------------------
	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
	if ( $sec_A_MAIN->GetIsActive() ) {

		my $posX = $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matType" );
		my $cellLen = $secMngr->GetColumnCnt(1) - $posX - 1;

		my @letters = ( "A" .. "Z" );
		my @NCtxt   = ();
		foreach my $ncL (@NC) {

			my $start = $ncL->{"gROWdrl_dir"} eq "bot2top" ? $ncL->{"NCSigEndOrder"}   : $ncL->{"NCSigStartOrder"};
			my $end   = $ncL->{"gROWdrl_dir"} eq "bot2top" ? $ncL->{"NCSigStartOrder"} : $ncL->{"NCSigEndOrder"};

			my $let = shift @letters;

			my $type = undef;

			$type = "through"        if ( $ncL->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill );
			$type = "filled through" if ( $ncL->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill );
			$type = "blind"          if ( $ncL->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop );
			$type = "filled blind"   if ( $ncL->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillTop );
			$type = "blind"          if ( $ncL->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot );
			$type = "filled blind"   if ( $ncL->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillBot );
			$type = "burried"        if ( $ncL->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill );
			$type = "filled burried" if ( $ncL->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cFillDrill );

			die "Unknow NC layer type: " . $ncL->{"type"} if ( !defined $type );

			push( @NCtxt, $let . " = $type L$start-L$end" );
		}

		my $NCTxt = "";
		for ( my $i = 0 ; $i < scalar(@NCtxt) ; $i++ ) {

			$NCTxt .= $NCtxt[$i] . ( $i <= scalar(@NCtxt) - 2 ? "; " : "" ) . ( ( $i + 1 ) % 3 == 0 ? "\n" : "" );
		}

		my $NCTextStyle = TextStyle->new( TblDrawEnums->TextStyle_MULTILINE,
										  EnumsStyle->TxtSize_STANDARD,
										  Color->new( 0, 0, 0 ),
										  undef, undef,
										  TblDrawEnums->TextHAlign_LEFT,
										  TblDrawEnums->TextVAlign_CENTER );

		$tblMain->AddCell( $posX, $tblMain->GetRowDefPos($row), $cellLen, undef, $NCTxt, $NCTextStyle );
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

