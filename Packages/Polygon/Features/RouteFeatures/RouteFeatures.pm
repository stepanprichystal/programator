
#-------------------------------------------------------------------------------------------#
# Description: Class can parse incam layer fetures for route.
# This is decorator of base Features.pm
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Polygon::Features::RouteFeatures::RouteFeatures;

use Class::Interface;

&implements('Packages::Polygon::Features::IFeatures');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Packages::Polygon::Features::RouteFeatures::RouteItem';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	#instance of  "base" class Features.pm
	$self->{"base"} = Features->new();

	my @features = ();
	$self->{"features"} = \@features;

	return $self;
}

#parse features layer
sub Parse {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;

	$self->{"base"}->Parse( $inCAM, $jobId, $step, $layer );

	my @baseFeats = $self->{"base"}->GetFeatures();
	my @features  = ();

	# add route extra info

	foreach my $f (@baseFeats) {

		my $newF = RouteItem->new($f);

		push( @features, $newF );
	}

	$self->{"features"} = \@features;

}

# Return fatures for route layer
sub GetFeatures {
	my $self = shift;

	return @{ $self->{"features"} };
}

# Return array of unique route chain hashes
# Each info contain at least:
# "tool_size" = tool size
# ".route_chain" = number of chain (unique)
sub GetChains {
	my $self = shift;

	my @chains = ();

	foreach my $f ( @{ $self->{"features"} } ) {

		my %attr = %{ $f->{"att"} };

		# if features contain attribute rout chain
		if ( $attr{".rout_chain"} && $attr{".rout_chain"} > 0 ) {

			# test, if chain with given routchain not exist exist, add it
			unless ( scalar( grep { $_->{".rout_chain"} eq $attr{".rout_chain"} } @chains ) ) {

				my %chainInfo = ();
				
				%chainInfo = %attr; # add all attributes from feature
				$chainInfo{".tool_size"} = $f->{"thick"}; # add ifnp about rout tool size

				push( @chains, \%chainInfo );
			}

		}

	}
	return @chains;
}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Polygon::Features::RouteFeatures::RouteFeatures';
	use aliased 'Packages::InCAM::InCAM';

	my $route = RouteFeatures->new();

	my $jobId = "f49180";
	my $inCAM = InCAM->new();

	my $step  = "panel";
	my $layer = "fr";

	$route->Parse( $inCAM, $jobId, $step, $layer );

	my @features = $route->GetFeatures();
	my @chains = $route->GetChains();
	
	my $maxXlen;
	my $maxYlen;
	
	foreach my $f (@features){
		
		my $lenX = abs($f->{"x1"} -  $f->{"x2"});
		my $lenY = abs($f->{"y1"} -  $f->{"y2"});
		
		if(!defined $maxXlen || $lenX >  $maxXlen){
			
			$maxXlen = $lenX;
		}
		
		 if(!defined $maxYlen || $lenY >  $maxYlen){
			
			$maxYlen = $lenY;
		}
		
	}
	
	print $maxXlen."\n";
	print $maxYlen."\n";
	

	 
}

1;

