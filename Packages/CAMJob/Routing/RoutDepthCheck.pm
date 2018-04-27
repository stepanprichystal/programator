#-------------------------------------------------------------------------------------------#
# Description: Function for checking layers with rout depth
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Routing::RoutDepthCheck;

#3th party library
use utf8;
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
use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Check chains in depth milling if Chains with same tool diameter are merged
sub CheckDepthChainMerge {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $errMess = shift;    # reference on err mess

	my $result = 1;

	my @steps = ("o+1");

	if ( CamHelper->StepExists( $inCAM, $jobId, "panel" ) ) {

		@steps = map { $_->{"stepName"} } CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, "panel" );
	}

	my @types = (
				  EnumsGeneral->LAYERTYPE_nplt_bMillTop, EnumsGeneral->LAYERTYPE_nplt_bMillBot,
				  EnumsGeneral->LAYERTYPE_plt_bMillTop,  EnumsGeneral->LAYERTYPE_plt_bMillBot
	);

	foreach my $step (@steps) {

		foreach my $l ( CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, \@types ) ) {

			my $rtm = UniRTM->new( $inCAM, $jobId, $step, $l->{"gROWname"} );
			my @chList = $rtm->GetChainList();

			my %tools = ();

			for ( my $i = 0 ; $i < scalar(@chList) ; $i++ ) {

				$tools{ $chList[$i]->GetChainSize() } = [ $chList[$i] ];

				for ( my $j = 0 ; $j < scalar(@chList) ; $j++ ) {

					next if ( $j == $i );

					if ( $chList[$j]->GetChainSize() == $chList[$i]->GetChainSize() ) {

						push( @{ $tools{ $chList[$i]->GetChainSize() } }, $chList[$j] );
					}
				}
			}

			my $strErr = "";

			foreach my $t ( keys %tools ) {

				if ( scalar( @{ $tools{$t} } ) > 1 ) {

					$strErr .=
					    "More \"Chains\" ("
					  . join( ";", map { $_->GetChainOrder() } @{ $tools{$t} } )
					  . ") have same tool diameter: "
					  . $tools{$t}->[0]->GetChainSize() . "mm\n";

				}
			}

			if ($strErr) {
				$result = 0;
				$$errMess .= "Step: $step, layer:".$l->{"gROWname"}. " - $strErr";
			}
		}
	}

	unless($result){
		$$errMess .= "\nIf it is possible merge these \"Chains\" into one.\n";
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::Routing::RoutDepthCheck';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d152456";
	my $step  = "o+1";

	my $mess = "";
	my $res = RoutDepthCheck->CheckDepthChainMerge( $inCAM, $jobId, \$mess  );

	print "$res - $mess";

}

1;
