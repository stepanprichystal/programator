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
use aliased 'Packages::CAMJob::Stackup::CustStackup::BuilderMngrs::MngrVV';
use aliased 'Packages::CAMJob::Stackup::CustStackup::BuilderMngrs::Mngr2V';
use aliased 'Packages::Other::TableDrawing::TableDrawing';
use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::GeometryHelper';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::Enums' => 'EnumsDrawBldr';
use aliased 'Packages::CAMJob::Stackup::CustStackup::Section::SectionMngr';
use aliased 'Packages::CAMJob::Stackup::CustStackup::Enums';
use aliased 'Packages::CAMJob::Stackup::CustStackup::EnumsStyle';
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

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift // "panel";

	$self->{"tblDrawing"} = TableDrawing->new( TblDrawEnums->Units_MM );

	my $borderStyle = BorderStyle->new();
	$borderStyle->AddEdgeStyle( "top",   TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.3, Color->new( EnumsStyle->Clr_SECTIONBORDER ) );
	$borderStyle->AddEdgeStyle( "bot",   TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.3, Color->new( EnumsStyle->Clr_SECTIONBORDER ) );
	$borderStyle->AddEdgeStyle( "left",  TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.3, Color->new( EnumsStyle->Clr_SECTIONBORDER ) );
	$borderStyle->AddEdgeStyle( "right", TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.3, Color->new( EnumsStyle->Clr_SECTIONBORDER ) );

	$self->{"tblMain"} = $self->{"tblDrawing"}->AddTable( "Main", undef, $borderStyle );

	$self->{"tblMain"}->{"renderOrderEvt"}->Add( sub { $self->__OnRenderPriorityHndl(@_) } );
	return $self;
}

sub Build {
	my $self = shift;

	my $result = 1;

	# 2) Choose proper stackup builder
	my $builderMngr = undef;

	my $pcbType = JobHelper->GetPcbType( $self->{"jobId"} );

	if (    $pcbType eq EnumsGeneral->PcbType_NOCOPPER
		 || $pcbType eq EnumsGeneral->PcbType_1V
		 || $pcbType eq EnumsGeneral->PcbType_1VFLEX
		 || $pcbType eq EnumsGeneral->PcbType_2V
		 || $pcbType eq EnumsGeneral->PcbType_2VFLEX )
	{

		$builderMngr = Mngr2V->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, $self->{"tblMain"} );
	}
	elsif ( $pcbType eq EnumsGeneral->PcbType_MULTI ) {

		$builderMngr = MngrVV->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, $self->{"tblMain"} );

	}
	elsif (    $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXO
			|| $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXI )
	{

		$builderMngr = MngrRigidFlex->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, $self->{"tblMain"} );
	}
	else {

		die "Unknow type of pcb" . $pcbType;
	}

	# 3) Define section style by builder and init sectiopn columns

	my $secMngr = SectionMngr->new();

	unless ( $builderMngr->BuildSections($secMngr) ) {
		$result = 0;
	}
	unless ( $builderMngr->BuildBlocks($secMngr) ) {
		$result = 0;
	}
	
	return $result;
}

sub GetSize {
	my $self = shift;

	my %tblLim = $self->{"tblDrawing"}->GetOriLimits();

	my $w = abs( $tblLim{"xMax"} - $tblLim{"xMin"} );
	my $h = abs( $tblLim{"yMax"} - $tblLim{"yMin"} );

	return ( $w, $h );
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
sub __OnRenderPriorityHndl {
	my $self     = shift;
	my $priority = shift;

	$priority->{ TblDrawEnums->DrawPriority_COLLBORDER } = 1;
	$priority->{ TblDrawEnums->DrawPriority_COLLBACKG }  = 2;
	$priority->{ TblDrawEnums->DrawPriority_ROWBACKG }   = 3;
}

# DrawPriority_TABBORDER  => "DrawPriority_TABBORDER",     # table frame
#			   DrawPriority_COLLBACKG  => "DrawPriority_COLLBACKG",     # column background
#			   DrawPriority_COLLBORDER => "DrawPriority_COLLBORDER",    # column border
#			   DrawPriority_ROWBACKG   => "DrawPriority_ROWBACKG",      # row background
#			   DrawPriority_ROWBORDER  => "DrawPriority_ROWBORDER",     # row border
#			   DrawPriority_CELLBACKG  => "DrawPriority_CELLBACKG",     # cell background
#			   DrawPriority_CELLBORDER => "DrawPriority_CELLBORDER",    # cell border
#			   DrawPriority_CELLTEXT   => "DrawPriority_CELLTEXT",      # cell text

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

