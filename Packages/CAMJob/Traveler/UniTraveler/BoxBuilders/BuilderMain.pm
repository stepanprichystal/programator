#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::UniTraveler::BoxBuilders::BuilderMain;
use base('Packages::CAMJob::Traveler::UniTraveler::BoxBuilders::BoxBuilderBase');

use Class::Interface;
&implements('Packages::CAMJob::Traveler::UniTraveler::BoxBuilders::IBoxBuilder');

#3th party library
use utf8;
use strict;
use warnings;
use Time::localtime;
use Storable qw(dclone);
use List::Util qw(first);

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Traveler::UniTraveler::Enums';
use aliased 'Packages::CAMJob::Traveler::UniTraveler::EnumsStyle';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::TextStyle';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::Color';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::BackgStyle';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::BorderStyle';
use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';
use aliased 'Packages::CAMJob::Traveler::UniTraveler::BoxBuilders::BuilderMainHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"builderHelper"} = BuilderMainHelper->new( $self->{"table"} );

	return $self;
}

sub Build {
	my $self = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $tbl         = $self->{"table"};
	my $stackupMngr = $self->{"travelerMngr"};
	my $traveler    = $self->{"traveler"};

	# 1) Define columns
	$tbl->AddColDef( "leftMargin", EnumsStyle->BoxMainClmnWidth_MARGIN );
	$tbl->AddColDef( "mainColl",   EnumsStyle->BoxMainClmnWidth_TEXT );
	$tbl->AddColDef( "signColl",   EnumsStyle->BoxMainClmnWidth_SIGN );

	# 2) Build title row
	$self->__BuildStckpTitle();

	$self->__BuildStckpBody();

}

sub __BuildStckpTitle {
	my $self = shift;
	my $tbl  = $self->{"table"};

	# Define border style for all tables
	my $borderStyle = BorderStyle->new();
	$borderStyle->AddEdgeStyle( "left", TblDrawEnums->EdgeStyle_SOLIDSTROKE, EnumsStyle->Border_THICK, Color->new( EnumsStyle->Clr_BOXBORDER ) );

	my $borderRowStyle = BorderStyle->new();
	$borderRowStyle->AddEdgeStyle( "bot", TblDrawEnums->EdgeStyle_SOLIDSTROKE, EnumsStyle->Border_THICK, Color->new( EnumsStyle->Clr_BOXBORDER ) );

	# 2) Define ROWS
	#my $BACKtmp = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new("255, 100, 50") );
	my $BACKtmp = undef;
	$tbl->AddRowDef( "titleBody", EnumsStyle->BoxMainRowHeight_TITLE, $BACKtmp, $borderRowStyle );

	# 3) Define cells

	my $txtStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
								   EnumsStyle->TxtSize_NORMAL,
								   Color->new( 0, 0, 0 ),
								   TblDrawEnums->Font_BOLD, undef,
								   TblDrawEnums->TextHAlign_LEFT,
								   TblDrawEnums->TextVAlign_CENTER, 1 );

	# Mat type
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("mainColl") ), 0, undef, undef, "Operace", $txtStyle );

	# Mat ID
	$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("signColl") ), 0, undef, undef, "Datum a podpis", $txtStyle, undef, $borderStyle );

}

sub __BuildStckpBody {
	my $self = shift;

	my $tbl      = $self->{"table"};
	my $traveler = $self->{"traveler"};

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1) Define styles
	my $txtStckpStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
										EnumsStyle->TxtSize_NORMAL,
										Color->new( 255, 255, 255 ),
										undef, undef,
										TblDrawEnums->TextHAlign_LEFT,
										TblDrawEnums->TextVAlign_CENTER, 0.5 );
	my $txtStdStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
									  EnumsStyle->TxtSize_NORMAL,
									  Color->new( 0, 0, 0 ),
									  undef, undef,
									  TblDrawEnums->TextHAlign_LEFT,
									  TblDrawEnums->TextVAlign_CENTER, 0.5 );
	my $txtStdBoldStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
										  EnumsStyle->TxtSize_NORMAL,
										  Color->new( 0, 0, 0 ),
										  undef, undef,
										  TblDrawEnums->TextHAlign_LEFT,
										  TblDrawEnums->TextVAlign_CENTER, 0.5 );

	my $borderStyle = BorderStyle->new();
	$borderStyle->AddEdgeStyle( "bot", TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.3, Color->new( EnumsStyle->Clr_BOXBORDERLIGHT ) );

	# 2) Add all operations
	my @operations = $traveler->GetAllOperations();
	for ( my $i = 0 ; < scalar(@operations) ; $i++ ) {

		my $o = $operations[$i];

		my $row1 = $tbl->AddRowDef( "oper" . $i . "_row1", EnumsStyle->BoxHFRowHeight_TITLE );
		my $row2 = $tbl->AddRowDef( "oper" . $i . "_row2", EnumsStyle->BoxHFRowHeight_TITLE );

		$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("leftCol") ), $tbl->GetRowDefPos($row1), undef, undef, $o->GetName(), $txtLCollStyle );
		$tbl->AddCell( $tbl->GetCollDefPos( $tbl->GetCollByKey("rightCol") ), $tbl->GetRowDefPos($row2), undef, undef, $o->GetInfo(),
					   $txtRCollStyle );
	}

}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

