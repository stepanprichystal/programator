#-------------------------------------------------------------------------------------------#
# Description: Function for checking small drills in rout
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Drilling::MoveDrillHoles;

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

# Function move small NPTH hole from NPTH to PTH layer
# Max size of moved hole is given by $maxHoleSize
# Only hole without attribute pilotholes and withour tolerances +/- in DTM will be moved
# Note:
# - function do not work with S&R
sub MoveSmallNpth2Pth {
	my $self                = shift;
	my $inCAM               = shift;
	my $jobId               = shift;
	my $step                = shift;
	my $npltLayer           = shift;            # source nptl layer
	my $pltLayer            = shift;            # dest plt layer
	my $maxHoleSize         = shift // 1000;    # holes larger than this diamater will not be moved [µm]
	my $movedHoleCntRef     = shift;            # ref var for storing number of moved holes
	my $movedHoleAttrValRef = shift;            # ref var for storing .string attribute which moved hole get

	my $result = 0;

	# Check if layer is nplt
	my %npltInf = CamDrilling->GetNCLayerInfo( $inCAM, $jobId, $npltLayer, 1 );
	die "Layer $npltLayer must be non plated" if ( $npltInf{"plated"} );

	# check is layer is plt
	my %pltInf = CamDrilling->GetNCLayerInfo( $inCAM, $jobId, $pltLayer, 1 );
	die "Layer $pltLayer must be plated" if ( !$pltInf{"plated"} );

	my $movedHoleAttrVal = "moved_small_npth_hole";    # .string attr value which contain moved holes

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

			CamHelper->SetStep( $inCAM, $step );

			my $f = Features->new();
			$f->Parse( $inCAM, $jobId, $step, $npltLayer, 0 );

			# filter tools by d-code
			my @allF = grep { $_->{"type"} eq "P" } $f->GetFeatures();
			my @features = ();

			foreach my $uniDTmTool (@tools) {
				push( @features, grep { $_->{"dcode"} == $uniDTmTool->GetToolNum() } @allF );
			}

			# Filter non pilot hole
			@features = grep { !defined $_->{"att"}->{".pilot_hole"} } @features;

			if (@features) {

				# Load counts of all diameters in layers  $npltLayer + $pltLayer
				# This info will be used as check after move holes do detect missing holes
				my $featCntOri =
				  { CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $npltLayer, 0 ) }->{"total"} +
				  { CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $pltLayer,  0 ) }->{"total"};

				my %histNPltOri = %{ { CamHistogram->GetSymHistogram( $inCAM, $jobId, $step, $npltLayer, 0, 1 ) }->{"pads"} };
				my %histPltOri  = %{ { CamHistogram->GetSymHistogram( $inCAM, $jobId, $step, $pltLayer,  0, 1 ) }->{"pads"} };
				my %histTotOri  = ();

				foreach my $k ( uniq( ( keys %histNPltOri, keys %histPltOri ) ) ) {
					$histTotOri{$k} = 0 if ( !exists $histTotOri{$k} );
					$histTotOri{$k} += $histNPltOri{$k} if ( $histNPltOri{$k} );
					$histTotOri{$k} += $histPltOri{$k}  if ( $histPltOri{$k} );
				}

				# move holes
				my $lMove = "move_npth_holes";
				CamMatrix->DeleteLayer( $inCAM, $jobId, $lMove );
				CamMatrix->CreateLayer( $inCAM, $jobId, $lMove, "document", "positive", 0 );

				my $f = FeatureFilter->new( $inCAM, $jobId, $npltLayer );
				$f->AddFeatureIndexes( [ map { $_->{"id"} } @features ] );

				if ( $f->Select() ) {

					CamLayer->MoveSelOtherLayer( $inCAM, $lMove );
					CamLayer->WorkLayer( $inCAM, $lMove );
					CamAttributes->SetFeatuesAttribute( $inCAM, ".string", $movedHoleAttrVal );

					$inCAM->COM( "merge_layers", "source_layer" => $lMove, "dest_layer" => $pltLayer );

					CamLayer->ClearLayers( $inCAM, $jobId );

					# Do check layers integrity after move holes if some are missing
					my $featCntCur =
					  { CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $npltLayer, 0 ) }->{"total"} +
					  { CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $pltLayer,  0 ) }->{"total"};

					my %histNPltCur = %{ { CamHistogram->GetSymHistogram( $inCAM, $jobId, $step, $npltLayer, 0, 1 ) }->{"pads"} };
					my %histPltCur  = %{ { CamHistogram->GetSymHistogram( $inCAM, $jobId, $step, $pltLayer,  0, 1 ) }->{"pads"} };
					my %histTotCur  = ();
					foreach my $k ( uniq( ( keys %histNPltOri, keys %histPltOri ) ) ) {
						$histTotCur{$k} = 0 if ( !exists $histTotCur{$k} );
						$histTotCur{$k} += $histNPltCur{$k} if ( $histNPltCur{$k} );
						$histTotCur{$k} += $histPltCur{$k}  if ( $histPltCur{$k} );
					}

					my $errMess = "";

					# 1) Check on all holes
					foreach my $toolDim ( keys %histTotOri ) {

						if ( $histTotOri{$toolDim} != $histTotCur{$toolDim} ) {
							$errMess .=
							    "Error during move holes d=$toolDim from: $npltLayer to: $pltLayer layer. "
							  . "Total number of holes in both layers before moving: "
							  . $histTotOri{$toolDim}
							  . " after moving: "
							  . $histTotCur{$toolDim} . "\n";
						}
					}

					# 2) Check on all type features count
					if ( $featCntOri != $featCntCur ) {
						$errMess .=
						    "Error during move holes from: $npltLayer to: $pltLayer layer. "
						  . "Total feature number both layers before moving: $featCntOri  after moving: $featCntCur \n";
					}

					die $errMess if ( $errMess ne "" );

					$$movedHoleCntRef     = scalar(@features) if ( defined $movedHoleCntRef );
					$$movedHoleAttrValRef = $movedHoleAttrVal if ( defined $movedHoleAttrValRef );
					$result               = 1;
				}

				# Delete layer with moved holes only if script not die
				CamMatrix->DeleteLayer( $inCAM, $jobId, $lMove );
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

	use aliased 'Packages::CAMJob::Drilling::MoveDrillHoles';
	use aliased 'Packages::CAMJob::Drilling::NPltDrillCheck';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM     = InCAM->new();
	my $jobId     = "d269744";
	my $step      = "o+1";
	my $npltLayer = "f";
	my $pltLayer  = "m";
	my $maxTool   = 1000;

	my $checkRes = {};
	unless ( NPltDrillCheck->SmallNPltHoleCheck( $inCAM, $jobId, $step, $npltLayer, $pltLayer, $maxTool, $checkRes ) ) {

		print STDERR "Small holes in $npltLayer\n";

		foreach my $padFeat ( @{ $checkRes->{"padFeatures"} } ) {

			print STDERR $padFeat . "\n";
		}

		foreach my $padT ( @{ $checkRes->{"padTools"} } ) {

			print STDERR $padT . "\n";
		}

		my $movedHoleCntRef     = -1;
		my $movedHoleAttrValRef = -1;
		my $res =
		  MoveDrillHoles->MoveSmallNpth2Pth( $inCAM, $jobId, $step, $npltLayer, $pltLayer, $maxTool, \$movedHoleCntRef, \$movedHoleAttrValRef );

		if ($res) {

			print "moved holes : $movedHoleCntRef ";

			CamLayer->WorkLayer( $inCAM, $pltLayer );
			my $f = FeatureFilter->new( $inCAM, $jobId, $pltLayer );
			$f->AddIncludeAtt( ".string", $movedHoleAttrValRef );
			$f->Select();
		}

	}

}

1;
