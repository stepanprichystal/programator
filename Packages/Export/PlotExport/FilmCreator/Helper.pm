
#-------------------------------------------------------------------------------------------#
# Description: Cover merging, spliting and checking before exporting NC files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::PlotExport::FilmCreator::Helper;

#3th party library
use strict;
use warnings;



#local library
use aliased 'Packages::Polygon::PolygonHelper';
use aliased 'Packages::Export::PlotExport::Enums';
use aliased 'Packages::Polygon::Features::RouteFeatures::RouteFeatures';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub GetPcbLimits {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $smallLim = shift;
	my $bigLim   = shift;

	my $route = RouteFeatures->new();

	$route->Parse( $inCAM, $jobId, "panel", "c" );

	my @features = $route->GetFeatures();

	@features = grep { $_->{"att"}->{".pnl_place"} =~ /pcbf_/i } @features;

	my @smallFeatures = grep { $_->{"att"}->{".pnl_place"} !~ /big/ } @features;
	my @bigFeatures = grep { $_->{"att"}->{".pnl_place"} =~ /big/ } @features;

	# temporary solution - some not anted lines has atribut pcbf_... and rout flag, filter..
	@bigFeatures = grep { !defined $_->{"att"}->{".rout_flag"} } @bigFeatures;

	my %lim = PolygonHelper->GetLimByRectangle( \@smallFeatures );

	%{$smallLim} = %lim;

	my %lim2 = PolygonHelper->GetLimByRectangle( \@bigFeatures );

	%{$bigLim} = %lim2;

	return 1;
}

sub AddLayerPlotSize {
	my $self     = shift;
	my $plotSize = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $layers   = shift;

	my %smallDim = ();
	my %bigDim   = ();

	my %smallLim = ();
	my %bigLim   = ();

	# Get limits of pcb
	$self->GetPcbLimits( $inCAM, $jobId, \%smallLim, \%bigLim );

	#$self->GetPcbDimensions($inCAM, $jobId, \%smallLim, \%bigLim, \%smallDim, \%bigDim);

	foreach my $l ( @{$layers} ) {

		if ( $plotSize eq Enums->Size_PROFILE ) {

			$l->{"pcbSize"}->{"xSize"} = abs( $smallLim{"xMax"} - $smallLim{"xMin"} );
			$l->{"pcbSize"}->{"ySize"} = abs( $smallLim{"yMax"} - $smallLim{"yMin"} );

			$l->{"pcbLimits"} = \%smallLim;

		}
		elsif ( $plotSize eq Enums->Size_FRAME ) {

			$l->{"pcbSize"}->{"xSize"} = abs( $bigLim{"xMax"} - $bigLim{"xMin"} );
			$l->{"pcbSize"}->{"ySize"} = abs( $bigLim{"yMax"} - $bigLim{"yMin"} );

			$l->{"pcbLimits"} = \%bigLim;
		}

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

