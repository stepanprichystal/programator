
#-------------------------------------------------------------------------------------------#
# Description: Base class for semi produc of stackup
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::Stackup::StackupProduct::ProductBase;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Stackup::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	# id of stackup product
	$self->{"id"} = shift;

	#top pressing signal layer name
	$self->{"topCopper"} = shift;

	#top pressing signal layer number c=1, v2 = 2, etc..
	$self->{"topCopperNum"} = shift;

	#bot pressing signal layer name
	$self->{"botCopper"} = shift;

	#bot pressing signal layer number c=1, v2 = 2, etc..
	$self->{"botCopperNum"} = shift;

	$self->{"layers"} = shift;

	$self->{"NCLayers"} = shift;

	$self->{"productType"} = undef;

	# indicate, if product contain plugging holes
	$self->{"plugging"} = 0;

	# Indicate if core copper contain only full Copper during first product exposition
	# because core is on outer side in pressing package
	$self->{"outerCoreTop"} = 0;
	$self->{"outerCoreBot"} = 0;

	return $self;
}

sub GetId {
	my $self = shift;

	return $self->{"id"};
}

# Return name of most outer TOP copper layer
# (inspite of very frist ProductLayer is not copper)
sub GetTopCopperLayer {
	my $self = shift;

	return $self->{"topCopper"};
}

# Return order of most outer TOP copper layer in entire stackup
# (inspite of very frist ProductLayer is not copper)
sub GetTopCopperNum {
	my $self = shift;

	return $self->{"topCopperNum"};
}

# Return name of most outer BOT copper layer
# (inspite of very frist ProductLayer is not copper)
sub GetBotCopperLayer {
	my $self = shift;

	return $self->{"botCopper"};
}

# Return order of most outer BOT copper layer in entire stackup
# (inspite of very frist ProductLayer is not copper)
sub GetBotCopperNum {
	my $self = shift;

	return $self->{"botCopperNum"};
}

sub GetProductType {
	my $self = shift;

	return $self->{"productType"};
}

# Return if exist plating of this product
sub GetIsPlated {
	my $self = shift;

	if ( scalar( $self->GetPltNCLayers() ) ) {

		return 1;
	}
	else {

		return 0;
	}
}

sub GetLayers {
	my $self      = shift;
	my $layerType = shift;

	my @l = @{ $self->{"layers"} };

	@l = grep { $_->GetType() eq $layerType } @l if ( defined $layerType );

	return @l;
}

# Return Plated NC layers which influence stackup design
# (plating frame drilling do not influence stackup)
sub GetPltNCLayers {
	my $self = shift;

	my @NC = grep { $_->{"plated"} && !$_->{"technical"} } $self->GetNCLayers();
	return @NC;
}

# Return all NC layers which start/stop at product
sub GetNCLayers {
	my $self = shift;
 
	  return @{ $self->{"NCLayers"} };
}

sub SetPlugging {
	my $self = shift;

	$self->{"plugging"} = shift;
}

sub GetPlugging {
	my $self = shift;

	return $self->{"plugging"};
}

sub GetOuterCoreTop {
	my $self = shift;

	return $self->{"outerCoreTop"};
}

sub GetOuterCoreBot {
	my $self = shift;

	return $self->{"outerCoreBot"};
}

sub GetSideByCopperLayer {
	my $self  = shift;
	my $layer = shift;    # original layer name eg.:c (not outerc; plgc;...)

	my $side;

	if ( $layer eq $self->GetTopCopperLayer() ) {

		$side = Enums->SignalLayer_TOP;

	}
	elsif ( $layer eq $self->GetBotCopperLayer() ) {

		$side = Enums->SignalLayer_BOT;
	}
	else {

		die "Copper layer: \"$layer\" is not at this Product";
	}

	return $side;
}

# Return total thickness of product in µm
# Plating is included
sub GetThick {
	my $self = shift;
	my $inclOuterPlt = shift // 1;

	my $thick = 0;

	if ( $inclOuterPlt && scalar( $self->GetPltNCLayers() ) > 0 ) {

		$thick += 2 * Enums->Plating_STD;
	}

	foreach my $l ( $self->GetLayers() ) {

		# Layer can by either type ProductL_MATERIAL or ProductL_PRODUCT
		# Each both types have method GetThick

		$thick += $l->GetData()->GetThick(1);
	}

	return $thick;
}

#-------------------------------------------------------------------------------------------#
#  Special methods, working with nested products
#-------------------------------------------------------------------------------------------#

# Return very first or very last layer (IProductLayer) of this product which is type of ProductL_MATERIAL
# If product layer (IProductLayer) is type of ProductL_PRODUCT, go deeper and search until hit layer type ProductL_MATERIAL
sub GetProductOuterMatLayer {
	my $self         = shift;
	my $pos          = shift;    # first/last
	my $sourceProduc = shift;    # reference of source product of returned ProductLayer

	die "Position of IProductLayer layer in IProduct is not defined" unless ( defined $pos );

	my $idx = ( $pos eq "first" ? 0 : -1 );
	my $topStackupL;

	if ( $self->{"layers"}->[$idx]->GetType() eq Enums->ProductL_PRODUCT ) {

		$topStackupL = $self->{"layers"}->[$idx]->GetData()->GetProductOuterMatLayer( $pos, $sourceProduc );

	}
	elsif ( $self->{"layers"}->[$idx]->GetType() eq Enums->ProductL_MATERIAL ) {

		$topStackupL = $self->{"layers"}->[$idx];
		$$sourceProduc = $self if ( defined $sourceProduc );
	}

	return $topStackupL;
}

sub RemoveProductOuterMatLayer {
	my $self         = shift;
	my $pos          = shift;    # first/last
	my $sourceProduc = shift;    # reference of source product of returned ProductLayer

	die "Position of IProductLayer layer in IProduct is not defined" unless ( defined $pos );

	my $lCut;
	my $idx = ( $pos eq "first" ? 0 : -1 );

	if ( $self->{"layers"}->[$idx]->GetType() eq Enums->ProductL_PRODUCT ) {

		$lCut = $self->{"layers"}->[$idx]->GetData()->RemoveProductOuterMatLayer( $pos, $sourceProduc );

	}
	elsif ( $self->{"layers"}->[$idx]->GetType() eq Enums->ProductL_MATERIAL ) {

		$lCut = splice @{ $self->{"layers"} }, $idx, 1;
		$$sourceProduc = $self if ( defined $sourceProduc );
	}

	return $lCut;
}

## Return if there is plating of product (top or bot side)
## While method GetIsPLated() return if plating exist in current product,
## this method go through all outer nested Products and return 1 if exist at least one product with plating
#sub GetExistOuterPlating{
#	my $self         = shift;
#	my $side          = shift;    # top/bot
#
#	die "Side of outer plating is not defined" unless ( defined $side );
#
# 	my $plating = $self->GetIsPlated();
#	my $idx = ( $side eq "top" ? 0 : -1 );
#
#	if ( $self->{"layers"}->[$idx]->GetType() eq Enums->ProductL_PRODUCT ) {
#
#		$plating = $self->{"layers"}->[$idx]->GetData()->GetExistOuterPlating( $side );
#
#	}
#	elsif ( $self->{"layers"}->[$idx]->GetType() eq Enums->ProductL_MATERIAL ) {
#
#		$plating = 1 if($self->GetIsPlated());
#	}
#
#	return $plating;
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

