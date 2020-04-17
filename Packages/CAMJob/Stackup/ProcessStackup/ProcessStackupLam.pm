#-------------------------------------------------------------------------------------------#
# Description:

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::ProcessStackup::ProcessStackupLam;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'Enums::EnumsGeneral';

use aliased 'Packages::CAMJob::Stackup::ProcessStackup::BoxBuilders::BuilderHeaderFooter';
use aliased 'Packages::CAMJob::Stackup::ProcessStackup::BoxBuilders::BuilderTitle';
use aliased 'Packages::CAMJob::Stackup::ProcessStackup::BoxBuilders::BuilderMain';
use aliased 'Packages::CAMJob::Stackup::ProcessStackup::BoxBuilders::BuilderInfo';
use aliased 'Packages::Other::TableDrawing::TableDrawing';
use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';

use aliased 'Packages::CAMJob::Stackup::ProcessStackup::EnumsStyle';
use aliased 'Packages::Other::TableDrawing::Table::Style::BorderStyle';
use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';
use aliased 'Packages::Other::TableDrawing::Table::Style::Color';

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
	my $self = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Define border style for all tables
	my $borderStyle = BorderStyle->new();
	$borderStyle->AddEdgeStyle( "top",   TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.1, Color->new( EnumsStyle->Clr_BOXBORDER ) );
	$borderStyle->AddEdgeStyle( "bot",   TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.1, Color->new( EnumsStyle->Clr_BOXBORDER ) );
	$borderStyle->AddEdgeStyle( "left",  TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.1, Color->new( EnumsStyle->Clr_BOXBORDER ) );
	$borderStyle->AddEdgeStyle( "right", TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.1, Color->new( EnumsStyle->Clr_BOXBORDER ) );

	# Build all boxes (each box has own table)
	my %o = ( "x" => 0, "y" => 0 );    # origin of boxes

	# BOX Header
	my $headerTbl = $self->{"tblDrawing"}->AddTable( "Header", \%o );
	$headerTbl->{"renderOrderEvt"}->Add( sub { $self->__OnRenderPriorityHndl(@_) } );
	my $builderHeader = BuilderHeaderFooter->new( $inCAM, $jobId, $self->{"lamination"}, $self->{"stackupMngr"}, $headerTbl );
	$builderHeader->Build("header");

	# BOX Title
	my %oTitle = %o;
	$oTitle{"y"} += $headerTbl->GetHeight() + EnumsStyle->BoxSpace_SIZE;
	my $titleTbl = $self->{"tblDrawing"}->AddTable( "Title", \%oTitle, $borderStyle );
	$titleTbl->{"renderOrderEvt"}->Add( sub { $self->__OnRenderPriorityHndl(@_) } );
	my $builderTitle = BuilderTitle->new( $inCAM, $jobId, $self->{"lamination"}, $self->{"stackupMngr"}, $titleTbl );
	$builderTitle->Build();

	# BOX Main
	my %oMain = %oTitle;
	$oMain{"y"} += $titleTbl->GetHeight() + EnumsStyle->BoxSpace_SIZE;
	my $mainTbl = $self->{"tblDrawing"}->AddTable( "Main", \%oMain, $borderStyle );
	$mainTbl->{"renderOrderEvt"}->Add( sub { $self->__OnRenderPriorityHndl(@_) } );
	my $builderMain = BuilderMain->new( $inCAM, $jobId, $self->{"lamination"}, $self->{"stackupMngr"}, $mainTbl );
	$builderMain->Build();

	# BOX Info
	my %oInfo = %oMain;
	$oInfo{"x"} += $mainTbl->GetWidth() + EnumsStyle->BoxSpace_SIZE;
	my $infoTbl = $self->{"tblDrawing"}->AddTable( "Info", \%oInfo, $borderStyle );
	$infoTbl->{"renderOrderEvt"}->Add( sub { $self->__OnRenderPriorityHndl(@_) } );
	my $builderInfo = BuilderInfo->new( $inCAM, $jobId, $self->{"lamination"}, $self->{"stackupMngr"}, $infoTbl );
	$builderInfo->Build();

	# BOX Footer
	my %oFooter = %oMain;
	$oFooter{"y"} += $mainTbl->GetHeight() + EnumsStyle->BoxSpace_SIZE;
	my $footerTbl = $self->{"tblDrawing"}->AddTable( "Footer", undef );
	$footerTbl->{"renderOrderEvt"}->Add( sub { $self->__OnRenderPriorityHndl(@_) } );
	my $builderFooter = BuilderHeaderFooter->new( $inCAM, $jobId, $self->{"lamination"}, $self->{"stackupMngr"}, $footerTbl );
	$builderFooter->Build("footer");

	return $result;
}

sub GetTableDrawing {
	my $self = shift;

	return $self->{"tblDrawing"};
}

# Set object (borders, backgrounds,...) render priority
sub __OnRenderPriorityHndl {
	my $self     = shift;
	my $priority = shift;

	$priority->{ TblDrawEnums->DrawPriority_COLLBACKG } = 1;
	$priority->{ TblDrawEnums->DrawPriority_ROWBACKG }  = 2;
	$priority->{ TblDrawEnums->DrawPriority_CELLBACKG } = 3;

	$priority->{ TblDrawEnums->DrawPriority_COLLBORDER } = 4;
	$priority->{ TblDrawEnums->DrawPriority_ROWBORDER }  = 5;
	$priority->{ TblDrawEnums->DrawPriority_TABBORDER }  = 6;
	$priority->{ TblDrawEnums->DrawPriority_CELLBORDER } = 7;
	$priority->{ TblDrawEnums->DrawPriority_CELLTEXT }   = 8;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

