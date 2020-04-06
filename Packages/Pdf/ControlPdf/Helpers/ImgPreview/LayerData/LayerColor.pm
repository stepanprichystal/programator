
#-------------------------------------------------------------------------------------------#
# Description: Information about color or texcture of given layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::Helpers::ImgPreview::LayerData::LayerColor;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Pdf::ControlPdf::Helpers::ImgPreview::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"type"} = shift;

	if ( $self->{"type"} ) {
		if ( $self->{"type"} eq Enums->Surface_COLOR ) {
			$self->{"color"} = shift;

		}
		elsif ( $self->{"type"} eq Enums->Surface_TEXTURE ) {
			$self->{"texture"} = shift;
		}
	}

	$self->{"brightness"} = shift;    # allow set brightness of final layer/image

	unless ( defined $self->{"brightness"} ) {
		$self->{"brightness"} = 0;
	}

	$self->{"opaque"} = shift;

	unless ( defined $self->{"opaque"} ) {
		$self->{"opaque"} = 100;
	}

	$self->{"3DEdges"} = shift;

	unless ( defined $self->{"3DEdges"} ) {
		$self->{"3DEdges"} = 0;
	}

	$self->{"overlay"} = shift;    # allow place overlay image over basic colored/textured canvas

	return $self;
}

sub GetType {
	my $self = shift;

	return $self->{"type"};
}

sub SetType {
	my $self = shift;

	$self->{"type"} = shift;
}

sub GetColor {
	my $self = shift;

	return $self->{"color"};
}

sub SetColor {
	my $self = shift;

	$self->{"color"} = shift;
}

sub GetTexture {
	my $self = shift;
	return $self->{"texture"};
}

sub SetTexture {
	my $self = shift;
	$self->{"texture"} = shift;
}

sub GetOverlayTexture {
	my $self        = shift;
	my $overlayName = shift;    # Physic name of overlay texture

	return $self->{"overlay"};
}

sub SetOverlayTexture {
	my $self = shift;

	$self->{"overlay"} = shift;
}

sub GetBrightness {
	my $self = shift;

	return $self->{"brightness"};
}

sub SetBrightness {
	my $self = shift;

	$self->{"brightness"} = shift;
}

sub GetOpaque {
	my $self = shift;

	return $self->{"opaque"};
}

sub SetOpaque {
	my $self = shift;

	$self->{"opaque"} = shift;
}

sub Get3DEdges {
	my $self = shift;

	return $self->{"3DEdges"};
}

# passed value
# 0 - no edges
# > 0 - value of blur ("sharbness of edge" 1-9)
sub Set3DEdges {
	my $self = shift;

	$self->{"3DEdges"} = shift;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

