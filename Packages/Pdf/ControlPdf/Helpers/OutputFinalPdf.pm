#-------------------------------------------------------------------------------------------#
# Description: Merge together, stackup, preview top bot, preview single
# Add red stripes to each pages + titles
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::Helpers::OutputFinalPdf;

#3th party library
use utf8;
use threads;
use strict;
use warnings;
use PDF::API2;
use CAM::PDF;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#
use constant mm => 25.4 / 72;
use constant in => 1 / 72;
use constant pt => 1;

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"lang"}      = shift;
	$self->{"infoToPdf"} = shift;

	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";

	return $self;
}

sub Output {
	my $self       = shift;
	my $pdfFiles   = shift;
	my $pageTitles = shift;

	# Test if all pdf files exist
	foreach my $f ( @{$pdfFiles} ) {
		unless ( -e $f ) {
			die "Pdf file doesn't exist at: $f.\n";
		}
	}

	# Merge files, add titles
	$self->__AddHeaderFooter( $pdfFiles, $pageTitles );

	# remove tmp files
	foreach my $f ( @{$pdfFiles} ) {
		unlink($f);
	}

	return 1;

}

sub __AddHeaderFooter {
	my $self    = shift;
	my @inFiles = @{ shift(@_) };
	my @titles  = @{ shift(@_) };    # if more pages than titles, rest of pages will have last title in list

	# the output file
	my $pdf_out = PDF::API2->new( -file => $self->{"outputPath"} );

	my $pagesTotal = 1;

	foreach my $input_file (@inFiles) {
		my $pdf_in   = PDF::API2->open($input_file);
		my @numpages = ( 1 .. $pdf_in->pages() );

		foreach my $numpage (@numpages) {

			my $page_in = $pdf_in->openpage($numpage);

			#
			#		#
			#		# create a new page
			#		#
			my $page_out = $pdf_out->page(0);

			#
			my @mbox = $page_in->get_mediabox;
			$page_out->mediabox(@mbox);

			#
			my $xo = $pdf_out->importPageIntoForm( $pdf_in, $numpage );

			#
			#		#
			#		# lay up the input page in the output page
			#		# note that you can adjust the position and scale, if required
			#		#
			my $gfx = $page_out->gfx;

			#
			$gfx->formimage(
				$xo,
				0, 0,    # x y
				1
			);           # scale

			my $title = $titles[ $pagesTotal - 1 ];

			unless ( defined $title ) {

				$title = $titles[ scalar(@titles) - 1 ];
			}

			$self->__DrawHeaderFooter( $pagesTotal, scalar(@numpages), $title, $page_out, $pdf_out );

			$pagesTotal++;

		}
	}

	$pdf_out->save();
}

sub __DrawHeaderFooter {
	my $self      = shift;
	my $pageNum   = shift;
	my $pageTotal = shift;
	my $pageTitle = shift;
	my $page_out  = shift;
	my $pdf_out   = shift;

	my $a4H        = 290 / mm;
	my $a4W        = 210 / mm;
	my $pageMargin = 15 / mm;

	# 1) add text title

	my $txtHeader = $page_out->text;

	my $fontBold = $pdf_out->ttfont( GeneralHelper->Root() . '\Packages\Pdf\ControlPdf\Helpers\Resources\ProximaNova-Black.otf' );
	my $font     = $pdf_out->ttfont( GeneralHelper->Root() . '\Packages\Pdf\ControlPdf\Helpers\Resources\ProximaNova-Regular.otf' );

	$txtHeader->fillcolor("black");

	my @lines = split( ":", $pageTitle );

	$txtHeader->translate( $pageMargin, $a4H - $pageMargin + 2.5 / mm );
	$txtHeader->font( $fontBold, 6 / mm );
	$txtHeader->text( $lines[0] );
	$txtHeader->translate( $pageMargin - 2 / mm, $a4H - $pageMargin - 7 / mm );
	$txtHeader->font( $fontBold, 10 / mm );
	$txtHeader->text( $lines[1] );

	# 2) Add Logo
	if ( $self->{"infoToPdf"} ) {
		my $p    = GeneralHelper->Root() . '\Packages\Pdf\ControlPdf\Helpers\Resources\logo-gatema.jpg';
		my $logo = $page_out->gfx;
		die("Unable to find image file: $!") unless -e $p;
		my $photo_file = $pdf_out->image_jpeg($p);
		$logo->image( $photo_file, $a4W -46/mm, $a4H - 20/mm, 30/mm, 9/mm   );

	}

	# 3) add page number

	my $txtFooter = $page_out->text;
	$txtFooter->translate( $a4W - $pageMargin, $pageMargin - 20 );

	$txtFooter->font( $font, 4 / mm );
	$txtFooter->fillcolor("black");

	$txtFooter->text( $pageNum . "/" . $pageTotal );

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
