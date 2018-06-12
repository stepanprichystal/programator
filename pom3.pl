#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

use XML::LibXML;
use Integer::Partition;
use Set::Partition;
use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Packages::Coupon::Enums';

my @layers = ( "L1", "L2", "L3", "L4" );

my @constraints = ();

my %se1 = (
			"id"   => Enums->Type_SE . "1",
			"type" => Enums->Type_SE,
			"l"    => {
					 "L1" => Enums->Layer_TYPENOAFFECT,
					 "L2" => Enums->Layer_TYPEGND,
					 "L3" => Enums->Layer_TYPEEXTRA,
					 "L4" => Enums->Layer_TYPETRACK
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
					   "L1" => Enums->Layer_TYPETRACK,
					   "L2" => Enums->Layer_TYPEGND,
					   "L3" => Enums->Layer_TYPENOAFFECT,
					   "L4" => Enums->Layer_TYPENOAFFECT
			  }
);

my %consHash = ();
$consHash{ $se1{"id"} }   = \%se1;
$consHash{ $se2{"id"} }   = \%se2;
$consHash{ $diff1{"id"} } = \%diff1;
$consHash{ $diff2{"id"} } = \%diff2;

my @ids = keys %consHash;

my $cnt = 1;

my @allComb = ();

my $j = Integer::Partition->new( scalar(@ids), { lexicographic => 1 } );
while ( my $p = $j->next ) {
	print join( ' ', @$p ), $/;

	my $s = Set::Partition->new( list      => \@ids,
								 partition => $p, );

	while ( my $p = $s->next ) {
		push( @allComb, $p );

		#print join( ' ', map { "(@$_)" } @$p ), $/;

		$cnt++;
	}

}

# Name notation
# Coupon:

# |=============================Coupon=============================|
# | ________________________ Coupon single 2 ______________________|
# | Pool 2 - track pad + tracks                                    |
# | ...... - gnd pads .............................................|
# | Pool 1 - track pad + tracks                                    |
# | ________________________ Coupon single 2 ______________________|
# | Pool 2 - track pad + tracks                                    |
# | ...... - gnd pads .............................................|
# | Pool 1 - track pad + tracks                                    |
# |================================================================|

print STDERR "\n\n--- Pocet kombinaci " . scalar(@allComb) . "-----\n";

print STDERR "--- Kontrola kolize vrstev-----\n";

for ( my $i = scalar(@allComb) - 1 ; $i >= 0 ; $i-- ) {

	my $remove         = 0;
	my @affectedLayers = ();

	# go through each group
	foreach my $pool ( @{ $allComb[$i] } ) {

		my @p = map { $consHash{$_} } @{$pool};

		foreach my $l (@layers) {
			my %h              = ();
			my $lTypestByGroup = 0;

			my %types = ();
			$types{$_}++ foreach ( grep { $_ ne Enums->Layer_TYPENOAFFECT } map { $_->{"l"}->{$l} } @p );

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
				my @mTypes = map { $_->{"type"} } grep { $_->{"l"}->{$l} eq Enums->Layer_TYPETRACK } @p;

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
					$rules{ Enums->Type_SE . Enums->Type_COSE }   = 1;
					$rules{ Enums->Type_SE . Enums->Type_CODIFF } = 0;

					# diff
					$rules{ Enums->Type_DIFF . Enums->Type_SE }     = 1;
					$rules{ Enums->Type_DIFF . Enums->Type_DIFF }   = 0;
					$rules{ Enums->Type_DIFF . Enums->Type_COSE }   = 1;
					$rules{ Enums->Type_DIFF . Enums->Type_CODIFF } = 0;

					# cose
					$rules{ Enums->Type_COSE . Enums->Type_SE }     = 1;
					$rules{ Enums->Type_COSE . Enums->Type_DIFF }   = 1;
					$rules{ Enums->Type_COSE . Enums->Type_COSE }   = 0;
					$rules{ Enums->Type_COSE . Enums->Type_CODIFF } = 0;

					# codiff
					$rules{ Enums->Type_CODIFF . Enums->Type_SE }     = 0;
					$rules{ Enums->Type_CODIFF . Enums->Type_DIFF }   = 0;
					$rules{ Enums->Type_CODIFF . Enums->Type_COSE }   = 0;
					$rules{ Enums->Type_CODIFF . Enums->Type_CODIFF } = 0;

					unless ( $rules{ $mTypes[0] . $mTypes[1] } ) {
						print STDERR "Removed by not alowed microstrim cob (" . $rules{ $mTypes[0] . $mTypes[1] } . ") in one pool\n";
						$remove = 1;
						last;
					}
				}

				my $mTypes = map { $_->{"type"} } @p;
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

print STDERR "\n\n--- Pocet kombinaci " . scalar(@allComb) . "-----\n";

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
