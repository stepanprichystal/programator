#-------------------------------------------------------------------------------------------#
# Description:

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::ProcessStackup::ProcessStackup;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Stackup::ProcessStackup::StackupMngr::StackupMngr2V';
use aliased 'Packages::CAMJob::Stackup::ProcessStackup::StackupMngr::StackupMngrVV';
use aliased 'Packages::CAMJob::Stackup::ProcessStackup::ProcessStackupLam';

#use aliased 'Packages::CAMJob::Stackup::CustStackup::BuilderMngrs::MngrRigidFlex';
#use aliased 'Packages::CAMJob::Stackup::CustStackup::BuilderMngrs::MngrVV';
#use aliased 'Packages::CAMJob::Stackup::CustStackup::BuilderMngrs::Mngr2V';
#use aliased 'Packages::Other::TableDrawing::TableDrawing';
use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::GeometryHelper';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::Enums' => 'EnumsDrawBldr';

#use aliased 'Packages::CAMJob::Stackup::CustStackup::Section::SectionMngr';
#use aliased 'Packages::CAMJob::Stackup::CustStackup::Enums';
#use aliased 'Packages::CAMJob::Stackup::CustStackup::EnumsStyle';
#use aliased 'Packages::Other::TableDrawing::Table::Style::BorderStyle';
#use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';
#use aliased 'Packages::Other::TableDrawing::Table::Style::Color';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"step"}              = "panel";
	$self->{"stackupMngr"}       = undef;
	$self->{"processStackupLam"} = [];

	$self->__Init();

	return $self;
}

sub LamintaionCnt {
	my $self = shift;

	my $cnt = 0;

	if ( defined $self->{"stackupMngr"} ) {

		$cnt = scalar( $self->{"stackupMngr"}->GetAllLamination() );
	}

	return $cnt;

}

# Return number of lamination
sub Build {
	my $self = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @allLam = $self->{"stackupMngr"}->GetAllLamination();

	# 1) Choose stackup manager
	foreach my $lam (@allLam) {

		my $processLam = ProcessStackupLam->new( $inCAM, $jobId, $lam, $self->{"stackupMngr"} );

		$processLam->Build();

		push( @{ $self->{"processStackupLam"} }, $processLam );

	}

	return $result;
}

sub Output {
	my $self        = shift;
	my $IDrawers    = shift;                                   # Array of drawers (one drawer for one lamination)
	my $fitInCanvas = shift // 1;
	my $HAlign      = shift // EnumsDrawBldr->HAlign_MIDDLE;
	my $VAlign      = shift // EnumsDrawBldr->VAlign_MIDDLE;

	my $result     = 1;
	my @stackupLam = @{ $self->{"processStackupLam"} };

	die "IDrawers count (" . scalar( @{$IDrawers} ) . ") isn not equal to lamination count (" . scalar(@stackupLam) . ")"
	  if ( scalar( @{$IDrawers} ) != scalar(@stackupLam) );
	  

	for ( my $i = 0 ; $i < scalar(@stackupLam) ; $i++ ) {

		my $lam     = $stackupLam[$i];
		my $IDrawer = $IDrawers->[$i];
		my $tblDraw = $lam->GetTableDrawing();

		my $scaleX = 1;
		my $scaleY = 1;

		if ($fitInCanvas) {
			( $scaleX, $scaleY ) = GeometryHelper->ScaleDrawingInCanvasSize( $tblDraw, $IDrawer );
		}

		my $xOffset = GeometryHelper->HAlignDrawingInCanvasSize( $tblDraw, $IDrawer, $HAlign, $scaleX, $scaleY );
		my $yOffset = GeometryHelper->VAlignDrawingInCanvasSize( $tblDraw, $IDrawer, $VAlign, $scaleX, $scaleY );

		unless ( $tblDraw->Draw( $IDrawer, $scaleX, $scaleY, $xOffset, $yOffset ) ) {

			print STDERR "Error during build lamination process id:" . $lam->GetLamOrder();
			$result = 0;
		}

	}
	return $result;
}

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

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

