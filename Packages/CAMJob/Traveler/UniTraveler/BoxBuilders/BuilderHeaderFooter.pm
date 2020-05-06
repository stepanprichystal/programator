#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::UniTraveler::BoxBuilders::BuilderHeaderFooter;
use base('Packages::CAMJob::Traveler::UniTraveler::BoxBuilders::BoxBuilderBase');

use Class::Interface;
&implements('Packages::CAMJob::Traveler::UniTraveler::BoxBuilders::IBoxBuilder');

#3th party library
use utf8;
use strict;
use warnings;
use POSIX qw(strftime);

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Traveler::UniTraveler::Enums';
use aliased 'Packages::CAMJob::Traveler::UniTraveler::EnumsStyle';
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
	my $self      = shift;
	my $type      = shift;    # header/footer
	my $pageWidth = shift;

	my $inCAM     = $self->{"inCAM"};
	my $jobId     = $self->{"jobId"};
	my $tbl       = $self->{"table"};
	my $travelMngr = $self->{"travelerMngr"};

	# 1) Define columns
	$self->{"table"}->AddColDef( "leftCol",  $pageWidth / 2 );
	$self->{"table"}->AddColDef( "rightCol", $pageWidth / 2 );

	my $cLTxtStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
									 EnumsStyle->TxtSize_NORMAL,
									 Color->new( 0, 0, 0 ),
									 TblDrawEnums->Font_NORMAL, undef,
									 TblDrawEnums->TextHAlign_LEFT,
									 TblDrawEnums->TextVAlign_CENTER, 1 );

	my $cRTxtStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
									 EnumsStyle->TxtSize_NORMAL,
									 Color->new( 0, 0, 0 ),
									 TblDrawEnums->Font_NORMAL, undef,
									 TblDrawEnums->TextHAlign_RIGHT,
									 TblDrawEnums->TextVAlign_CENTER, 1 );

	# 2) Define ROWS + cells
	#my $BACKtmp = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new("255, 0, 0") );
	my $BACKtmp = undef;
	my $row = $tbl->AddRowDef( "text", EnumsStyle->BoxHFRowHeight_TITLE, $BACKtmp );

	if ( $type eq "header" ) {

		my $str = "Technologický postup - lisování";
		$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ), $tbl->GetRowDefPos($row), undef, undef, $str, $cLTxtStyle );
	}
	elsif ( $type eq "footer" ) {

		my $strLeftCol = "Vygenerováno: " . strftime "%d.%m.%Y %H:%M", localtime;
		$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ), $tbl->GetRowDefPos($row), undef, undef, $strLeftCol, $cLTxtStyle );

		my %employyInf = $travelMngr->GetPCBEmployeeInfo();

		my $strRightCol = "TPV: " . $employyInf{"jmeno"} . " " . $employyInf{"prijmeni"};
		$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("rightCol") ), $tbl->GetRowDefPos($row), undef, undef, $strRightCol, $cRTxtStyle );
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
