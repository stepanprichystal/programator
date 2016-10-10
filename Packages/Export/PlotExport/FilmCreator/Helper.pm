
#-------------------------------------------------------------------------------------------#
# Description: Cover merging, spliting and checking before exporting NC files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::PlotExport::FilmCreator::Helper;

#3th party library
use strict;
use warnings;
use File::Copy;
use Try::Tiny;

#local library
use aliased 'Packages::Polygon::PolygonHelper';
use aliased 'Packages::Export::PlotExport::Enums';
use aliased 'Packages::Polygon::Features::RouteFeatures::RouteFeatures';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# 
sub GetPcbDimensions {
	my $self   = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $smallDim = shift;
	my $bigDim = shift;
 
 
	my $route = RouteFeatures->new();

	$route->Parse( $inCAM, $jobId, "panel", "c" );

	my @features = $route->GetFeatures();

	
	@features =  grep { $_->{"att"}->{".pnl_place"} =~ /pcbf_/i } @features;
	
	my @smallFeatures = grep { $_->{"att"}->{".pnl_place"} !~ /big/ } @features;
	my @bigFeatures = grep { $_->{"att"}->{".pnl_place"} =~ /big/ } @features;
	
	# temporary solution - some not anted lines has atribut pcbf_... and rout flag, filter..
	@bigFeatures = grep { !defined$_->{"att"}->{".rout_flag"} } @bigFeatures;

	my %dim = PolygonHelper->GetDimByRectangle(\@smallFeatures);
 
	$smallDim->{"xSize"} = $dim{"xSize"}; 
	$smallDim->{"ySize"} = $dim{"ySize"}; 
	
	%dim = PolygonHelper->GetDimByRectangle(\@bigFeatures);
 
	$bigDim->{"xSize"} = $dim{"xSize"}; 
	$bigDim->{"ySize"} = $dim{"ySize"}; 

	return 1;
}


sub AddLayerPlotSize {
	my $self = shift;
	my $plotSize = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $layers = shift;
 
 	my %smallDim = ();
	my %bigDim = ();
	
	$self->GetPcbDimensions($inCAM, $jobId, \%smallDim, \%bigDim);
	 
	my %dim;

	if($plotSize eq Enums->Size_PROFILE){
		
		%dim = %smallDim;
		
	}elsif($plotSize eq Enums->Size_FRAME){
		
		%dim = %bigDim;
		
	}

	foreach my $l ( @{ $layers } ) {

		$l->{"pcbSize"}->{"xSize"} =  $dim{"xSize"};
		$l->{"pcbSize"}->{"ySize"} =  $dim{"ySize"};

	}

}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#print $test;

}

1;

