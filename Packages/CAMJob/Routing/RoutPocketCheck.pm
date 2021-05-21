#-------------------------------------------------------------------------------------------#
# Description: Function for checking rout pocket
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Routing::RoutPocketCheck;

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::Polygon::Features::Features::Features';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Check if rout pocket dierction is routed from inside to outside
sub RoutPocketCheckDir {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $step        = shift;
	my $ncLayerType = shift;
	my $breakSR     = shift;
	my $errInfo     = shift;    # arraz ref, where info about wrong layer/surfs will be stored

	my $result = 1;

	my @layers = CamDrilling->GetNCLayersByType( $inCAM, $jobId, $ncLayerType );
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@layers );

	CamHelper->SetStep( $inCAM, $step ) if ( scalar(@layers) );

	foreach my $l (@layers) {

		my $lName = $l->{"gROWname"};
		my $dir   = $l->{"gROWdrl_dir"};

		my %fHist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $l->{"gROWname"} );

		if ( $fHist{"surf"} ) {

			my $f = Features->new();

			$f->Parse( $inCAM, $jobId, $step, $l->{"gROWname"}, $breakSR );

			my @surfs = $f->GetFeatures();

			my $rightDir = "standard";
			my $wrongDir = "opposite";

			if ( $dir eq "bot2top" ) {

				$rightDir = "opposite";
				$wrongDir = "standard";
			}

			my @wrongDir =
			  grep { defined $_->{"att"}->{".rout_pocket_direction"} && $_->{"att"}->{".rout_pocket_direction"} eq $wrongDir } @surfs;

			if ( scalar(@wrongDir) ) {

				$result = 0;

				my %inf = ( "layer" => $lName, "rightDir" => $rightDir, "wrongDir" => $wrongDir, "surfaces" => \@wrongDir );
				push( @{$errInfo}, \%inf );
			}

		}
	}

	return $result;
}

# Check if rout pocket dierction is routed from inside to outside
# Check all zaxis routing from top/bot
sub RoutPocketCheckDirAllLayers {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $breakSR = shift;
	my $errInfo = shift;    # arraz ref, where info about wrong layer/surfs will be stored

	my $result = 1;

	my @types = (
		EnumsGeneral->LAYERTYPE_plt_bMillTop,
		EnumsGeneral->LAYERTYPE_plt_bMillBot,
		EnumsGeneral->LAYERTYPE_nplt_bMillTop,
		EnumsGeneral->LAYERTYPE_nplt_bMillBot,
		EnumsGeneral->LAYERTYPE_nplt_lcMill,
		EnumsGeneral->LAYERTYPE_nplt_lsMill,
		EnumsGeneral->LAYERTYPE_nplt_cbMillTop,
		EnumsGeneral->LAYERTYPE_nplt_cbMillBot,
		EnumsGeneral->LAYERTYPE_nplt_cvrlycMill,
		EnumsGeneral->LAYERTYPE_nplt_cvrlysMill,
		EnumsGeneral->LAYERTYPE_nplt_prepregMill,
		EnumsGeneral->LAYERTYPE_nplt_stiffcMill,
		EnumsGeneral->LAYERTYPE_nplt_stiffsMill,
		EnumsGeneral->LAYERTYPE_nplt_bstiffcMill,
		EnumsGeneral->LAYERTYPE_nplt_bstiffsMill,
		EnumsGeneral->LAYERTYPE_nplt_soldcMill,
		EnumsGeneral->LAYERTYPE_nplt_soldsMill
	);

	foreach my $t (@types) {

		unless ( $self->RoutPocketCheckDir( $inCAM, $jobId, $step, $t, $breakSR, $errInfo ) ) {

			$result = 0;
		}
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::Routing::RoutPocketCheck';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d152456";
	my $step  = "o+1";

	my @pole = ();
	my $res = RoutPocketCheck->RoutPocketCheckDirAllLayers( $inCAM, $jobId, $step, 1, \@pole );

	print "ddd";

}

1;
