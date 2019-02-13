#-------------------------------------------------------------------------------------------#
# Description: Multichain is group of UniChainSeq which create connected sequence of features.
# It is abstraction above standard UniChainSeq.
# Chain number of UniChainSeq is not considered in this case, therefore "UniMultiChain" - can be
# created from many different Chain tools
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniRTM::UniChain::UniMultiChainSeq;

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Packages::CAM::UniRTM::Enums';
use aliased 'Packages::Routing::RoutLayer::RoutParser::RoutArc';
use aliased 'Enums::EnumsRout';
use aliased "Packages::Polygon::PolygonFeatures";
use aliased 'Packages::Polygon::Polygon::PolygonPoints';
use aliased 'Packages::Polygon::Polygon::PolygonArc';
use aliased 'Packages::Polygon::Polygon::PolygonAttr';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"chains"}    = shift;
	$self->{"cyclic"}    = undef;
	$self->{"direction"} = undef;

	$self->{"isInside"} = 0;    # if is inside another chain sequence (inside mean fully inside or at lesast partly)

	return $self;
}

# GET/SET Properties -------------------------------------

sub SetIsInside {
	my $self     = shift;
	my $isInside = shift;

	$self->{"isInside"} = $isInside;

}

sub GetIsInside {
	my $self = shift;

	return $self->{"isInside"};

}

sub SetCyclic {
	my $self   = shift;
	my $cyclic = shift;

	$self->{"cyclic"} = $cyclic;

}

sub GetCyclic {
	my $self = shift;

	return $self->{"cyclic"};

}

sub GetChains {
	my $self = shift;

	return @{ $self->{"chains"} };

}

sub SetDirection {
	my $self = shift;
	my $dir  = shift;

	$self->{"direction"} = $dir;
}

# Return direction of cyclic rout polygon (based on all original feature)
# CW - clockwise
# CWW - counter  clockwise
# undef - not all original features has no same direction, thus we can't return direction
sub GetDirection {
	my $self = shift;
	
	return $self->{"direction"}
}

sub SetFeatureType {
	my $self = shift;
	my $type = shift;

	$self->{"featureType"} = $type;

}

sub GetFeatureType {
	my $self = shift;

	return $self->{"featureType"};

}

sub AddOutsideMultiChainSeq {
	my $self  = shift;
	my $multiChain = shift;

	push( @{ $self->{"outMultiChainSeq"} }, $multiChain );

}

sub GetOutsideMultiChainSeq {
	my $self = shift;

	return $self->{"outMultiChainSeq"};

}

# Reeturn points, which crate given chain. Points are used to detect mutual position of chainsequences
# For Line, Arc (arc is fragmented on small arcs) return list of points
# - ecah points are not duplicated
# - for cycle chains, return sorted points CW (start and and are not equal)
# For Surfaces
# - return list of sorted points CW, which create envelop for surface (convex-hull)

sub GetShapePoints {
	my $self = shift;

	my $accuracy = 0.2;    # radius tolerance, when convert arc to points

	my @points = ();

	my @features = $self->GetFeatures();

	if ( $self->GetFeatureType eq Enums->FeatType_SURF ) {

		@points = Helper->GetSurfPoints( \@features, $accuracy );
	}
	else {

		@points = Helper->GetLineArcShapePoints( \@features, $accuracy );
	}

	return @points;
}
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

