#!/usr/bin/perl

use PDF::API2;

my $infile  = "c:\\Export\\report\\test.pdf";
 
 
my $pdf_in  = PDF::API2->open($infile);


foreach my $pagenum ( 1 .. $pdf_in->pages ) {
	
	my $pdf_out = PDF::API2->new;

	my $page_in = $pdf_in->openpage($pagenum);

	#
	# create a new page
	#
	my $page_out = $pdf_out->page(0);

	my @mbox = $page_in->get_mediabox;
	$page_out->mediabox(@mbox);

	my $xo = $pdf_out->importPageIntoForm( $pdf_in, $pagenum );
	
		my $gfx = $page_out->gfx;

	$gfx->formimage(
		$xo,
		0, 0,    # x y
		1
	);           # scale
	
	$pdf_out->saveas("c:\\Export\\report\\page".$pagenum.".pdf");
 
}

 
