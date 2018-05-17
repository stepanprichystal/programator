#-------------------------------------------------------------------------------------------#
# Description: Contain special function and computation for countersink
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Tooling::CountersinkHelper;

#3th party library
use strict;
use warnings;
use Math::Trig;
use Math::Trig ':pi';

#local library

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Compute new final "slot" radius for given tool and tool slot radius
# Tool rout according given radius. Whole tool diameter is inside "routed circle"
# Thus center of tool is NOT center of hole diameter
# Used for countersing diameters larger than available tool diameters
# All in µm
sub GetSlotRadiusByToolDepth {
	my $self         = shift;
	my $slotRadius   = shift;    # radius if we doesn't consider tool angle
	my $toolDiameter = shift;    # tool diameter
	my $toolAngle    = shift;
	my $toolDepth    = shift;

	my $rRadius = $slotRadius - ( $toolDiameter / 2 - ( tan( deg2rad( $toolAngle / 2 ) ) * $toolDepth ) );

	if ( $rRadius > $slotRadius ) {

		return $slotRadius;
	}

	return $rRadius;
}

# Compute new final  radius for given tool
# Tool drill only, no slot
# Center of tool is center of hole diameter
# All in µm
sub GetHoleRadiusByToolDepth {
	my $self         = shift;
	my $toolDiameter = shift;
	my $toolAngle    = shift;
	my $toolDepth    = shift;

	my $rRadius = tan( deg2rad( $toolAngle / 2 ) ) * $toolDepth;

	if ( $rRadius * 2 > $toolDiameter ) {
		return $toolDiameter/2;
	}

	return $rRadius;
}

# If counter sink is plated, drill depth has to be larger
# Return this extra depth
sub GetExtraDepthIfPlated {
	my $self      = shift;
	my $toolAngle = shift;

	my $platinThick = 50;    #µm

	# DO NOT CONSIDER ANGLE OF DRILL, USE ONLY CONSTANT 50µm for simplicity
	#my $dDepth = $platinThick / sin( deg2rad( $toolAngle / 2 ) );

	return $platinThick;
}

## All in µm
#sub GetDepthSlotCounterSink {
#	my $self         = shift;
#	my $finalRadius  = shift;
#	my $toolDiameter = shift;
#	my $toolAngle    = shift;
#	my $plating      = shift;
#	my $platedRadius = shift;
#
#	my $depth = ( $toolDiameter / 2 ) / tan( deg2rad( $toolAngle / 2 ) );
#
#	# Compute new slot radius
#	# we can't do bigger depth, but we have to do larger slot radius
#	if ($plating) {
#
#		my $tmpDepth = $self->GetExtraDepthIfPlated($toolAngle);
#
#		my $a = tan( deg2rad( $toolAngle / 2 ) ) * ( $depth + $tmpDepth );
#
#		$$platedRadius = $finalRadius + tan( deg2rad( $toolAngle / 2 ) ) * ( $depth + $tmpDepth ) - ( $toolDiameter / 2 );
#	}
#
#	# do chack if depth is no so bif for given toolDiameter
#	my $drillPointLen = ( $toolDiameter / 2 ) / tan( deg2rad( $toolAngle / 2 ) );
#	if ( $depth > $drillPointLen ) {
#
#		die "Too big final radius: $finalRadius, for given tool diameter: $toolDiameter and tool angle: $toolAngle \n"
#		  . "\"Tool point lenght\" is: $drillPointLen, but computed depth is bigger: $depth";
#	}
#
#	return $depth;
#}
#
## All in µm
#sub GetDepthHoleCounterSink {
#	my $self         = shift;
#	my $finalRadius  = shift;
#	my $toolDiameter = shift;
#	my $toolAngle    = shift;
#	my $plating      = shift;
#
#	my $depth = ($finalRadius) / tan( deg2rad( $toolAngle / 2 ) );
#
#	if ($plating) {
#
#		$depth += $self->GetExtraDepthIfPlated($toolAngle);
#
#	}
#
#	# do chack if depth is no so bif for given toolDiameter
#	my $drillPointLen = ( $toolDiameter / 2 ) / tan( deg2rad( $toolAngle / 2 ) );
#	if ( $depth > $drillPointLen ) {
#
#		die "Too big final radius: $finalRadius, for given tool diameter: $toolDiameter and tool angle: $toolAngle \n"
#		  . "\"Tool point lenght\" is: $drillPointLen, but computed depth is bigger: $depth";
#	}
#
#	return $depth;
#
#}


# Return exceeded depth o tool if exist (if depth ot tool is bigger than size of tool peak)
# Exceeded shape   looks like this:
# |     |  - depth of drill where are streight "hole walls" (exceeded depth)
#  \   /
#	| |
# (if  depth is smaller than 10µm return 0 (Round error during compute tool peak length))
sub GetToolExceededDepth {
	my $self         = shift;
	my $toolDiameter   = shift; # µm
	my $toolAngle    = shift; 
	my $toolDepth    = shift; # µm
 
	my $csHeadDepth = ( $toolDepth - ($toolDiameter/2) / tan( deg2rad( ( $toolAngle / 2 ) ) ) );
	if ( $csHeadDepth > 0 && abs($csHeadDepth) > 10 ) {
		$csHeadDepth = sprintf( "%.2f", $csHeadDepth );
	}
	else {
		$csHeadDepth = 0;
	}

	return $csHeadDepth;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Tooling::CountersinkHelper';

	#print CountersinkHelper->GetSlotRadiusByToolDepth( 10, 6, 120, 1.5 );

	#print CountersinkHelper->GetHoleRadiusByToolDepth( 6000, 60, 3000 );

	#my $newRadius = undef;
	#print CountersinkHelper->GetDepthHoleCounterSink( 3000, 6000, 90, 1);

}

1;
