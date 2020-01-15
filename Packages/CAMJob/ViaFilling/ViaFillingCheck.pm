#-------------------------------------------------------------------------------------------#
# Description: Checks for via fill layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::ViaFilling::ViaFillingCheck;

#3th party library
use utf8;
use strict;
use warnings;
use List::Util qw[max min];

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'CamHelpers::CamDrilling';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#
# Check minimal alowed distance of via holes from panel edge
sub CheckViaFillPnlEdgeDist {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $errMess = shift;    # reference on err mess

	my $step = "panel";

	# Distances are given by viafill machine limitations
	my $minDistLR = 20;     # 20 mm
	my $minDistT  = 25;     # 25 mm

	my $result = 1;

	my %stepLim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );

	my @ncLayers = CamDrilling->GetNCLayersByTypes(
													$inCAM, $jobId,
													[
													   EnumsGeneral->LAYERTYPE_plt_nFillDrill, EnumsGeneral->LAYERTYPE_plt_bFillDrillTop,
													   EnumsGeneral->LAYERTYPE_plt_bFillDrillBot
													]
	);

	my $f = Features->new();

	foreach my $NCL ( map { $_->{"gROWname"} } @ncLayers ) {

		$f->Parse( $inCAM, $jobId, $step, $NCL, 1 );

		my @features = grep { $_->{"step"} ne "coupon_drill" } $f->GetFeatures();

		my %NCLim = ();
		$NCLim{"xMin"} = min( map { $_->{"x1"} } @features );
		$NCLim{"xMax"} = max( map { $_->{"x1"} } @features );
		$NCLim{"yMin"} = min( map { $_->{"y1"} } @features );
		$NCLim{"yMax"} = max( map { $_->{"y1"} } @features );

		my $curLDist = ( $NCLim{"xMin"} - $stepLim{"xMin"} );
		if ( $curLDist < $minDistLR ) {

			$result = 0;
			$$errMess .=
			    "Layer: \"$NCL\", Via-fill hole to LEFT panel edge distance is:"
			  . sprintf( "%.2f", $curLDist )
			  . "mm. Min allowed distance is: $minDistLR" . "mm.\n";
		}

		my $curRDist = ( $stepLim{"xMax"} - $NCLim{"xMax"} );
		if ( $curRDist < $minDistLR ) {

			$result = 0;
			$$errMess .=
			    "Layer: \"$NCL\", Via-fill hole to RIGHT panel edge distance is:"
			  . sprintf($curRDist)
			  . "mm. Min allowed distance is: $minDistLR" . "mm.\n";
		}

		my $curTDist = ( $stepLim{"yMax"} - $NCLim{"yMax"} );
		if ( $curTDist < $minDistT ) {

			$result = 0;
			$$errMess .= "Layer: \"$NCL\", Viafill hole to TOP panel edge distance is:" . sprintf($curTDist)
			  . "mm. Min allowed distance is: $minDistT" . "mm.\n";
		}
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use Data::Dump qw(dump);

	use aliased 'Packages::CAMJob::ViaFilling::ViaFillingCheck';
	use aliased 'CamHelpers::CamDrilling';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d267352";

	my $mess = "";

	my $result = ViaFillingCheck->CheckViaFillPnlEdgeDist( $inCAM, $jobId, \$mess );

	print $mess;
}

1;
