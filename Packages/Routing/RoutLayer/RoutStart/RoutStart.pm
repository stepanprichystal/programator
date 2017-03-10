#-------------------------------------------------------------------------------------------#
# Description: Do checks of tool in Universal DTM
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::RoutStart::RoutStart;

#3th party library
use strict;
use warnings;
use Math::Trig;
use Math::Polygon::Calc;       #Math-Polygon
use Math::Geometry::Planar;    #Math-Geometry-Planar-GPC
use Math::Vec qw(NewVec);

#local library
use aliased 'Packages::Routing::RoutLayer::RoutParser::RoutParser';
use aliased 'Packages::Polygon::PolygonFeatures';
use aliased 'Packages::Routing::RoutLayer::RoutMath::RoutMath';
use aliased 'Packages::Polygon::PointsTransform';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

# When suitable start chain candidate is searching, some mofification can be needed
# Modification - "break line": If it is necessery, fragment outline to more parts
sub RoutNeedModify {
	my $self       = shift;
	my @sorteEdges = @{ shift(@_) };

	# Result with modification
	my %modify = ( "result" => 0 );    # mofification
	my @bl = ();
	$modify{"breakLine"} = \@bl;

	# Candidates on foot down position
	my @footDowns = $self->GetPossibleFootDowns( \@sorteEdges );

	# Modification 1 =================================
	# Chceck if lines are necessary break to two lines

	for ( my $i = 0 ; $i < scalar(@sorteEdges) ; $i++ ) {

		my $footDown = ( grep { $_->{"id"} == $sorteEdges[$i]->{"id"} } @footDowns )[0];

		unless ($footDown) {
			next;
		}

		my $idNext     = ( $i + 1 == scalar(@sorteEdges) )      ? 0 : $i + 1;
		my $idNextNext = ( $idNext + 1 == scalar(@sorteEdges) ) ? 0 : $idNext + 1;

		my $breakLine = 0;

		#kontrola jestli nasledujici usecka je rovnobezna s aktualni. Aby freza nezajizdela do desky.
		#pokud ne, je potreba linu roydelit

		my ( $vAct, $vNext, $innerAngel, $posOfPoint ) = ( undef, undef, 0, undef );
		my $origin = NewVec( 0, 0, 0 );

		$vAct = NewVec( $sorteEdges[$i]{"x1"} - $sorteEdges[$i]{"x2"}, $sorteEdges[$i]{"y1"} - $sorteEdges[$i]{"y2"}, 0 );

		if ( $sorteEdges[$idNext]{"type"} eq "L" ) {

			$vNext =
			  NewVec( $sorteEdges[$idNext]{"x2"} - $sorteEdges[$idNext]{"x1"}, $sorteEdges[$idNext]{"y2"} - $sorteEdges[$idNext]{"y1"}, 0 );

			#@vPlus = $vAct->Plus($vNext);
			$posOfPoint = RoutMath->PosOfPoint( 0, 0, @{$vAct}[0], @{$vAct}[1], @{$vNext}[0], @{$vNext}[1] );

			$innerAngel = rad2deg( $origin->InnerAnglePoints( $vAct, $vNext ) );

			if ( $posOfPoint eq "right" && $innerAngel < 180 ) {
				$breakLine = 1;

			}
		}
		elsif ( $sorteEdges[$idNext]{"type"} eq "A" ) {
			$vNext =
			  NewVec( $sorteEdges[$idNext]{"xmid"} - $sorteEdges[$idNext]{"x1"}, $sorteEdges[$idNext]{"ymid"} - $sorteEdges[$idNext]{"y1"}, 0 );

			$innerAngel = rad2deg( $origin->InnerAnglePoints( $vAct, $vNext ) );

			#@vPlus = $vAct->Plus($vNext);

			$posOfPoint = RoutMath->PosOfPoint( 0, 0, @{$vAct}[0], @{$vAct}[1], @{$vNext}[0], @{$vNext}[1] );

			if ( $sorteEdges[$idNext]{"newDir"} eq "CW" ) {

				if ( $posOfPoint eq "left" && $innerAngel > 90 ) {
					$breakLine = 1;
				}
			}
			elsif ( $sorteEdges[$idNext]{"newDir"} eq "CCW" ) {

				if ( $posOfPoint eq "right" && $innerAngel < 180 ) {
					$breakLine = 1;
				}
			}
		}

		#Pokud nasledujici usecka je mensi jak 2mm
		#kontrola jestli 2. nasledujici usecka v poradi  je rovnobezna s 1. nasledujici useckou. Aby freza nezajizdela do desky.
		#pokud ne, je potreba linu rozdelit. V podstate stejna kontrola jako vzse, ale u nasledujiciho elementu v poradi
		unless ($breakLine) {
			if ( $sorteEdges[$idNext]{"length"} < 2 ) {

				$vAct =
				  NewVec( $sorteEdges[$idNext]{"x1"} - $sorteEdges[$idNext]{"x2"}, $sorteEdges[$idNext]{"y1"} - $sorteEdges[$idNext]{"y2"}, 0 );

				if ( $sorteEdges[$idNextNext]{"type"} eq "L" ) {

					$vNext = NewVec( $sorteEdges[$idNextNext]{"x2"} - $sorteEdges[$idNextNext]{"x1"},
									 $sorteEdges[$idNextNext]{"y2"} - $sorteEdges[$idNextNext]{"y1"}, 0 );

					$posOfPoint = RoutMath->PosOfPoint( 0, 0, @{$vAct}[0], @{$vAct}[1], @{$vNext}[0], @{$vNext}[1] );

					$innerAngel = rad2deg( $origin->InnerAnglePoints( $vAct, $vNext ) );

					if ( $posOfPoint eq "right" && $innerAngel < 180 ) {
						$breakLine = 1;
					}
				}
				elsif ( $sorteEdges[$idNextNext]{"type"} eq "A" ) {
					$vNext = NewVec( $sorteEdges[$idNextNext]{"xmid"} - $sorteEdges[$idNextNext]{"x1"},
									 $sorteEdges[$idNextNext]{"ymid"} - $sorteEdges[$idNextNext]{"y1"}, 0 );

					$innerAngel = rad2deg( $origin->InnerAnglePoints( $vAct, $vNext ) );
					$posOfPoint = RoutMath->PosOfPoint( 0, 0, @{$vAct}[0], @{$vAct}[1], @{$vNext}[0], @{$vNext}[1] );

					if ( $sorteEdges[$idNextNext]{"newDir"} eq "CW" ) {

						if ( $posOfPoint eq "left" && $innerAngel > 90 ) {
							$breakLine = 1;
						}
					}
					elsif ( $sorteEdges[$idNextNext]{"newDir"} eq "CCW" ) {

						if ( $posOfPoint eq "right" && $innerAngel < 180 ) {
							$breakLine = 1;
						}
					}
				}
			}
		}

		# Compute where line should be break
		if ($breakLine) {

			if ( $sorteEdges[$i]{"type"} eq "L" ) {

				#test both cases
				my ( $vBef, $vNext, $vJoinLine, $innerAngel, @vPlus ) =
				  ( undef, undef, undef, 0, () );
				my $origin = NewVec( 0, 0, 0 );

				$vAct = NewVec( $sorteEdges[$i]{"x2"} - $sorteEdges[$i]{"x1"}, $sorteEdges[$i]{"y2"} - $sorteEdges[$i]{"y1"}, 0 );

				my $vx =
				  ( ( $sorteEdges[$i]{"x2"} - $sorteEdges[$i]{"x1"} ) - ( $sorteEdges[$i]{"x1"} - $sorteEdges[$i]{"x1"} ) ) /
				  $sorteEdges[$i]{"length"};
				my $vy =
				  ( ( $sorteEdges[$i]{"y2"} - $sorteEdges[$i]{"y1"} ) - ( $sorteEdges[$i]{"y1"} - $sorteEdges[$i]{"y1"} ) ) /
				  $sorteEdges[$i]{"length"};
				my $px = $sorteEdges[$i]{"x1"} + $vx * ( $sorteEdges[$i]{"length"} - 2 );
				my $py = $sorteEdges[$i]{"y1"} + $vy * ( $sorteEdges[$i]{"length"} - 2 );

				# save changes to hash
				my %breakLine = ( "edge" => $sorteEdges[$i], "breakX" => $px, "breakY" => $py );
				push( @{ $modify{"breakLine"} }, \%breakLine );
			}
		}
	}

	# return modification result
	if ( scalar( @{ $modify{"breakLine"} } ) > 0 ) {
		$modify{"result"} = 1;
	}

	return %modify;
}

# If modification are necessary in order find proper foot down, prcocess them
sub ProcessModify {
	my $self       = shift;
	my $modify     = shift;
	my $sorteEdges = shift;

	#Do changes
	if ( $modify->{"result"} ) {

		# 1) Process "break line" modification

		my @breakLines = @{ $modify->{"breakLine"} };

		for ( my $i = scalar(@$sorteEdges) - 1 ; $i >= 0 ; $i-- ) {

			my $break = ( grep { $_->{"edge"}->{"id"} == $sorteEdges->[$i]->{"id"} } @breakLines )[0];

			if ($break) {
				my %featInfo;

				$featInfo{"id"}   = -1;
				$featInfo{"type"} = $sorteEdges->[$i]{"type"};

				$featInfo{"x1"} = $break->{"breakX"};
				$featInfo{"y1"} = $break->{"breakY"};
				$featInfo{"x2"} = $sorteEdges->[$i]{"x2"};
				$featInfo{"y2"} = $sorteEdges->[$i]{"y2"};

				$sorteEdges->[$i]{"x2"} = $break->{"breakX"};
				$sorteEdges->[$i]{"y2"} = $break->{"breakY"};

				RoutParser->AddGeometricAtt( \%featInfo );
				RoutParser->AddGeometricAtt( $sorteEdges->[$i] );
				splice @$sorteEdges, $i + 1, 0, \%featInfo;

			}
		}
	}

	return 1;
}

# Determine suitable rout edges for foot down
# Method contain several rules for determine it
sub GetPossibleFootDowns {
	my $self       = shift;
	my @sorteEdges = @{ shift(@_) };

	# All edges are rout start candidates
	my @footDowns = ();

	my ( $l, $d, $dir ) = ( 0, 0 );

	for ( my $i = 0 ; $i < scalar(@sorteEdges) ; $i++ ) {

		$footDowns[$i] = 1;

		$l   = $sorteEdges[$i]{"length"};
		$d   = $sorteEdges[$i]{"diameter"};
		$dir = $sorteEdges[$i]{"newDir"};

		# If line
		if ( $sorteEdges[$i]{"type"} eq "L" ) {

			#RULE 1) - line shorter than 4mm
			if ( ( $sorteEdges[$i]{"y1"} + 4 ) > $sorteEdges[$i]{"y2"} ) {

				$footDowns[$i] = 0;    # delete candidate
			}

			my $idBefore =
			  ( $i == scalar(@sorteEdges) )
			  ? scalar(@sorteEdges) - 1
			  : $i - 1;

			#RULE 2) - kontrola jestli nasledujici usecka je rovnobezna s aktualni. Aby freza nezajizdela do desky.
			if (    $sorteEdges[$idBefore]{"x1"} < $sorteEdges[$i]{"x1"}
				 && $sorteEdges[$i]{"length"} < 6 )
			{
				$footDowns[$i] = 0;    # delete candidate
			}

			my $lBott = abs( $sorteEdges[$i]{"x2"} - $sorteEdges[$i]{"x1"} );
			my $alfa  = rad2deg( asin( $lBott / $l ) );

			#RULE 3) - if angel between vertical line and "ortogonal line" is bigger than 10�
			#It's mean, that line for foot down has to be as much verticall as possible +-10 degree
			if ( $alfa > 25 ) {
				$footDowns[$i] = 0;    # delete candidate
			}

		}

		# If arc
		elsif ( $sorteEdges[$i]{"type"} eq "A" ) {

			#RULE 1) - length of arc has to be larget than 5
			if ( $l < 5 ) {
				$footDowns[$i] = 0;    # delete candidate
			}

			#RULE 2) - diameter of arc has to be larget than 15
			if ( $d < 15 ) {
				$footDowns[$i] = 0;    # delete candidate
			}

			#RULE 3) - filter only suitable arc
			if ( $dir eq "CCW" ) {

				if (    $sorteEdges[$i]{"x1"} < $sorteEdges[$i]{"x2"}
					 && $sorteEdges[$i]{"y1"} < $sorteEdges[$i]{"y2"} )
				{
					$footDowns[$i] = 0;    # delete candidate

				}
				elsif (    $sorteEdges[$i]{"x1"} > $sorteEdges[$i]{"x2"}
						&& $sorteEdges[$i]{"y1"} > $sorteEdges[$i]{"y2"} )
				{
					$footDowns[$i] = 0;    # delete candidate
				}
				elsif (    $sorteEdges[$i]{"x1"} < $sorteEdges[$i]{"x2"}
						&& $sorteEdges[$i]{"y1"} > $sorteEdges[$i]{"y2"} )
				{
					$footDowns[$i] = 0;    # delete candidate
				}
			}

			#RULE 4) - filter only suitable arc
			if (    $dir eq "CW"
				 && $sorteEdges[$i]{"x1"} < $sorteEdges[$i]{"x2"} )
			{
				$footDowns[$i] = 0;        # delete candidate
			}
		}
	}

	my @footDownEdge = ();

	for ( my $i = 0 ; $i < scalar(@footDowns) ; $i++ ) {

		if ( $footDowns[$i] ) {
			push( @footDownEdge, $sorteEdges[$i] );
		}
	}

	return @footDownEdge;
}

# Return on specific edge, where is foot down posiible
# If is foot down found
sub GetRoutFootDown {
	my $self       = shift;
	my @sorteEdges = @{ shift(@_) };

	my %result = ( "result" => 1 );

	# 1) Test if no modification needed
	my %modify = $self->RoutNeedModify( \@sorteEdges );

	if ( $modify{"result"} == 1 ) {
		die "Rout need mofify, before choose \"rout start\".\n";
	}

	# 2) Get rout candidates
	my @candidates = $self->GetPossibleFootDowns( \@sorteEdges );

	# 3) Choose from candidates

	if ( scalar(@candidates) == 0 ) {

		$result{"result"} = 0;

		return %result;
	}

	#get profile of polygon
	my @points = ();
	foreach my $e (@sorteEdges) {

		my %p1 = ( "x" => $e->{"x1"}, "y" => $e->{"y1"} );
		my %p2 = ( "x" => $e->{"x2"}, "y" => $e->{"y2"} );
		push( @points, ( \%p1, \%p2 ) );
	}

	my %lim = PointsTransform->GetLimByPoints( \@points );

	#Compute nearest distance from profile point (top-left) to polygon points.
	#Take End point from each edge. We assume, that polzgon is Clockwise direction.

	my $min  = undef;
	my $idx  = -1;
	my $dist = 0;

	for ( my $i = 0 ; $i < scalar(@candidates) ; $i++ ) {

		$dist = sqrt( ( $lim{"xMin"} - $candidates[$i]{"x2"} )**2 + ( $lim{"yMax"} - $candidates[$i]{"y2"} )**2 );

		if ( $candidates[$i]{"type"} eq "A" ) {

			$dist = $dist * 1.2;                   #because of type "Arc", add little disadvantage 20%
		}

		if ( !defined $min || $dist < $min ) {
			$min = $dist;
			$idx = $i;
		}

	}

	#	for ( my $i = 0 ; $i < scalar(@sorteEdges) ; $i++ ) {
	#
	#		my $footCandidate = ( grep { $_->{"id"} == $sorteEdges[$i]->{"id"} } @candidates )[0];
	#
	#		if ($footCandidate) {
	#
	#			$dist = sqrt( ( $lim{"minX"} - $sorteEdges[$i]{"x2"} )**2 + ( $lim{"maxY"} - $sorteEdges[$i]{"y2"} )**2 );
	#
	#			if ( $sorteEdges[$i]{"type"} eq "A" ) {
	#
	#				$dist = $dist * 1.2;    #because of type "Arc", add little disadvantage 20%
	#			}
	#
	#			if ( !defined $min|| $dist < $min ) {
	#				$min = $dist;
	#				$idx = $i;
	#			}
	#		}
	#	}

	#line for footdown
	my $footDown = $candidates[$idx];

	$result{"edge"} = $footDown;

	return %result;

}

# Return  specific edge, where is start rout posiible
# Start rout edge is placed as very next edge of foot down edge (direction CW)
sub GetRoutStart {
	my $self       = shift;
	my @sorteEdges = @{ shift(@_) };

	my %result = ( "result" => 1 );

	# 1) Get rout start
	my %footDown = $self->GetRoutFootDown( \@sorteEdges );

	# 2) If rout start was not found, result 0
	if ( $footDown{"result"} == 0 ) {

		$result{"result"} = 0;
		return %result;
	}

	#line for start chain. Next edge in order, because polzgon is clockwise

	my $idx = ( grep { $sorteEdges[$_]->{"id"} eq $footDown{"edge"}->{"id"} } 0 .. $#sorteEdges )[0];

	if ( $idx + 1 == scalar(@sorteEdges) ) {
		$result{"edge"} = $sorteEdges[0];
	}
	else {
		$result{"edge"} = $sorteEdges[ $idx + 1 ];
	}
	return %result;
}

1;

