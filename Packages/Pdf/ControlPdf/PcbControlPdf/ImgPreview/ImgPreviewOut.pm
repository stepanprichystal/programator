
#-------------------------------------------------------------------------------------------#
# Description: Responsible for output image previev of pcb
# Prepare each export layer, print as pdf, convert to image => than merge all layers together
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::PcbControlPdf::ImgPreview::ImgPreviewOut;
use base('Packages::Pdf::ControlPdf::Helpers::ImgPreview::ImgPreviewOutBase');

#3th party library
use threads;
use strict;
use warnings;
use PDF::API2;
use List::Util qw[max min];
use Math::Trig;
use Image::Size;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::ImgPreview::Enums';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamFilter';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::SystemCall::SystemCall';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $output = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".jpeg";
	my $self = $class->SUPER::new( @_, $output );
	bless $self;

	return $self;
}

sub Output {
	my $self           = shift;
	my $reducedQuality = shift;
	
	my $result = 1;

	CamHelper->SetStep( $self->{"inCAM"}, $self->{"pdfStep"} );

	$self->__OptimizeLayers();
	$self->_Output($reducedQuality);
	$self->__FinalTransform();
	
	return $result;
}

# Return path of image
sub GetOutput {
	my $self = shift;
 
	return $self->SUPER::GetOutput();
}

# Clip area arpound profile
# Create border around pcb which is responsible for keep all layer dimension same
# border is 5mm behind profile
# if preview is bot, mirror data
sub __OptimizeLayers {
	my $self = shift;

	my $inCAM  = $self->{"inCAM"};
	my @layers = $self->{"layerList"}->GetOutputLayers();

	# 1) Clip area behind profile

	CamLayer->ClearLayers($inCAM);

	foreach my $l ( grep { $_->GetType() ne Enums->Type_NPLTTHROUGHNC } @layers ) {

		$inCAM->COM( "affected_layer", "name" => $l->GetOutputLayer(), "mode" => "single", "affected" => "yes" );
	}

	# clip area around profile
	$inCAM->COM(
		"clip_area_end",
		"layers_mode" => "affected_layers",
		"layer"       => "",
		"area"        => "profile",

		#"area_type"   => "rectangle",
		"inout"       => "outside",
		"contour_cut" => "yes",

		#"margin"      => ( $self->{"pdfStep"} eq "pdf_panel" ? "0" : "1000" ),    # keep panel dimension, else add extra margin 1mm
		"margin"     => 0,                              # keep panel dimension, else add extra margin 1mm
		"feat_types" => "line\;pad;surface;arc;text",
		"pol_types"  => "positive\;negative"
	);
	$inCAM->COM(
				 "affected_layer",
				 "mode"     => "all",
				 "affected" => "no"
	);

	# 2) Create frame 5mm behind profile. Frame define border of layer data

	my $lName = GeneralHelper->GetGUID();
	$inCAM->COM(
				 'create_layer',
				 "layer"     => $lName,
				 "context"   => 'misc',
				 "type"      => 'document',
				 "polarity"  => 'positive',
				 "ins_layer" => ''
	);
	CamLayer->WorkLayer( $inCAM, $lName );

	my %lim = CamJob->GetProfileLimits2( $self->{"inCAM"}, $self->{"jobId"}, $self->{"pdfStep"}, 1 );

	# frame width 2mm
	my $frame = 4;

	my @coord = ();

	my %p1 = (
			   "x" => $lim{"xMin"} - $frame,
			   "y" => $lim{"yMin"} - $frame
	);
	my %p2 = (
			   "x" => $lim{"xMin"} - $frame,
			   "y" => $lim{"yMax"} + $frame
	);
	my %p3 = (
			   "x" => $lim{"xMax"} + $frame,
			   "y" => $lim{"yMax"} + $frame
	);
	my %p4 = (
			   "x" => $lim{"xMax"} + $frame,
			   "y" => $lim{"yMin"} - $frame
	);
	push( @coord, \%p1 );
	push( @coord, \%p2 );
	push( @coord, \%p3 );
	push( @coord, \%p4 );

	# frame 100µm width around pcb (fr frame coordinate)
	CamSymbol->AddPolyline( $self->{"inCAM"}, \@coord, "r10", "positive", 1 );

	# copy border to all output layers

	my @layerStr = map { $_->GetOutputLayer() } @layers;
	my $layerStr = join( "\\;", @layerStr );
	$inCAM->COM(
		"sel_copy_other",
		"dest"         => "layer_name",
		"target_layer" => $layerStr,
		"invert"       => "no"

	);

	$inCAM->COM( 'delete_layer', "layer" => $lName );
	CamLayer->ClearLayers($inCAM);

	# if preview from BOT mirror all layers
	if ( $self->{"viewType"} eq Enums->View_FROMBOT ) {

		my $rotateBy = undef;

		my $x = abs( $lim{"xMax"} - $lim{"xMin"} );
		my $y = abs( $lim{"yMax"} - $lim{"yMin"} );

		if ( $x <= $y ) {

			$rotateBy = "y";
		}
		else {

			$rotateBy = "x";
		}

		foreach my $l (@layers) {

			CamLayer->WorkLayer( $inCAM, $l->GetOutputLayer() );
			CamLayer->MirrorLayerData( $inCAM, $l->GetOutputLayer(), $rotateBy );
		}
	}

}

sub __FinalTransform {
	my $self = shift;

	my $outputTmp = $self->{"outputPath"};

	# 2) Adjust image to ratio 3:5. Thus if image is square, this fill image by white color
	# in order image has ratio 3:5

	# Get the size of globe.gif
	( my $x, my $y ) = imgsize($outputTmp);

	my $rotate = $x < $y ? 1 : 0;

	# we want to longer side was width
	if ($rotate) {
		my $pom = $y;
		my $y   = $x;
		my $x   = $pom;
	}

	my $ratio = min( $x, $y ) / max( $x, $y );

	# compute new image resolution
	my $dimW = 0;
	my $dimH = 0;

	# compute new height
	if ( $ratio <= 3 / 5 ) {

		$dimW = max( $x, $y );
		$dimH = int( ( $dimW / 5 ) * 3 );

	}
	else {

		# compute new width

		$dimH = min( $x, $y );
		$dimW = int( ( $dimH / 3 ) * 5 );

	}

	my @cmd2 = ( EnumsPaths->Client_IMAGEMAGICK . "convert.exe" );
	push( @cmd2, $outputTmp );

	if ($rotate) {
		push( @cmd2, "-rotate 90" );
	}

	push( @cmd2, "-gravity center -background " . $self->_ConvertColor( $self->{"layerList"}->GetBackground() ) );
	push( @cmd2, "-extent " . $dimW . "x" . $dimH );

	push( @cmd2, $self->{"outputPath"} );

	my $cmdStr2 = join( " ", @cmd2 );

	my $systeMres2 = system($cmdStr2);

	#unlink($outputTmp);

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
