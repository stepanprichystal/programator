
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnGenerator::CpnLayers::LayerBase;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::Coupon::Enums';
use aliased 'CamHelpers::CamLayer';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	#require rows in nif section
	$self->{"layerName"} = shift;

	$self->{"inCAM"}    = undef;
	$self->{"jobId"}    = undef;
	$self->{"step"}     = undef;
	$self->{"settings"} = undef;     # global settings for generating coupon

	return $self;
}

sub Init {
	my $self = shift;

	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"step"}     = shift;
	$self->{"settings"} = shift;

	$self->{"drawing"} = SymbolDrawing->new( $self->{"inCAM"}, $self->{"jobId"}, );

}

sub GetLayerName {
	my $self = shift;

	return $self->{"layerName"};
}

sub GetDrawing {
	my $self = shift;

	return $self->{"drawing"};
}

sub _Draw {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	CamLayer->WorkLayer( $inCAM, $self->{"layerName"} );

	$self->{"drawing"}->Draw();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

