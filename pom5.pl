#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

use XML::LibXML;
use Integer::Partition;
use Set::Partition;
use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );
use Algorithm::Combinatorics qw(partitions);

use aliased 'Packages::Coupon::Enums';

my @layers = ( "L1", "L2", "L3", "L4" );

my @constraints = ();

my %se1 = (
			"id"   => Enums->Type_SE . "1",
			"type" => Enums->Type_SE,
			"l"    => {
					 "L1" => Enums->Layer_TYPETRACK,
					 "L2" => Enums->Layer_TYPEGND,
					 "L3" => Enums->Layer_TYPENOAFFECT,
					 "L4" => Enums->Layer_TYPENOAFFECT
			}
);

my %se2 = (
			"id"   => Enums->Type_SE . "2",
			"type" => Enums->Type_SE,
			"l"    => {
					 "L1" => Enums->Layer_TYPETRACK,
					 "L2" => Enums->Layer_TYPEGND,
					 "L3" => Enums->Layer_TYPENOAFFECT,
					 "L4" => Enums->Layer_TYPENOAFFECT
			}
);

my %se3 = (
			"id"   => Enums->Type_SE . "3",
			"type" => Enums->Type_SE,
			"l"    => {
					 "L1" => Enums->Layer_TYPETRACK,
					 "L2" => Enums->Layer_TYPEGND,
					 "L3" => Enums->Layer_TYPENOAFFECT,
					 "L4" => Enums->Layer_TYPENOAFFECT
			}
);

my %se4 = (
			"id"   => Enums->Type_SE . "4",
			"type" => Enums->Type_SE,
			"l"    => {
					 "L1" => Enums->Layer_TYPETRACK,
					 "L2" => Enums->Layer_TYPEGND,
					 "L3" => Enums->Layer_TYPENOAFFECT,
					 "L4" => Enums->Layer_TYPENOAFFECT
			}
);

my %diff1 = (
			  "id"   => Enums->Type_DIFF . "1",
			  "type" => Enums->Type_DIFF,
			  "l"    => {
					   "L1" => Enums->Layer_TYPETRACK,
					   "L2" => Enums->Layer_TYPEGND,
					   "L3" => Enums->Layer_TYPENOAFFECT,
					   "L4" => Enums->Layer_TYPENOAFFECT
			  }
);

my %diff2 = (
			  "id"   => Enums->Type_DIFF . "2",
			  "type" => Enums->Type_DIFF,
			  "l"    => {
					   "L1" => Enums->Layer_TYPENOAFFECT,
					   "L2" => Enums->Layer_TYPENOAFFECT,
					   "L3" => Enums->Layer_TYPEGND,
					   "L4" => Enums->Layer_TYPETRACK
			  }
);

my %consHash = ();
$consHash{ $se1{"id"} } = \%se1;
$consHash{ $se2{"id"} } = \%se2;

#$consHash{ $se3{"id"} }   = \%se3;
#$consHash{ $se4{"id"} }   = \%se4;
$consHash{ $diff1{"id"} } = \%diff1;
$consHash{ $diff2{"id"} } = \%diff2;

my @consArr = ();
push( @consArr, \%se1 );
push( @consArr, \%se2 );
push( @consArr, \%diff1 );
push( @consArr, \%diff2 );

my @ids = keys %consHash;

my $cnt = 1;

# Get all combination of miscrostrip
# From all microstrips in one pool to one microstrip in one pool

my @allComb = partitions( \@consArr );

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


PrintCombination(\@allComb);

sub PrintCombination {
	my @comb = @{shift(@_)};
	
	foreach my $t (@allComb) {
		foreach my $p ( @{$t} ) {

			print STDERR "(" . join( " ", map { $_->{"id"} } @{$p} ) . ") ";
		}
		print STDERR "\n";
	}
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

print STDERR "\n\n--- Pocet kombinaci " . scalar(@allComb) . "-----\n";

print STDERR "--- Kontrola kolize vrstev-----\n";

for ( my $i = scalar(@allComb) - 1 ; $i >= 0 ; $i-- ) {

	my $remove         = 0;
	my @affectedLayers = ();

	# go through each group
	foreach my $pool ( @{ $allComb[$i] } ) {

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

			# 2. RULE Max count of miscrostrip track in one "pool" is 2
			if ( defined $types{ Enums->Layer_TYPETRACK } && $types{ Enums->Layer_TYPETRACK } > 2 ) {

				print STDERR "Removed by max trace cnt\n";
				$remove = 1;
				last;
			}

			# 3. RULE. Only some combination of microstrip are alowed in one track layer
			# if script is here its mean only track layer are in this pool in current layer
			if ( defined $types{ Enums->Layer_TYPETRACK } ) {

				# get all microstrip which contain for current layer, layer type : track
				my @mTypes = map { $_->{"type"} } grep { $_->{"l"}->{$l} eq Enums->Layer_TYPETRACK } @{$pool};

				# Check allowed combination of microstrip which has track in same layer
				if ( scalar(@mTypes) > 2 ) {

					print STDERR "Removed by max trace cnt\n";
					$remove = 1;
					last;

				}
				elsif ( scalar(@mTypes) == 2 ) {

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
		print STDERR "Combination REMOVED: " . join( ' ', map { "(@$_)" } @{ $allComb[$i] } ) . "\n";
		splice @allComb, $i, 1;
	}
	else {
		print STDERR "Combination OK     : " . join( ' ', map { "(@$_)" } @{ $allComb[$i] } ) . "\n";
	}

}

#print STDERR "\n\n--- Pocet kombinaci " . scalar(@allComb) . "-----\n";
#
#foreach my $t (@allComb) {
#
#	print STDERR join( ' ', map { "(@$_)" } @$t ), $/;
#
#}

# sort microstrips by priority
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

	#	my @tTmp = sort { $p{ $consHash{$b}->{"type"}} <=> $p{$consHash{$a}->{"type"}} } @{$allComb[$i]};
	#	$allComb[$i] = \@tTmp;
}

print STDERR "\n\n--- Pocet kombinaci after sort " . scalar(@allComb) . "-----\n";

die;

my $poolCnt = 2;

my $c1 = $allComb[0];

my @coupon = ();    #contain single coupons

# define single coupon until all pool are not processed
while ( scalar( @{$c1} ) ) {

	my @cpnSingle = ();
	my @pools     = ();
	for ( my $i = 0 ; $i < scalar($poolCnt) ; $i++ ) {

		# define pool

		my $p = shift @{$c1};

		unless ( defined $p ) {
			last;
		}

		my @strips = ();
		for ( my $j = 0 ; $j < scalar( @{$p} ) ; $j++ ) {

			my $strpId = @{$p}[$j];
			my $strip  = $consHash{$strpId};

			my %stripInfo = (
							  "id"   => $strpId,
							  "pool" => $i,
							  "col"  => undef
			);

			# consider GND pads of last created pool (pool below this pool if exist)
			if ( defined $pools[ $i - 1 ] ) {

				my $newColumn = undef;
				my @gndLayers = grep { $strip->{"l"}->{$_} eq Enums->Layer_TYPEGND } keys %{ $strip->{"l"} };

				# go through all microstrip in below pool and chcek if is poosible set same position
				# check only microstips from position of last microstrip in current pool
				my $stripsPrevInfo = $pools[ $i - 1 ];
				my $startCol = scalar(@strips) ? $strips[ scalar(@strips) - 1 ]->{"col"} : undef;

				for ( my $k = 0 ; $k < scalar( @{$stripsPrevInfo} ) ; $k++ ) {

					next if ( defined $startCol && $stripsPrevInfo->[$k]->{"col"} <= $startCol );

					my $gndOk      = 1;
					my $stripsPrev = $consHash{ $stripsPrevInfo->[$k]->{"id"} };

					# go through GND layers (max two GND top+bot ref layer)
					for ( my $l = 0 ; $l < scalar(@gndLayers) ; $l++ ) {

						# get layer type of below pool strip in for current layer

						my $prevLType = $stripsPrev->{"l"}->{ $gndLayers[$l] };
						if ( $prevLType ne Enums->Layer_TYPENOAFFECT && $prevLType ne Enums->Layer_TYPEGND ) {

							$gndOk = 0;
							last;
						}
					}

					if ($gndOk) {
						$newColumn = $stripsPrevInfo->[$k]->{"col"};
						last;

					}
				}

				if ( !defined $newColumn ) {
					$newColumn = $pools[ scalar(@pools) - 1 ]->{"col"} + 1;
				}
				$stripInfo{"col"} = $newColumn;

			}
			else {
				$stripInfo{"col"} = $j;
			}

			push( @strips, \%stripInfo );
		}

		push( @pools, \@strips );
	}

	push( @coupon, \@pools );

}

die;

#  my $s = Set::Partition->new(
#    list      => [qw(a b c d e)],
#    partition => [2, 3],
#  );
#
#
#  while (my $p = $s->next) {
#    print join( ' ', map { "(@$_)" } @$p ), $/;
#  }
# produces

#  # or with a hash
#  my $s = Set::Partition->new(
#    list      => { b => 'bat', c => 'cat', d => 'dog' },
#    partition => [2, 1],
#  );
#  while (my $p = $s->next) {
#    ...
#  }

#my $j = Integer::Partition->new( scalar(@ids), { lexicographic => 1 } );
#while ( my $p = $j->next ) {
#	print STDERR join( ' ', @$p ), $/;
#
#	my $s = Set::Partition->new( list      => \@ids,
#								 partition => $p, );
#
#	while ( my $p = $s->next ) {
#		push( @allComb, $p );
#
#		print STDERR join( ' ', map { "(@$_)" } @$p ), $/;
#
#		$cnt++;
#	}
#
#}
