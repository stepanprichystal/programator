
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::BlockBuilders::BuilderThick;
use base('Packages::CAMJob::Stackup::CustStackup::BlockBuilders::BlockBuilderBase');

use Class::Interface;
&implements('Packages::CAMJob::Stackup::CustStackup::BlockBuilders::IBlockBuilder');

#3th party library
use strict;
use warnings;

#use File::Copy;

#local library
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

	$self->__BuildThickRows();

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
	my $row = $tblMain->AddRowDef( "thick_head", EnumsStyle->RowHeight_STANDARD, $rowBackgStyle );

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
						   undef, undef, "Stackup thickness", $txtStyle );
	}

	# Sec_A_MAIN ---------------------------------------------
	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
	if ( $sec_A_MAIN->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "leftEdge" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, undef, undef, undef, $borderStyle );

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matThick" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, "Thickness", $txtStyle, undef, );

	}

	# Sec_B_FLEX ---------------------------------------------
	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );
	if ( $sec_B_FLEX->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matType" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, undef, undef, undef, $borderStyle );

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matThick" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, "Thickness", $txtStyle );
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

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matThick" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, "Thickness", $txtStyle );
	}

	# Sec_E_STIFFENER ---------------------------------------------
	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );

	if ( $sec_E_STIFFENER->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matType" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, undef, undef, undef, $borderStyle );

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matThick" ),
						   $tblMain->GetRowDefPos($row),
						   undef, undef, "Thickness", $txtStyle );
	}
	
		# Sec_END
	my $sec_END = $secMngr->GetSection( Enums->Sec_END );

	if ( $sec_END->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_END, "end" ),
						   $tblMain->GetRowDefPos($row),
						  undef,
						   undef, undef, $txtStyle, undef, $borderStyle );

	}

}

sub __BuildThickRows {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# Define first title row
	my $rowBackgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_HEADSUBBACK ) );
	my $rowComp = $tblMain->AddRowDef( "real_thick",    EnumsStyle->RowHeight_STANDARD );
	my $rowReq  = $tblMain->AddRowDef( "request_thick", EnumsStyle->RowHeight_STANDARD );

	my $txtStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
								   EnumsStyle->TxtSize_TITLE, Color->new( 0, 0, 0 ),
								   undef, undef,
								   TblDrawEnums->TextHAlign_LEFT,
								   TblDrawEnums->TextVAlign_CENTER );

	# Sec_BEGIN ---------------------------------------------
	my $sec_BEGIN = $secMngr->GetSection( Enums->Sec_BEGIN );
	if ( $sec_BEGIN->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ),
						   $tblMain->GetRowDefPos($rowComp),
						   undef, undef, "Computed", $txtStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_BEGIN, "matTitle" ),
						   $tblMain->GetRowDefPos($rowReq),
						   undef, undef, "Requested", $txtStyle );
	}

	# Sec_A_MAIN ---------------------------------------------
	my $sec_A_MAIN = $secMngr->GetSection( Enums->Sec_A_MAIN );
	if ( $sec_A_MAIN->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matThick" ),
						   $tblMain->GetRowDefPos($rowComp),
						   undef, undef, $self->{"helper"}->GetCompThickness( Enums->Sec_A_MAIN ), $txtStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "matThick" ),
						   $tblMain->GetRowDefPos($rowReq),
						   undef, undef, $self->{"helper"}->GetReqThickness( Enums->Sec_A_MAIN ), $txtStyle );

	}

	# Sec_B_FLEX ---------------------------------------------
	my $sec_B_FLEX = $secMngr->GetSection( Enums->Sec_B_FLEX );
	if ( $sec_B_FLEX->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matThick" ),
						   $tblMain->GetRowDefPos($rowComp),
						   undef, undef, $self->{"helper"}->GetCompThickness( Enums->Sec_B_FLEX ), $txtStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_B_FLEX, "matThick" ),
						   $tblMain->GetRowDefPos($rowReq),
						   undef, undef, $self->{"helper"}->GetReqThickness( Enums->Sec_B_FLEX ), $txtStyle );
	}

	# Sec_D_FLEXTAIL ---------------------------------------------
	my $sec_D_FLEXTAIL = $secMngr->GetSection( Enums->Sec_D_FLEXTAIL );
	if ( $sec_D_FLEXTAIL->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matThick" ),
						   $tblMain->GetRowDefPos($rowComp),
						   undef, undef, $self->{"helper"}->GetCompThickness( Enums->Sec_D_FLEXTAIL ), $txtStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_D_FLEXTAIL, "matThick" ),
						   $tblMain->GetRowDefPos($rowReq),
						   undef, undef, $self->{"helper"}->GetReqThickness( Enums->Sec_D_FLEXTAIL ), $txtStyle );
	}

	# Sec_E_STIFFENER ---------------------------------------------
	my $sec_E_STIFFENER = $secMngr->GetSection( Enums->Sec_E_STIFFENER );

	if ( $sec_E_STIFFENER->GetIsActive() ) {

		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matThick" ),
						   $tblMain->GetRowDefPos($rowComp),
						   undef, undef, $self->{"helper"}->GetCompThickness( Enums->Sec_E_STIFFENER ), $txtStyle );
		$tblMain->AddCell( $secMngr->GetColumnPos( Enums->Sec_E_STIFFENER, "matThick" ),
						   $tblMain->GetRowDefPos($rowReq),
						   undef, undef, $self->{"helper"}->GetReqThickness( Enums->Sec_E_STIFFENER ), $txtStyle );
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

