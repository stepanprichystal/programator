
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

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	# Define first title row
	my $rowTitleBackg = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( 192, 0, 0 ) );
	$tblMain->AddRowDef( "row_title", 25, $rowTitleBackg );

	# Add title
	my $titleStr = "";

	my $pcbType = $stckpMngr->GetPcbType();

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

	if ( $pcbType eq EnumsGeneral->PcbType_MULTI ) {
		$titleStr .= "Multi layer PCB";
	}

	if ( $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXO ) {
		$titleStr .= "Outer RigidFlex";
	}

	if ( $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXI ) {
		$titleStr .= "Inner RigidFlex";
	}

	# Add job Id

	$titleStr .= "; " . uc($jobId);

	# CELL DEF: Add left cell with title

	my $c1TxtStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
									 3, Color->new( 200, 200, 200 ),
									 undef, undef,
									 TblDrawEnums->TextHAlign_LEFT,
									 TblDrawEnums->TextVAlign_CENTER );

	my $secBegin = $secMngr->GetSection( Enums->Section_BEGIN );

	$tblMain->AddCell( 0, 0, $secBegin->GetColumnCnt() + 1, undef, $titleStr, $c1TxtStyle );

	# CELL DEF: Add right cell with date

	my $c2TxtStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
									 3, Color->new( 200, 200, 200 ),
									 undef, undef,
									 TblDrawEnums->TextHAlign_RIGHT,
									 TblDrawEnums->TextVAlign_CENTER );

	my $c2xStart = $secBegin->GetColumnCnt() + 1;
	my $c2xpos   = $secMngr->GetColumnCnt() - 1 - $c2xStart;

	my $date = sprintf "%02.f.%02.f.%04.f", localtime->mday(), ( localtime->mon() + 1 ), ( localtime->year() + 1900 );
	my $c2Str = "Date:" . $date;

	  $tblMain->AddCell( $c2xStart, 0, $c2xpos, undef, $c2Str, $c2TxtStyle );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

