#-------------------------------------------------------------------------------------------#
# Description: Function for checking aspect ratio
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Drilling::AspectRatioCheck;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::CAM::UniDTM::UniDTM';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#
# For each layer of layer type, return tools with computed "aspectratio"
sub GetToolsARatio {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $step        = shift;
	my $breakSr     = shift;
	my $ncLayerType = shift;

	my @toolAR = ();

	unless ($breakSr) {
		$breakSr = 0;
	}

	my $pcbThick;
	my $stackup = undef;

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	if ( $layerCnt > 2 ) {

		$stackup = Stackup->new($jobId);

		$pcbThick = $stackup->GetFinalThick();
	}
	else {

		$pcbThick = HegMethods->GetPcbMaterialThick($jobId);
		$pcbThick = $pcbThick * 1000;
	}

	my @layers = CamDrilling->GetNCLayersByType( $inCAM, $jobId, $ncLayerType );
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@layers );

	foreach my $l (@layers) {

		unless ( CamHelper->LayerExists( $inCAM, $jobId, $l->{"gROWname"} ) ) {
			next;
		}

		my $dtm = UniDTM->new( $inCAM, $jobId, $step, $l->{"gROWname"}, $breakSr );
		my @tools = $dtm->GetUniqueTools();

		foreach my $t (@tools) {

			# if tool has do depth, we have to get thickness of whole pcb, actual press, core etc,..
			if ( $t->GetDepth() == 0 ) {

				my $thickReal = undef;

				if ( $layerCnt > 2 ) {

					$thickReal = $stackup->GetThickByLayerName( $l->{"gROWdrl_start_name"} ) * 1000;
				}
				else {

					$thickReal = $pcbThick;
				}

				$t->{"aspectRatio"} = $thickReal / $t->GetDrillSize();

			}
			else {

				$t->{"aspectRatio"} = ( $t->GetDepth() * 1000 ) / $t->GetDrillSize();
			}

		}

		my %inf = ( "layer" => $l->{"gROWname"}, "tools" => \@tools );
		push( @toolAR, \%inf );
	}

	return @toolAR;
}

# return tools info, which has wrong aspect ratio
# Consider all layer, which are plated and tools of layers are on pcb (not technical frame)
# Returned value is hash, key: "min1.0", "min0.1"
# Each kay contain array of layers, where is stored info about layer name and tools with wrong AR
sub CheckWrongARAllLayers {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $wrongAr = shift;

	my $result = 1;

	$wrongAr->{"max10.0"} = [];
	$wrongAr->{"max1.0"}  = [];

	my @toolAR = ();

	my @types = ( EnumsGeneral->LAYERTYPE_plt_nDrill, EnumsGeneral->LAYERTYPE_plt_cDrill );

	foreach my $t (@types) {

		foreach my $l ( $self->GetToolsARatio( $inCAM, $jobId, $step, 1, $t ) ) {
			my @tools = grep { $_->{"aspectRatio"} > 10 } @{ $l->{"tools"} };

			if (@tools) {
				my %inf = ( "layer" => $l->{"layer"}, "tools" => \@tools );
				push( @{ $wrongAr->{"max10.0"} }, \%inf );
				$result = 0;
			}

		}
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::Drilling::AspectRatioCheck';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d152457";
	my $step  = "o+1";

	my %res = ();
	my $r = AspectRatioCheck->CheckWrongARAllLayers( $inCAM, $jobId, $step, \%res );

	print $r;

}

1;
