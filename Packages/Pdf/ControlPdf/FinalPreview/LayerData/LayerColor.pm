
#-------------------------------------------------------------------------------------------#
# This sctructure contain information: type of layer: mask, silk, copeer etc...
# Amd Which layer merge
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::FinalPreview::LayerData::LayerColor;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Pdf::ControlPdf::FinalPreview::Enums';

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

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

