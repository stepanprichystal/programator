#-------------------------------------------------------------------------------------------#
# Description:
# Source fetures can have either CW direction or CCW direction
# All rout start searching algorithm search rout start in Left-Top corner of CW oriented cyclic rout
# Of default non rotated outline
# If we want to search rout start in another corner, outline rout should be modified first.
# In other word wee need to transform "desired rout start sorner" to LT_CW position
# Example 1:
# We want to find rout start for RB_CW corner:
# 1) Rotate outline 180° CCW
# 2) Find rout start in Left Top corner
# 3) Rotate outline BACK
# Example 2:
# We want to find rout start for RB_CCW corner:
# 1) Rotate outline 90° CCW
# 2) Mirror outline in Y axes
# 3) Find rout start  in Left Top corner
# 4) Mirror outline BACK
# 3) Rotate outline BACK
#
# First diagram shows default orientation and corners positions
# for searching rout start in Left Top corner. For other corner except LT_CW outline must be rotated
# Second diagram shows CCW outline. For all corner outline must be mirrored + rotated(depends on corner)
#
#           ====> (CW)
# !!! LT_CW  -----  RT_CW
#           |     |
#           |     |
#     LB_CW  -----  RB_CW
#
#
#             <==== (CCW)
#     LT_CCW  -----  RT_CCW
#            |     |
#            |     |
#     LB_CCW  -----  RB_CCW
#
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::RoutStart::RoutStartAdjust;

#3th party library
use strict;
use warnings;
use XML::Simple;
use Math::Trig ':pi';

#local library
use aliased 'Packages::Routing::RoutLayer::RoutParser::RoutTransform';
use aliased 'Packages::Polygon::PolygonFeatures';
use aliased 'Packages::Polygon::PointsTransform';
use aliased 'Packages::Routing::RoutLayer::RoutParser::RoutCyclic';
use aliased 'Enums::EnumsRout';

use constant LT_CORNER => "LT";
use constant LB_CORNER => "LB";
use constant RB_CORNER => "RB";
use constant RT_CORNER => "RT";

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"features"} = shift;

	#get limits of rout chain by points
	my @points = ();
	foreach my $f ( @{ $self->{"features"} } ) {
		my %p1 = ( "x" => $f->{"x1"}, "y" => $f->{"y1"} );
		my %p2 = ( "x" => $f->{"x2"}, "y" => $f->{"y2"} );
		push( @points, ( \%p1, \%p2 ) );
	}

	my %lim = PointsTransform->GetLimByPoints( \@points );

	$self->{"lim"}   = \%lim;
	$self->{"trans"} = [];

	return $self;
}

sub Transform {
	my $self               = shift;
	my $reqRoutStartCorner = shift;    # Requested outline rout start corner
	my $finalPCBangle      = shift;    # final PCB rotation on panel
	 

	my $outlDir = RoutCyclic->GetRoutDirection( $self->{"features"} );    # EnumsRout->Dir_CW/EnumsRout->Dir_CCW

	# target corner will be moved to LeftTop corner (CW direction is set)
	my $oriCornerNoAngle = $self->__GetCorner2Transform( $reqRoutStartCorner, $finalPCBangle, $outlDir );

	die "Corner is not set" unless ( defined $oriCornerNoAngle );

	# Pcb widtt /height
	my $width  = abs( $self->{"lim"}->{"xMax"} - $self->{"lim"}->{"xMin"} );
	my $height = abs( $self->{"lim"}->{"yMax"} - $self->{"lim"}->{"yMin"} );

	# 1) Build transformations
	$self->{"trans"} = [];

	if ( $outlDir eq EnumsRout->Dir_CW ) {

		if ( $oriCornerNoAngle eq LT_CORNER ) {

			# no rotation
			# no move
		}
		elsif ( $oriCornerNoAngle eq RT_CORNER ) {

			push( @{ $self->{"trans"} }, [ "rotationCCW", 90 ] );
			push( @{ $self->{"trans"} }, [ "moveX",       $height ] );
		}
		elsif ( $oriCornerNoAngle eq RB_CORNER ) {

			push( @{ $self->{"trans"} }, [ "rotationCCW", 90 ] );
			push( @{ $self->{"trans"} }, [ "moveX",       $height ] );
			push( @{ $self->{"trans"} }, [ "rotationCCW", 90 ] );
			push( @{ $self->{"trans"} }, [ "moveX",       $width ] );

		}
		elsif ( $oriCornerNoAngle eq LB_CORNER ) {

			push( @{ $self->{"trans"} }, [ "rotationCCW", 90 ] );
			push( @{ $self->{"trans"} }, [ "moveX",       $height ] );
			push( @{ $self->{"trans"} }, [ "rotationCCW", 90 ] );
			push( @{ $self->{"trans"} }, [ "moveX",       $width ] );
			push( @{ $self->{"trans"} }, [ "rotationCCW", 90 ] );
			push( @{ $self->{"trans"} }, [ "moveX",       $height ] );
		}

	}
	elsif ( $outlDir eq EnumsRout->Dir_CCW ) {

		if ( $oriCornerNoAngle eq RT_CORNER ) {

			push( @{ $self->{"trans"} }, [ "mirrorY", 0 ] );
			push( @{ $self->{"trans"} }, [ "moveX",   $width ] );
		}
		elsif ( $oriCornerNoAngle eq RB_CORNER ) {

			push( @{ $self->{"trans"} }, [ "rotationCCW", 90 ] );
			push( @{ $self->{"trans"} }, [ "moveX",       $height ] );
			push( @{ $self->{"trans"} }, [ "mirrorY",     0 ] );
			push( @{ $self->{"trans"} }, [ "moveX",       $height ] );

		}
		elsif ( $oriCornerNoAngle eq LB_CORNER ) {

			push( @{ $self->{"trans"} }, [ "rotationCCW", 90 ] );
			push( @{ $self->{"trans"} }, [ "moveX",       $height ] );
			push( @{ $self->{"trans"} }, [ "rotationCCW", 90 ] );
			push( @{ $self->{"trans"} }, [ "moveX",       $width ] );
			push( @{ $self->{"trans"} }, [ "mirrorY",     0 ] );
			push( @{ $self->{"trans"} }, [ "moveX",       $width ] );

		}
		elsif ( $oriCornerNoAngle eq LT_CORNER ) {

			push( @{ $self->{"trans"} }, [ "rotationCCW", 90 ] );
			push( @{ $self->{"trans"} }, [ "moveX",       $height ] );
			push( @{ $self->{"trans"} }, [ "rotationCCW", 90 ] );
			push( @{ $self->{"trans"} }, [ "moveX",       $width ] );
			push( @{ $self->{"trans"} }, [ "rotationCCW", 90 ] );
			push( @{ $self->{"trans"} }, [ "moveX",       $height ] );
			push( @{ $self->{"trans"} }, [ "mirrorY",     0 ] );
			push( @{ $self->{"trans"} }, [ "moveX",       $height ] );
		}

	}

	# Push tranformation which register pcb to 0,0 coordination
	if ( scalar( @{ $self->{"trans"} } ) ) {

		# 1) test if features are in zero
		if ( $self->{"lim"}->{"xMin"} != 0 || $self->{"lim"}->{"yMin"} != 0 ) {

			unshift( @{ $self->{"trans"} }, [ "moveX", $self->{"lim"}->{"xMin"} ] );
			unshift( @{ $self->{"trans"} }, [ "moveY", $self->{"lim"}->{"yMin"} ] );
		}
	}

	# 2) Transform

	foreach my $t ( @{ $self->{"trans"} } ) {

		if ( $t->[0] eq "rotationCCW" ) {

			RoutTransform->RotateRout( $t->[1], EnumsRout->Dir_CCW, $self->{"features"} );

		}
		elsif ( $t->[0] eq "moveX" ) {

			RoutTransform->MoveRout( $t->[1], 0, $self->{"features"} );

		}
		elsif ( $t->[0] eq "moveY" ) {

			RoutTransform->MoveRout( 0, $t->[1], $self->{"features"} );

		}
		elsif ( $t->[0] eq "mirrorY" ) {

			RoutTransform->MirrorRoutY( $t->[1], $self->{"features"} );
		}
		else {
			die "Unknow transform";
		}
	}
}

sub TransformBack {
	my $self = shift;

	# 1) transform back (do reverse operation)

	foreach my $t ( reverse( @{ $self->{"trans"} } ) ) {

		if ( $t->[0] eq "rotationCCW" ) {

			RoutTransform->RotateRout( $t->[1], EnumsRout->Dir_CW, $self->{"features"} );

		}
		elsif ( $t->[0] eq "moveX" ) {

			RoutTransform->MoveRout( -$t->[1], 0, $self->{"features"} );

		}
		elsif ( $t->[0] eq "moveY" ) {

			RoutTransform->MoveRout( 0, -$t->[1], $self->{"features"} );

		}
		elsif ( $t->[0] eq "mirrorY" ) {

			RoutTransform->MirrorRoutY( $t->[1], $self->{"features"} );
		}
		else {
			die "Unknow transform";
		}
	}

	$self->{"trans"} = []

}

# Return specific corner which sohould be transform to defualt LeftTop corner 
# (corner position of original non rotated outline)
# In order to find rout start
# Note: Class method
sub __GetCorner2Transform {
	my $self               = shift;
	my $reqRoutStartCorner = shift;    # Requested outline rout start corner
	my $finalPCBangle      = shift;    # final PCB rotation on panel
	my $routDirection      = shift;

	my $corner = undef;

	if ( $reqRoutStartCorner eq EnumsRout->OutlineStart_LEFTTOP ) {

		if ( $routDirection eq EnumsRout->Dir_CW ) {

			if ( $finalPCBangle == 0 ) {

				$corner = LT_CORNER;
			}
			elsif ( $finalPCBangle == 90 ) {
				$corner = RT_CORNER;
			}
			elsif ( $finalPCBangle == 180 ) {
				$corner = RB_CORNER;
			}
			elsif ( $finalPCBangle == 270 ) {
				$corner = LB_CORNER;
			}
		}
	}
	elsif ( $reqRoutStartCorner eq EnumsRout->OutlineStart_RIGHTTOP ) {
		if ( $routDirection eq EnumsRout->Dir_CCW ) {

			if ( $finalPCBangle == 0 ) {

				$corner = RT_CORNER;
			}
			elsif ( $finalPCBangle == 90 ) {
				$corner = RB_CORNER;
			}
			elsif ( $finalPCBangle == 180 ) {
				$corner = LB_CORNER;
			}
			elsif ( $finalPCBangle == 270 ) {
				$corner = LT_CORNER;
			}
		}
	}

	die "No translation for corner: $reqRoutStartCorner; rout dir: $routDirection; pcb angle: $finalPCBangle"
	  unless ( defined $corner );

	return $corner;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

