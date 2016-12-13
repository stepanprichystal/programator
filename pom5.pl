#!/usr/bin/perl

use PDF::API2;

my $infile  = "c:\\Export\\report\\test.pdf";
my $outfile = "c:\\Export\\report\\template2.pdf";
die "usage $0: infile outfile"
  unless $infile && $outfile;

my $pdf_in  = PDF::API2->open($infile);
my $pdf_out = PDF::API2->new;

foreach my $pagenum ( 1 .. $pdf_in->pages ) {

	my $page_in = $pdf_in->openpage($pagenum);

	#
	# create a new page
	#
	my $page_out = $pdf_out->page(0);

	my @mbox = $page_in->get_mediabox;
	$page_out->mediabox(@mbox);

	my $xo = $pdf_out->importPageIntoForm( $pdf_in, $pagenum );

	#
	# lay up the input page in the output page
	# note that you can adjust the position and scale, if required
	#
	my $gfx = $page_out->gfx;

	$gfx->formimage(
		$xo,
		0, 0,    # x y
		1
	);           # scale

	
	my $blue_box = $page_out->gfx;
	$blue_box->fillcolor('gray');
	$blue_box->rect(
		200 ,    # left
		50,    # bottom
		200,     # width
		50                 # height
	);

	$blue_box->fill;

	#
	# add page number text
	#
	my $txt = $page_out->text;

	$txt->strokecolor('red');

	$txt->translate( my $_x = 200, my $_y = 50 );

	my $font = $pdf_out->corefont('arial');
	$txt->font( $font, 12 );
	$txt->fillcolor("white");
	$txt->text( 'Page: ' . $pagenum );
	

	#
	# add header image
	#

	my $header_img = $pdf_out->image_png('SomeHeader.png');
	$gfx->image( $header_img, 0, 400 );





	# The text in the blue box
#	$txt = $page->text;
#	$txt->translate( $self->{report}->{header}->{x} * mm, A4_y - ( $self->{report}->{header}->{y} * mm ) );
#	$txt->font( $self->{fonts}->{Times}->{Bold}, 18 );
#	$txt->fillcolor("green");
#	$txt->text( $self->{report}->{header}->{text} );

}

$pdf_out->saveas($outfile);
