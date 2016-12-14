#!/usr/bin/perl

use PDF::API2;

my $infile  = "c:\\Export\\report\\pages.pdf";
my $outfile = "c:\\Export\\report\\pagegsResult.pdf";
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

	# =================== add 4 tables

	my @data = GetPageData($pagenum);
	
	__DrawHeaderFooter($pagenum, "test", $page_out);

	for ( my $i = 0 ; $i < scalar(@data) ; $i++ ) {

		my $d = $data[$i];

	 
		if ( $i == 0 ) {
			
			__DrawTable(20, 435,$d, $page_out );


		}elsif ( $i == 1 ) {
			
			__DrawTable(20, 25,$d, $page_out );


		}elsif ( $i == 2 ) {
			
			__DrawTable(315, 435,$d, $page_out );
			
		}elsif ( $i == 3 ) {
			
			__DrawTable(315, 25, $d, $page_out );
		}
		

	}

##
## add page number text
##
	#my $txt = $page_out->text;
	#
	#$txt->strokecolor('red');
	#
	#$txt->translate( my $_x = 200, my $_y = 50 );
	#
	#my $font = $pdf_out->corefont('arial');
	#$txt->font( $font, 12 );
	#$txt->fillcolor("white");
	#$txt->text( 'Page: ' . $pagenum );
	#
##
## add header image
##
	#
	#my $header_img = $pdf_out->image_png('SomeHeader.png');
	#$gfx->image( $header_img, 0, 400 );

	# The text in the blue box
	#	$txt = $page->text;
	#	$txt->translate( $self->{report}->{header}->{x} * mm, A4_y - ( $self->{report}->{header}->{y} * mm ) );
	#	$txt->font( $self->{fonts}->{Times}->{Bold}, 18 );
	#	$txt->fillcolor("green");
	#	$txt->text( $self->{report}->{header}->{text} );

}

$pdf_out->saveas($outfile);

print "done";

sub __DrawTable {
	my $xPos = shift;
	my $yPos = shift;
	my $data = shift;
	my $page_out = shift;
	
 

	my $leftCellW = 20;
	my $leftCellH = 30;
	my $rightCellW = 240;
	my $rightCellH = 30;

	# draw frame
	my $frame = $page_out->gfx;
	$frame->fillcolor('#E5E5E5');
	$frame->rect(
				  $xPos-0.5,     # left
				  $yPos-0.5,    # bottom
				  $leftCellW+$rightCellW + 1,     # width
				  $leftCellH  + 1     # height
	);

	$frame->fill;

	# draw left cell
	my $lCell = $page_out->gfx;
	$lCell->fillcolor('#F5F5F5');
	$lCell->rect(
					 $xPos,    # left
					 $yPos,    # bottom
					 $leftCellW,     # width
					 $leftCellH      # height
	);

	$lCell->fill;
	
	
	# draw right cell
	my $rCell = $page_out->gfx;
	$rCell->fillcolor('#FFFFFF');
	$rCell->rect(
					 $xPos + $leftCellW,    # left
					 $yPos,    # bottom
					 $rightCellW,     # width
					 $rightCellH      # height
	);

	$rCell->fill;
	
	# draw crosst cell
	my $lineV = $page_out->gfx;
	$lineV->fillcolor('#E5E5E5');
	$lineV->rect(
					 $xPos + $leftCellW,    # left
					 $yPos,    # bottom
					 0.5,     # width
					 $rightCellH      # height
	);
	$lineV->fill;
	
	my $lineH = $page_out->gfx;
	$lineH->fillcolor('#E5E5E5');
	$lineH->rect(
					 $xPos,    # left
					 $yPos +$rightCellH/2,    # bottom
					 $rightCellW +$leftCellW,     # width
					   0.5    # height
	);
	$lineH->fill;
 
 	my $txtSize = 6;
 
	# add text title
	
	my $txtTitle = $page_out->text;
	#
	#$txt->strokecolor('black');
	#
	
	$txtTitle->translate(  $xPos +2,  $yPos + $rightCellH -10);
	#
	my $font = $pdf_out->corefont('arial');
	$txtTitle->font( $font, $txtSize );
	$txtTitle->fillcolor("black");
	$txtTitle->text( 'Title:     '. $data->{"title"} );
	

	# add text title
	
	my $txtInf = $page_out->text;
	#
	#$txt->strokecolor('black');
	#
	
	$txtInf->translate(  $xPos +2, $yPos +2);
	#
	 
	$txtInf->font( $font, $txtSize );
	$txtInf->fillcolor("black");
	$txtInf->text( 'Info:    '. $data->{"info"} );

}  




sub __DrawHeaderFooter {
	my $pageNum = shift;
	my $pageTitle = shift;
		my $page_out = shift;
	
	my $headerW = 595;
	my $headerH = 30;
	my $footerW = 595;
	my $footerH = 20;

	# header frame
	my $header = $page_out->gfx;
	$header->fillcolor('#C9101A');
	$header->rect(
				  0,     # left
				  842-$headerH,    # bottom
				  $headerW,     # width
				  $headerH     # height
	);

	$header->fill;

	# footer frame
	my $footer = $page_out->gfx;
	$footer->fillcolor('#C9101A');
	$footer->rect(
				  0,     # left
				  0,    # bottom
				  $footerW,     # width
				  $footerH     # height
	);

	$footer->fill;
 	
 
	# add text title
	
	my $txtHeader = $page_out->text;
	$txtHeader->translate(  10, 842-$headerH +10);
	my $font = $pdf_out->corefont('arial');
	$txtHeader->font( $font, 10 );
	$txtHeader->fillcolor("white");
	$txtHeader->text( 'Production preview'.$pageNum );
 
	# add text title
	
		# add text title
	
	my $txtFooter = $page_out->text;
	$txtFooter->translate(  280,  +10);
	my $font2 = $pdf_out->corefont('arial');
	$txtFooter->font( $font, 8 );
	$txtFooter->fillcolor("white");
	$txtFooter->text( 'page'.$pageNum );

}  

sub GetPageData {

	my @array = ();

	my %inf = ( "title" => "SignalLayer", "info" => "SignalLaySignalLayer infSignalLayer infer infoSignalLayer infSignalLayer infrmation" );
	push( @array, \%inf );
	my %inf2 = ( "title" => "SignalLayer2", "info" => "SignalLaySignalLayer infSignalLayer infer infoSignalLayer infSignalLayer infrmation" );
	push( @array, \%inf2 );
	my %inf3 = ( "title" => "SignalLayer3", "info" => "SignalLaySignalLayer infSignalLayer infer infoSignalLayer infSignalLayer infrmation" );
	push( @array, \%inf3 );
	my %inf4 = ( "title" => "SignalLayer4", "info" => "SignalLaySignalLayer infSignalLayer infer infoSignalLayer infSignalLayer infrmation" );
	push( @array, \%inf4 );

	return @array;

}
