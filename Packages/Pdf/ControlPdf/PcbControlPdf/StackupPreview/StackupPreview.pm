
#-------------------------------------------------------------------------------------------#
# Description: Load stackup xml, create pdf preview and from preview create/cut image of stackup
# return Image of stackup
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::PcbControlPdf::StackupPreview::StackupPreview;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Pdf::StackupPdf::StackupPdf';
use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAMJob::Stackup::CustStackup::CustStackup';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::PDFDrawing::PDFDrawing';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::Enums' => 'EnumsBuilder';
use aliased 'Packages::Other::TableDrawing::Enums'                  => 'TblDrawEnums';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";

	return $self;
}

sub Create {
	my $self    = shift;
	my $message = shift;

	my $result = 1;

	# 1) Init customer stackup class
	my $custStckp = CustStackup->new( $self->{"inCAM"}, $self->{"jobId"} );

	# 2) Build stackup
	unless ( $custStckp->Build() ) {
		$result = 0;
		$$message .= "Error when create stackup preview. Build stackup preview failed";
	}

	# 3) Generate output by pdf drawer

	# Page size is A4

	my $a4W = 210;    # width in mm
	my $a4H = 290;    # height mm

	# Stackup rotation by real stackup preview dimension
	# if stackup width is more than 130% stackup height AND stackup real width is more than 130% A4 widtt => rotate
	my ( $w, $h ) = $custStckp->GetSize();
	my $rotation = $h * 1.3 < $w && $w > $a4W ? 270  : undef;
	my $canvasX  = $rotation                  ? $a4H : $a4W;
	my $canvasY  = $rotation                  ? $a4W : $a4H;
	my $margin = 15;    # 15 mm margin of whole page

	unlink( $self->{"outputPath"} );
	my $drawBuilder = PDFDrawing->new( TblDrawEnums->Units_MM, $self->{"outputPath"}, undef, [ $canvasX, $canvasY ], $margin, $rotation );

	#my $drawBuilder = PDFDrawing->new( TblDrawEnums->Units_MM, undef, $p, [$canvasX, $canvasY], $margin, $rotation );

	# Gemerate output
	
		my $HAlign      =   EnumsBuilder->HAlign_MIDDLE;
	my $VAlign      =  EnumsBuilder->VAlign_MIDDLE;

	unless ( $custStckp->Output($drawBuilder, 1, $HAlign, $VAlign) ) {
		$result = 0;
		$$message .= "Error when create stackup preview. Generate pdf preview failed";
	}

	return $result;
}

sub GetOutput {
	my $self = shift;

	return $self->{"outputPath"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

