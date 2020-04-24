
#-------------------------------------------------------------------------------------------#
# Description: Modul is responsible for creation pdf stackup from prepared xml definition
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ProcessStackupPdf::ProcessStackupPdf;

#3th party library
use strict;
use warnings;
use English;
use PDF::API2;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::CAMJob::Stackup::ProcessStackup::ProcessStackup';
use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::PDFDrawing::PDFDrawing';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::Enums' => 'EnumsBuilder';

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

	# 1) Init customer stackup class
	$self->{"processStckp"} = ProcessStackup->new( $self->{"inCAM"}, $self->{"jobId"} );

	return $self;
}

sub GetLaminationExist {
	my $self = shift;

	if ( $self->{"processStckp"}->LamintaionCnt() ) {
		return 1;
	}
	else {
		return 0;
	}

}

sub Create {
	my $self          = shift;
	my $paperWidth    = shift // 210;
	my $paperHeight   = shift // 297;
	my $printerMargin = shift // 6;     # margin of printer
	my $lamType       = shift;          # Build only specific lam type

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 0;

	# 1) Check if there is any laminations
	my $lamCnt = $self->{"processStckp"}->LamintaionCnt($lamType);

	unless ($lamCnt) {
		return $result;
	}

	my $canvasX = $paperWidth - 2 * $printerMargin;
	my $canvasY = $paperHeight - 2 * $printerMargin;

	# 2) Build stackup
	$result = $self->{"processStckp"}->Build( $canvasX, $canvasY, $lamType );

	# 3) Generate output by some drawer

	my @drawBuilders = ();
	my @lamFiles     = ();
	for ( my $i = 0 ; $i < $lamCnt ; $i++ ) {

		my $p = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";
		unlink($p);
		my $pageMargin = 2;
		my $drawBuilder = PDFDrawing->new( TblDrawEnums->Units_MM, $p, undef, [ $canvasX, $canvasY ], $pageMargin );

		push( @drawBuilders, $drawBuilder );
		push( @lamFiles,     $p );
	}

	# Gemerate single laminations

	$self->{"processStckp"}->Output( \@drawBuilders, 1, undef, EnumsBuilder->VAlign_TOP );

	# Merge all togehter

	# the output file
	my $pdf_out = PDF::API2->new( -file => $self->{"outputPath"} );

	my $pagesTotal = 1;

	foreach my $input_file (@lamFiles) {
		my $pdf_in   = PDF::API2->open($input_file);
		my @numpages = ( 1 .. $pdf_in->pages() );

		foreach my $numpage (@numpages) {

			my $page_in  = $pdf_in->openpage($numpage);
			my $page_out = $pdf_out->page(0);

			my @mbox = $page_in->get_mediabox;
			$page_out->mediabox(@mbox);

			my $xo = $pdf_out->importPageIntoForm( $pdf_in, $numpage );

			my $gfx = $page_out->gfx;

			#
			$gfx->formimage(
				$xo,
				0, 0,    # x y
				1
			);

			unlink($input_file);
		}
	}

	$pdf_out->save();

	return $result;
}

sub GetOutputPath {
	my $self = shift;

	return $self->{"outputPath"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Pdf::ProcessStackupPdf::ProcessStackupPdf';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Packages::CAMJob::Stackup::ProcessStackup::Enums' => 'ProcStckpEnums';

	my $inCAM = InCAM->new();

	#my $jobId    = "d152456"; #Outer RigidFLex TOP
	#my $jobId = "d270787";    #Outer RigidFLex BOT

	my $jobId    = "d261919"; # standard vv 10V
	#my $jobId = "d274753"; # standard vv 8V
	#my $jobId = "d274986";    # standard vv 4V
	#my $jobId = "d266566"; # inner flex
	#my $jobId = "d146753"; # 1v flex
	#my $jobId = "d267628" ; # flex 2v + stiff
	#my $jobId = "d064915"; # neplat
	#my $jobId = "d275112"; # standard 1v
	#my $jobId = "d275162"; # standard 2v

	my $stackup = ProcessStackupPdf->new( $inCAM, $jobId );

	if ( $stackup->GetLaminationExist() ) {

		#my $lamType = ProcStckpEnums->LamType_CVRLPRODUCT;
		my $lamType =undef;
		my $resultCreate = $stackup->Create( undef, undef, undef, $lamType );

		if ($resultCreate) {

			$stackup->GetOutputPath();

		}
		else {

			print STDERR "ERROR during stackup";
		}
	}
	else {

		print STDERR "Lamination doesnt exist";
	}

}

1;

