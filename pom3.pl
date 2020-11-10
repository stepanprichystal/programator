
use List::MoreUtils qw(uniq);

my %a = ( 1 => 200, 2 => 250 );
my %b = ( 1 => 200, 3 => 500 );

my %t = ();
 
foreach my $k (uniq( ( keys %a, keys %b ) )) {
	$t{$k} = 0 if ( !exists $t{$k} );
	$t{$k} += $a{$k} if ( $a{$k} );
	$t{$k} += $b{$k} if ( $b{$k} );
}

print %t;
