#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::ProcessStackup::BoxBuilders::BuilderHeaderFooter;
use base('Packages::CAMJob::Stackup::ProcessStackup::BoxBuilders::BoxBuilderBase');

use Class::Interface;
&implements('Packages::CAMJob::Stackup::ProcessStackup::BoxBuilders::IBoxBuilder');

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Stackup::ProcessStackup::Enums';
use aliased 'Packages::CAMJob::Stackup::ProcessStackup::EnumsStyle';
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
	my $tbl   = $self->{"table"};

	# 1) Define columns
	$self->{"table"}->AddColDef( "leftMargin", EnumsStyle->ClmnWidth_margin );

	my $c1TxtStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
									 EnumsStyle->TxtSize_NORMAL,
									 Color->new( 0, 0, 0 ),
									 TblDrawEnums->Font_NORMAL, undef,
									 TblDrawEnums->TextHAlign_LEFT,
									 TblDrawEnums->TextVAlign_CENTER, 1 );

	# 2) Define ROWS + cells
	my $BACKtmp = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( "255, 0, 0") );
 	$tbl->AddRowDef( "text", EnumsStyle->RowHeight_STD, $BACKtmp  );
 	
	my $str = "Technologický postup - lisování";
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftMargin") ), 0, undef, undef, $str, $c1TxtStyle );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
