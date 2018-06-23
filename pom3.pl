#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

use XML::LibXML;
use Integer::Partition;
use Set::Partition;
use Algorithm::Combinatorics qw(partitions);
use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Packages::Coupon::Enums';

my @group = ( "m1", "m2", "m3", "m4", "m5");

my $cnt = 1;

my @allComb = ();

#my $j = Integer::Partition->new( 2, { lexicographic => 1 } );
#while ( my $p = $j->next ) {
#	print join( ' ', @$p ), $/;
#
#}

my $maxPoolCnt = 2;

#for(my $i= 1;  $i <= $maxPoolCnt; $i++){

#my @allComb = partitions( \@ids );

my @poolComb = ();

# define paratitions (dividing strip measurement into "pools" by "n" items)
my @partitions = ();

push( @partitions, scalar(@group) );    # max pool count = 1pool per 1 group

if ( $maxPoolCnt == 2 ) {
	push( @partitions, ( 1 .. int( scalar(@group) / 2 ) ) );
}

foreach my $partSize (@partitions) {

	my $s = Set::Partition->new( list      => \@group,
								 partition => [$partSize], );

	while ( my $p = $s->next ) {
		push( @poolComb, $p );

		print join( ' ', map { "(@$_)" } @$p ), $/;

	}
}

#}
