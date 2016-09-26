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


1;
