#-------------------------------------------------------------------------------------------#
# Description:

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::CustStackup;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Stackup::CustStackup::BuilderMngrs::MngrRigidFlex';
use aliased 'Packages::CAMJob::Stackup::CustStackup::BuilderMngrs::Mngr1V';
use aliased 'Packages::Other::TableDrawing::TableDrawing';
use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::GeometryHelper';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::Enums' => 'EnumsDrawBldr';
use aliased 'Packages::CAMJob::Stackup::CustStackup::Section::SectionMngr';
use aliased 'Packages::CAMJob::Stackup::CustStackup::Enums';
use aliased 'Packages::CAMJob::Stackup::CustStackup::EnumsStyle';
use aliased 'Packages::Other::TableDrawing::Table::Style::BorderStyle';
use aliased 'Packages::Other::TableDrawing::Enums'                  => 'TblDrawEnums';
use aliased 'Packages::Other::TableDrawing::Table::Style::Color';
#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}      = shift;
	$self->{"jobId"}      = shift;
	$self->{"tblDrawing"} = TableDrawing->new( TblDrawEnums->Units_MM );

	my $borderStyle = BorderStyle->new();
	$borderStyle->AddEdgeStyle( "top",   TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.2, Color->new( EnumsStyle->Clr_HEADMAINBACK ) );
	$borderStyle->AddEdgeStyle( "bot",   TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.2, Color->new( EnumsStyle->Clr_HEADMAINBACK ) );
	$borderStyle->AddEdgeStyle( "left",  TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.2, Color->new( EnumsStyle->Clr_HEADMAINBACK ) );
	$borderStyle->AddEdgeStyle( "right", TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.2, Color->new( EnumsStyle->Clr_HEADMAINBACK ) );

	$self->{"tblMain"} = $self->{"tblDrawing"}->AddTable("Main", undef, $borderStyle);
	
	$self->{"tblMain"}->{"renderOrderEvt"}->Add(sub { $self->__OnRenderPriorityHndl(@_) } );
	return $self;
}

sub Build {
	my $self = shift;

	# 2) Choose proper stackup builder
	my $builderMngr = undef;

	my $pcbType = JobHelper->GetPcbType( $self->{"jobId"} );

	if (    $pcbType eq EnumsGeneral->PcbType_NOCOPPER
		 || $pcbType eq EnumsGeneral->PcbType_1V
		 || $pcbType eq EnumsGeneral->PcbType_1VFLEX
		 || $pcbType eq EnumsGeneral->PcbType_2V
		 || $pcbType eq EnumsGeneral->PcbType_2VFLEX )
	{

		$builderMngr = Mngr1V->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"tblMain"} );
	}

	#	elsif (    $pcbType eq EnumsGeneral->PcbType_2V
	#			|| $pcbType eq EnumsGeneral->PcbType_2VFLEX )
	#	{
	#
	#		$builderMngr = BuilderMngr2V->new();
	#	}
	#	elsif (    $pcbType eq EnumsGeneral->PcbType_MULTI
	#			|| $pcbType eq EnumsGeneral->PcbType_2VFLEX )
	#	{
	#
	#		$builderMngr = BuilderMngrVV->new();
	#	}
	elsif (    $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXO
			|| $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXI
			|| $pcbType eq EnumsGeneral->PcbType_MULTI )
	{

		$builderMngr = MngrRigidFlex->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"tblMain"} );
	}
	else {

		die "Unknow type of pcb" . $pcbType;
	}

	# 3) Define section style by builder and init sectiopn columns

	my $secMngr = SectionMngr->new();

	$builderMngr->BuildSections($secMngr);
	$builderMngr->BuildBlocks($secMngr);
}

sub Output {
	my $self        = shift;
	my $IDrawer     = shift;
	my $fitInCanvas = shift // 1;
	my $HAlign      = shift // EnumsDrawBldr->HAlign_MIDDLE;
	my $VAlign      = shift // EnumsDrawBldr->VAlign_MIDDLE;

	my $result = 1;

	my $scaleX = 1;
	my $scaleY = 1;

	if ($fitInCanvas) {
		( $scaleX, $scaleY ) = GeometryHelper->ScaleDrawingInCanvasSize( $self->{"tblDrawing"}, $IDrawer );
	}

	my $xOffset = GeometryHelper->HAlignDrawingInCanvasSize( $self->{"tblDrawing"}, $IDrawer, $HAlign, $scaleX, $scaleY );
	my $yOffset = GeometryHelper->VAlignDrawingInCanvasSize( $self->{"tblDrawing"}, $IDrawer, $VAlign, $scaleX, $scaleY );

	$result = $self->{"tblDrawing"}->Draw( $IDrawer, $scaleX, $scaleY, $xOffset, $yOffset );

	return $result;
}


# Set object (borders, backgrounds,...) render priority
sub __OnRenderPriorityHndl{
	my $self = shift;
	my $priority = shift;
	
	
	 $priority->{TblDrawEnums->DrawPriority_COLLBORDER} = 100;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

