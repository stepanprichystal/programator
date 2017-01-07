#-------------------------------------------------------------------------------------------#
# Description: Merge together, stackup, preview top bot, preview single
# Add red stripes to each pages + titles
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::OutputPdf;

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
use aliased 'Packages::Pdf::ControlPdf::FinalPreview::Enums';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"lang"} = shift;

	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";

	return $self;
}

sub Output {
	my $self              = shift;
	my $templatePath      = shift;
	my $previewSinglePath = shift;

	unless ( -e $templatePath ) {
		die "Template pdf doesn't exist at: $templatePath.\n";
	}

	unless ( -e $previewSinglePath ) {
		die "Perview single pdf doesn't exist at: $previewSinglePath.\n";
	}


	my @files = ( $templatePath, $previewSinglePath );

	$self->__AddHeaderFooter( \@files );

	unlink($templatePath);
	unlink($previewSinglePath);

	return 1;

}

sub __AddHeaderFooter {
	my $self    = shift;
	my @inFiles = @{ shift(@_) };

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

			my $title = "Production preview: ";

			if ( $self->{"lang"} eq "cz" ) {
				$title = "Předvýrobní náhled: ";
			}

			if ( $pagesTotal == 1 ) {

				if ( $self->{"lang"} eq "cz" ) {
					$title .= "Obecné";
				}
				else {
					$title .= "General";
				}

			}
			elsif ( $pagesTotal == 2 ) {

				if ( $self->{"lang"} eq "cz" ) {
					$title .= "Dodání";
				}
				else {
					$title .= "Shipping units";
				}
			}
			else {

				if ( $self->{"lang"} eq "cz" ) {
					$title .= "Jednotlivé vrstvy - pohled z vrchu";
				}
				else {
					$title .= "Single layers - view from top";
				}
			}

			$self->__DrawHeaderFooter( $pagesTotal, $title, $page_out, $pdf_out );

			$pagesTotal++;

		}
	}

	$pdf_out->save();
}

sub __DrawHeaderFooter {
	my $self      = shift;
	my $pageNum   = shift;
	my $pageTitle = shift;
	my $page_out  = shift;
	my $pdf_out   = shift;

	my $headerW = 595;
	my $headerH = 25;
	my $footerW = 595;
	my $footerH = 18;

	# header frame
	my $header = $page_out->gfx;
	$header->fillcolor('#C9101A');
	$header->rect(
				   0,                 # left
				   842 - $headerH,    # bottom
				   $headerW,          # width
				   $headerH           # height
	);

	$header->fill;

	# footer frame
	my $footer = $page_out->gfx;
	$footer->fillcolor('#C9101A');
	$footer->rect(
				   0,                 # left
				   0,                 # bottom
				   $footerW,          # width
				   $footerH           # height
	);

	$footer->fill;

	# add text title

	my $txtHeader = $page_out->text;
	$txtHeader->translate( 10, 842 - $headerH + 12 );

	my $font = $pdf_out->ttfont( GeneralHelper->Root() . '\Packages\Pdf\ControlPdf\HtmlTemplate\arial.ttf' );

	#my $font = $pdf_out->corefont('arial');
	$txtHeader->font( $font, 10 );
	$txtHeader->fillcolor("white");
	$txtHeader->text($pageTitle);

	# add text title

	# add text title

	my $txtFooter = $page_out->text;
	$txtFooter->translate( 280, 6 );

	$txtFooter->font( $font, 8 );
	$txtFooter->fillcolor("white");

	if ( $self->{"lang"} eq "cz" ) {
		$txtFooter->text( 'Strana - ' . $pageNum );
	}
	else {
		$txtFooter->text( 'Page - ' . $pageNum );
	}

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
