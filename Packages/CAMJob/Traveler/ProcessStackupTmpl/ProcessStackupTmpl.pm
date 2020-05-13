#-------------------------------------------------------------------------------------------#
# Description: Create single TableDrawing for every lamination
# Each teble drawing is possinle to output with arbotrary  IDrawingBuilder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::ProcessStackupTmpl::ProcessStackupTmpl;

use Class::Interface;
&implements('Packages::CAMJob::Traveler::ITravelerBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::StackupMngr::StackupMngr2V';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::StackupMngr::StackupMngrVV';
use aliased 'Packages::CAMJob::Traveler::ProcessStackupTmpl::ProcessStackupLam';
use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::GeometryHelper';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::Enums' => 'EnumsDrawBldr';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}   = shift;
	$self->{"jobId"}   = shift;
	$self->{"lamType"} = shift;    # Build only specific lam types

	$self->{"step"}              = "panel";
	$self->{"stackupMngr"}       = undef;
	$self->{"processStackupLam"} = [];

	$self->__Init();

	return $self;
}

# Return laout cont for specific PCB
sub LamintaionCnt {
	my $self = shift;

	my $cnt = 0;

	my @allLam = ();

	if ( defined $self->{"stackupMngr"} ) {

		@allLam = $self->{"stackupMngr"}->GetAllLamination( $self->{"lamType"} );
	}

	return scalar(@allLam);
}

# Prepare table drawing for each laminations
sub Build {
	my $self        = shift;
	my $pageWidth   = shift // 210;    # A4 width mm
	my $pageHeight  = shift // 290;    # A4 height mm
	my $tblDrawings = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @allLam = $self->{"stackupMngr"}->GetAllLamination( $self->{"lamType"} );

	# 1) Choose stackup manager
	foreach my $lam (@allLam) {

		my $processLam = ProcessStackupLam->new( $inCAM, $jobId, $lam, $self->{"stackupMngr"} );

		$processLam->Build( $pageWidth, $pageHeight );

		push( @{ $self->{"processStackupLam"} }, $processLam );

	}

	return $result;
}

# Return prepared table drawing
sub GetTblDrawings {
	my $self = shift;

	my @drawings = ();
	push( @drawings, $_->GetTableDrawing() ) foreach ( @{ $self->{"processStackupLam"} } );

	return @drawings;
}

#
#sub Output {
#	my $self        = shift;
#	my $IDrawers    = shift;                                   # Array of drawers (one drawer for one lamination)
#	my $fitInCanvas = shift // 1;
#	my $HAlign      = shift // EnumsDrawBldr->HAlign_MIDDLE;
#	my $VAlign      = shift // EnumsDrawBldr->VAlign_MIDDLE;
#
#	my $result     = 1;
#	my @stackupLam = @{ $self->{"processStackupLam"} };
#
#	die "IDrawers count (" . scalar( @{$IDrawers} ) . ") isn not equal to lamination count (" . scalar(@stackupLam) . ")"
#	  if ( scalar( @{$IDrawers} ) != scalar(@stackupLam) );
#
#	for ( my $i = 0 ; $i < scalar(@stackupLam) ; $i++ ) {
#
#		my $lam     = $stackupLam[$i];
#		my $IDrawer = $IDrawers->[$i];
#		my $tblDraw = $lam->GetTableDrawing();
#
#		my $scaleX = 1;
#		my $scaleY = 1;
#
#		if ($fitInCanvas) {
#			( $scaleX, $scaleY ) = GeometryHelper->ScaleDrawingInCanvasSize( $tblDraw, $IDrawer );
#		}
#
#		my $xOffset = GeometryHelper->HAlignDrawingInCanvasSize( $tblDraw, $IDrawer, $HAlign, $scaleX, $scaleY );
#		my $yOffset = GeometryHelper->VAlignDrawingInCanvasSize( $tblDraw, $IDrawer, $VAlign, $scaleX, $scaleY );
#
#		unless ( $tblDraw->Draw( $IDrawer, $scaleX, $scaleY, $xOffset, $yOffset ) ) {
#
#			print STDERR "Error during build lamination process id:" . $lam->GetLamOrder();
#			$result = 0;
#		}
#	}
#
#	return $result;
#}
#
#

sub __Init {
	my $self = shift;

	my $pcbType = JobHelper->GetPcbType( $self->{"jobId"} );

	# 1) Choose stackup manager

	if (    $pcbType eq EnumsGeneral->PcbType_1VFLEX
		 || $pcbType eq EnumsGeneral->PcbType_2VFLEX )
	{

		$self->{"stackupMngr"} = StackupMngr2V->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );
	}
	elsif (    $pcbType eq EnumsGeneral->PcbType_MULTI
			|| $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXO
			|| $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXI )
	{

		$self->{"stackupMngr"} = StackupMngrVV->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );

	}
	else {

		$self->{"stackupMngr"} = undef;
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

