#-------------------------------------------------------------------------------------------#
# Description: Create single TableDrawing for every lamination
# Each teble drawing is possinle to output with arbotrary  IDrawingBuilder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::UniTravelerTmpl::UniTravelerSingle;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'Enums::EnumsGeneral';

use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::GeometryHelper';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::Enums' => 'EnumsDrawBldr';
use aliased 'Packages::CAMJob::Traveler::UniTravelerTmpl::TravelerData::Traveler';
use aliased 'Packages::Other::TableDrawing::TableDrawing';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::BorderStyle';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::Color';
use aliased 'Packages::CAMJob::Traveler::UniTravelerTmpl::BoxBuilders::BuilderHeaderFooter';
use aliased 'Packages::CAMJob::Traveler::UniTravelerTmpl::BoxBuilders::BuilderTitle';
use aliased 'Packages::CAMJob::Traveler::UniTravelerTmpl::BoxBuilders::BuilderMain';
use aliased 'Packages::CAMJob::Traveler::UniTravelerTmpl::BoxBuilders::BuilderInfo';
use aliased 'Packages::CAMJob::Traveler::UniTravelerTmpl::EnumsStyle';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}         = shift;
	$self->{"jobId"}         = shift;
	$self->{"travelerMngr"}  = shift;
	$self->{"ITravelerBldr"} = shift;
	my $order = shift;    # tarveler page order

	$self->{"travelerData"} = Traveler->new($order);
	$self->{"tblDrawing"}   = TableDrawing->new( TblDrawEnums->Units_MM );

	return $self;
}

# Prepare table drawing for each laminations
sub Build {
	my $self       = shift;
	my $pageWidth  = shift // 210;    # A4 width mm
	my $pageHeight = shift // 290;    # A4 height mm

	my $result = 1;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1) Build traveler operation and info boxes
	$self->__BuildTrevelerData();

	# 1) Build physic structure with table drawings
	$self->__BuildBoxes( $pageWidth, $pageHeight );

	return $result;
}

# Return prepared table drawing
sub GetTblDrawing {
	my $self = shift;

	return $self->{"tblDrawing"};
}

sub __BuildTrevelerData {
	my $self   = shift;
	my $result = 1;

	my $ITravelerBldr = $self->{"ITravelerBldr"};
	my $traveler      = $self->{"travelerData"};

	# 1) Build traveler general
	unless ( $ITravelerBldr->BuildTraveler($traveler) ) {
		$result = 0;
	}

	# 2) Build operations
	unless ( $ITravelerBldr->BuildOperations($traveler) ) {
		$result = 0;
	}

	# 3) Build info boxes
	unless ( $ITravelerBldr->BuildInfoBoxes($traveler) ) {
		$result = 0;
	}

	return $result;
}

sub __BuildBoxes {
	my $self       = shift;
	my $pageWidth  = shift;    # A4 width mm
	my $pageHeight = shift;    # A4 height mm

	my $result = 1;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Define border style for all tables
	my $borderStyle = BorderStyle->new();
	$borderStyle->AddEdgeStyle( "top",   TblDrawEnums->EdgeStyle_SOLIDSTROKE, EnumsStyle->Border_THICK, Color->new( EnumsStyle->Clr_BOXBORDER ) );
	$borderStyle->AddEdgeStyle( "bot",   TblDrawEnums->EdgeStyle_SOLIDSTROKE, EnumsStyle->Border_THICK, Color->new( EnumsStyle->Clr_BOXBORDER ) );
	$borderStyle->AddEdgeStyle( "left",  TblDrawEnums->EdgeStyle_SOLIDSTROKE, EnumsStyle->Border_THICK, Color->new( EnumsStyle->Clr_BOXBORDER ) );
	$borderStyle->AddEdgeStyle( "right", TblDrawEnums->EdgeStyle_SOLIDSTROKE, EnumsStyle->Border_THICK, Color->new( EnumsStyle->Clr_BOXBORDER ) );

	# Build all boxes (each box has own table)
	my %o = ( "x" => 0, "y" => 0 );    # origin of boxes

	# BOX Header
	my $headerTbl = $self->{"tblDrawing"}->AddTable( "Header", \%o );
	$headerTbl->SetRenderPriority( $self->__GetRenderPriority() );
	my $builderHeader = BuilderHeaderFooter->new( $inCAM, $jobId, $self->{"travelerData"}, $self->{"travelerMngr"}, $headerTbl );
	$builderHeader->Build( "header", $pageWidth );

	# BOX Title
	my %oTitle = %o;
	$oTitle{"y"} += $headerTbl->GetHeight() + EnumsStyle->BoxSpace_SIZE;
	my $titleTbl = $self->{"tblDrawing"}->AddTable( "Title", \%oTitle, $borderStyle );
	$titleTbl->SetRenderPriority( $self->__GetRenderPriority() );
	my $builderTitle = BuilderTitle->new( $inCAM, $jobId, $self->{"travelerData"}, $self->{"travelerMngr"}, $titleTbl );
	$builderTitle->Build($pageWidth);

	# Compute, where boxes MatList + Info should end
	# Add special row "extender" which stretch table to bottom edge of page
	my $boxYEndPos = $pageHeight - EnumsStyle->BoxHFRowHeight_TITLE - EnumsStyle->BoxSpace_SIZE;
	my $boxXEndPos = $pageWidth;

	# BOX Main
	my %oMain = %oTitle;
	$oMain{"y"} += $titleTbl->GetHeight() + EnumsStyle->BoxSpace_SIZE;
	my $mainTbl = $self->{"tblDrawing"}->AddTable( "Main", \%oMain, $borderStyle );
	$mainTbl->SetRenderPriority( $self->__GetRenderPriority() );
	my $builderMain = BuilderMain->new( $inCAM, $jobId, $self->{"travelerData"}, $self->{"travelerMngr"}, $mainTbl );
	$builderMain->Build($boxYEndPos);

	# BOX Info
	my %oInfo = %oMain;
	$oInfo{"x"} += $mainTbl->GetWidth() + EnumsStyle->BoxSpace_SIZE;
	my $infoTbl = $self->{"tblDrawing"}->AddTable( "Info", \%oInfo, $borderStyle );
	$infoTbl->SetRenderPriority( $self->__GetRenderPriority() );
	my $builderInfo = BuilderInfo->new( $inCAM, $jobId, $self->{"travelerData"}, $self->{"travelerMngr"}, $infoTbl );
	$builderInfo->Build( $boxXEndPos, $mainTbl->GetOrigin()->{"y"} + $mainTbl->GetHeight() );

	# BOX Footer
	my %oFooter = %oMain;
	$oFooter{"y"} += $mainTbl->GetHeight() + EnumsStyle->BoxSpace_SIZE;
	my $footerTbl = $self->{"tblDrawing"}->AddTable( "Footer", \%oFooter );
	$footerTbl->SetRenderPriority( $self->__GetRenderPriority() );
	my $builderFooter = BuilderHeaderFooter->new( $inCAM, $jobId, $self->{"travelerData"}, $self->{"travelerMngr"}, $footerTbl );
	$builderFooter->Build( "footer", $pageWidth );

	return $result;
}

# Set object (borders, backgrounds,...) render priority
sub __GetRenderPriority {
	my $self = shift;

	my $priority = {};

	$priority->{ TblDrawEnums->DrawPriority_COLLBACKG } = 1;
	$priority->{ TblDrawEnums->DrawPriority_ROWBACKG }  = 2;
	$priority->{ TblDrawEnums->DrawPriority_CELLBACKG } = 3;

	$priority->{ TblDrawEnums->DrawPriority_COLLBORDER } = 4;
	$priority->{ TblDrawEnums->DrawPriority_ROWBORDER }  = 5;
	$priority->{ TblDrawEnums->DrawPriority_TABBORDER }  = 6;
	$priority->{ TblDrawEnums->DrawPriority_CELLBORDER } = 7;
	$priority->{ TblDrawEnums->DrawPriority_CELLTEXT }   = 8;

	return $priority;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

