#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for building lamination prescription
# bz specific type of lamination

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::ProcessStackupTmpl::ProcessStackupLam;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::Enums';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::BoxBuilders::BuilderHeaderFooter';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::BoxBuilders::BuilderTitle';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::BoxBuilders::BuilderMain';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::BoxBuilders::BuilderMatList';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::BoxBuilders::BuilderInfo';
use aliased 'Packages::Other::TableDrawing::TableDrawing';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::EnumsStyle';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::BorderStyle';
use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::Color';

use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::LamItemBuilders::BuilderSTIFFPRODUCT';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::LamItemBuilders::BuilderTAPEFLEXPRODUCT';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::LamItemBuilders::BuilderCVRLBASE';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::LamItemBuilders::BuilderCVRLPRODUCT';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::LamItemBuilders::BuilderFLEXBASE';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::LamItemBuilders::BuilderRIGIDFINAL';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::LamItemBuilders::BuilderORIGIDFLEXFINAL';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::LamItemBuilders::BuilderIRIGIDFLEXFINAL';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::LamItemBuilders::BuilderMULTIPRODUCT';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::LamItemBuilders::BuilderRIGIDBASE';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}       = shift;
	$self->{"jobId"}       = shift;
	$self->{"lamination"}  = shift;
	$self->{"stackupMngr"} = shift;

	$self->{"tblDrawing"} = TableDrawing->new( TblDrawEnums->Units_MM );

	return $self;
}

sub Build {
	my $self       = shift;
	my $pageWidth  = shift;    # A4 width mm
	my $pageHeight = shift;    # A4 height mm

	$self->__BuildStackupItems();

	$self->__BuildBoxes( $pageWidth, $pageHeight );
}

# Build lamination instruction structure by lamination type
sub __BuildStackupItems {
	my $self = shift;

	my $result = 1;

	my $lam       = $self->{"lamination"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $inCAM     = $self->{"inCAM"};
	my $jobId     = $self->{"jobId"};

	# 1) Pick proper builder

	my $itemBldr = undef;
	if ( $lam->GetLamType() eq Enums->LamType_STIFFPRODUCT ) {

		$itemBldr = BuilderSTIFFPRODUCT->new( $inCAM, $jobId );
	}
	elsif ( $lam->GetLamType() eq Enums->LamType_TAPEPRODUCT ) {

		$itemBldr = BuilderTAPEFLEXPRODUCT->new( $inCAM, $jobId );
	}
	elsif ( $lam->GetLamType() eq Enums->LamType_CVRLBASE ) {

		$itemBldr = BuilderCVRLBASE->new( $inCAM, $jobId );
	}
	elsif ( $lam->GetLamType() eq Enums->LamType_CVRLPRODUCT ) {

		$itemBldr = BuilderCVRLPRODUCT->new( $inCAM, $jobId, $lam, $stckpMngr );
	}
	elsif ( $lam->GetLamType() eq Enums->LamType_RIGIDBASE ) {

		$itemBldr = BuilderRIGIDBASE->new( $inCAM, $jobId );
	}
	elsif ( $lam->GetLamType() eq Enums->LamType_FLEXBASE ) {

		$itemBldr = BuilderFLEXBASE->new( $inCAM, $jobId, $lam, $stckpMngr );
	}
	elsif ( $lam->GetLamType() eq Enums->LamType_RIGIDFINAL ) {

		$itemBldr = BuilderRIGIDFINAL->new( $inCAM, $jobId, $lam, $stckpMngr );

	}
	elsif ( $lam->GetLamType() eq Enums->LamType_ORIGIDFLEXFINAL ) {

		$itemBldr = BuilderORIGIDFLEXFINAL->new( $inCAM, $jobId, $lam, $stckpMngr );

	}
	elsif ( $lam->GetLamType() eq Enums->LamType_IRIGIDFLEXFINAL ) {

		$itemBldr = BuilderIRIGIDFLEXFINAL->new( $inCAM, $jobId, $lam, $stckpMngr );
	}

	$result = $itemBldr->Build( $lam, $stckpMngr ) if ( defined $itemBldr );

	return $result;
}

# Phzsic drawing of lamination instruction to TableDrawing
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
	my $builderHeader = BuilderHeaderFooter->new( $inCAM, $jobId, $self->{"lamination"}, $self->{"stackupMngr"}, $headerTbl );
	$builderHeader->Build( "header", $pageWidth );

	# BOX Title
	my %oTitle = %o;
	$oTitle{"y"} += $headerTbl->GetHeight() + EnumsStyle->BoxSpace_SIZE;
	my $titleTbl = $self->{"tblDrawing"}->AddTable( "Title", \%oTitle, $borderStyle );
	$titleTbl->SetRenderPriority( $self->__GetRenderPriority() );
	my $builderTitle = BuilderTitle->new( $inCAM, $jobId, $self->{"lamination"}, $self->{"stackupMngr"}, $titleTbl );
	$builderTitle->Build($pageWidth);

	# BOX Main
	my %oMain = %oTitle;
	$oMain{"y"} += $titleTbl->GetHeight() + EnumsStyle->BoxSpace_SIZE;
	my $mainTbl = $self->{"tblDrawing"}->AddTable( "Main", \%oMain, $borderStyle );
	$mainTbl->SetRenderPriority( $self->__GetRenderPriority() );
	my $builderMain = BuilderMain->new( $inCAM, $jobId, $self->{"lamination"}, $self->{"stackupMngr"}, $mainTbl );
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
	my $builderMatList = BuilderMatList->new( $inCAM, $jobId, $self->{"lamination"}, $self->{"stackupMngr"}, $matListTbl );
	$builderMatList->Build($boxYEndPos);

	# BOX Info
	my %oInfo = %oMain;
	$oInfo{"x"} += $mainTbl->GetWidth() + EnumsStyle->BoxSpace_SIZE;
	my $infoTbl = $self->{"tblDrawing"}->AddTable( "Info", \%oInfo, $borderStyle );
	$infoTbl->SetRenderPriority( $self->__GetRenderPriority() );
	my $builderInfo = BuilderInfo->new( $inCAM, $jobId, $self->{"lamination"}, $self->{"stackupMngr"}, $infoTbl );
	$builderInfo->Build( $boxXEndPos, $matListTbl->GetOrigin()->{"y"} + $matListTbl->GetHeight() );

	# BOX Footer
	my %oFooter = %oMatList;
	$oFooter{"y"} += $matListTbl->GetHeight() + EnumsStyle->BoxSpace_SIZE;
	my $footerTbl = $self->{"tblDrawing"}->AddTable( "Footer", \%oFooter );
	$footerTbl->SetRenderPriority( $self->__GetRenderPriority() );
	my $builderFooter = BuilderHeaderFooter->new( $inCAM, $jobId, $self->{"lamination"}, $self->{"stackupMngr"}, $footerTbl );
	$builderFooter->Build( "footer", $pageWidth );

	return $result;
}

sub GetTableDrawing {
	my $self = shift;

	return $self->{"tblDrawing"};
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

