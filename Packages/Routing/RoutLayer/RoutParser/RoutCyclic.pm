#-------------------------------------------------------------------------------------------#
# Description: Helper class working with not open routs
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::RoutParser::RoutCyclic;

#3th party library
use strict;
use warnings;
use Math::Trig;
use Math::Polygon::Calc;       #Math-Polygon
use Math::Geometry::Planar;    #Math-Geometry-Planar-GPC
use List::Util qw[max min];

#local library
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamDTMSurf';
use aliased 'Packages::Routing::RoutLayer::RoutParser::RoutArc';

use aliased 'Packages::CAM::UniDTM::Enums';
use aliased 'Enums::EnumsRout';
use List::MoreUtils qw(uniq);
use aliased 'Packages::Polygon::Polygon::PolygonPoints';
use aliased 'Packages::Polygon::PolygonFeatures';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

# Return if rout iis cyclic
sub IsCyclic {
	my $self        = shift;
	my @sortedFeats = @{ shift(@_) };
	my $openPoint   = shift;            # if rout is not cyclyc, return point where is rout open

	my $cyclic = 1;

	for ( my $i = 0 ; $i < scalar(@sortedFeats) ; $i++ ) {

		my $next = undef;

		if ( $i + 1 == scalar(@sortedFeats) ) {
			$next = $sortedFeats[0];
		}
		else {
			$next = $sortedFeats[ $i + 1 ];
		}

		if ( !( abs( $sortedFeats[$i]->{"x2"} - $next->{"x1"} ) < 0.001 && abs( $sortedFeats[$i]->{"y2"} - $next->{"y1"} ) < 0.001 ) ) {
			$cyclic = 0;

			if ( defined $openPoint ) {
				$openPoint->{"x"} = $next->{"x1"};
				$openPoint->{"y"} = $next->{"y1"};
			}
			last;

		}

	}

	return $cyclic;
}

# Return polygon direction CW/CCW
sub GetRoutDirection {
	my $self        = shift;
	my @sortedFeats = @{ shift(@_) };

	unless ( $self->IsCyclic( \@sortedFeats ) ) {
		die "Rout must be cyclilc to determine rout direction";
	}

	my $dir = undef;

	# Special case, when rout is created by one arc, return arc direction
	if ( scalar(@sortedFeats) == 1 && $sortedFeats[0]->{"type"} eq "A" ) {

		$dir = $sortedFeats[0]->{"newDir"};
	}
	else {

		my @points = map { [ $_->{"x1"}, $_->{"y1"} ] } @sortedFeats;    # rest of points "x2,y2"
		$dir = PolygonPoints->GetPolygonDirection( \@points );
	}

	return $dir;
}

# Set new rout direction CW/CCW
# Rout must by cyclic
sub SetRoutDirection {
	my $self        = shift;
	my $sortedEdges = shift;
	my $newDir      = shift;

	unless ( $self->IsCyclic($sortedEdges) ) {
		die "Rout must be cyclilc to determine rout direction";
	}

	# Get original direction
	my $oriDir = $self->GetRoutDirection($sortedEdges);

	if ( $oriDir eq $newDir ) {
		return 0;
	}

	my @ori = @{$sortedEdges};

	# Switch direction

	@ori = reverse @ori;
	@{$sortedEdges} = @ori;    # set reversed edges

	#switch start and end point of edges
	for ( my $i = 0 ; $i < scalar( @{$sortedEdges} ) ; $i++ ) {

		my $pX = $sortedEdges->[$i]->{"x2"};
		my $pY = $sortedEdges->[$i]->{"y2"};

		$sortedEdges->[$i]->{"x2"} = $sortedEdges->[$i]->{"x1"};
		$sortedEdges->[$i]->{"y2"} = $sortedEdges->[$i]->{"y1"};
		$sortedEdges->[$i]->{"x1"} = $pX;
		$sortedEdges->[$i]->{"y1"} = $pY;

		#compute new arc direction depending on original direction and switchin start/end point
		if ( $sortedEdges->[$i]->{"type"} eq "A" ) {

			$sortedEdges->[$i]->{"newDir"} = ( $sortedEdges->[$i]->{"newDir"} eq EnumsRout->Dir_CW ) ? EnumsRout->Dir_CCW : EnumsRout->Dir_CW;
		}

		# SwitchPoints property tell if points are switched against original version
		$sortedEdges->[$i]->{"switchPoints"} = ( $sortedEdges->[$i]->{"switchPoints"} == 1 ) ? 0 : 1;

	}

}

# One chain can have more features
# Some features can have same start/end point (are connected). Only arc and lines can create sequences
# Thiese featurec join to "sequences"
# Return list of sequences, where sequence is list of features
sub GetRoutSequences {
	my $self  = shift;
	my @edges = @{ shift(@_) };

	my @sequences = ();

	unless ( scalar(@edges) ) {
		return 0;
	}

	# 1) all features which are not line or arc add as single sequences
	my @nonSeqFeats = grep { $_->{"type"} !~ /l/i && $_->{"type"} !~ /a/i } @edges;

	# 2) filter all non arc and line features
	@edges = grep { $_->{"type"} =~ /l/i || $_->{"type"} =~ /a/i } @edges;

	unless ( scalar(@edges) ) {
		return @sequences;
	}

	# 3) create feature matrix for fast searching of joined edegs
	my $report = "";
	my %m = PolygonFeatures->GetFeatureMatrix( \@edges, 10, \$report );

	#print STDERR $report;

	my $buildSeqDone = scalar(@edges) ? 0 : 1;

	my $usedCnt = 0;
	my @seq     = ();

	# 3) search sequences, until all edges are not used in some sequence
	while ( !$buildSeqDone ) {

		if ( scalar(@seq) == 0 ) {

			for ( my $i = 0 ; $i < scalar(@edges) ; $i++ ) {
				if ( !$edges[$i]->{"used"} ) {

					$edges[$i]->{"used"} = 1;
					$usedCnt += 1;
					push( @seq, $edges[$i] );
					last;
				}
			}
		}

		#find next part of chain
		my $isFind = 0;    # if some edges from @edge array was find

		for ( my $i = 0 ; $i < scalar(@seq) ; $i++ ) {

			if ( !$seq[$i]->{"processed"} ) {

				$seq[$i]->{"processed"} = 1;

				# identidfy which cells are features point located in
				my $sCell = $m{ $seq[$i]->{"cellS"}->{"x"} }{ $seq[$i]->{"cellS"}->{"y"} };
				my $eCell = $m{ $seq[$i]->{"cellE"}->{"x"} }{ $seq[$i]->{"cellE"}->{"y"} };

				my @set = grep { !$_->{"used"} } ( @{$sCell}, @{$eCell} );    # search joined feature in these cells

				# only unique features, remove duplicities
				my %seen;
				@set = grep { !$seen{ $_->{"id"} }++ } @set;

				my @joined = grep {
					$_->{"id"} != $seq[$i]->{"id"}
					  && (    ( abs( $_->{"x1"} - $seq[$i]->{"x1"} ) < 0.001 && abs( $_->{"y1"} - $seq[$i]->{"y1"} ) < 0.001 )
						   || ( abs( $_->{"x1"} - $seq[$i]->{"x2"} ) < 0.001 && abs( $_->{"y1"} - $seq[$i]->{"y2"} ) < 0.001 )
						   || ( abs( $_->{"x2"} - $seq[$i]->{"x1"} ) < 0.001 && abs( $_->{"y2"} - $seq[$i]->{"y1"} ) < 0.001 )
						   || ( abs( $_->{"x2"} - $seq[$i]->{"x2"} ) < 0.001 && abs( $_->{"y2"} - $seq[$i]->{"y2"} ) < 0.001 ) )
				} @set;

				if ( scalar(@set) ) {

					splice @seq, $i + 1, 0, @joined;    # move edges to curr sequence

					# mark used edges
					foreach (@joined) {
						$_->{"used"} = 1;
					}

					$usedCnt += scalar(@joined);

					$isFind = 1;
					last;                               # exit from loop and start search again

				}
			}
		}

		if ( !$isFind || $usedCnt == scalar(@edges) ) {

			my @seqTmp = @seq;
			push( @sequences, \@seqTmp );
			@seq = ();

			if ( $usedCnt == scalar(@edges) ) {

				$buildSeqDone = 1;
			}
		}

	}

	# do final check. Compute numbers of feature in sequences and comape with number of sorce edges
	my $fSeqCnt = 0;
	$fSeqCnt += @$_ for @sequences;

	if ( $fSeqCnt != scalar(@edges) ) {

		die "Feat number in sequences ($fSeqCnt) not equal  source  feat number (" . scalar(@edges) . ")";
	}

	# All features which are not line or arc add as single sequences
	foreach my $f (@nonSeqFeats) {
		my @s = ($f);
		push( @sequences, \@s );
	}

	# Remove helper key value
	foreach my $e (@edges) {
		$e->{"used"}      = undef;
		$e->{"processed"} = undef;
		$e->{"cellS"}     = undef;
		$e->{"cellE"}     = undef;

	}

	return @sequences;
}

# Return sorted rout  CW
# Works out only for close polygon
# If rout is open, return empty array
# What means "sorted":
# - rout can be made by edges with differnet dierction ..|-->|-->|<--|-->|...
# - this method do same direction CW/CCW randomly by first choosed edge
sub GetSortedRout {
	my $self  = shift;
	my @edges = @{ shift(@_) };

	# Result of sorting edges
	my %result = ();
	$result{"result"}    = 1;        # if 1 sorting ok, else rout was open
	$result{"changes"}   = 0;        # some changes are done, arc fragment, switch edge points..
	$result{"openPoint"} = undef;    # if rout is open, point where rout is open
	$result{"edges"}     = undef;    # sorted edges

	my @sorteEdges = ();
	my $sorted     = 0;
	my %actEdge;
	my $isOpen = 0;

	my $x;
	my $y;

	#sorting, "create chain"
	#sorting, "create chain"
	if ( scalar(@edges) > 1 ) {

		while ( !$sorted ) {

			#take arbitrary edge
			if ( scalar(@sorteEdges) == 0 ) {
				%actEdge = %{ $edges[0] };
			}

			$x = $actEdge{"x2"};
			$y = $actEdge{"y2"};

			my $isFind = 0;

			#find next part of chain
			for ( my $i = 0 ; $i < scalar(@edges) ; $i++ ) {

				#avoid to first item
				if ( scalar(@sorteEdges) == 0 && $i == 0 ) {
					next;
				}

				$isFind = 0;
				my %e = %{ $edges[$i] };

				if (    ( abs( $x - $e{"x1"} ) < 0.001 && abs( $y - $e{"y1"} ) < 0.001 )
					 || ( abs( $x - $e{"x2"} ) < 0.001 && abs( $y - $e{"y2"} ) < 0.001 ) )
				{
					$isFind = 1;

					if ( $e{"type"} eq "A" ) {
						$e{"newDir"} = $e{"oriDir"};    # set new drirection to default = eroginal dir
					}

					#switch edge points for achieve same-oriented polygon
					if ( abs( $x - $e{"x2"} ) < 0.001 && abs( $y - $e{"y2"} ) < 0.001 ) {

						my $pX = $e{"x2"};
						my $pY = $e{"y2"};
						$e{"x2"} = $e{"x1"};
						$e{"y2"} = $e{"y1"};
						$e{"x1"} = $pX;
						$e{"y1"} = $pY;

						# switch direction
						if ( $e{"type"} eq "A" ) {

							$e{"newDir"} = $e{"newDir"} eq EnumsRout->Dir_CW ? EnumsRout->Dir_CCW : EnumsRout->Dir_CW;
						}

						$e{"switchPoints"} = 1;
					}
					else {

						$e{"switchPoints"} = 0;
					}

					push( @sorteEdges, \%e );
					splice @edges, $i, 1;
					%actEdge = %e;

					last;
				}
			}

			#something is wrong, probably sortedEdges contain line/arc, which are not part of route

			if ( $isFind == 0 ) {

				$isOpen = 1;
				my %inf = ( "x" => $x, "y" => $y );
				$result{"openPoint"} = \%inf;

				last;    # exit from loop
			}

			if ( scalar(@edges) == 0 ) {

				# now edges are sorted. Start/end points of edges are connected each other
				# Final test on cyclyc shape, if points not lie in one line etc

				if ( $self->IsCyclic( \@sorteEdges, $result{"openPoint"} ) ) {
					$sorted = 1;
				}
				else {

					$isOpen = 1;
					last;    # exit from loop
				}
			}
		}

	}

	#if circle case = one arc
	elsif (    scalar(@edges) == 1
			&& $edges[0]->{"type"} =~ /a/i
			&& sprintf( "%.3f", $edges[0]->{"x1"} ) == sprintf( "%.3f", $edges[0]->{"x2"} )
			&& sprintf( "%.3f", $edges[0]->{"y1"} ) == sprintf( "%.3f", $edges[0]->{"y2"} ) )
	{

		$edges[0]{"switchPoints"} = 0;
		$edges[0]{"newDir"}       = $edges[0]{"oriDir"};
		push( @sorteEdges, $edges[0] );

	}
	elsif ( scalar(@edges) == 1 ) {
		@sorteEdges = ();
		return @sorteEdges;
	}

	# if polygon is not close, return 0
	if ($isOpen) {

		$result{"result"} = 0;
		return %result;
	}

	#pokud obrys obsahuje obloukz, je potreba je potreba je dostatecne aproximovat,
	#aby jsme spolehlive spocitali zda je obrys CW nebo CCW
	my $fragmented = 0;
	my $idStartFrom = max( map{$_->{"id"}} @sorteEdges) +1;
	my $uidStartFrom = max( map{$_->{"uid"}} @sorteEdges) +1;
	@sorteEdges = RoutArc->FragmentArcReplace( \@sorteEdges, -1, \$fragmented,  $idStartFrom, $uidStartFrom);

	# Get information about original direction

	my $switched = scalar( grep { $_->{"switchPoints"} } @sorteEdges );

	# Test if changes on rout  are done
	if ( $switched || $fragmented ) {
		$result{"changes"} = 1;
	}

	$result{"edges"} = \@sorteEdges;

	return %result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13608";

	print "fff";

}

1;

