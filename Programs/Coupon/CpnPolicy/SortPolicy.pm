
#-------------------------------------------------------------------------------------------#
# Description: Sort coupons, by amount of microstrip in group
# The more microstrips in a small place, the better
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnPolicy::SortPolicy;

#3th party library
use strict;
use warnings;

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

	 
	return $self;
}
 

sub SortVariants {
	my $self = shift;
	my @variants = @{ shift(@_) };

	my @sortedGroups = ();

	# 1. Group variants by number of single coupon in each cou[pon]

	my $curSinglCnt = 1;

	while (@variants) {

		my @vGroup = ();

		for ( my $i = scalar(@variants) - 1 ; $i >= 0 ; $i-- ) {

			if ( $variants[$i]->GetSingleCpnsCnt() == $curSinglCnt ) {

				my $v = splice @variants, $i, 1;
				push( @vGroup, $v );
			}
		}

		if (@vGroup) {
			push( @sortedGroups, \@vGroup );
		}

		$curSinglCnt++;
	}

	# 2. If same count of single coupon in goup, sort by max number of column in pools
	for ( my $i = 0 ; $i < scalar(@sortedGroups) ; $i++ ) {

		if ( scalar( @{ $sortedGroups[$i] } ) > 1 ) {

			my @sorted = sort { $a->GetColumnCnt() <=> $b->GetColumnCnt() } @{ $sortedGroups[$i] };
			$sortedGroups[$i] = \@sorted;

		}
	}

	my @sorted = map { @{$_} } @sortedGroups;

	return @sorted;
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

