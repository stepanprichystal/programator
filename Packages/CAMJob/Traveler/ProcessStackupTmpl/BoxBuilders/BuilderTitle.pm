#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::ProcessStackupTmpl::BoxBuilders::BuilderTitle;
use base('Packages::CAMJob::Traveler::ProcessStackupTmpl::BoxBuilders::BoxBuilderBase');

use Class::Interface;
&implements('Packages::CAMJob::Traveler::ProcessStackupTmpl::BoxBuilders::IBoxBuilder');

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::Enums';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::EnumsStyle';
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
	my $pageWidth = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $tbl         = $self->{"table"};
	my $stackupMngr = $self->{"stackupMngr"};

	# 1) Define columns
	 
	$tbl->AddColDef( "leftMargin",  EnumsStyle->ClmnWidth_margin);
	$tbl->AddColDef( "col1Text",   EnumsStyle->BoxTitleClmnWidth_1 );
	$tbl->AddColDef( "col1Val",    EnumsStyle->BoxTitleClmnWidth_2 );
	$tbl->AddColDef( "col2Text",   EnumsStyle->BoxTitleClmnWidth_3 );
	$tbl->AddColDef( "col2Val",   $pageWidth -   $tbl->GetWidth() );

	# 2) Define ROWS
	#my $BACKtmp = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new("255, 100, 0") );
	my $BACKtmp = undef;
	$tbl->AddRowDef( "row1", EnumsStyle->BoxTitleRowHeight_STD, $BACKtmp );
	$tbl->AddRowDef( "row2", EnumsStyle->BoxTitleRowHeight_STD, $BACKtmp );
	$tbl->AddRowDef( "row3", EnumsStyle->BoxTitleRowHeight_STD, $BACKtmp );

	# 3) Define cells

	my $txtStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
								   EnumsStyle->TxtSize_NORMAL,
								   Color->new( 0, 0, 0 ),
								   TblDrawEnums->Font_NORMAL, undef,
								   TblDrawEnums->TextHAlign_RIGHT,
								   TblDrawEnums->TextVAlign_CENTER, 1 );
	
		my $txtRedStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
								   EnumsStyle->TxtSize_SMALL,
								   Color->new( 204, 0, 0 ),
								   TblDrawEnums->Font_NORMAL, undef,
								   TblDrawEnums->TextHAlign_RIGHT,
								   TblDrawEnums->TextVAlign_CENTER, 1 );
								   
	my $txtValStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
									  EnumsStyle->TxtSize_NORMAL,
									  Color->new( 0, 0, 0 ),
									  TblDrawEnums->Font_NORMAL, undef,
									  TblDrawEnums->TextHAlign_LEFT,
									  TblDrawEnums->TextVAlign_CENTER, 1 );
	my $txtStylePcbId = TextStyle->new( TblDrawEnums->TextStyle_LINE,
										EnumsStyle->TxtSize_PCBID, Color->new( 0, 0, 0 ),
										TblDrawEnums->Font_BOLD, undef,
										TblDrawEnums->TextHAlign_LEFT,
										TblDrawEnums->TextVAlign_CENTER, 1 );

	# Pcb number
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("col1Text") ), 0, undef, undef, "C??slo zak??zky:", $txtStyle );
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("col1Val") ), 0, undef, undef, uc($stackupMngr->GetOrderId()), $txtStylePcbId );

	# PCB name
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("col1Text") ), 1, undef, undef, "N??zev desky:", $txtStyle );
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("col1Val") ), 1, undef, undef, $stackupMngr->GetPCBName(), $txtValStyle );

	# PCB customer
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("col1Text") ), 2, undef, undef, "Z??kazn??k:", $txtStyle );
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("col1Val") ), 2, undef, undef, $stackupMngr->GetCustomerName(), $txtValStyle );

	# Date
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("col2Text") ), 0, undef, undef, "Datum:", $txtStyle );
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("col2Val") ), 0, undef, undef, $stackupMngr->GetOrderDate(), $txtValStyle );

	# Date
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("col2Text") ), 1, undef, undef, "Term??n:", $txtStyle );
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("col2Val") ), 1, undef, undef, $stackupMngr->GetOrderTerm(), $txtValStyle );
	
	# Date control
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("col2Val") ), 2, undef, undef, "Datumy jsou p??edb????n??, ov???? spr??vnost na hlavn??m postupu!", $txtRedStyle );
	#$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("col1Val") ), 2, undef, undef, $stackupMngr->GetCustomerName(), $txtValStyle );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

