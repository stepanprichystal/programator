#-------------------------------------------------------------------------------------------#
# Description: Create single TableDrawing for every lamination
# Each teble drawing is possinle to output with arbotrary  IDrawingBuilder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::UniTraveler::UniTraveler;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Traveler::UniTraveler::TravelerMngr';
use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::GeometryHelper';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::Enums' => 'EnumsDrawBldr';
use aliased 'Packages::CAMJob::Traveler::UniTraveler::TravelerData::Traveler';
use aliased 'Packages::Other::TableDrawing::TableDrawing';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::BorderStyle';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::Color';
use aliased 'Packages::CAMJob::Stackup::ProcessStackupTempl::BoxBuilders::BuilderHeaderFooter';
use aliased 'Packages::CAMJob::Stackup::ProcessStackupTempl::BoxBuilders::BuilderTitle';
use aliased 'Packages::CAMJob::Stackup::ProcessStackupTempl::BoxBuilders::BuilderMain';
use aliased 'Packages::CAMJob::Stackup::ProcessStackupTempl::BoxBuilders::BuilderMatList';
use aliased 'Packages::CAMJob::Stackup::ProcessStackupTempl::BoxBuilders::BuilderInfo';
use aliased 'Packages::CAMJob::Stackup::ProcessStackupTempl::EnumsStyle';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}            = shift;
	$self->{"jobId"}            = shift;
	$self->{"ITravelerBuilder"} = shift;

	$self->{"step"} = "panel";

	$self->{"travelerData"} = Traveler->new();
	$self->{"travelerMngr"} = TravelerMngr->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );
	$self->{"tblDrawings"}  = [ TableDrawing->new( TblDrawEnums->Units_MM ) ];

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
	$self->__BuildBoxes();

	return $result;
}

# Return prepared table drawing
sub GetTblDrawings {
	my $self = shift;

	die "Taveler was not build" unless ( scalar( @{$self->{"tblDrawings"}} ));

	return @{ $self->{"tblDrawings"} };
}

sub __BuildTrevelerData {
	my $self   = shift;
	my $result = 1;

	my $ITravelerBldr = $self->{"ITravelerBuilder"};
	my $traveler      = $self->{"travelerData"};

	# 1) Add "default" boxes

	# 2) Build operations
	if ( $ITravelerBldr->BuildOperations($traveler) ) {

	}
	else {
		$result = 0;
	}

	# 3) Build info boxes
	if ( $ITravelerBldr->BuildInfoBoxes($traveler) ) {

	}
	else {
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

	# BOX Main
	my %oMain = %oTitle;
	$oMain{"y"} += $titleTbl->GetHeight() + EnumsStyle->BoxSpace_SIZE;
	my $mainTbl = $self->{"tblDrawing"}->AddTable( "Main", \%oMain, $borderStyle );
	$mainTbl->SetRenderPriority( $self->__GetRenderPriority() );
	my $builderMain = BuilderMain->new( $inCAM, $jobId, $self->{"travelerData"}, $self->{"travelerMngr"}, $mainTbl );
	$builderMain->Build();

	# Compute, where boxes MatList + Info should end
	# Add special row "extender" which stretch table to bottom edge of page
	my $boxYEndPos = $pageHeight - EnumsStyle->BoxHFRowHeight_TITLE - EnumsStyle->BoxSpace_SIZE;
	my $boxXEndPos = $pageWidth;

	# BOX mat list
	my %oMatList = %oMain;
	$oMatList{"y"} += $mainTbl->GetHeight() + EnumsStyle->BoxSpace_SIZE;
	my $matListTbl = $self->{"tblDrawing"}->AddTable( "MatList", \%oMatList, $borderStyle );
	$matListTbl->SetRenderPriority( $self->__GetRenderPriority() );
	my $builderMatList = BuilderMatList->new( $inCAM, $jobId, $self->{"travelerData"}, $self->{"travelerMngr"}, $matListTbl );
	$builderMatList->Build($boxYEndPos);

	# BOX Info
	my %oInfo = %oMain;
	$oInfo{"x"} += $mainTbl->GetWidth() + EnumsStyle->BoxSpace_SIZE;
	my $infoTbl = $self->{"tblDrawing"}->AddTable( "Info", \%oInfo, $borderStyle );
	$infoTbl->SetRenderPriority( $self->__GetRenderPriority() );
	my $builderInfo = BuilderInfo->new( $inCAM, $jobId, $self->{"travelerData"}, $self->{"travelerMngr"}, $infoTbl );
	$builderInfo->Build( $boxXEndPos, $matListTbl->GetOrigin()->{"y"} + $matListTbl->GetHeight() );

	# BOX Footer
	my %oFooter = %oMatList;
	$oFooter{"y"} += $matListTbl->GetHeight() + EnumsStyle->BoxSpace_SIZE;
	my $footerTbl = $self->{"tblDrawing"}->AddTable( "Footer", \%oFooter );
	$footerTbl->SetRenderPriority( $self->__GetRenderPriority() );
	my $builderFooter = BuilderHeaderFooter->new( $inCAM, $jobId, $self->{"travelerData"}, $self->{"travelerMngr"}, $footerTbl );
	$builderFooter->Build( "footer", $pageWidth );

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

