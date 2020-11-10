#-------------------------------------------------------------------------------------------#
# Description: Function for checking small drills in rout
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Drilling::NPltDrillCheck;

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAM::UniDTM::Enums' => "DTMEnums";
use aliased 'Enums::EnumsDrill';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAM::FeatureFilter::Enums' => 'FilterEnums';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Check if exis NPTH holes with small tool diameter
# These holes should be moved to plt layer
# Return:
# -  1 if no hole for moving
# -  0 if there are holes for moving
# Note:
# - function do not work with S&R
# - function consider all types of npth layer:
# 	- EnumsGeneral->LAYERTYPE_nplt_nMill
# 	- EnumsGeneral->LAYERTYPE_nplt_nDrill
# - holes for moving can't have set tolerances + cant have set atribute pilot hole
sub SmallNPltHoleCheck {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $step        = shift;
	my $npltLayer   = shift;            # target plt layer
	my $pltLayer    = shift // "m";     # target plt layer
	my $maxHoleSize = shift // 1000;    # holes larger than this should be moved to plt layer
	my $resultData  = shift // {};

	my $result = 1;

	if ( CamHelper->LayerExists( $inCAM, $jobId, $pltLayer ) ) {

		my $uniDTM = UniDTM->new( $inCAM, $jobId, $step, $npltLayer, 0, 0, 0 );

		# Note.: Don't $uniDTM->GetUniqueTools() when use GetTolPlus/GetTolMinus function
		# More tools with same diameter may have different tolerances
		my @tools =
		  grep {
			     $_->GetSource() eq DTMEnums->Source_DTM
			  && $_->GetTypeProcess() eq EnumsDrill->TypeProc_HOLE
			  && $_->GetTolPlus() == 0
			  && $_->GetTolMinus() == 0
			  && $_->GetDrillSize() <= $maxHoleSize
		  } $uniDTM->GetTools();

		if ( scalar(@tools) ) {

			my $f = Features->new();
			$f->Parse( $inCAM, $jobId, $step, $npltLayer, 0 );

			# filter tools by d-code
			my @allF = grep { $_->{"type"} eq "P" }  $f->GetFeatures();
			my @features = ();

			foreach my $uniDTmTool (@tools) {
				push( @features, grep { $_->{"dcode"} == $uniDTmTool->GetToolNum() } @allF );
			}

			# Filter non pilot hole
			@features = grep { !defined $_->{"att"}->{".pilot_hole"} } @features;

			if ( scalar(@features) ) {

				$result = 0;

				$resultData->{"padFeatures"} = [ map { $_->{"id"} } @features ];    # pad to move features
				$resultData->{"padTools"} = [ uniq( map { $_->{"thick"} } @features ) ];    # pad tools
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

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d237874";
	my $step  = "o+1";

}

1;
