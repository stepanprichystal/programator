
#-------------------------------------------------------------------------------------------#
# This sctructure contain information: type of layer: mask, silk, copeer etc...
# Amd Which layer merge
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::FinalPreview::LayerData::LayerData;

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"type"}         = shift;
	$self->{"order"}        = undef;
	$self->{"color"}        = undef;
	$self->{"texture"}      = undef;
	$self->{"brightness"}   = undef;    # allow set brightness of final layer/image
	$self->{"output"}       = undef;
	$self->{"transparency"} = 100;

	my @l = ();
	$self->{"singleLayers"} = \@l;

	return $self;
}

sub PrintLayer {
	my $self = shift;

	if ( $self->{"output"} && ( defined $self->{"color"} || defined $self->{"texture"} ) ) {

		return 1;
	}
	else {

		return 0;
	}

}

sub GetColor {
	my $self = shift;
	return $self->{"color"};
}

sub SetColor {
	my $self  = shift;
	my $color = shift;

	$self->{"color"} = $color;
}

sub GetTexture {
	my $self = shift;
	return $self->{"texture"};
}

sub SetTexture {
	my $self    = shift;
	my $texture = shift;

	$self->{"texture"} = $texture;
}

sub GetBrightness {
	my $self = shift;
	return $self->{"brightness"};
}

sub SetBrightness {
	my $self       = shift;
	my $brightness = shift;

	$self->{"brightness"} = $brightness;
}

sub SetTransparency {
	my $self = shift;
	my $val  = shift;

	$self->{"transparency"} = $val;
}

sub GetTransparency {
	my $self = shift;

	return $self->{"transparency"};
}

sub GetType {
	my $self = shift;

	return $self->{"type"};
}

sub GetOutputLayer {
	my $self = shift;

	return $self->{"output"};
}

sub SetOutputLayer {
	my $self  = shift;
	my $lName = shift;

	$self->{"output"} = $lName;
}

sub AddSingleLayer {
	my $self    = shift;
	my $singleL = shift;

	push( @{ $self->{"singleLayers"} }, $singleL );
}

sub GetSingleLayers {
	my $self = shift;
	return @{ $self->{"singleLayers"} };
}

sub HasLayers {
	my $self = shift;
	scalar( @{ $self->{"singleLayers"} } );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

