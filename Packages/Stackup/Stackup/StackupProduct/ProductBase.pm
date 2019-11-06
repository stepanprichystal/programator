
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

	$self->{"PltNClayers"} = shift;

	$self->{"productType"} = undef;

	# indicate, if product contain plugging holes
	$self->{"plugging"} = 0;

	# Indicate if core copper contain only full Copper during first product exposition
	# because core is on outer side in pressing package
	$self->{"outerCoreTop"} = 0;
	$self->{"outerCoreBot"} = 0;

	return $self;
}

sub GetTopCopperLayer {
	my $self = shift;

	return $self->{"topCopper"};
}

sub GetTopCopperNum {
	my $self = shift;

	return $self->{"topCopperNum"};
}

sub GetBotCopperLayer {
	my $self = shift;

	return $self->{"botCopper"};
}

sub GetBotCopperNum {
	my $self = shift;

	return $self->{"botCopperNum"};
}

sub GetProductType {
	my $self = shift;

	return $self->{"productType"};
}

sub GetIsPlated {
	my $self = shift;

	if ( scalar( @{ $self->{"PltNClayers"} } ) > 0 ) {
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

sub GetPltNCLayers {
	my $self = shift;

	return @{ $self->{"PltNClayers"} };
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
sub GetThick{
	my $self = shift;
	
	my $thick = 0;
	
	if(scalar($self->GetPltNCLayers()) > 0){
		
	}
	
	foreach my $l  ($self->GetLayers()){

		# Layer can by either type ProductL_MATERIAL or ProductL_PRODUCT
		# Each both types have method GetThick

		$thick += $l->GetData()->GetThick();
	}
	
	return $thick;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

