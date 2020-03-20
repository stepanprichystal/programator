
#-------------------------------------------------------------------------------------------#
# Description: Responsible o create single pdf from prepared LayerDataList strucure
# Author:SPR
#-------------------------------------------------------------------------------------------#
package  Packages::Pdf::ControlPdf::Helpers::SinglePreview::OutputPdfBase;

#3th party library
use strict;
use warnings;
use PDF::API2;
use POSIX;
use List::Util qw[max min];

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::SinglePreview::Enums';
use aliased 'Packages::CAMJob::OutputData::Enums' => "OutputEnums";
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
# Public method
#-------------------------------------------------------------------------------------------#

use constant mm => 25.4 / 72;
use constant in => 1 / 72;
use constant pt => 1;

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}      = shift;
	$self->{"jobId"}      = shift;
	$self->{"pdfStep"}    = shift;
	$self->{"lang"}       = shift;
	$self->{"outputPath"} = shift;

	$self->{"profileLim"} = undef;

	return $self;
}

sub Output {
	my $self      = shift;
	my $layerList = shift;
	my $multiplX  = shift;
	my $multiplY  = shift;

	if ( !( $multiplX >= 1 && $multiplX <= 2 ) ) {
		die "Multiplicity of image in X axis has to by between 1-2";
	}

	if ( !( $multiplY >= 1 && $multiplY <= 2 ) ) {
		die "Multiplicity of image in Y axis has to by between 1-2";
	}

	my %lim = CamJob->GetProfileLimits( $self->{"inCAM"}, $self->{"jobId"}, $self->{"pdfStep"} );

	$self->{"profileLim"} = \%lim;

	$self->__OptimizeLayers( $layerList, $multiplX, $multiplY );

	my $titleMargin = 42;    # top page margin [mm] which creates space for title

	my $pathPdf = $self->__OutputRawPdf( $layerList, $multiplX, $multiplY, $titleMargin );

	$self->__AddTextPdf( $layerList,, $multiplX, $multiplY, $pathPdf, $titleMargin );

}

sub GetOutput {
	my $self = shift;

	return $self->{"outputPath"};
}

#-------------------------------------------------------------------------------------------#
# Private method
#-------------------------------------------------------------------------------------------#

sub __OptimizeLayers {
	my $self      = shift;
	my $layerList = shift;

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layerList->GetLayers();

	CamLayer->ClearLayers($inCAM);

	# Create border around layer data. Border has to has ratio min 290:305 because of right place in pdf
	# if not, pcb layer would be covered by table with title and description of layer

	#for each layer own border

	# affect all layers
	foreach my $l (@layers) {

		my $lName = GeneralHelper->GetGUID();

		$inCAM->COM( "profile_to_rout", "layer" => $l->GetOutput(), "width" => 1 );

		my %lim = CamJob->GetLayerLimits( $inCAM, $self->{"jobId"}, $self->{"pdfStep"}, $l->GetOutput() );

		my $x = abs( $lim{"xmax"} - $lim{"xmin"} );
		my $y = abs( $lim{"ymax"} - $lim{"ymin"} );

		# prepare coordination for frame

		if ( min( $x, $y ) == $x ) {

			# compute min x length
			my $newX = ( $y / 305 ) * 290;
			$lim{"xmin"} -= ( ( $newX - $x ) / 2 );
			$lim{"xmax"} += ( ( $newX - $x ) / 2 );

		}
		elsif ( min( $x, $y ) == $y ) {

			# compute min x length
			my $newY = ( $x / 305 ) * 290;
			$lim{"ymin"} -= ( ( $newY - $y ) / 2 );
			$lim{"ymax"} += ( ( $newY - $y ) / 2 );
		}

		CamLayer->WorkLayer( $inCAM, $l->GetOutput() );

		my %c1 = ( "x" => $lim{"xmin"}, "y" => $lim{"ymin"} );
		my %c2 = ( "x" => $lim{"xmax"}, "y" => $lim{"ymin"} );
		my %c3 = ( "x" => $lim{"xmax"}, "y" => $lim{"ymax"} );
		my %c4 = ( "x" => $lim{"xmin"}, "y" => $lim{"ymax"} );
		my @coord = ( \%c1, \%c2, \%c3, \%c4 );

		#
		CamSymbol->AddPolyline( $inCAM, \@coord, "r1", "negative", 1 );

	}

}

sub __CopyFrame {
	my $self   = shift;
	my $lName  = shift;
	my @layers = @{ shift(@_) };

	my $inCAM = $self->{"inCAM"};

	CamLayer->WorkLayer( $inCAM, $lName );

	# affect all layers
	foreach my $l (@layers) {

		$inCAM->COM( "affected_layer", "name" => $l->GetOutput(), "mode" => "single", "affected" => "yes" );

	}

	my @layerStr = map { $_->GetOutput() } @layers;
	my $layerStr = join( "\\;", @layerStr );
	$inCAM->COM(
		"sel_copy_other",
		"dest"         => "affected_layers",
		"target_layer" => $lName . "\\;" . $layerStr,
		"invert"       => "no"

	);

	$inCAM->COM( "affected_layer", "mode" => "all", "affected" => "no" );
	$inCAM->COM( 'delete_layer', "layer" => $lName );

}

# Do output pdf of expor tlayers
sub __OutputRawPdf {
	my $self        = shift;
	my $layerList   = shift;
	my $multiplX    = shift;
	my $multiplY    = shift;
	my $titleMargin = shift;

	my $inCAM = $self->{"inCAM"};

	my @layers = $layerList->GetLayers();

	my @layerStr = map { $_->GetOutput() } @layers;
	my $layerStr = join( "\\;", @layerStr );

	my $outputPdf = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";

	$outputPdf =~ s/\\/\//g;

	# here was problem, when there is lots of layer, each layer has long name: fdfsd-df78f7d-f7d8f-f7d8f78d
	# Than incam command lenght was long and it doeasnt work
	# So layer are now named as ten position number

	$inCAM->COM(
		'print',

		#title             => '',

		layer_name        => "$layerStr",
		mirrored_layers   => '',
		draw_profile      => 'yes',
		drawing_per_layer => 'yes',
		label_layers      => 'no',
		dest              => 'pdf_file',
		num_copies        => '1',
		dest_fname        => $outputPdf,

		paper_size => 'A4',

		#scale_to          => '0.0',
		nx     => $multiplX,
		ny     => $multiplY,
		orient => 'none',

		#paper_orient => 'best',

		#paper_width   => 260,
		#paper_height  => 260,
		#auto_tray     => 'no',
		top_margin    => $titleMargin,    # margin for page title
		bottom_margin => '0',
		left_margin   => '0',
		right_margin  => '0',
		"x_spacing"   => '0',
		"y_spacing"   => '0',

		#3color1        => $self->__ConvertColor( $l->GetColor()
	);

	# delete created layers
	#	foreach my $lData (@layers) {
	#
	#		$inCAM->COM( 'delete_layer', "layer" => $lData->GetOutput() );
	#	}

	return $outputPdf;

}

# add title and description to each pdf page for each layer
sub __AddTextPdf {
	my $self        = shift;
	my $layerList   = shift;
	my $multiplX    = shift;
	my $multiplY    = shift;
	my $infile      = shift;
	my $titleMargin = shift;

	unless ( -e $infile ) {
		die "Pdf file doesn't exiswt $infile.\n";
	}

	my $inCAM = $self->{"inCAM"};

	my $a4H = 297 / mm;
	my $a4W = 210 / mm;
	$titleMargin /= mm;    # conver to points

	my $pdf_in  = PDF::API2->open($infile);
	my $pdf_out = PDF::API2->new;

	foreach my $pagenum ( 1 .. $pdf_in->pages ) {

		my $page_in = $pdf_in->openpage($pagenum);

		#
		# copy page content
		#
		my $page_out = $pdf_out->page(0);
		my @mbox     = $page_in->get_mediabox;
		$page_out->mediabox(@mbox);
		my $xo = $pdf_out->importPageIntoForm( $pdf_in, $pagenum );
		my $gfx = $page_out->gfx;

		$gfx->formimage(
			$xo,
			0, 0,    # x y
			1
		);           # scale
		             # 1) Cover black border in PDF

		my $coverLine = $page_out->gfx;
		$coverLine->strokecolor('white');
		$coverLine->linewidth( 2 / mm );

		# left vertical
		$coverLine->move( $titleMargin / 2, 0 );
		$coverLine->line( $titleMargin / 2, $a4H );
		$coverLine->stroke;

		# middle vertical
		$coverLine->move( $a4W / 2, 0 );
		$coverLine->line( $a4W / 2, $a4H );
		$coverLine->stroke;

		# middle vertical
		$coverLine->move( $a4W - $titleMargin / 2, 0 );
		$coverLine->line( $a4W - $titleMargin / 2, $a4H );
		$coverLine->stroke;

		# top horizontal
		$coverLine->move( 0, $a4H - $titleMargin - 4 / mm );
		$coverLine->line( $a4W, $a4H - $titleMargin - 4 / mm );
		$coverLine->stroke;

		# middle top horizontal
		$coverLine->move( 0, $a4H - $titleMargin - 123 / mm );
		$coverLine->line( $a4W, $a4H - $titleMargin - 123 / mm );
		$coverLine->stroke;

		# middle bot horizontal
		$coverLine->move( 0, $a4H - $titleMargin - 132 / mm  );
		$coverLine->line( $a4W, $a4H - $titleMargin - 132 / mm  );
		$coverLine->stroke;

		# middle bot horizontal
		$coverLine->move( 0, 4 / mm );
		$coverLine->line( $a4W, 4 / mm );
		$coverLine->stroke;

		# 2) draw info tables

		my @data = $self->__GetPageData( $layerList, $pagenum, $multiplX * $multiplY );

		# 1 x 1 images per page
		if ( $multiplX == 1 && $multiplY == 1 ) {

			my $d = $data[0];
			$self->__DrawInfoTable( 55 / mm, 15 / mm, $d, $page_out, $pdf_out );

		}

		# 2 x 1 images per page
		elsif ( $multiplX == 2 && $multiplY == 1 ) {

			die "not implemented";

		}

		# 1 x 2 images per page
		elsif ( $multiplX == 1 && $multiplY == 2 ) {

			die "not implemented";
		}

		# 2 x 2 images per page
		elsif ( $multiplX == 2 && $multiplY == 2 ) {

			for ( my $i = 0 ; $i < scalar(@data) ; $i++ ) {

				if ( $i == 0 ) {
					my $d = $data[$i];
					$self->__DrawInfoTable( $titleMargin / 2-7/mm, $a4H - $titleMargin-4/mm, $d, $page_out, $pdf_out );
				}
				elsif ( $i == 1 ) {
					my $d = $data[$i];
					$self->__DrawInfoTable( $titleMargin / 2-7/mm, $a4H / 2 - $titleMargin / 2-5/mm, $d, $page_out, $pdf_out );
				}
				elsif ( $i == 2 ) {
					my $d = $data[$i];
					$self->__DrawInfoTable( $a4W / 2 +2/mm , $a4H - $titleMargin-4/mm, $d, $page_out, $pdf_out );
				}
				elsif ( $i == 3 ) {
					my $d = $data[$i];
					$self->__DrawInfoTable( $a4W / 2 +2/mm , $a4H / 2 - $titleMargin / 2-5/mm, $d, $page_out, $pdf_out );
				}
			}

		}

	}

	$pdf_out->saveas( $self->{"outputPath"} );

	unlink($infile);

}

sub __GetPageData {
	my $self      = shift;
	my $layerList = shift;
	my $pageNum   = shift;
	my $cnt       = shift;    # number of page datas (multiplicitz layers per page)

	my @data = ();

	my @layers = $layerList->GetLayers();
	my $start  = ( $pageNum - 1 ) * $cnt;

	for ( my $i = 0 ; $i < $cnt ; $i++ ) {

		my $lData = $layers[ $start + $i ];

		if ($lData) {

			#my @singleLayers = $lData->GetSingleLayers();

			my $langu = $self->{"lang"};
			my $tit   = $lData->GetTitle($langu);

			#my $tit = $lData->GetTitle( $self->{"lang"} );
			my $inf = $lData->GetInfo( $self->{"lang"} );

			my %inf = ( "title" => $tit, "info" => $inf );
			push( @data, \%inf );
		}

	}

	return @data;

}

sub __DrawInfoTable {
	my $self     = shift;
	my $xPos     = shift;
	my $yPos     = shift;
	my $data     = shift;
	my $page_out = shift;
	my $pdf_out  = shift;

	my $a4H = 297 / mm;
	my $a4W = 210 / mm;

	my $leftClmnW  = 15 / mm;
	my $rightClmnW = 73 / mm;
	my $topRowH    = 15;
	my $botRowH    = 15;

	# draw frame
	#	my $frame = $page_out->gfx;
	#	$frame->fillcolor('#E5E5E5');
	#	$frame->rect(
	#				  $xPos - 0.5,                     # left
	#				  $yPos - 0.5,                     # bottom
	#				  $leftCellW + $rightCellW + 1,    # width
	#				  $leftCellH + 1                   # height
	#	);

	#	$frame->fill;

	# draw top row
	my $tCell = $page_out->gfx;
	$tCell->fillcolor('#C9101A');
	$tCell->rect(
				  $xPos,                        
				  $yPos + $botRowH,             
				  $leftClmnW + $rightClmnW,     
				  $topRowH                     
	);
	$tCell->fill;

	# draw bot row - left cell
	my $lbCell = $page_out->gfx;
	$lbCell->fillcolor('#F5F5F5');
	$lbCell->rect(
				  $xPos,                        
				  $yPos,             
				  $leftClmnW,     
				  $botRowH                     
	);
	$lbCell->fill;
	
	# draw bot row - right cell
	my $rbCell = $page_out->gfx;
	$rbCell->fillcolor('white');
	$rbCell->rect(
				  $xPos + $leftClmnW,                        
				  $yPos,             
				  $rightClmnW,     
				  $botRowH                     
	);
	$rbCell->fill;

#	# draw crosst cell
#	my $lineV = $page_out->gfx;
#	$lineV->fillcolor('#E5E5E5');
#	$lineV->rect(
#				  $xPos + $leftCellW,          # left
#				  $yPos,                       # bottom
#				  0.5,                         # width
#				  $rightCellH                  # height
#	);
#	$lineV->fill;

#	my $lineH = $page_out->gfx;
#	$lineH->fillcolor('#E5E5E5');
#	$lineH->rect(
#				  $xPos,                       # left
#				  $yPos + $rightCellH / 2,     # bottom
#				  $rightCellW + $leftCellW,    # width
#				  0.5                          # height
#	);
#	$lineH->fill;

	my $txtSize = 3/mm;
	my $txtMargin =1.5/mm; 
	# add text title

	my $txtTitle = $page_out->text;
	$txtTitle->translate( $xPos + $txtMargin, $yPos + $botRowH + $txtMargin );
	my $font = $pdf_out->ttfont( GeneralHelper->Root() . '\Packages\Pdf\ControlPdf\Helpers\Resources\arial.ttf' );
	$txtTitle->font( $font, $txtSize );
	$txtTitle->fillcolor("white");

	$txtTitle->text( $data->{"title"} );

	# add text title

	my $txtInf = $page_out->text;
	$txtInf->translate( $xPos + $txtMargin, $yPos + $txtMargin );
	$txtInf->font( $font, $txtSize );
	$txtInf->fillcolor("black");

	if ( $self->{"lang"} eq "cz" ) {
		$txtInf->text( 'Pozn.    ' . $data->{"info"} );
	}
	else {
		$txtInf->text( 'Info       ' . $data->{"info"} );
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

