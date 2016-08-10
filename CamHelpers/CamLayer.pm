#-------------------------------------------------------------------------------------------#
# Description: Helper class, contains general function working with InCAM layer
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamLayer;

#3th party library
use strict;
use warnings;

#loading of locale modules

use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamCopperArea';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

#Return hash, kyes are "top"/"bot", values are 0/1
sub ExistSolderMasks {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my %masks = HegMethods->GetSolderMaskColor($jobId);

	unless ( defined $masks{"top"} ) {
		$masks{"top"} = 0;
	}
	else {
		$masks{"top"} = 1;
	}
	unless ( defined $masks{"bot"} ) {
		$masks{"bot"} = 0;
	}
	else {
		$masks{"bot"} = 1;
	}
	return %masks;
}

#Return hash, kyes are "top"/"bot", values are 0/1
sub ExistSilkScreens {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my %silk = HegMethods->GetSilkScreenColor($jobId);

	unless ( defined $silk{"top"} ) {
		$silk{"top"} = 0;
	}
	else {
		$silk{"top"} = 1;
	}

	unless ( defined $silk{"bot"} ) {
		$silk{"bot"} = 0;
	}
	else {
		$silk{"bot"} = 1;
	}
	return %silk;
}

# flattern layer
# create tem flattern layer, delete original layer and place flatern data to original layer
sub FlatternLayer {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $stepName  = shift;
	my $layerName = shift;

	my $tmpLayer = GeneralHelper->GetGUID();

	$inCAM->COM( 'flatten_layer', "source_layer" => $layerName, "target_layer" => $tmpLayer );
	$inCAM->COM(
				 'copy_layer',
				 "source_job"   => $jobId,
				 "source_step"  => $stepName,
				 "source_layer" => $tmpLayer,
				 "dest"         => 'layer_name',
				 "dest_layer"   => $layerName,
				 "mode"         => 'replace',
				 "invert"       => 'no'
	);

	$inCAM->COM( 'delete_layer', "layer" => $tmpLayer );
}

1;
