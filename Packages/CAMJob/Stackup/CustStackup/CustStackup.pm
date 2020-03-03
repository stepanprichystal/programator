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
	$self->{"tblMain"}    = $self->{"tblDrawing"}->AddTable("Main");
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
			|| $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXI )
	{

		$builderMngr = MngrRigidFlex->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"tblMain"} );
	}
	else {

		die "Unknow type of pcb" . $pcbType;
	}

	# 3) Define section style by builder and init sectiopn columns

	my $secMngr = $self->__GetSectionMngr();
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

sub __GetSectionMngr {
	my $self = shift;

	my $secMngr = SectionMngr->new();

	my $colCont = 0;

	#	my %stles = ();
	#			   Section_BEGIN       => "section_begin",          # Begining of table with material text
	#			   Section_A_MAIN      => "section_A_Main",         # Main stackup section with layer names and drilling
	#			   Section_B_FLEX      => "section_B_Flex",         # Flex part of RigidFlex pcb
	#			   Section_C_RIGIDFLEX => "section_C_RigidFlex",    # Second Rigid part of RigidFLex
	#			   Section_D_FLEXTAIL  => "section_D_FlexTail",     # Flexible tail of rigid flex section
	#			   Section_E_STIFFENER => "section_E_STIFFENER",    # Flex with stiffeners
	#			   Section_END         => "section_end"             # End of table

	# Section_BEGIN

	my $secBEGIN = $secMngr->AddSection( Enums->Section_BEGIN );
	$secBEGIN->AddColumn( "matTitle", 23 );
	$secBEGIN->AddColumn( "cuUsage",  10 );

	# Section_A_MAIN

	my $secA_MAIN = $secMngr->AddSection( Enums->Section_A_MAIN );
	$secA_MAIN->AddColumn( "leftEdge",  1.6 );    # left margin
	$secA_MAIN->AddColumn( "matType",   16 );     # material type
	$secA_MAIN->AddColumn( "matThick",  12 );     # material type
	$secA_MAIN->AddColumn( "rightEdge", 1.6 );    # left margin

	# Section_B_FLEX

	my $sec_B_FLEX = $secMngr->AddSection( Enums->Section_B_FLEX );
	$sec_B_FLEX->AddColumn( "matType",  1.6 );    # left margin
	$sec_B_FLEX->AddColumn( "matThick", 16 );     # material type

	# Section_C_RIGIDFLEX

	my $sec_C_RIGIDFLEX = $secMngr->AddSection( Enums->Section_C_RIGIDFLEX );
	$sec_C_RIGIDFLEX->AddColumn( "leftEdge",  1.6 );    # left margin
	$sec_C_RIGIDFLEX->AddColumn( "middle",    16 );     # material type
	$sec_C_RIGIDFLEX->AddColumn( "rightEdge", 1.6 );    # left margin

	return $secMngr;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

