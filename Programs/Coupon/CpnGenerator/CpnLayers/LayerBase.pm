
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
use aliased 'Packages::CAM::SymbolDrawing::Enums' => 'DrawEnums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	#require rows in nif section
	$self->{"layerName"} = shift;

	# determines order of drawing in group of other layers
	# Smaller number means higher priority
	$self->{"drawPriority"} = shift;

	$self->{"inCAM"} = undef;
	$self->{"jobId"} = undef;
	$self->{"step"}  = undef;

	return $self;
}

sub Init {
	my $self = shift;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;

	$self->{"drawing"} = SymbolDrawing->new( $self->{"inCAM"}, $self->{"jobId"}, );

}

sub GetLayerName {
	my $self = shift;

	return $self->{"layerName"};
}

# determines order of drawing in group of other layers
# Smaller number means higher priority
sub GetDrawPriority {
	my $self = shift;

	die "Layer draw order priority is not defined" unless(defined $self->{"drawPriority"});

	return $self->{"drawPriority"};
}

sub Draw {
	my $self = shift;

	$self->{"drawing"}->Draw();
}

# For signal layer convert polarity if signal layer is negative
sub _InvertPolar {
	my $self        = shift;
	my $polarity    = shift;
	my $layerLayout = shift;

	my $t = $layerLayout->GetType();

	die "Layer: " . $layerLayout->GetLayerName() . " is not signal layer"
	  if ( $t ne "signal" && $t ne "power_ground" && $t ne "mixed" );

	# if layer is negative, invert polarity
	if ( $layerLayout->GetPolarity() eq DrawEnums->Polar_NEGATIVE ) {

		return $polarity eq DrawEnums->Polar_POSITIVE
		  ? DrawEnums->Polar_NEGATIVE
		  : DrawEnums->Polar_POSITIVE;
	}
	else {

		return $polarity;
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

