
#-------------------------------------------------------------------------------------------#
# Description: Default coupon settings
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnPolicy::GroupPolicy;

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use List::Util qw[max];
use Algorithm::Combinatorics qw(partitions);
use Integer::Partition;
use Set::Partition;
use POSIX;

#local library
use aliased 'Programs::Coupon::Enums';
use aliased 'Programs::Coupon::CpnSource::CpnSource';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"cpnSource"} = shift;

	# Properties

	my @layers = map { $_->{"NAME"} } $self->{"cpnSource"}->GetCopperLayers();
	$self->{"layers"} = \@layers;

	# global settings
	$self->{"maxTrackCnt"} = undef;

	# groups settings
	$self->{"groupSett"} = {};

	return $self;

}

sub SetGlobalSettings {
	my $self = shift;

	$self->{"maxTrackCnt"} = shift;

}

sub SetGroupSettings {
	my $self    = shift;
	my $groupId = shift;

	my %sett = ();
	$sett{"maxPoolCnt"}    = shift;
	$sett{"maxStripsCntH"} = shift;

	$self->{"groupSett"}->{$groupId} = \%sett;

}

sub __GetGroupSett {
	my $self    = shift;
	my $groupId = shift;

	die "group settings: $groupId is not defined" unless ( defined $self->{"groupSett"}->{$groupId} );

	return $self->{"groupSett"}->{$groupId};
}

sub VerifyGroupComb {
	my $self          = shift;
	my $groupComb     = shift;
	my $groupPoolComb = shift;

	my $result  = 1;
	my $groupId = 0;
	foreach my $group ( @{$groupComb} ) {

		my $maxPoolCnt    = $self->__GetGroupSett($groupId)->{"maxPoolCnt"};
		my $maxStripsCntH = $self->__GetGroupSett($groupId)->{"maxStripsCntH"};

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

		$groupId++;

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

	# Remove if max strip cnt in one group is exceeded
	if ( scalar( @{$group} ) > $maxPoolCnt * $maxStripsCntH ) {

		print STDERR "Max strips count (" . ( $maxPoolCnt * $maxStripsCntH ) . ") per group exceeded (" . scalar( @{$group} ) . ")\n";
		return @poolComb;
	}

	# define paratitions (dividing strip measurement into "pools" by "n" items)

	# Merge more constrain which create "fake constraint". After partition process this fake constraint will be splited
	# Merge constrain to max 6 "fake constraints"
	my $maxItems   = 8;
	my %fakeConstr = ();

	my $fakeConstrCnt = ceil( scalar( @{$group} ) / $maxItems );
	my $fakeItem      = 0;
	while ( scalar( @{$group} ) ) {

		my @fakeItem = splice @{$group}, 0, $fakeConstrCnt;
		$fakeConstr{$fakeItem} = \@fakeItem;

		$fakeItem++;
	}

	my @fakeItems = keys %fakeConstr;

	#################
	#@{$group} = partitions( \@fakeItems );
	my @partitions = ();

	push( @partitions, scalar(@fakeItems) );    # max pool count = 1pool per 1 group

	if ( $maxPoolCnt == 2 && scalar(@fakeItems) != 1 ) {
		push( @partitions, ( int( scalar(@fakeItems) / 2 ) .. scalar(@fakeItems) - 1 ) );
	}

	foreach my $partSize (@partitions) {

		my $s = Set::Partition->new( list      => \@fakeItems,
									 partition => [$partSize], );

		while ( my $p = $s->next ) {
			push( @poolComb, $p );

			#print join( ' ', map { "(@$_)" } @$p ), $/;

		}
	}

	###########

	# replace fake items by constraints

	for ( my $i = 0 ; $i < scalar(@poolComb) ; $i++ ) {

		for ( my $j = 0 ; $j < scalar( @{ $poolComb[$i] } ) ; $j++ ) {

			my @comb = ();
			for ( my $k = 0 ; $k < scalar( @{ $poolComb[$i]->[$j] } ) ; $k++ ) {

				push( @comb, @{ $fakeConstr{ $poolComb[$i]->[$j]->[$k] } } );

				#$allComb[$i]->[$j]->[$k] = @{$fakeConstr{ $allComb[$i]->[$j]->[$k] }};
			}

			$poolComb[$i]->[$j] = \@comb;
		}
	}

	# 2) Filter pools by Layout criteria
	my @layers      = @{ $self->{"layers"} };
	my $maxTrackCnt = $self->{"maxTrackCnt"};

	for ( my $i = scalar(@poolComb) - 1 ; $i >= 0 ; $i-- ) {

		my $remove         = 0;
		my @affectedLayers = ();

		# go through each group
		foreach my $pools ( @{ $poolComb[$i] } ) {

			if ( scalar( @{$pools} ) > $maxStripsCntH ) {
				$remove = 1;

				print STDERR "Removed by max strip count in Horizontal dir (cnt: " . scalar( @{$pools} ) . ", max: $maxStripsCntH)\n";
				last;
			}

			my $maxTrackCntUsed = 0;    # In one track layer was already found max possible count of track by settings

			foreach my $l (@layers) {
				my %h              = ();
				my $lTypestByGroup = 0;

				my %types = ();
				$types{$_}++ foreach ( grep { $_ ne Enums->Layer_TYPENOAFFECT } map { $_->{"l"}->{$l} } @{$pools} );

				# 1. RULE Layer type collision in one "pool"
				if ( scalar( keys %types ) > 1 ) {

					print STDERR "Removed by layer colisiton. More types in one layer (types: " . join( ";", keys %types ) . ")\n";
					$remove = 1;
					last;
				}

				if ( defined $types{ Enums->Layer_TYPETRACK } ) {

					#					# 3. RULE If exist 2 track in same track layer, no another layer can contain 2 or more tracks
					#					if ( $types{ Enums->Layer_TYPETRACK } == $maxTrackCnt && $maxTrackCntUsed ) {
					#
					#						print STDERR "Removed by max trace count in more layers than one layer per pool\n";
					#						$remove = 1;
					#						last;
					#					}
					#					elsif ( $types{ Enums->Layer_TYPETRACK } == $maxTrackCnt && !$maxTrackCntUsed ) {
					#						$maxTrackCntUsed = 1;
					#
					#					}
					if ( $types{ Enums->Layer_TYPETRACK } > $maxTrackCnt ) {
						print STDERR "Removed by max trace count in one layer per group\n";
						$remove = 1;
						last;

					}
				}

				#				# 4. RULE. Only some combination of microstrip are alowed in one track layer
				#				# if script is here its mean only track layer are in this pool in current layer
				#				if ( defined $types{ Enums->Layer_TYPETRACK } ) {
				#
				#					my @forbidden = ();
				#
				#					push( @forbidden, [ Enums->Type_COSE,   Enums->Type_SE ] );
				#					push( @forbidden, [ Enums->Type_COSE,   Enums->Type_DIFF ] );
				#					push( @forbidden, [ Enums->Type_COSE,   Enums->Type_COSE ] );
				#					push( @forbidden, [ Enums->Type_COSE,   Enums->Type_CODIFF ] );
				#					push( @forbidden, [ Enums->Type_CODIFF, Enums->Type_SE ] );
				#					push( @forbidden, [ Enums->Type_CODIFF, Enums->Type_DIFF ] );
				#					push( @forbidden, [ Enums->Type_CODIFF, Enums->Type_CODIFF ] );
				#
				#					# get all microstrip which contain for current layer, layer type : track
				#					my @mTypes = map { $_->{"type"} } grep { $_->{"l"}->{$l} eq Enums->Layer_TYPETRACK } @{$pool};
				#
				#					# Check all forbidden combination
				#					foreach my $fComb (@forbidden) {
				#
				#						# convert forbibidden comb to array
				#						my %fCombTmp = @{$fComb};
				#						$fCombTmp{$_} = 0 foreach ( keys %fCombTmp );
				#
				#						foreach my $mTytpe (@mTypes) {
				#
				#							if ( defined $fCombTmp{$mTytpe} ) {
				#								$fCombTmp{$mTytpe} = 1;
				#							}
				#						}
				#
				#						# check if exist forbidden combination
				#						my $combOk = 0;
				#						foreach my $type ( keys %fCombTmp ) {
				#
				#							if ( defined $fCombTmp{$type} && $fCombTmp{$type} == 0 ) {
				#								$combOk = 1;
				#								last;
				#							}
				#						}
				#
				#						unless ($combOk) {
				#							$remove = 1;
				#							#print STDERR "Removed by bz forbidden combination in one pool (" . join( ";", @{$fComb} ) . ")\n";
				#							last;
				#						}
				#
				#						last if ($remove);
				#					}
				#
				#				}

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

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

