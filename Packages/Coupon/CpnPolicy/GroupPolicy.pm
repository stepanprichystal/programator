
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
	$self->{"poolCnt"}     = shift;

	return $self;

}

sub GenerateGroups {
	my $self   = shift;
	my $filter = shift;

	my @poolCombs = $self->__GeneratePools($filter);

	my @groupCombs = ();

	my $poolCnt = $self->{"poolCnt"};

	foreach my $c (@poolCombs) {

		my @poolComb  = @{$c};
		my @groupComb = ();

		# define single coupon until all pool are not processed
		while ( scalar(@poolComb) ) {

			my @group = ();

			for ( my $i = 0 ; $i < scalar($poolCnt) ; $i++ ) {

				# define pool
				last unless ( scalar(@poolComb) );

				push( @group, shift(@poolComb) );
			}

			push( @groupComb, \@group );
		}

		push( @groupCombs, \@groupComb );
	}

	return @groupCombs;
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

sub __GeneratePools {
	my $self   = shift;
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

	print STDERR "\n\n--- Pocet kombinaci " . scalar(@allComb) . "-----\n";

	print STDERR "--- Kontrola kolize vrstev-----\n";

	for ( my $i = scalar(@allComb) - 1 ; $i >= 0 ; $i-- ) {

		my $remove         = 0;
		my @affectedLayers = ();

		# go through each group
		foreach my $pool ( @{ $allComb[$i] } ) {

			my $moreTracksExists = 0;    # More (= 2 by actual seetings) tracks per one track layer

			foreach my $l (@layers) {
				my %h              = ();
				my $lTypestByGroup = 0;

				my %types = ();
				$types{$_}++ foreach ( grep { $_ ne Enums->Layer_TYPENOAFFECT } map { $_->{"l"}->{$l} } @{$pool} );

				# 1. RULE Layer type collision in one "pool"
				if ( scalar( keys %types ) > 1 ) {

					print STDERR "Removed by layer colisiton\n";
					$remove = 1;
					last;
				}

				if ( defined $types{ Enums->Layer_TYPETRACK } ) {

					# 2. RULE Max count of miscrostrip track in one "pool" is $maxTrackCnt
					if ( $types{ Enums->Layer_TYPETRACK } > $maxTrackCnt ) {
						print STDERR "Removed by max trace cnt\n";
						$remove = 1;
						last;
					}

					# 3. RULE If exist 2 track in same track layer, no another layer can contain 2 or more tracks
					elsif ( $types{ Enums->Layer_TYPETRACK } == $maxTrackCnt && $moreTracksExists ) {
						print STDERR "Removed by max trace in more layers cnt\n";
						$remove = 1;
						last;
					}
					elsif ( $types{ Enums->Layer_TYPETRACK } == $maxTrackCnt && !$moreTracksExists ) {
						$moreTracksExists = 1;

					}
				}

				# 4. RULE. Only some combination of microstrip are alowed in one track layer
				# if script is here its mean only track layer are in this pool in current layer
				if ( defined $types{ Enums->Layer_TYPETRACK } ) {

					# get all microstrip which contain for current layer, layer type : track
					my @mTypes = map { $_->{"type"} } grep { $_->{"l"}->{$l} eq Enums->Layer_TYPETRACK } @{$pool};

					# Check allowed combination of microstrip which has track in same layer
					if ( scalar(@mTypes) == $maxTrackCnt ) {

						# allowed combination
						my %rules = ();

						# se
						$rules{ Enums->Type_SE . Enums->Type_SE }     = 1;
						$rules{ Enums->Type_SE . Enums->Type_DIFF }   = 1;
						$rules{ Enums->Type_SE . Enums->Type_COSE }   = 0;
						$rules{ Enums->Type_SE . Enums->Type_CODIFF } = 0;

						# diff
						$rules{ Enums->Type_DIFF . Enums->Type_SE }     = 1;
						$rules{ Enums->Type_DIFF . Enums->Type_DIFF }   = 0;
						$rules{ Enums->Type_DIFF . Enums->Type_COSE }   = 0;
						$rules{ Enums->Type_DIFF . Enums->Type_CODIFF } = 0;

						# cose
						$rules{ Enums->Type_COSE . Enums->Type_SE }     = 0;
						$rules{ Enums->Type_COSE . Enums->Type_DIFF }   = 0;
						$rules{ Enums->Type_COSE . Enums->Type_COSE }   = 0;
						$rules{ Enums->Type_COSE . Enums->Type_CODIFF } = 0;

						# codiff
						$rules{ Enums->Type_CODIFF . Enums->Type_SE }     = 0;
						$rules{ Enums->Type_CODIFF . Enums->Type_DIFF }   = 0;
						$rules{ Enums->Type_CODIFF . Enums->Type_COSE }   = 0;
						$rules{ Enums->Type_CODIFF . Enums->Type_CODIFF } = 0;

						unless ( $rules{ $mTypes[0] . $mTypes[1] } ) {
							print STDERR "Removed by not alowed microstrim combinations (" . $mTypes[0] . "-" . $mTypes[1] . ") in one pool\n";
							$remove = 1;
							last;
						}
					}

				}

			}

			last if ($remove);
		}

		if ($remove) {
			print STDERR "Combination REMOVED: " . $self->CombToStr( $allComb[$i] ) . "\n";
			splice @allComb, $i, 1;
		}
		else {
			print STDERR "Combination OK     :  " . $self->CombToStr( $allComb[$i] ) . "\n";
		}

	}

	# -------------------
	# SORTING
	# -------------------

	# 1. sort, strips with measurement in highest layers (L1 = top) will sorted from left -> right in coupon single
	for ( my $i = 0 ; $i < scalar(@allComb) ; $i++ ) {

		for ( my $j = 0 ; $j < scalar( @{ $allComb[$i] } ) ; $j++ ) {

			my @tTmp = sort { ( $a->{"track"} =~ /L(\d+)/ )[0] <=> ( $b->{"track"} =~ /L(\d+)/ )[0] } @{ @{ $allComb[$i] }[$j] };

			@{ $allComb[$i] }[$j] = \@tTmp;
		}

		#	my @tTmp = sort { $p{ $consHash{$b}->{"type"}} <=> $p{$consHash{$a}->{"type"}} } @{$allComb[$i]};
		#	$allComb[$i] = \@tTmp;
	}

	# 2. sort microstrips by priority
	# priority of order left to right (1 highest priority -> the most right order)
	my %p = ();

	$p{ Enums->Type_SE }     = 1;
	$p{ Enums->Type_DIFF }   = 2;
	$p{ Enums->Type_COSE }   = 3;
	$p{ Enums->Type_CODIFF } = 4;

	for ( my $i = 0 ; $i < scalar(@allComb) ; $i++ ) {

		for ( my $j = 0 ; $j < scalar( @{ $allComb[$i] } ) ; $j++ ) {

			my @tTmp = sort { $p{ $b->{"type"} } <=> $p{ $a->{"type"} } } @{ @{ $allComb[$i] }[$j] };

			@{ $allComb[$i] }[$j] = \@tTmp;
		}
	}

	return @allComb;
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

		$inf{"id"}    = $c->GetConstrainId();
		$inf{"type"}  = $c->GetType();
		$inf{"track"} = $c->GetTrackLayer();
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

