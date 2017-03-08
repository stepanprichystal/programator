#-------------------------------------------------------------------------------------------#
# Description: Do checks of tool in Universal DTM
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniRTM::UniRTM::Parser::RoutParser;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Routing::RoutLayer::RoutParser::RoutParser';
use aliased 'Packages::Polygon::Features::RouteFeatures::RouteFeatures';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

# Check if tools parameters are ok
# When some errors occure here, proper NC export is not possible
sub GetFeatures {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $layer   = shift;
	my $breakSR = shift;

	my $parser = RouteFeatures->new();
	$parser->Parse( $inCAM, $jobId, $step, $layer, $breakSR );

	# 1) Get all rout features
	my @features = $parser->GetFeatures();
	
	# 2) Filter pads
	@features = grep{ $_->{"type"} !~ /p/i } @features;
	
	# 3) If some features doesn't have att .rout_chain die
	
	my @wrongFeatures = grep{ !defined $_->{"att"}->{".rout_chain"} || !$_->{"att"}->{".rout_chain"} } @features;
	if(@wrongFeatures){
		
		@wrongFeatures = map { $_->{"id"} } @wrongFeatures;
		my $str = join("; ", @wrongFeatures );
		
		die "Layer: \"$layer\", step: \"$step\" contain features without attribute \".rout_chain\". Features ids: \"$str\".\n";
		
	}
	
	foreach my $f (@features){
		RoutParser->AddGeometricAtt( $f );
	}
 
	return @features;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13608";

	my $f = FeatureFilter->new( $inCAM, "m" );

	$f->SetPolarity("positive");

	my @types = ( "surface", "pad" );
	$f->SetTypes( \@types );

	my @syms = ( "r500", "r1" );
	$f->AddIncludeSymbols( \[ "r500", "r1" ] );

	print $f->Select();

	print "fff";

}

1;

