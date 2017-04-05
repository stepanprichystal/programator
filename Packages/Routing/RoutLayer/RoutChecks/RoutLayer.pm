#-------------------------------------------------------------------------------------------#
# Description: Helper class contain controls for rout layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::RoutChecks::RoutLayer;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Packages::Polygon::Features::RouteFeatures::RouteFeatures';

 

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#
 # Check if tool sizes are sorted ASC
sub RoutChainAttOk {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;
	my $mess  = shift;
	
	my $result = 1;

	 my $route = RouteFeatures->new();
 
	$route->Parse( $inCAM, $jobId, $step, $layer );
	
	my @features = $route->GetFeatures();
	
	# filter out pads
	@features = grep { $_->{"type"} !~ /p/i} @features;
	
	my @chainMiss = grep { !defined $_->{"att"}->{".rout_chain"} } @features;
	
	if(scalar(@chainMiss)){
		$result = 0;
		
		@chainMiss = map {"\"".$_->{"id"}."\"" } @chainMiss;
		
		my $str = join(";", @chainMiss);
		
		$$mess .= "Step:  \"$step\", some features (id numbers: $str) doesn't contain rout in layer: \"$layer\".";  
	}
	
	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

