#-------------------------------------------------------------------------------------------#
# Description: Contain listo of all tools in layer, regardless it is tool from surface, pad,
# lines..
# Responsible for tools are unique (diameter + typeProc)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniRTM::UniRTM::UniChainSeq;

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

	$self->{"chain"}     = shift;
	$self->{"cyclic"}    = undef;
	$self->{"direction"} = undef;

	$self->{"startEdge"} = undef;

	my @foots = ();
	$self->{"footsDown"} = \@foots;    # features, which cintain foot_down attribute

	$self->{"isInside"} = 0;           # if is inside another chain sequence (inside mean fully inside or at lesast partly)

	my @outsideChainSeq = ();
	$self->{"outsideChainSeq"} = \@outsideChainSeq;    # chain seq ref, which is this chain sequence inside

	# Features, wchich chain sequnece is created from. 
	$self->{"oriFeatures"}    = [];  
	
	# Features, wchich chain sequnece is created from. 
	# These features can by modified during UniRTM initialization (arc/circles are fragmented, direction is changed to CW etc)
	$self->{"features"}    = [];               
	$self->{"featureType"} = undef;                    # tell type of features, wchich chain is created from. FeatType_SURF/FeatType_LINEARC

	# ==== Property set, only if rout is cyclic ====

	$self->{"modified"} =
	  0;    # only when seq is cyclic. If modified = 1, sequence was modified during parsing (arc fragment, edge point switching etc..)

	return $self;
}

# Helper methods -------------------------------------

# Reeturn points, which crate given chain. Points are used to detect mutual position of chainsequences
# For Line, Arc (arc is fragmented on small arcs) return list of points
# - ecah points are not duplicated
# - for cycle chains, return sorted points CW (start and and are not equal)
# For Surfaces
# - return list of sorted points CW, which create envelop for surface (convex-hull)

sub GetPoints {
	my $self = shift;

	my $accuracy = 0.2; # radius tolerance, when convert arc to points

	my @points = ();

	my @features = $self->GetFeatures();

	if ( $self->GetFeatureType eq Enums->FeatType_SURF ) {

		# Chain sequnce created form surface contain only one surface feature
		my $singleIsland    = 1;
		my @surfaceEnvelops = ();

		# if more surfaces ore more islands in one surface, do convex hull for all surfaces
		if ( scalar(@features) > 1 ) {
			$singleIsland = 0;
		}

		foreach my $surfFeat (@features) {

			my @envelops = PolygonFeatures->GetSurfaceEnvelops( $surfFeat, $accuracy );

			if ( scalar(@envelops) > 1 ) {
				$singleIsland = 0;
			}

			foreach my $e (@envelops) {
				push( @surfaceEnvelops, @{$e} );
			}
		}

		@surfaceEnvelops = map { [ $_->{"x"}, $_->{"y"} ] } @surfaceEnvelops;

		# Do convex hull from all surface envelop points
		if ($singleIsland) {

			#@surfaceEnvelops = map { [ $_->{"x"}, $_->{"y"} ] } @surfaceEnvelops;
		}
		else {

			@surfaceEnvelops = PolygonPoints->GetConvexHull( \@surfaceEnvelops );
		}

		@points = @surfaceEnvelops;

		#		my @envPoints = map { @{ $_->{"envelop"} } } $self->GetFeatures();
		#
		#		push( @points, map { [ $_->{"x"}, $_->{"y"} ] } @envPoints );

	}
	else {

		my @pointsPom = ();

		
		for(my $i = 0; $i <scalar(@features); $i++ ) {

			my $f = $features[$i];
			my $lastPoint = undef;

			if ( $f->{"type"} =~ /A/i ) {

				my $result = undef;
 				
 				$f->{"dir"} = $f->{"newDir"}; # GetFragmentArc assume propertt "dir"
				my @p = PolygonArc->GetFragmentArc( $f, $accuracy, \$result );

				if ($result) {

					push( @pointsPom, @p );
				
				}else{
					# takke start + end point of arc/circle
					push( @pointsPom, [ $f->{"x1"}, $f->{"y1"} ] );

				  }

			}
			elsif ( $f->{"type"} =~ /l/i ) {

				push( @pointsPom, [ $f->{"x1"},  $f->{"y1"} ] );
				
			}
			
			$lastPoint = [ $f->{"x2"}, $f->{"y2"} ];
			
			if($i == scalar(@features) -1){
				push( @points,   $lastPoint );
			}
		}


		push( @points,   @pointsPom );    

	}

	return @points;
}

sub HasFootDown {
	my $self = shift;

	if ( scalar( @{ $self->{"footsDown"} } ) ) {
		return 1;
	}
	else {
		return 0;
	}
}

# Chain seq is cyclic when com is left, is not inside another rout and is cyclic
sub IsOutline {
	my $self = shift;

	if (    $self->GetChain()->GetComp() eq EnumsRout->Comp_LEFT
		 && !$self->GetIsInside()
		 && $self->GetCyclic()
		 && $self->GetDirection() eq EnumsRout->Dir_CW )
	{

		return 1;
	}
	else {

		return 0;
	}
}

sub GetStrInfo {
	my $self = shift;

	my @features = @{ $self->{"oriFeatures"} };
	my @ids      = map { $_->{"id"} } @features;
	my $idStr    = join( ";", @ids );

	my $str = "Chain number: \"" . $self->GetChain()->GetChainOrder() . "\" ( feature ids: \"" . $idStr . "\")";
}

# GET/SET Properties -------------------------------------

sub GetFeatures {
	my $self = shift;

	return @{ $self->{"features"} };

}

sub SetFeatures {
	my $self     = shift;
	my $features = shift;

	$self->{"features"} = $features;
}


sub GetOriFeatures {
	my $self = shift;

	return @{ $self->{"oriFeatures"} };

}

sub SetOriFeatures {
	my $self     = shift;
	my $features = shift;

	$self->{"oriFeatures"} = $features;
}

sub AddFeature {
	my $self    = shift;
	my $feature = shift;

	push( @{ $self->{"features"} }, $feature );

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

sub SetIsInside {
	my $self     = shift;
	my $isInside = shift;

	$self->{"isInside"} = $isInside;

}

sub GetIsInside {
	my $self = shift;

	return $self->{"isInside"};

}

sub AddOutsideChainSeq {
	my $self  = shift;
	my $chain = shift;

	push( @{ $self->{"outsideChainSeq"} }, $chain );

}

sub GetOutsideChainSeq {
	my $self = shift;

	return $self->{"outsideChainSeq"};

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

sub SetFootsDown {
	my $self     = shift;
	my $footDown = shift;

	$self->{"footsDown"} = $footDown;

}

sub GetFootsDown {
	my $self = shift;

	return @{ $self->{"footsDown"} };

}

sub GetChain {
	my $self = shift;

	return $self->{"chain"};

}

sub SetModified {
	my $self     = shift;
	my $modified = shift;

	$self->{"modified"} = $modified;

}

sub GetModified {
	my $self = shift;

	return $self->{"modified"};

}

sub SetDirection {
	my $self = shift;
	my $dir  = shift;

	$self->{"direction"} = $dir;
}

sub GetDirection {
	my $self = shift;

	return $self->{"direction"};
}

sub SetStartEdge {
	my $self = shift;
	my $dir  = shift;

	$self->{"startEdge"} = $dir;
}

sub GetStartEdge {
	my $self = shift;

	return $self->{"startEdge"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

