
#-------------------------------------------------------------------------------------------#
# Description: Base class, responsible for output image previev of pcb
# Prepare each export layer, print as pdf, convert to image => than merge all layers together
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::Helpers::FinalPreview::OutputPdfBase;

#3th party library
use strict;
use warnings;
use PDF::API2;
use List::Util qw[max min];
use Math::Trig;
use Image::Size;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Pdf::ControlPdf::Helpers::FinalPreview::Enums' => 'PrevEnums';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamFilter';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::SystemCall::SystemCall';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}      = shift;
	$self->{"jobId"}      = shift;
	$self->{"pdfStep"}    = shift;
	$self->{"outputPath"} = shift;

	return $self;
}

sub GetOutput {
	my $self = shift;

	return $self->{"outputPath"};
}

sub _Output {
	my $self      = shift;
	my $layerList = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	my @layers = $layerList->GetLayers(1);

	# folder, where are putted temporary layer pdf and layer png
	my $dirPath = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . "\\";
	mkdir($dirPath) or die "Can't create dir: " . $dirPath . $_;

	# 1) output all layers together
	my @layerStr = map { $_->GetOutputLayer() } @layers;
	my $layerStr = join( "\\;", @layerStr );

	my $multiPdf = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";
	$multiPdf =~ s/\\/\//g;

	$inCAM->COM(
				 'print',
				 layer_name        => $layerStr,
				 mirrored_layers   => '',
				 draw_profile      => 'no',
				 drawing_per_layer => 'yes',
				 label_layers      => 'no',
				 dest              => 'pdf_file',
				 num_copies        => '1',
				 dest_fname        => $multiPdf,
				 paper_size        => 'A4',
				 orient            => 'none',
				 auto_tray         => 'no',
				 top_margin        => '0',
				 bottom_margin     => '0',
				 left_margin       => '0',
				 right_margin      => '0',
				 "x_spacing"       => '0',
				 "y_spacing"       => '0'
	);

	unless ( -e $multiPdf ) {
		die "Nepodarilo se vytvorit PDF, asi chyba \"CAT.exe\" nic s jobem nedelej a volej SPR";
	}

	# delete helper layers
	foreach my $lData (@layers) {

		$inCAM->COM( 'delete_layer', "layer" => $lData->GetOutputLayer() );
	}

	# 2) split whole pdf to single pdf
	$self->__SplitMultiPdf( $layerList, $multiPdf, $dirPath );

	# 3) compute image resolution by phzsic size of pcb
	my %resolution = $self->__GetResolution();

	# 3) conver each pdf page to image
	$self->__CreatePng( $layerList, $dirPath, \%resolution );

	# 4) merge all images together
	$self->__MergePng( $layerList, $dirPath );

	# 5) delete temporary png and directory
	foreach my $l (@layers) {
		if ( -e $dirPath . $l->GetOutputLayer() . ".png" ) {

			unlink( $dirPath . $l->GetOutputLayer() . ".png" );
		}
		if ( -e $dirPath . $l->GetOutputLayer() . ".pdf" ) {

			unlink( $dirPath . $l->GetOutputLayer() . ".pdf" );
		}
	}

	rmdir($dirPath);

}

sub __SplitMultiPdf {
	my $self      = shift;
	my $layerList = shift;
	my $pdfOutput = shift;
	my $dirPath   = shift;

	my @layers = $layerList->GetLayers(1);

	my $pdf_in = PDF::API2->open($pdfOutput);

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

		my $out = $dirPath . $layers[ $pagenum - 1 ]->GetOutputLayer() . ".pdf";

		$pdf_out->saveas($out);

	}

	unlink($pdfOutput);
}

# Convert layer in pdf to PNG image
sub __GetResolution {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $self->{"pdfStep"} );

	my $x = abs( $lim{"xMax"} - $lim{"xMin"} ) + 8;    # value ten is 2x5 mm frame from each side, which is added
	my $y = abs( $lim{"yMax"} - $lim{"yMin"} ) + 8;    # value ten is 2x5 mm frame from each side, which is added

	my $maxPcbSize = 300;                              # asume, max pcb are 350 mm long
	my $pcbSize = max( $x, $y );                       # longer side of actual pcb

	my $maxFloatRes = 2000;                            # resolution of 'x', which is depand on image size

	my $pcbFloatRes = $pcbSize / $maxPcbSize * $maxFloatRes;

	# max resolution, if pcb has max size
	my $maxResX = 3000;
	my $maxResY = 4245;

	# if pcb x dimension exceed max x dimension
	#if ( $pcbResolution > $maxFloatRes ) {
	#$pcbResolution = $maxFloatRes;
	#}

	# final pcb resolution, compute resolution Y side

	my $pcbResY = int( ( $maxResY - $maxFloatRes ) + $pcbFloatRes );

	if ( $pcbResY > $maxResY ) {
		$pcbResY = $maxResY;
	}

	my $pcbResX = int( ( $pcbResY / max( $x, $y ) ) * min( $x, $y ) );    # compute y size based on pcb ratio

	# if y resolution is begger than max, recompute y resolution

	if ( $pcbResX > $maxResX ) {

		$pcbResX = $maxResX;
		$pcbResY = int( ( $pcbResX / min( $x, $y ) ) * max( $x, $y ) );   # compute y size based on pcb ratio
	}

	# test if pcb resolution in y exceed max y dimension

	my %res = ( "x" => $pcbResX, "y" => $pcbResY );

	return %res;
}

# Convert layer in pdf to PNG image
sub __CreatePng {
	my $self       = shift;
	my $layerList  = shift;
	my $dirPath    = shift;
	my $resolution = shift;

	my @layers = $layerList->GetLayers(1);

	my @allCmds = ();

	my @fileToDel = ();

	foreach my $l (@layers) {

		my $layerSurf = $l->GetSurface();

		my $result = 1;

		# 1) ============================================================================================
		# Cmd1 - take pdf, convert to png with specific resolution, flatten (in order full opaque image)
		# and copy alpha channel, which is created from white background
		my @cmds1 = ();

		# command convert pdf to png with specific resolution
		push( @cmds1, " ( " );

		push( @cmds1, " -density 300" );
		push( @cmds1, $dirPath . $l->GetOutputLayer() . ".pdf -flatten" );
		push( @cmds1, "-shave 20x20 -trim -shave 5x5" );                     # shave two borders around image
		push( @cmds1, "-resize " . $resolution->{"x"} );

		push( @cmds1, " ) " );

		# command from white do transparent and copy alpha channel
		push( @cmds1, "-background black -alpha copy -type truecolormatte -alpha copy -channel A -negate" );

		my $cmds1str = join( " ", @cmds1 );                                  # finnal comand cmd1

		# 2) ============================================================================================
		# Cmd2 - based on surface type TEXTURE/COLOR take texture image or create colored canvas

		my @cmds2 = ();

		if ( $layerSurf->GetType() eq PrevEnums->Surface_COLOR ) {

			push( @cmds2, "-size " . $resolution->{"x"} . "x" . $resolution->{"y"} . " canvas:" . $self->_ConvertColor( $layerSurf->GetColor() ) );

			#push( @cmds2, "-background " .  $self->_ConvertColor( $layerSurf->GetColor() ) );

		}
		elsif ( $layerSurf->GetType() eq PrevEnums->Surface_TEXTURE ) {

			my $texturPath = GeneralHelper->Root() . "\\Resources\\Textures\\" . $layerSurf->GetTexture() . ".jpeg";

			push( @cmds2, $texturPath . " -crop " . $resolution->{"x"} . "x" . $resolution->{"y"} . "+0+0" );
		}

		my $cmds2Str = join( " ", @cmds2 );    # finnal comand cmd2

		# 3) ============================================================================================
		# Cmd3 - merge created canvas/background with copied alpha channel created in cmd1

		my @cmds3 = ();

		push( @cmds3, $cmds2Str );
		push( @cmds3, " ( " . $cmds1str . " -channel a -separate +channel ) " );
		push( @cmds3, " -alpha off -compose copy_opacity -composite " );

		my $cmds3Str = join( " ", @cmds3 );    # finnal comand cmd3

		# 4) ============================================================================================
		# Cmd4 -add brightness, and set transparetnt, set output path

		my @cmds4 = ();

		# run 'convert' console application

		push( @cmds4, EnumsPaths->Client_IMAGEMAGICK . "convert.exe" );

		#push( @cmds4, "convert" );

		push( @cmds4, " ( " );
		push( @cmds4, $cmds3Str );
		push( @cmds4, " ) " );

		my $brightness = ( $layerSurf->GetBrightness() != 0 ) ? " -brightness-contrast " . $layerSurf->GetBrightness() : "";
		my $opaque = "";

		if ( $layerSurf->GetOpaque() < 100 ) {

			if ( $layerSurf->GetType() eq PrevEnums->Surface_TEXTURE ) {

			}
			else {

				$opaque =
				    "-fuzz 20% -matte -fill "
				  . $self->_ConvertColor( $layerSurf->GetColor(), $layerSurf->GetOpaque() )
				  . " -opaque "
				  . $self->_ConvertColor( $layerSurf->GetColor() );
			}
		}

		my $edges3d = "";
		if ( $layerSurf->Get3DEdges() ) {

			$edges3d .= " ( +clone -channel A -separate +channel -negate ";
			$edges3d .= " -background black -virtual-pixel background -blur 0x" . $layerSurf->Get3DEdges() . " -shade 0x21.78 -contrast-stretch ";
			$edges3d .= "  0% +sigmoidal-contrast 7x50%  -fill grey50 -colorize 10% +clone +swap  ";
			$edges3d .= " -compose overlay -composite  ) -compose In -composite   ";
		}

		push( @cmds4, $brightness );
		push( @cmds4, $opaque );
		push( @cmds4, $edges3d );

		# if surfeace is texture, this line convert all transparent color to solid color and back to transparnt
		# This cauze smaller size of final image (because most of area is transparent) and faster creation
		if ( $layerSurf->GetType() eq PrevEnums->Surface_TEXTURE ) {

			push( @cmds4, " -fill blue -opaque none -fill none -opaque blue" );
		}

		push( @cmds4, $dirPath . $l->GetOutputLayer() . ".png" );

		my $cmds4Str = join( " ", @cmds4 );    # finnal comand cmd3

		push( @allCmds, $cmds4Str );

		print $cmds4Str. "\n\n\n";

	}

	print STDERR "threat created (conversion pdf => png)\n";

	# conversion is processed in another perl instance by this script
	my $script = GeneralHelper->Root() . "\\Packages\\Pdf\\ControlPdf\\Helpers\\FinalPreview\\CreatePng.pl";

	my $createPngCall = SystemCall->new( $script, \@allCmds );
	unless ( $createPngCall->Run(1) ) {

		die "Error when convert pdf to png.\n";
	}

	print STDERR "threats done (conversion pdf => png)\n";

}

# Merge converted png together
sub __MergePng {
	my $self      = shift;
	my $layerList = shift;
	my $dirPath   = shift;

	my @layers = $layerList->GetLayers(1);

	my @layerStr2 = map { $dirPath . $_->GetOutputLayer() . ".png" } @layers;
	my $layerStr2 = join( " ", @layerStr2 );

	#my $outputTmp = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".jpg";
	my $outputTmp = $self->{"outputPath"};

	# 1) Flatten all images/layers together
	my @cmd = ( EnumsPaths->Client_IMAGEMAGICK . "convert.exe" );
	push( @cmd, $layerStr2 );

	push( @cmd, "-background " . $self->_ConvertColor( $layerList->GetBackground() ) );
	push( @cmd, "-flatten" );
	push( @cmd, "-trim" );

	#if background image is not white, add little border around whole image
	if ( $layerList->GetBackground() ne "255,255,255" ) {
		push( @cmd, "-bordercolor " . $self->_ConvertColor( $layerList->GetBackground() ) . " -border 20x20" );
	}

	#push( @cmd, "-blur 0.2x0.2" );
	push( @cmd, "-quality 82%" );
	push( @cmd, $outputTmp );

	my $cmdStr = join( " ", @cmd );

	my $systeMres = system($cmdStr);

}

sub _ConvertColor {
	my $self   = shift;
	my $rgbStr = shift;
	my $opaque = shift;

	if ( defined $opaque && $opaque < 100 ) {
		$rgbStr = "\"rgba(" . $rgbStr . ", " . ( ($opaque) / 100 ) . ")\"";

	}
	else {
		$rgbStr = "\"rgb(" . $rgbStr . ")\"";
	}

	return $rgbStr;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
