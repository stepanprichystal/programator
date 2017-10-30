
#-------------------------------------------------------------------------------------------#
# Description: Responsible for output image previev of pcb
# Prepare each export layer, print as pdf, convert to image => than merge all layers together
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::StencilControlPdf::FinalPreview::OutputPdf;
use base('Packages::Pdf::ControlPdf::Helpers::FinalPreview::OutputPdfBase');

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
use aliased 'Packages::Pdf::ControlPdf::StencilControlPdf::FinalPreview::Enums';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamFilter';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::SystemCall::SystemCall';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	
	my $output = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".jpeg";
	my $self      = $class->SUPER::new(@_, $output);
	bless $self;
  

	return $self;
}


sub Output {
	my $self      = shift;
	my $layerList = shift;

	$self->_Output($layerList);
	
	$self->__FinalTransform($layerList);
}


sub __FinalTransform{
	my $self = shift;
	my $layerList = shift;
	
	my $outputTmp = $self->{"outputPath"};
	
	# 2) Adjust image to ratio 9,5:10. Thus if image is square, this fill image by white color
	# in order image has ratio 9,5:10

	# Get the size of globe.gif
	( my $x, my $y ) = imgsize($outputTmp);

	my $rotate = $x > $y ? 1 : 0;

	# we want to longer side was height
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
	if ( $ratio <= 9 / 10 ) {

		# compute new width

		$dimH = max( $x, $y );
		$dimW = int( ( $dimH / 10 ) * 9.5 );
	}
	else {

		$dimW = min( $x, $y );
		$dimH = int( ( $dimW / 9.5 ) * 10 );
	}

	my @cmd2 = ( EnumsPaths->Client_IMAGEMAGICK . "convert.exe" );
	push( @cmd2, $outputTmp );

	if ($rotate) {
		push( @cmd2, "-rotate 90" );
	}

	push( @cmd2, "-gravity center -background " . $self->_ConvertColor( $layerList->GetBackground() ) );
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
