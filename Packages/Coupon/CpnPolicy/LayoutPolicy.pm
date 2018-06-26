
#-------------------------------------------------------------------------------------------#
# Description: Default coupon settings
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnPolicy::LayoutPolicy;

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use List::Util qw[max];

#local library
use aliased 'Packages::Coupon::CpnSource::CpnSource';
use aliased 'Packages::Coupon::CpnPolicy::CpnVariant::CpnStripVariant';
use aliased 'Packages::Coupon::CpnPolicy::CpnVariant::CpnVariant';
use aliased 'Packages::Coupon::CpnPolicy::CpnVariant::CpnSingleVariant';
use aliased 'Packages::Coupon::CpnPolicy::CpnVariant::CpnPoolVariant';
use aliased 'Packages::Coupon::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"layers"} = shift;    # layer names from instack job Xml

	# Load settings if defined

	$self->{"poolCnt"}      = shift;
	$self->{"shareGNDPads"} = shift;
	$self->{"maxTrackCnt"}  = shift;

	$self->{"trackPadIsolation"} = shift;
	$self->{"trackPad2GNDPad"}   = shift;
	$self->{"padTrackSize"}      = shift;
	$self->{"padGNDSize"}        = shift;

	$self->{"routeBetween"}  = shift;
	$self->{"routeAbove"}    = shift;
	$self->{"routeBelow"}    = shift;
	$self->{"routeStreight"} = shift;

	return $self;
}

# Name notation
# Coupon:
# Max number of pool inside single coupon: 2
# Max number of single coupon: infinity
# Max number of columns: infinity

# |=============================Coupon=============================|
# | ________________________ Coupon single 2 ______________________|
# | Pool 2 - track pad + tracks                                    |
# | ...... - gnd pads .............................................|
# | Pool 1 - track pad + tracks                                    |
# | ________________________ Coupon single 1 ______________________|
# | Pool 2 - track pad + tracks                                    |
# | ...... - gnd pads .............................................|
# | Pool 1 - track pad + tracks                                    |
# |================================================================|
#
# | col1 | col2 | col3 | ... | coln                                |
# Columns contains pads GND+track in vertical line
sub GetStripLayoutVariants {
	my $self      = shift;
	my @groupComb = @{ shift(@_) };    # one group combination

	my $result = 1;

	my $cpnVar = CpnVariant->new();

	#contain single coupons

	# define single coupon until all pool are not processed
	foreach my $group (@groupComb) {

		# 1) Process all grou pool variants for scurrent group
		# Each grou pool variant create CpnVariantStructure
 
		my @singleCpnVariants = ();
		foreach my $groupPoolComb ( @{$group} ) {
 

			# 1) Choose microstrip positions in current pools variant
			my $pools = $self->__ProcessGroupPoolComb($groupPoolComb);

			# 2) build SingleCpnVariant structure
			my $signleCpnVar = CpnSingleVariant->new();

			for ( my $i = 0 ; $i < scalar( @{$pools} ) ; $i++ ) {

				my $poolVar = CpnPoolVariant->new($i);

				for ( my $j = 0 ; $j < scalar( @{ $pools->[$i] } ) ; $j++ ) {
					my $s = $pools->[$i]->[$j];

					my $stripInfo = CpnStripVariant->new( $s->{"id"} );
					$stripInfo->SetPool( $s->{"pool"} );

					$stripInfo->SetColumn( $s->{"col"} );
					$stripInfo->SetData( $s->{"d"} );

					if ( $j + 1 == scalar( @{ $pools->[$i] } ) ) {
						$stripInfo->SetIsLast(1);
					}
					else {
						$stripInfo->SetIsLast(0);
					}

					$poolVar->AddStrip($stripInfo);
				}

				$signleCpnVar->AddPool($poolVar);
			}

			# 3) Verify route
			my $errMess = "";

			if ( $self->__VerifyStripRoutes( $signleCpnVar, \$errMess ) ) {
				push( @singleCpnVariants, $signleCpnVar );
			}

		}

		# 2) Choose one SingleCpnVariant from all variants
		if ( scalar(@singleCpnVariants) ) {

			@singleCpnVariants = sort __SortVariants @singleCpnVariants;

			sub __SortVariants {
				( scalar( @{ $b->{'pools'} } ) <=> scalar( @{ $a->{'pools'} } ) )    # more pools better
				  or
				  ( $a->GetColumnCnt() <=> $b->GetColumnCnt() )                      # less column better
				 
			}

			my $signleCpnVar = $singleCpnVariants[0];

			$cpnVar->AddCpnSingle($signleCpnVar);

		}
		else {
			$result = 0;
			last;
		}

	}

	if ($result) {
		return $cpnVar;
	}
	else {
		return undef;
	}

}
#
#sub __GenerateCpnVariant {
#	my $self   = shift;
#	my @coupon = @{ shift(@_) };
#
#	# Build object structure - CpnVariant
#
#	my $cpnVar = CpnVariant->new();
#
#	foreach my $signleCpn (@coupon) {
#
#		my $signleCpnVar = CpnSingleVariant->new();
#
#		for ( my $i = 0 ; $i < scalar( @{$signleCpn} ) ; $i++ ) {
#
#			my $poolVar = CpnPoolVariant->new($i);
#
#			for ( my $j = 0 ; $j < scalar( @{ $signleCpn->[$i] } ) ; $j++ ) {
#				my $s = $signleCpn->[$i]->[$j];
#
#				my $stripInfo = CpnStripVariant->new( $s->{"id"} );
#				$stripInfo->SetPool( $s->{"pool"} );
#
#				$stripInfo->SetColumn( $s->{"col"} );
#				$stripInfo->SetData( $s->{"d"} );
#
#				if ( $j + 1 == scalar( @{ $signleCpn->[$i] } ) ) {
#					$stripInfo->SetIsLast(1);
#				}
#				else {
#					$stripInfo->SetIsLast(0);
#				}
#
#				$poolVar->AddStrip($stripInfo);
#			}
#
#			$signleCpnVar->AddPool($poolVar);
#		}
#
#		$cpnVar->AddCpnSingle($signleCpnVar);
#	}
#
#	return $cpnVar;
#
#}

sub __ProcessGroupPoolComb {
	my $self          = shift;
	my $groupPoolComb = shift;

	my $shareGNDPads = $self->{"shareGNDPads"};
	my $maxTrackCnt  = $self->{"maxTrackCnt"};

	my @cpnSingle = ();
	my @pools     = ();
	for ( my $i = 0 ; $i < scalar( @{$groupPoolComb} ) ; $i++ ) {

		my @p = @{ $groupPoolComb->[$i] };

		push( @pools, [] );

		# Check if pool contain max alowed track cnt in one layer in one pool
		# Cut last strip
		my @lastCandidates = ();
		foreach my $l ( @{ $self->{"layers"} } ) {

			#my $trackCnt = scalar( grep { $_ eq Enums->Layer_TYPETRACK } map { $_->{"l"}->{$l} } @p );
			#if ( $trackCnt == $maxTrackCnt ) {

			# in current layer exist microstrip, which has in current layer track and has to by last
			# take arbitrary se/cose and mark him as last
			for ( my $j = scalar(@p) - 1 ; $j >= 0 ; $j-- ) {

				if ( $p[$j]->{"l"}->{$l} eq Enums->Layer_TYPETRACK
					 && ( $p[$j]->{"type"} eq Enums->Type_SE || $p[$j]->{"type"} eq Enums->Type_COSE ) )
				{
					push( @lastCandidates, splice @p, $j, 1 );
				}
			}

			#}
		}

		while ( scalar(@p) || @lastCandidates ) {

			# return back last strip
			unless ( scalar(@p) ) {

				push( @p, @lastCandidates );
				@lastCandidates = ();
			}

			# get next suitable strip
			my $stripInfo = $self->__GetNextStrip( \@p, \@pools, $shareGNDPads, $maxTrackCnt );

			if ( scalar(@lastCandidates) > 1 ) {
				my $stripInfoLast = $self->__GetNextStrip( \@lastCandidates, \@pools, $shareGNDPads, $maxTrackCnt );
				if ( $stripInfoLast->{"col"} < $stripInfo->{"col"} ) {

					push( @p, $stripInfo->{"d"} );    # push back
					$stripInfo = $stripInfoLast;
				}
				else {
					push( @lastCandidates, $stripInfoLast->{"d"} );    # push back
				}
			}

			push( @{ $pools[-1] }, $stripInfo );
		}

	}

	return \@pools;
}

sub __GetNextStrip {
	my $self         = shift;
	my $p            = shift;
	my @pools        = @{ shift(@_) };
	my $shareGNDPads = shift;
	my $maxTrackCnt  = shift;

	my $poolPrev = $pools[-2];
	my $poolCur  = $pools[-1];

	my $foundStripIdx = undef;
	my $foundStripPos = undef;

	for ( my $j = 0 ; $j < scalar(@$p) ; $j++ ) {

		# test each strip in current pool and take suitable (suitable is strip which can be placed most left - smallest col pos. in current pool)
		my $strip = $p->[$j];

		# consider GND pads of last created pool (pool below this pool if exist)
		if ( $shareGNDPads && defined $poolPrev ) {

			my $newColumn = undef;
			my @gndLayers = grep { $strip->{"l"}->{$_} eq Enums->Layer_TYPEGND } keys %{ $strip->{"l"} };

			# go through all microstrip in below pool and chcek if is poosible set same position
			# check only microstips from position of last microstrip in current pool

			my $startCol = scalar(@$poolCur) ? $poolCur->[-1]->{"col"} + 1 : undef;

			for ( my $k = 0 ; $k < scalar( @{$poolPrev} ) ; $k++ ) {

				next if ( defined $startCol && $poolPrev->[$k]->{"col"} < $startCol );

				my $gndOk         = 1;
				my $stripPrevInfo = $poolPrev->[$k];

				# go through GND layers (max two GND top+bot ref layer)
				for ( my $l = 0 ; $l < scalar(@gndLayers) ; $l++ ) {

					# get layer type of below pool strip in for current layer

					my $prevLType = $stripPrevInfo->{"d"}->{"l"}->{ $gndLayers[$l] };
					if ( $prevLType ne Enums->Layer_TYPENOAFFECT && $prevLType ne Enums->Layer_TYPEGND ) {
						$gndOk = 0;
						last;
					}
				}

				# if column position of below pool strip is suitable, save index of strip and continue in searching
				if ($gndOk) {
					if ( !defined $foundStripPos || $foundStripPos > $stripPrevInfo->{"col"} ) {
						$foundStripIdx = $j;
						$foundStripPos = $stripPrevInfo->{"col"};
					}
				}
			}
		}
	}

	# no position was found, take next positions in current pool
	if ( !defined $foundStripIdx ) {

		$foundStripIdx = 0;

		if ( !defined $poolPrev ) {

			if ( scalar( @{$poolCur} ) > 0 ) {
				$foundStripPos = $poolCur->[-1]->{"col"} + 1;
			}
			else {
				$foundStripPos = 0;
			}
		}
		else {

			# get max col pos from below and current pool
			my $maxPrev = defined $poolPrev->[-1] ? $poolPrev->[-1]->{"col"} : -1;
			my $maxCur  = defined $poolCur->[-1]  ? $poolCur->[-1]->{"col"}  : -1;

			$foundStripPos = max( $maxPrev, $maxCur ) + 1;
		}

		# previev strip in current pool +1

	}

	unless ( defined $foundStripPos ) {
		die "strip position was not found";
	}

	# build strip info

	my %stripInfo = (
					  "id"   => $p->[$foundStripIdx]->{"id"},
					  "pool" => scalar(@pools) - 1,
					  "col"  => $foundStripPos,
					  "d"    => $p->[$foundStripIdx]
	);

	splice @$p, $foundStripIdx, 1;

	return \%stripInfo;

}

#sub SetRoute {
#	my $self     = shift;
#	my @variants = @{ shift(@_) };
#
#	my $errMess = shift;
#
#	for ( my $i = scalar(@variants) - 1 ; $i >= 0 ; $i-- ) {
#
#		my $result  = 1;
#		my $errMess = "";
#
#		foreach my $singlCpn ( $variants[$i]->GetSingleCpns() ) {
#
#			unless ( $self->__VerifyStripRoutes( $singlCpn, \$errMess ) ) {
#
#				$result = 0;
#				last;
#			}
#		}
#
#		unless ($result) {
#			print STDERR "Removed because unable to set rout: $errMess\n";
#			splice @variants, $i, 1;
#		}
#	}
#}

# Verify strip routes layer by layer
sub __VerifyStripRoutes {
	my $self     = shift;
	my $singlCpn = shift;
	my $errMess  = shift;

	my $routeBetween  = $self->{"routeBetween"};
	my $routeAbove    = $self->{"routeAbove"};
	my $routeBelow    = $self->{"routeBelow"};
	my $routeStreight = $self->{"routeStreight"};

	my $reuslt = 1;

	foreach my $pool ( $singlCpn->GetPools() ) {

		foreach my $l ( @{ $self->{"layers"} } ) {

			my %usedRoute = (
							  Enums->Route_ABOVE    => 0,
							  Enums->Route_BELOW    => 0,
							  Enums->Route_STREIGHT => 0
			);

			foreach my $strip ( $pool->GetStripsByLayer($l) ) {

				my $stripRouteOk = 0;

				if ( $routeStreight && !$singlCpn->IsMultistrip() ) {

					$usedRoute{ Enums->Route_STREIGHT } = 1;
					$strip->SetRoute( Enums->Route_STREIGHT );
					$strip->SetRouteDist(0);
					$strip->SetRouteWidth($self->__GetTrackWidth($strip));
					$stripRouteOk = 1;
					next;
				}

				if ( $routeStreight && !$usedRoute{ Enums->Route_STREIGHT } && $self->__CheckStraightRoute($strip) ) {

					$usedRoute{ Enums->Route_STREIGHT } = 1;
					$strip->SetRoute( Enums->Route_STREIGHT );
					$stripRouteOk = 1;
					next;
				}

				if ( $pool->GetOrder() == 0 ) {

					if ( $routeBetween && !$usedRoute{ Enums->Route_ABOVE } && $self->__CheckRoute( $strip, 1, $errMess ) ) {

						$usedRoute{ Enums->Route_ABOVE } = 1;
						$strip->SetRoute( Enums->Route_ABOVE );
						$stripRouteOk = 1;
						next;
					}

					if ( $routeBelow && !$usedRoute{ Enums->Route_BELOW } && $self->__CheckRoute( $strip, 0, $errMess ) ) {

						$usedRoute{ Enums->Route_BELOW } = 1;
						$strip->SetRoute( Enums->Route_BELOW );
						$stripRouteOk = 1;
						next;
					}

				}
				elsif ( $pool->GetOrder() == 1 ) {

					if ( $routeBetween && !$usedRoute{ Enums->Route_BELOW } && $self->__CheckRoute( $strip, 1, $errMess ) ) {

						$usedRoute{ Enums->Route_BELOW } = 1;
						$strip->SetRoute( Enums->Route_BELOW );
						$stripRouteOk = 1;
						next;
					}

					if ( $routeAbove && !$usedRoute{ Enums->Route_ABOVE } && $self->__CheckRoute( $strip, 0, $errMess ) ) {

						$usedRoute{ Enums->Route_ABOVE } = 1;
						$strip->SetRoute( Enums->Route_ABOVE );
						$stripRouteOk = 1;
						next;
					}
				}

				unless ($stripRouteOk) {
					$reuslt = 0;
					last;
				}

			}

			unless ($reuslt) {
				last;
			}

		}

		unless ($reuslt) {
			last;
		}
	}

	return $reuslt;
}

# Only strips which are last in pool and which are type SE or COSE
sub __CheckStraightRoute {
	my $self  = shift;
	my $strip = shift;

	my $res = 1;

	if ( $strip->GetType() ne Enums->Type_SE && $strip->GetType() ne Enums->Type_COSE ) {
		$res = 0;
	}

	if ( !$strip->GetIsLast() ) {
		$res = 0;
	}
	
	if($res){

		$strip->SetRouteDist(0);
		$strip->SetRouteWidth( $self->__GetTrackWidth($strip));
		
	}
	

	return $res;
}

sub __CheckRoute {
	my $self             = shift;
	my $strip            = shift;
	my $trackThroughPads = shift;   
	my $errMess          = shift;

	my $result = 1;

	my $trackPadIsolation = $self->{"trackPadIsolation"} / 1000;    # mm
	my $trackPad2GNDPad   = $self->{"trackPad2GNDPad"} / 1000;      # mm
	my $padTrackSize      = $self->{"padTrackSize"} / 1000;         # mm
	my $padGNDSize        = $self->{"padGNDSize"} / 1000;           # mm

	my $stripData = $strip->Data();

	my $trackW = $self->__GetTrackWidth($strip); # total track (tracks if differential) width
	my $trackDistance = undef; # track distance from track pad (height from track pad which track is placed on coupon)

	 

	if ($trackThroughPads) {

		# free space for track
		my $space = $trackPad2GNDPad - $padTrackSize / 2 - $padGNDSize / 2;

		if ( ( $space - $trackW ) >= 2 * $trackPadIsolation ) {

			$trackDistance = $trackPad2GNDPad / 2;
		}
		else {
			$result = 0;
			$$errMess = "Small isolation between track and pads" if ( defined $$errMess );
		}

	}

	# pads go around track pad (above or below)
	else {

		$trackDistance = $padTrackSize / 2 + $trackPadIsolation + $trackW / 2;
	}
	
	if($result){
		$strip->SetRouteDist($trackDistance);
		$strip->SetRouteWidth($trackW);
		
	}

	return $result;
}

sub __GetTrackWidth{
	my $self             = shift;
	my $strip            = shift;
	
	my $trackW = undef; # total track (tracks if differential) width

	my $stripData = $strip->Data();

	if ( $strip->GetType() eq Enums->Type_SE || $strip->GetType() eq Enums->Type_COSE ) {

		$trackW = $stripData->{"xmlConstraint"}->GetParamDouble("WB");
	}
	else {

		$trackW = 2 * $stripData->{"xmlConstraint"}->GetParamDouble("WB") + $stripData->{"xmlConstraint"}->GetParamDouble("S");
	}

	$trackW /= 1000;
	
	return $trackW
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

