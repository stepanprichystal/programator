#-------------------------------------------------------------------------------------------#
# Description: Checks for via fill layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::ViaFilling::ViaFillingCheck;

#3th party library
use utf8;
use strict;
use warnings;
use List::Util qw[max min first];
use Data::Dump qw(dump);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamFilter';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAM::FeatureFilter::Enums' => 'FilterEnums';

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
			$$errMess .=
			    "Layer: \"$NCL\", Viafill hole to TOP panel edge distance is:"
			  . sprintf($curTDist)
			  . "mm. Min allowed distance is: $minDistT" . "mm.\n";
		}
	}

	return $result;
}

# Check if holes in plated drill layers are not in collision
# Checks the layers that are included in themselves from matrix start/stop point of view
sub CheckDrillHoleCollision {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $errMess = shift;    # reference on err mess

	my $result = 1;

	my @NClayers = CamJob->GetLayerByType( $inCAM, $jobId, "drill" );
	CamDrilling->AddNCLayerType( \@NClayers );
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@NClayers );
	@NClayers = grep { $_->{"plated"} && !$_->{"technical"} } @NClayers;

	my %NC = ();

	# Match included drill layer from job matrix point of view
	# Included means,
	# - start layer of tested drill layer has heigher index than examines layer
	# - end layer of tested drill layer has lower index than examines layer

	for ( my $i = 0 ; $i < scalar(@NClayers) ; $i++ ) {

		$NC{ $NClayers[$i]{"gROWname"} } = [];

		my $sIdx = $NClayers[$i]{"gROWdrl_dir"} eq "bot2top" ? $NClayers[$i]{"NCSigEndOrder"}   : $NClayers[$i]{"NCSigStartOrder"};
		my $eIdx = $NClayers[$i]{"gROWdrl_dir"} eq "bot2top" ? $NClayers[$i]{"NCSigStartOrder"} : $NClayers[$i]{"NCSigEndOrder"};

		for ( my $j = 0 ; $j < scalar(@NClayers) ; $j++ ) {

			next if ( $i == $j );

			my $sIdxIncl = $NClayers[$j]{"gROWdrl_dir"} eq "bot2top" ? $NClayers[$j]{"NCSigEndOrder"} : $NClayers[$j]{"NCSigStartOrder"};
			my $eIdxIncl =
			  $NClayers[$j]{"gROWdrl_dir"} eq "bot2top" ? $NClayers[$j]{"NCSigStartOrder"} : $NClayers[$j]{"NCSigEndOrder"};

			if ( $sIdx <= $sIdxIncl && $eIdx >= $eIdxIncl ) {

				my $incldued = 0;
				if (
					defined $NC{ $NClayers[$j]{"gROWname"} } && defined first { $_ eq $NClayers[$i]{"gROWname"} }
					@{ $NC{ $NClayers[$j]{"gROWname"} } }
				  )
				{
					$incldued = 1;
				}

				push( @{ $NC{ $NClayers[$i]{"gROWname"} } }, $NClayers[$j]{"gROWname"} ) unless ($incldued);
			}
		}
	}

	#print STDERR dump( \%NC );

	if ( grep { scalar( @{ $NC{$_} } ) > 0 } keys %NC ) {

		CamHelper->SetStep( $inCAM, $step );

		foreach my $lName ( keys %NC ) {

			next unless ( scalar( @{ $NC{$lName} } ) );

			my $f = FeatureFilter->new( $inCAM, $jobId, undef, $NC{$lName} );

			# 1) select all pads covered by negative features
			$f->SetRefLayer($lName);
			$f->SetReferenceMode( FilterEnums->RefMode_TOUCH );
			if ( $f->Select() ) {

				$$errMess .= "Holes in layer(s): " . join( ";", @{ $NC{$lName} } ) . " are in collision with holes in layer: $lName\n";
				$result = 0;
			}

			CamLayer->ClearLayers($inCAM);
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
	my $jobId = "d250516";

	my $mess = "";

	my $result = ViaFillingCheck->CheckDrillHoleCollision( $inCAM, $jobId, "o+1", \$mess );

	print "Result: $result, mess: $mess";
}

1;
