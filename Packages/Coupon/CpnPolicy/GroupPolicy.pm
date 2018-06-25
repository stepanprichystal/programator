
#-------------------------------------------------------------------------------------------#
# Description: Default coupon settings
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnPolicy::GroupPolicy;

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use List::Util qw[max];
use Algorithm::Combinatorics qw(partitions);
use Integer::Partition;
use Set::Partition;

#local library
use aliased 'Packages::Coupon::Enums';
use aliased 'Packages::Coupon::CpnSource::CpnSource';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"cpnSource"} = shift;

	# se
	$self->{"maxTrackCnt"} = shift;

	my @layers = map { $_->{"NAME"} } $self->{"cpnSource"}->GetCopperLayers();
	$self->{"layers"} = \@layers;

	#$self->{"poolCnt"}     = shift;

	return $self;

}

sub GenerateGroups {
	my $self = shift;

	my $filter = shift;    # process only some constrain by  specify array of STACKUP_ORDERING_INDEX vals

	my $maxTrackCnt = $self->{"maxTrackCnt"};    # max tracks on one layer in one pool

	my @layers = map { $_->{"NAME"} } $self->{"cpnSource"}->GetCopperLayers();
	my @xmlCons = $self->{"cpnSource"}->GetConstraints();

	if ( defined $filter ) {
		my %tmp;

		@tmp{ @{$filter} } = ();

		@xmlCons = grep { exists $tmp{ $_->GetOption("STACKUP_ORDERING_INDEX") } } @xmlCons;
	}

	@xmlCons = $self->__GetConstraints( \@xmlCons );    # build structure for constrain

	my @allComb = partitions( \@xmlCons );

	# sort
	# Sort whole array. Combination with minimum cpool cnt on begining of all combinations in list
	@allComb = sort { scalar( @{$a} ) <=> scalar( @{$b} ) } @allComb;

	# sort inside each combination. Pool with maxiaml count of strips move to begining of all poos
	for ( my $i = 0 ; $i < scalar(@allComb) ; $i++ ) {

		my @tTmp = sort { scalar( @{$b} ) <=> scalar( @{$a} ) } @{ $allComb[$i] };
		$allComb[$i] = \@tTmp;
	}

	# Sort whole array. Sort combination by size of first pool in combination. Bigger pool are on begining
	@allComb = sort { scalar( @{ $b->[0] } ) <=> scalar( @{ $a->[0] } ) } @allComb;

	print STDERR "\n\n--- Combinations: " . scalar(@allComb) . "-----\n";

	foreach my $c (@allComb) {
		#print STDERR $self->CombToStr($c) . "\n";
	}

	print STDERR "\n\n--- Filter by max count of measure in one group \n";

	for ( my $i = scalar(@allComb) - 1 ; $i >= 0 ; $i-- ) {

		my $remove         = 0;
		my @affectedLayers = ();

		# go through each group
		foreach my $group ( @{ $allComb[$i] } ) {

			my $moreTracksExists = 0;    # More (= 2 by actual seetings) tracks per one track layer

			foreach my $l (@layers) {
				my %h              = ();
				my $lTypestByGroup = 0;

				my %types = ();
				$types{$_}++ foreach ( grep { $_ ne Enums->Layer_TYPENOAFFECT } map { $_->{"l"}->{$l} } @{$group} );

				# 2. RULE Max count of miscrostrip track in one "pool" is $maxTrackCnt
				if ( defined $types{ Enums->Layer_TYPETRACK } && $types{ Enums->Layer_TYPETRACK } > $maxTrackCnt ) {
					print STDERR "Removed by max trace cnt\n";
					$remove = 1;
					last;
				}
			}
		}

		if ($remove) {
			#print STDERR "Combination REMOVED: " . $self->CombToStr( $allComb[$i] ) . "\n";
			splice @allComb, $i, 1;
		}
		else {
			#print STDERR "Combination OK     :  " . $self->CombToStr( $allComb[$i] ) . "\n";
		}
	}

 

	return @allComb;
}

sub VerifyGroupComb {
	my $self          = shift;
	my $groupComb     = shift;
	my $maxPoolCnt    = shift;
	my $maxStripsCntH = shift;
	my $groupPoolComb = shift;

	my $result = 1;
	foreach my $group ( @{$groupComb} ) {

		# return all alowed pool combination for one group
		#
		# Example:
		# (m1 m2 m3 m4 m5)
		# (m1) (m2 m3 m4 m5)
		# (m5) (m1 m2 m3 m4)
		# (m1 m2) (m3 m4 m5)
		# (m1 m3) (m2 m4 m5)

		my @poolComb = $self->__GetPoolComb( $group, $maxPoolCnt, $maxStripsCntH );

		if ( scalar(@poolComb) ) {

			push( @{$groupPoolComb}, \@poolComb );

		}
		else {

			$result = 0;
			@{$groupPoolComb} = ();
			last;
		}

	}
	return $result;
}

sub __GetPoolComb {
	my $self          = shift;
	my $group         = shift;
	my $maxPoolCnt    = shift;
	my $maxStripsCntH = shift;

	# 1) Devide group to pools

	my @poolComb = ();

	# define paratitions (dividing strip measurement into "pools" by "n" items)
	my @partitions = ();

	push( @partitions, scalar( @{$group} ) );    # max pool count = 1pool per 1 group

	if ( $maxPoolCnt == 2 && scalar( @{$group} ) != 1 ) {
		push( @partitions, ( int( scalar( @{$group} ) / 2 ) .. scalar( @{$group} ) - 1 ) );
	}

	foreach my $partSize (@partitions) {

		my $s = Set::Partition->new( list      => $group,
									 partition => [$partSize], );

		while ( my $p = $s->next ) {
			push( @poolComb, $p );

			#print join( ' ', map { "(@$_)" } @$p ), $/;

		}
	}

	# 2) Filter pools by Layout criteria
	my @layers      = @{ $self->{"layers"} };
	my $maxTrackCnt = $self->{"maxTrackCnt"};

	for ( my $i = scalar(@poolComb) - 1 ; $i >= 0 ; $i-- ) {

		my $remove         = 0;
		my @affectedLayers = ();

		# go through each group
		foreach my $pool ( @{ $poolComb[$i] } ) {

			if ( scalar( @{$pool} ) > $maxStripsCntH ) {
				$remove = 1;
				#print STDERR "Removed by max strip count in Horizontal dir (cnt: " . scalar( @{$pool} ) . ", max: $maxStripsCntH)\n";
				last;
			}

			my $maxTrackCntUsed = 0;    # In one track layer was already found max possible count of track by settings

			foreach my $l (@layers) {
				my %h              = ();
				my $lTypestByGroup = 0;

				my %types = ();
				$types{$_}++ foreach ( grep { $_ ne Enums->Layer_TYPENOAFFECT } map { $_->{"l"}->{$l} } @{$pool} );

				# 1. RULE Layer type collision in one "pool"
				if ( scalar( keys %types ) > 1 ) {

					#print STDERR "Removed by layer colisiton. More types in one layer (types: " . join( ";", keys %types ) . ")\n";
					$remove = 1;
					last;
				}

				if ( defined $types{ Enums->Layer_TYPETRACK } ) {

					# 3. RULE If exist 2 track in same track layer, no another layer can contain 2 or more tracks
					if ( $types{ Enums->Layer_TYPETRACK } == $maxTrackCnt && $maxTrackCntUsed ) {
						#print STDERR "Removed by max trace count in more layers than one layer per pool\n";
						$remove = 1;
						last;
					}
					elsif ( $types{ Enums->Layer_TYPETRACK } == $maxTrackCnt && !$maxTrackCntUsed ) {
						$maxTrackCntUsed = 1;

					}
				}

				# 4. RULE. Only some combination of microstrip are alowed in one track layer
				# if script is here its mean only track layer are in this pool in current layer
				if ( defined $types{ Enums->Layer_TYPETRACK } ) {

					my @forbidden = ();

					push( @forbidden, [ Enums->Type_COSE,   Enums->Type_SE ] );
					push( @forbidden, [ Enums->Type_COSE,   Enums->Type_DIFF ] );
					push( @forbidden, [ Enums->Type_COSE,   Enums->Type_COSE ] );
					push( @forbidden, [ Enums->Type_COSE,   Enums->Type_CODIFF ] );
					push( @forbidden, [ Enums->Type_CODIFF, Enums->Type_SE ] );
					push( @forbidden, [ Enums->Type_CODIFF, Enums->Type_DIFF ] );
					push( @forbidden, [ Enums->Type_CODIFF, Enums->Type_CODIFF ] );

					# get all microstrip which contain for current layer, layer type : track
					my @mTypes = map { $_->{"type"} } grep { $_->{"l"}->{$l} eq Enums->Layer_TYPETRACK } @{$pool};

					# Check all forbidden combination
					foreach my $fComb (@forbidden) {

						# convert forbibidden comb to array
						my %fCombTmp = @{$fComb};
						$fCombTmp{$_} = 0 foreach ( keys %fCombTmp );

						foreach my $mTytpe (@mTypes) {

							if ( defined $fCombTmp{$mTytpe} ) {
								$fCombTmp{$mTytpe} = 1;
							}
						}

						# check if exist forbidden combination
						my $combOk = 0;
						foreach my $type ( keys %fCombTmp ) {

							if ( defined $fCombTmp{$type} && $fCombTmp{$type} == 0 ) {
								$combOk = 1;
								last;
							}
						}

						unless ($combOk) {
							$remove = 1;
							#print STDERR "Removed by bz forbidden combination in one pool (" . join( ";", @{$fComb} ) . ")\n";
							last;
						}

						last if ($remove);
					}

				}

			}

			last if ($remove);
		}

		if ($remove) {
			#print STDERR "Combination REMOVED: " . $self->CombToStr( $poolComb[$i] ) . "\n";
			splice @poolComb, $i, 1;
		}
		else {
			#print STDERR "Combination OK     :  " . $self->CombToStr( $poolComb[$i] ) . "\n";
		}

	}

	return @poolComb;
}

sub GroupCombExists {
	my $self   = shift;
	my $filter = shift;    # process only some constrain by  specify array of STACKUP_ORDERING_INDEX vals

	my @testGroups = @{ shift(@_) };

	my $maxTrackCnt = $self->{"maxTrackCnt"};    # max tracks on one layer in one pool

	my $result = 0;

	# created group test hash
	my %testH = ();

	for ( my $i = 0 ; $i < scalar(@testGroups) ; $i++ ) {

		for ( my $j = 0 ; $j < scalar( @{ $testGroups[$i] } ) ; $j++ ) {

			for ( my $k = 0 ; $k < scalar( @{ $testGroups[$i]->[$j] } ) ; $k++ ) {

				$testH{ $i . "-" . $testGroups[$i]->[$j]->[$k]->{"id"} } = 1;
			}
		}
	}

	foreach my $comb ( $self->GenerateGroups($filter) ) {

		my @defGroups = @{$comb};

		# create test hash
		my %genH = ();

		for ( my $i = 0 ; $i < scalar(@defGroups) ; $i++ ) {

			for ( my $j = 0 ; $j < scalar( @{ $defGroups[$i] } ) ; $j++ ) {

				for ( my $k = 0 ; $k < scalar( @{ $defGroups[$i]->[$j] } ) ; $k++ ) {

					$genH{ $i . "-" . $defGroups[$i]->[$j]->[$k]->{"id"} } = 1;
				}
			}
		}

		# compare test group and generated group
		my $same = 1;
		foreach my $k ( keys %testH ) {

			if ( !defined $genH{$k} ) {
				$same = 0;
				last;
			}
		}

		if ($same) {
			$result = 1;
			last;
		}

	}

	return $result;
}

sub GroupsToStr {
	my $self  = shift;
	my @combs = @{ shift(@_) };

	my $str = "";

	foreach my $groupsComb (@combs) {

		foreach my $group ( @{$groupsComb} ) {
			$str .= "{";
			foreach my $pool ( @{$group} ) {

				$str .= "(" . join( " | ", map { $_->{"title"} } @{$pool} ) . ") ";
			}
			$str .= "} ";
		}
		$str .= "\n";
	}

	return $str;
}

sub CombToStr {
	my $self = shift;
	my @comb = @{ shift(@_) };

	my $str = "";

	foreach my $p (@comb) {

		$str .= "(" . join( " | ", map { $_->{"title"} } @{$p} ) . ") ";
	}
	return $str;
}
 

sub __GetConstraints {
	my $self        = shift;
	my @xmlCons     = @{ shift(@_) };
	my @constraints = ();

	my @layers = map { $_->{"NAME"} } $self->{"cpnSource"}->GetCopperLayers();

	foreach my $c (@xmlCons) {

		my %inf = ();
		$inf{"title"} =
		    $c->GetType() . "_m="
		  . $c->GetTrackLayer() . " t="
		  . ( $c->GetTopRefLayer() =~ /^L/ ? $c->GetTopRefLayer() : "-" ) . " b="
		  . ( $c->GetBotRefLayer() =~ /^L/ ? $c->GetBotRefLayer() : "-" ) . " w="
		  . $c->GetParamDouble("WB");

		$inf{"id"}            = $c->GetConstrainId();
		$inf{"type"}          = $c->GetType();
		$inf{"track"}         = $c->GetTrackLayer();
		$inf{"xmlConstraint"} = $c;

		my %h = ();

		# init all layer type to -1
		$h{$_} = "notset" foreach (@layers);

		# set measure layer, top ref, bot ref, extra layers
		foreach my $lName (@layers) {
			my $t = undef;

			if ( $lName eq $c->GetTrackLayer() ) {
				$t = Enums->Layer_TYPETRACK;
			}
			elsif ( $lName eq $c->GetTopRefLayer() || $lName eq $c->GetBotRefLayer() ) {
				$t = Enums->Layer_TYPEGND;

			}
			elsif ( $lName eq $c->GetTrackExtraLayer() ) {
				$t = Enums->Layer_TYPETRACKEXTRA;
			}
			else {
				next;
			}
			$h{$lName} = $t;
		}

		# Identify extra layers which have impact to measurement
		# Layers which involve measurement are 2 positions above and 2 positions below trace layer and trace-extra layer
		my ($tLNum) = $c->GetTrackLayer() =~ /^L(\d+)$/;
		my @affectLayer = ( $tLNum - 1, $tLNum + 1 );

		my ($tELNum) = $c->GetTrackExtraLayer() =~ /^L(\d+)$/;
		if ( defined $tELNum ) {
			push( @affectLayer, ( $tELNum - 1, $tELNum + 1 ) );
		}

		foreach my $lNum (@affectLayer) {

			if ( defined $h{"L$lNum"} && $h{"L$lNum"} eq "notset" ) {
				$h{"L$lNum"} = Enums->Layer_TYPEAFFECT;
			}
		}

		foreach my $lName (@layers) {

			if ( $h{$lName} eq "notset" ) {
				$h{$lName} = Enums->Layer_TYPENOAFFECT;
			}
		}

		# rest of layer set tu unused

		$inf{"l"} = \%h;

		push( @constraints, \%inf );
	}

	return @constraints;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

