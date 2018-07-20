
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::CpnLayers::LayerBase;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Programs::Coupon::Enums';
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
	 

	return $self;
}

sub Init {
	my $self = shift;

	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"step"}     = shift;

	$self->{"drawing"} = SymbolDrawing->new( $self->{"inCAM"}, $self->{"jobId"}, );

}

sub GetLayerName {
	my $self = shift;

	return $self->{"layerName"};
}
 
sub Draw {
	my $self = shift;


	$self->{"drawing"}->Draw();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

