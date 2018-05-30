
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::MicrostripBuilders::CouponLayers::LayerBase;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;
	
	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	
	#require rows in nif section
	$self->{"layerName"} = shift;
	
	return $self;
}

sub Init{
	my $self = shift;
	
	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift; 
	$self->{"drawing"}  = SymbolDrawing->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"position"} );
 
}
 
 
sub GetLayerName{
	my $self = shift;
	
	return $self->{"layerName"};
} 

sub GetDrawing{
	my $self = shift;
	
	return $self->{"drawing"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

