#-------------------------------------------------------------------------------------------#
# Description: Package contain helper method for working with list of chains
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RouteList;

 

#3th party library
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#


#return list of chain with attributes
sub GetFeatures {

	my $self      = shift;
	my $fFeatures = shift;

	open( INFOFILE, $fFeatures );

	my @chains = ();

	while ( my $l = <INFOFILE> ) {

		my %routInfo;

		unless ( $l =~ /^#(\d*)/ ) { next; }

		if ( $l =~ /rout_chain/ ) {

			if ( $l =~ m/r(\d*)/ ) {
				$routInfo{"size"} = $1 / 1000;
			}

			if ( $l =~ m/.rout_tool=([0-9]*\.?[0-9]*)/ ) {
				$routInfo{"size"} = $1 * 25.4;
			}

			$l =~ m/.*;(.*)/;

			my @attr = split( ",", $1 );


			$routInfo{".rout_type"} = "";
			$routInfo{".foot_down"} = 0;
				
			foreach my $at (@attr) {

				my @attValue = split( "=", $at );
				$routInfo{ $attValue[0] } = $attValue[1];

				if ( $attValue[0] eq ".foot_down" ) {
					$routInfo{ $attValue[0] } = 1;
				}
			}

			unless ( grep { $routInfo{".rout_chain"} eq $_->{".rout_chain"} } @chains ) {
				push( @chains, \%routInfo );
			}
		}
	}
	return @chains;
}

#return count of chains with left comp
sub GetNumberOfLeftComp {
	my $self   = shift;
	my @chains = @{ shift(@_) };

	my $cnt = scalar( grep { $_->{".comp"} eq "left" && $_->{".rout_type"} ne "pocket" } @chains );

	return $cnt;
}

#return .routechain abbtribut of chains with left comp, whose .routechain is smaller
# than .routechain number of any NONleft chain
sub GetLeftChainNotLast {

	my $self   = shift;
	my @chains = @{ shift(@_) };

	my @chainIds = ();

	my @leftCh = grep { $_->{".comp"} eq "left" && $_->{".rout_type"} ne "pocket" } @chains;
	my @nonLeftCh = grep { $_->{".comp"} ne "left" } @chains;

	for ( my $i = 0 ; $i < scalar(@leftCh) ; $i++ ) {

		for ( my $j = 0 ; $j < scalar(@nonLeftCh) ; $j++ ) {

			if ( $leftCh[$i]{".rout_chain"} < $nonLeftCh[$j]{".rout_chain"} ) {
				push( @chainIds, $leftCh[$i]{".rout_chain"} );
				last;
			}

		}

	}

	return @chainIds;
}


#return .routechain abbtribut of chains with NONleft comp, that has .foot_down
sub GetNONLeftChainWithFoot {

	my $self   = shift;
	my @chains = @{ shift(@_) };

	my @nonLeftCh = grep { $_->{".comp"} ne "left" } @chains;

	my @footCh = grep { $_->{".foot_down"} == 1 } @nonLeftCh;
	
	return @footCh;
}


sub GetLargestChainId {

	my $self      = shift;
	my $fFeatures = shift;

	my @chains = RouteListHelper->GetChainList($fFeatures);

	my $max  = 0;
	my $idx  = -1;
	my $dist = 0;

	for ( my $i = 0 ; $i < scalar(@chains) ; $i++ ) {

		if ( $chains[$i]{".rout_chain"} > $max ) {

			$max = $chains[$i]{".rout_chain"};
		}
	}
	return $max;
}

sub SplitByChainNum {
	my $self     = shift;
	my @features = @{ shift(@_) };

	my %splitChains;

	#get all chain number
	my @chainNum = ();

	foreach my $f (@features) {

		push( @chainNum, $f->{"att"}{".rout_chain"} );
	}

	my %seen;

	@chainNum = grep { !$seen{$_}++ } @chainNum;

	foreach my $chNum (@chainNum) {
		my @chain = ();

		foreach my $f (@features) {

			if ( $f->{"att"}{".rout_chain"} == $chNum ) {

				push( @chain, $f );
			}

		}

		$splitChains{$chNum} = \@chain;

	}

	return %splitChains;

}
 

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

if (0) {

	#print "start";
	#my %errors    = ( "errors" => undef, "warrings" => undef );
	#my $fFeatures = "o2.txt";
	#my @features  = RouteListHelper->GetFeatures($fFeatures);

	#my $cnt = RouteListHelper->GetNumberOfLeftComp( \@features );
	#my $cnt = RouteListHelper->GetLeftChainNotLast( \@features );
	#my $cnt = RouteListHelper->GetNONLeftChainWithFoot( \@features );

	#print 1;

}

1;

