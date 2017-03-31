#-------------------------------------------------------------------------------------------#
# Description: Helper class, contains general function for routing
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamRouting;

#use lib qw(.. C:/Vyvoj/Perl/test);
#use LoadLibrary2;

#3th party library
use strict;
use warnings;

#loading of locale modules

use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamCopperArea';
use aliased 'Packages::Polygon::Features::RouteFeatures::RouteFeatures';

#my $genesis = new Genesis;

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

#Return minimal slot tool for given layer and layer type
# Type EnumsGeneral->LAYERTYPE
sub GetMinSlotTool {

	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $stepName  = shift;
	my $layertype = shift;

	my @layers = CamDrilling->GetNCLayersByType( $inCAM, $jobId, $layertype );

	my $minTool;

	foreach my $layer (@layers) {

		$inCAM->INFO(
					  units       => 'mm',
					  entity_type => 'layer',
					  entity_path => "$jobId/$stepName/" . $layer->{"gROWname"},
					  data_type   => 'TOOL',
					  parameters  => 'drill_size+shape',
					  options     => "break_sr"
		);
		my @toolSize  = @{ $inCAM->{doinfo}{gTOOLdrill_size} };
		my @toolShape = @{ $inCAM->{doinfo}{gTOOLshape} };

		for ( my $i = 0 ; $i < scalar(@toolSize) ; $i++ ) {

			my $t = $toolSize[$i];
			my $s = $toolShape[$i];

			if ( $s eq 'slot' ) {

				if ( !defined $minTool || $t < $minTool ) {
					$minTool = $t;
				}

			}

		}
	}

	return $minTool;
}

#Return minimal slot tool for given layer and layer type
# Type EnumsGeneral->LAYERTYPE
sub GetMinSlotToolByLayers {

	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;
	my @layers   = @{ shift(@_) };

	my $minTool;

	foreach my $layer (@layers) {

		$inCAM->INFO(
					  units       => 'mm',
					  entity_type => 'layer',
					  entity_path => "$jobId/$stepName/" . $layer->{"gROWname"},
					  data_type   => 'TOOL',
					  parameters  => 'drill_size+shape',
					  options     => "break_sr"
		);
		my @toolSize  = @{ $inCAM->{doinfo}{gTOOLdrill_size} };
		my @toolShape = @{ $inCAM->{doinfo}{gTOOLshape} };

		for ( my $i = 0 ; $i < scalar(@toolSize) ; $i++ ) {

			my $t = $toolSize[$i];
			my $s = $toolShape[$i];

			if ( $s eq 'slot' ) {

				if ( !defined $minTool || $t < $minTool ) {
					$minTool = $t;
				}

			}

		}
	}

	return $minTool;
}



# Return hash, where are dimension of panel
sub GetFrDimension {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $stepName  = shift;
 

	my %dim = ( "xSize" => -1, "ySize" => -1 );

	my $route = RouteFeatures->new();

	$route->Parse( $inCAM, $jobId, $stepName, "fr" );

	my @features = $route->GetFeatures();

	if ( scalar(@features) == 4 ) {

		my $maxXlen;
		my $maxYlen;

		foreach my $f (@features) {

			my $lenX = abs( $f->{"x1"} - $f->{"x2"} );
			my $lenY = abs( $f->{"y1"} - $f->{"y2"} );

			if ( !defined $maxXlen || $lenX > $maxXlen ) {

				$maxXlen = $lenX;
			}

			if ( !defined $maxYlen || $lenY > $maxYlen ) {

				$maxYlen = $lenY;
			}

		}

		$dim{"xSize"} = $maxXlen;
		$dim{"ySize"} = $maxYlen;

	}

	return %dim;

}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

#	use aliased 'CamHelpers::CamRouting';
#	use aliased 'Packages::InCAM::InCAM';
#
#	my $inCAM = InCAM->new();
#
#	my $jobId     = "f50251";
#	my $stepName  = "panel";
#	 
#
#	my $minTool = CamRouting->GetMinSlotTool( $inCAM, $jobId, $stepName, "nplt_nMill" );
#	
#	print 1;


}

1;
