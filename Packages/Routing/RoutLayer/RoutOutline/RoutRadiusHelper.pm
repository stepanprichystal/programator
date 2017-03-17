#-------------------------------------------------------------------------------------------#
# Description: Helper for automatic radius repairs
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::RoutOutline::RoutRadiusHelper;

#3th party library
use strict;
use List::Util qw( min max );
use Math::Trig;
use Math::Polygon::Calc;                 #Math-Polygon
use Math::Geometry::Planar;              #Math-Geometry-Planar-GPC
use Math::Intersection::StraightLine;    #Math-Intersection-StraightLine
use Math::Vec qw(NewVec);
use POSIX 'floor';

#local library

use aliased 'Packages::Routing::RoutLayer::RoutMath::RoutMath';
use aliased 'Packages::Routing::RoutLayer::RoutParser::RoutParser';
use aliased 'Helpers::GeneralHelper';
#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

#Remove small radiuses and replace them by lines, if it is possible
sub RemoveRadiuses {
	my $self       = shift;
	my $sorteEdges = shift;
	my $errors     = shift;

	if ( !scalar( @{$sorteEdges} ) > 1 ) {
		return -1;
	}

	#
	my %result = ();
	$result{"result"}          = 1;       # if no error, result 1
	$result{"boundArc"}        = 0;
	$result{"boundArcVal"}     = undef;
	$result{"newDrillHole"}    = 0;
	$result{"newDrillHoleVal"} = undef;

	my $finder      = Math::Intersection::StraightLine->new();
	my @idToDel     = ();                                        #contain id's with arcm which will be deleted
	my @drillPoints = ();                                        #contain coordinate and size of drill tool
	my $posOfLine;                                               #position of neghobour arc lines. Parallel, Parallel-overlapping, Intersection
	my $vectorAngel;                                             # angel betveen two vectors
	my $intersec;                                                #test if neighbour lines of arc have intersection

	for ( my $i = scalar( @{$sorteEdges} ) - 1 ; $i >= 0 ; $i-- ) {

		unless (    $sorteEdges->[$i]->{"type"} eq "A"
				 && $sorteEdges->[$i]->{"newDir"} eq "CCW"
				 && $sorteEdges->[$i]->{"diameter"} <= 2.2
				 && $sorteEdges->[$i]->{"distance"} <= 2.2 )
		{
			next;
		}

		my %arc = %{ $sorteEdges->[$i] };

		my $next = ( $i + 1 == scalar( @{$sorteEdges} ) ) ? 0 : $i + 1;
		my $before =
		  ( $i == 0 )
		  ? scalar( @{$sorteEdges} ) - 1
		  : $i - 1;

		#test if arc neighbours are line and
		unless (    $sorteEdges->[$next]->{"type"} eq "L"
				 && $sorteEdges->[$before]->{"type"} eq "L" )
		{
			my %val;

			if ( $sorteEdges->[$next]->{"type"} eq "A" ) {
				%val = (
						 "x" => $sorteEdges->[$next]->{"x1"},
						 "y" => $sorteEdges->[$next]->{"y1"}
				);
			}
			if ( $sorteEdges->[$before]->{"type"} eq "A" ) {
				%val = (
						 "x" => $sorteEdges->[$before]->{"x2"},
						 "y" => $sorteEdges->[$before]->{"y2"}
				);
			}
			$result{"boundArc"}    = 1;
			$result{"boundArcVal"} = \%val;

			return %result;
		}

		my $innerAngel = 0;
		my $origin = NewVec( 0, 0, 0 );
		$intersec = -1;

		#SMAYAT
		if ( $arc{"id"} == 1223 ) {
			1 == 1;
		}

		#Are paralel
		my $parallel = RoutMath->LinesAreParallel( $sorteEdges->[$before], $sorteEdges->[$next] );

		if ( !$parallel ) {
			my $vector_a =
			  [ [ $sorteEdges->[$next]->{"x1"}, $sorteEdges->[$next]->{"y1"} ], [ $sorteEdges->[$next]->{"x2"}, $sorteEdges->[$next]->{"y2"} ] ];
			my $vector_b = [
							 [ $sorteEdges->[$before]->{"x1"}, $sorteEdges->[$before]->{"y1"} ],
							 [ $sorteEdges->[$before]->{"x2"}, $sorteEdges->[$before]->{"y2"} ]
			];

			$intersec = $finder->points( $vector_a, $vector_b );

		}
		else {
			my $vBef = NewVec( $sorteEdges->[$before]->{"x2"} - $sorteEdges->[$before]->{"x1"},
							   $sorteEdges->[$before]->{"y2"} - $sorteEdges->[$before]->{"y1"}, 0 );
			my $vJoinLine =
			  NewVec( $sorteEdges->[$next]{"x1"} - $sorteEdges->[$before]->{"x2"}, $sorteEdges->[$next]{"y1"} - $sorteEdges->[$before]->{"y2"}, 0 );

			$innerAngel =
			  sprintf( "%.1f", rad2deg( $origin->InnerAnglePoints( $vBef, $vJoinLine ) ) );
		}

		#SMAYAT
		if ( $arc{"id"} == 902 ) {
			1 == 1;
		}

		if ( $intersec > 0 ) {
			$posOfLine = "intersection";
		}
		elsif ( $intersec < 0 && $innerAngel != 0 ) {
			$posOfLine = "parallel";
		}
		elsif ( $intersec < 0 && $innerAngel == 0 ) {
			$posOfLine = "parallel-overlapping";
		}

		if ( $posOfLine eq "intersection" ) {
			$vectorAngel =
			  RoutMath->VectorInnerEdge(
										 $sorteEdges->[$before]{"x1"} - $sorteEdges->[$before]{"x2"},
										 $sorteEdges->[$before]{"y1"} - $sorteEdges->[$before]{"y2"},
										 $sorteEdges->[$next]{"x2"} - $sorteEdges->[$next]{"x1"},
										 $sorteEdges->[$next]{"y2"} - $sorteEdges->[$next]{"y1"}
			  );

			my $posOfIntersection =
			  RoutMath->PosOfPoint( @{$intersec}[0], @{$intersec}[1],
									$sorteEdges->[$before]{"x2"},
									$sorteEdges->[$before]{"y2"},
									$sorteEdges->[$next]{"x1"},
									$sorteEdges->[$next]{"y1"} );

			if (    $vectorAngel > 180 && $posOfIntersection eq "right"
				 || $vectorAngel < 180 && $posOfIntersection eq "left" )
			{
				$posOfLine = "intersection-special";
			}
			else {
				$posOfLine = "intersection-normal";
			}

		}

		#test if neighbour lines has intersection. Number 10**4 means, intersecion is out of usefull dimension
		#thus, lines have no intersection
		if ( $posOfLine eq "intersection-normal" ) {

			#check angle between: end of 1st line, midpoint oc arc, start of 2nd line
			my ( $vRadiusBef, $vRadiusNext, $innerAngel ) = ( undef, undef, 0 );
			my $origin = NewVec( 0, 0, 0 );

			$vRadiusBef  = NewVec( $arc{"xmid"} - $sorteEdges->[$before]{"x2"}, $arc{"ymid"} - $sorteEdges->[$before]{"y2"}, 0 );
			$vRadiusNext = NewVec( $sorteEdges->[$next]{"x1"} - $arc{"xmid"},   $sorteEdges->[$next]{"y1"} - $arc{"ymid"},   0 );

			$innerAngel = rad2deg( $origin->InnerAnglePoints( $vRadiusBef, $vRadiusNext ) );

			push( @idToDel, $arc{"id"} );

			my $intersectX = @{$intersec}[0];
			my $intersectY = @{$intersec}[1];

			$sorteEdges->[$next]->{"x1"}   = $intersectX;
			$sorteEdges->[$next]->{"y1"}   = $intersectY;
			$sorteEdges->[$before]->{"x2"} = $intersectX;
			$sorteEdges->[$before]->{"y2"} = $intersectY;

			$vectorAngel =
			  RoutMath->VectorInnerEdge(
										 $sorteEdges->[$i]{"x1"} - $sorteEdges->[$i]{"x2"},
										 $sorteEdges->[$i]{"y1"} - $sorteEdges->[$i]{"y2"},
										 $sorteEdges->[$next]{"x2"} - $sorteEdges->[$next]{"x1"},
										 $sorteEdges->[$next]{"y2"} - $sorteEdges->[$next]{"y1"}
			  );

			#SMAYAT
			if ( $arc{"id"} == 1750 ) {
				1 == 1;
			}

			#radius is to small for tool 2mm or too closed - 2mm isn't
			#able to go into this radius and we've to put this drill hole
			#95 degree, 5 degree means little tolerance
			if ( ( $arc{"innerangle"} > 180 || $vectorAngel > 180 )
				 && $arc{"distance"} < 2.2 )
			{

				my %hole = (
							 "x"    => $arc{"xmid"},
							 "y"    => $arc{"ymid"},
							 'tool' => 1000 * $arc{"diameter"}
				);
				push( @drillPoints, \%hole );

			}
		}

		#onlz delete rout and put one new line insted of arc
		elsif ( $posOfLine eq "parallel-overlapping" ) {

			my %featInfo;
			$featInfo{"id"}           = GeneralHelper->GetNumUID();
			$featInfo{"type"}         = "L";
			$featInfo{"x1"}           = $sorteEdges->[$before]->{"x2"};
			$featInfo{"y1"}           = $sorteEdges->[$before]->{"y2"};
			$featInfo{"x2"}           = $sorteEdges->[$next]->{"x1"};
			$featInfo{"y2"}           = $sorteEdges->[$next]->{"y1"};
			$featInfo{"switchPoints"} = $sorteEdges->[$next]->{"switchPoints"};

			RoutParser->AddGeometricAtt( \%featInfo );

			splice @{$sorteEdges}, $i + 1, 0, \%featInfo;

			push( @idToDel, $arc{"id"} );

			if ( $arc{"innerangle"} > 90 && $arc{"distance"} < 2.2 ) {

				my %hole = (
							 "x"    => $arc{"xmid"},
							 "y"    => $arc{"ymid"},
							 'tool' => 1000 * $arc{"diameter"}
				);
				push( @drillPoints, \%hole );

			}
		}

		#lines don't have intersection. Here are two cases of neigbour line positions
		#1st:
		#________
		#________) <-arc
		#2nd:
		#__________
		#  arc -> (_______
		elsif (    $posOfLine eq "parallel"
				|| $posOfLine eq "intersection-special" )
		{

			#test both cases
			my ( $vBef, $vNext, $vJoinLine, $innerAngel ) = ( undef, undef, undef, 0, );
			my $origin = NewVec( 0, 0, 0 );
			my ( @p1, @p2, @p3, @p4 ) = ( (), (), (), () );
			my $intersec;
			my @box;

			$vBef = NewVec( $sorteEdges->[$before]->{"x2"} - $sorteEdges->[$before]->{"x1"},
							$sorteEdges->[$before]->{"y2"} - $sorteEdges->[$before]->{"y1"}, 0 );
			$vNext = NewVec( $sorteEdges->[$next]{"x2"} - $sorteEdges->[$next]{"x1"}, $sorteEdges->[$next]{"y2"} - $sorteEdges->[$next]{"y1"}, 0 );
			$vJoinLine =
			  NewVec( $sorteEdges->[$next]{"x1"} - $sorteEdges->[$before]->{"x2"}, $sorteEdges->[$next]{"y1"} - $sorteEdges->[$before]->{"y2"}, 0 );
			my @plus     = $vBef->Plus($vNext);
			my @minus    = $vBef->Minus($vNext);
			my $plusLen  = Math::Vec::Length( \@plus );
			my $minusLen = Math::Vec::Length( \@minus );

			$innerAngel = rad2deg( $origin->InnerAnglePoints( $vBef, $vJoinLine ) );

			#this is 1fs CASE
			if (    $plusLen < $minusLen
				 && abs( $innerAngel - 90 ) < 10
				 && $posOfLine ne "intersection-special" )
			{

				#imaginare bounding box
				@box = $self->__CreateBoxFirstCase( $sorteEdges->[$before], $sorteEdges->[$next], \%arc );
			}

			#this is second case
			elsif (    $plusLen > $minusLen
					|| $posOfLine eq "intersection-special" )
			{
				@box = $self->__CreateBoxSecondCase( $sorteEdges->[$before], $sorteEdges->[$next], \%arc );

			}
			else {

			}

			#remove old arc
			splice @{$sorteEdges}, $i, 1;    #remove arc

			#add new line to @sorted lines
			for ( my $k = scalar(@box) - 1 ; $k > 0 ; $k-- ) {

				my %featInfo;
				$featInfo{"id"}   = GeneralHelper->GetNumUID();
				$featInfo{"type"} = "L";
				$featInfo{"x1"}   = $box[ $k - 1 ][0];
				$featInfo{"y1"}   = $box[ $k - 1 ][1];
				$featInfo{"x2"}   = $box[$k][0];
				$featInfo{"y2"}   = $box[$k][1];

				RoutParser->AddGeometricAtt( \%featInfo );

				splice @{$sorteEdges}, $i, 0, \%featInfo;
			}
		}
	}

	#removing old arcs
	for ( my $i = scalar(@idToDel) - 1 ; $i >= 0 ; $i-- ) {

		my $arcId = $idToDel[$i];

		my ($idx) = grep { $sorteEdges->[$_]{"id"} eq $arcId } 0 .. $#$sorteEdges;

		splice @{$sorteEdges}, $idx, 1;                                              #remove arc

	}

	if ( scalar(@drillPoints) > 0 ) {

		$result{"newDrillHole"}    = 1;
		$result{"newDrillHoleVal"} = \@drillPoints;

	}

	return %result;
}

#return second coordinate of line which is vertical with given line
sub __GetEndVerticalLine {
	my $self = shift;
	my $x1   = shift;
	my $y1   = shift;
	my $x2   = shift;
	my $y2   = shift;

	if ( $x1 == $x2 ) {

		return ( $x1 + 2, $y1 );
	}
	if ( $y1 == $y2 ) {

		return ( $x1, $y1 + 2 );
	}

	my $c;

	#my @res = MathHelper->GetGeneralLineEquation( $x1, $y1, $x2, $y2 );
	my @nVec = ( ( $x2 - $x1 ), ( $y2 - $y1 ) );

	#my @sVec = ( ( $x2 - $x1 ), ( $y2 - $y1 ) );

	#according a*x + b*y + c = 0
	#c = -x*x -b*y
	#$c =  -(@nVec[0] * $y1) - (@nVec[1] * $x1);
	my $c2 = -( $nVec[0] * $x1 ) - ( $nVec[1] * $y1 );

	#second point We take second x similar to x1 (e.g x1 + 1)
	my $x2res = $x1 + 4;

	my $y2res = -( $nVec[0] * $x2res ) / $nVec[1] - $c2 / $nVec[1];

	return ( $x2res, $y2res );
}

#return points, which represent new coordinatec for lines, which will relplace old arc
#1st CASE:
#________
#________) <-arc
sub __CreateBoxFirstCase {
	my $self       = shift;
	my %edgeBefore = %{ shift(@_) };
	my %edgeNext   = %{ shift(@_) };
	my %arc        = %{ shift(@_) };

	my $finder  = Math::Intersection::StraightLine->new();
	my $polyBox = Math::Geometry::Planar->new;

	my @box = ();
	my ( @p1, @p2, @p3, @p4 ) = ( (), (), (), () );

	#1st point
	$p1[0] = $edgeBefore{"x2"};
	$p1[1] = $edgeBefore{"y2"};
	push( @box, \@p1 );

	#2dn point
	my $vx = ( ( $edgeBefore{"x2"} - $edgeBefore{"x1"} ) - ( $edgeBefore{"x1"} - $edgeBefore{"x1"} ) ) / $edgeBefore{"length"};
	my $vy = ( ( $edgeBefore{"y2"} - $edgeBefore{"y1"} ) - ( $edgeBefore{"y1"} - $edgeBefore{"y1"} ) ) / $edgeBefore{"length"};
	my $px = $edgeBefore{"x1"} + $vx * ( $edgeBefore{"length"} + $arc{"radius"} );
	my $py = $edgeBefore{"y1"} + $vy * ( $edgeBefore{"length"} + $arc{"radius"} );

	$p2[0] = $px;
	$p2[1] = $py;
	push( @box, \@p2 );

	#3dn point
	$vx = ( ( $edgeNext{"x1"} - $edgeNext{"x2"} ) - ( $edgeNext{"x2"} - $edgeNext{"x2"} ) ) / $edgeNext{"length"};
	$vy = ( ( $edgeNext{"y1"} - $edgeNext{"y2"} ) - ( $edgeNext{"y2"} - $edgeNext{"y2"} ) ) / $edgeNext{"length"};
	$px = $edgeNext{"x2"} + $vx * ( $edgeNext{"length"} + $arc{"radius"} );
	$py = $edgeNext{"y2"} + $vy * ( $edgeNext{"length"} + $arc{"radius"} );

	$p3[0] = $px;
	$p3[1] = $py;
	push( @box, \@p3 );

	#4th point
	$p4[0] = $edgeNext{"x1"};
	$p4[1] = $edgeNext{"y1"};
	push( @box, \@p4 );

	return @box;
}

#return points, which represent new coordinatec for lines, which will relplace old arc
#2nd CASE:
#__________
#  arc -> (_______
sub __CreateBoxSecondCase {
	my $self       = shift;
	my %edgeBefore = %{ shift(@_) };
	my %edgeNext   = %{ shift(@_) };

	my @box = ();
	my ( @p1, @p2, @p3, @p4 ) = ( (), (), (), () );
	my $intersec;
	my @normal;
	my ( $vBef, $vNext ) = ( undef, undef );
	my $finder  = Math::Intersection::StraightLine->new();
	my $polyBox = Math::Geometry::Planar->new;

	#1st point
	$p1[0] = $edgeBefore{"x2"};
	$p1[1] = $edgeBefore{"y2"};
	push( @box, \@p1 );

	#3th point
	$vBef = [ [ $edgeBefore{"x1"}, $edgeBefore{"y1"} ], [ $edgeBefore{"x2"}, $edgeBefore{"y2"} ] ];

	# get second point of "normal" line
	@normal = RouteRadiusHelper->__GetEndVerticalLine( $edgeNext{"x1"}, $edgeNext{"y1"}, $edgeNext{"x2"}, $edgeNext{"y2"} );

	$vNext = [ [ $edgeNext{"x1"}, $edgeNext{"y1"} ], [ $normal[0], $normal[1] ] ];

	$intersec = $finder->points( $vBef, $vNext );

	$p2[0] = @{$intersec}[0];
	$p2[1] = @{$intersec}[1];
	push( @box, \@p2 );

	#4th point

	# get second point of "normal" line
	@normal = RouteRadiusHelper->__GetEndVerticalLine( $edgeBefore{"x2"}, $edgeBefore{"y2"}, $edgeBefore{"x1"}, $edgeBefore{"y1"} );

	$vBef = [ [ $edgeBefore{"x2"}, $edgeBefore{"y2"} ], [ $normal[0], $normal[1] ] ];

	$vNext = [ [ $edgeNext{"x1"}, $edgeNext{"y1"} ], [ $edgeNext{"x2"}, $edgeNext{"y2"} ] ];

	$intersec = $finder->points( $vBef, $vNext );

	$p3[0] = @{$intersec}[0];
	$p3[1] = @{$intersec}[1];
	push( @box, \@p3 );

	$p4[0] = $edgeNext{"x1"};
	$p4[1] = $edgeNext{"y1"};
	push( @box, \@p4 );

	#$edge->{"posOfCenter"} =
	# ( $edge->{"x2"} - $edge->{"x1"} ) * ( $edge->{"ymid"} - $edge->{"y1"} ) -
	# ( $edge->{"y2"} - $edge->{"y1"} ) * ( $edge->{"xmid"} - $edge->{"x1"} ) > 0
	# ? "left"
	# : "right";

	#test which point 2 OR 3 lay right from line
	my $pos =
	  ( $edgeNext{"x1"} - $edgeBefore{"x2"} ) * ( $p2[1] - $edgeBefore{"y2"} ) -
	  ( $edgeNext{"y1"} - $edgeBefore{"y2"} ) * ( $p2[0] - $edgeBefore{"x2"} ) > 0
	  ? "left"
	  : "right";
	if ( $pos eq "left" ) {
		splice @box, 1, 1;
	}
	else {
		splice @box, 2, 1;
	}

	return @box;
}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

if (0) {

	my %featInfo1;

	$featInfo1{"x1"} = 1;
	$featInfo1{"y1"} = 2;
	$featInfo1{"x2"} = 2;
	$featInfo1{"y2"} = 4;

	my %featInfo2;

	$featInfo2{"x1"} = 5;
	$featInfo2{"y1"} = 6;
	$featInfo2{"x2"} = 6;
	$featInfo2{"y2"} = 8;

	RouteRadiusHelper->CreateBoxSecondCase( \%featInfo1, \%featInfo2 );

}

1;

