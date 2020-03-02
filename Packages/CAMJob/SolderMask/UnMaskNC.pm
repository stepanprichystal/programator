#-------------------------------------------------------------------------------------------#
# Description:
# Author:RVI
#-------------------------------------------------------------------------------------------#

package Packages::CAMJob::SolderMask::UnMaskNC;

use strict;
use warnings;

use aliased 'Packages::CAMJob::SolderMask::ClearenceCheck';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamFilter';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAM::FeatureFilter::Enums' => "FiltrEnums";
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamHistogram';
#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#
#
# If uncover solder mask on the rout path missing, then will be copy.
sub UnMaskNpltRout {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $stepId     = shift;
	my @layers     = qw (f r rs score);
	my @maskLayers = ();

	CamLayer->ClearLayers($inCAM);

	$inCAM->COM( 'set_step', name => $stepId );

	my @res = ();

	my $result = ClearenceCheck->RoutClearenceCheck( $inCAM, $jobId, $stepId, \@layers, \@res );

	unless ($result) {

		foreach my $s (@res) {

			my $lnew = CamLayer->RoutCompensation( $inCAM, $s->{"layer"}, 'document' );

			my $resize = 200;
			if ( $s->{"layer"} eq 'score' ) {
				$resize = -200;
			}

			CamLayer->WorkLayer( $inCAM, $lnew );
			CamLayer->CopySelOtherLayer( $inCAM, [ $s->{"mask"} ], 0, $resize );

			CamLayer->ClearLayers($inCAM);

			$inCAM->COM( "delete_layer", "layer" => $lnew );
		}
	}
}

# Unmask through hole near BGA
sub UnMaskThroughHoleNearBGA {
	my $self             = shift;
	my $inCAM            = shift;
	my $jobId            = shift;
	my $step             = shift;
	my $resize           = shift // -50;    # -50µm resize drill holes copied to solder mask
	my $minDistHole2Pad  = shift // 500;
	my $unMaskedCntRef   = shift;
	my $unMaskAttrValRef = shift;

	my $result = 1;

	my @sigLayers = ("c");
	push( @sigLayers, "s" ) if ( CamHelper->LayerExists( $inCAM, $jobId, "s" ) );

	my @NC = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nDrill );
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@NC );
	@NC = map { $_->{"gROWname"} } grep { $_->{"NCSigStartOrder"} == 1 } @NC;

	if ( !scalar(@sigLayers) || !scalar(@NC) ) {
		$result = 0;
		return $result;
	}

	my $unMaskAttrVal = "unmask_through_hole_bga";

	my $unMasked;

	$result = $self->__UnMaskThroughHoleNearPads( $inCAM, $jobId, $step, ".bga", \@sigLayers, $unMaskAttrVal, $resize, $minDistHole2Pad, \$unMasked );

	$$unMaskedCntRef   = $unMasked      if ( defined $unMaskedCntRef );
	$$unMaskAttrValRef = $unMaskAttrVal if ( defined $unMaskAttrValRef );

	return $result;

}

# UnMask through hole near SMD
sub UnMaskThroughHoleNearSMD {
	my $self             = shift;
	my $inCAM            = shift;
	my $jobId            = shift;
	my $step             = shift;
	my $resize           = shift // -50;    # -50µm resize drill holes copied to solder mask
	my $minDistHole2Pad  = shift // 500;
	my $unMaskedCntRef   = shift;
	my $unMaskAttrValRef = shift;

	my $result    = 1;
	my @sigLayers = ("c");
	push( @sigLayers, "s" ) if ( CamHelper->LayerExists( $inCAM, $jobId, "s" ) );

	my @NC = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nDrill );
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@NC );
	@NC = map { $_->{"gROWname"} } grep { $_->{"NCSigStartOrder"} == 1 } @NC;

	if ( !scalar(@sigLayers) || !scalar(@NC) ) {
		$result = 0;
		return $result;
	}

	my $unMaskAttrVal = "unmask_through_hole_smd";

	my $unMasked;

	$result = $self->__UnMaskThroughHoleNearPads( $inCAM, $jobId, $step, ".smd", \@sigLayers, $unMaskAttrVal, $resize, $minDistHole2Pad, \$unMasked );

	$$unMaskedCntRef   = $unMasked      if ( defined $unMaskedCntRef );
	$$unMaskAttrValRef = $unMaskAttrVal if ( defined $unMaskAttrValRef );

	return $result;

}

sub __UnMaskThroughHoleNearPads {
	my $self            = shift;
	my $inCAM           = shift;
	my $jobId           = shift;
	my $step            = shift;
	my $padAttr         = shift;
	my $padLayers       = shift;
	my $unMaskAttrVal   = shift;
	my $resize          = shift;
	my $minDistHole2Pad = shift;
	my $unMaskedCnt     = shift;

	die "Unmask size is not defiend"              unless ( defined $resize );
	die "Pad attribute is not defined"            unless ( defined $padAttr );
	die "Unmask feature attribute is not defined" unless ( defined $unMaskAttrVal );

	my $result = 1;

	my @NC = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nDrill );
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@NC );
	@NC = map { $_->{"gROWname"} } grep { $_->{"NCSigStartOrder"} == 1 } @NC;

	my @sm = map { $_->{"gROWname"} } grep { $_->{"gROWlayer_type"} eq "solder_mask" } CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	die "No NC layers exist"          if ( !scalar(@NC) );
	die "No solder mask layers exist" if ( !scalar(@sm) );

	CamHelper->SetStep( $inCAM, $step );

	# 1) Check if unmask features alread exist and delete it

	my $f = FeatureFilter->new( $inCAM, $jobId, undef, \@sm );

	$f->SetFeatureTypes( "pad" => 1 );    # select only pad umnask
	$f->SetPolarity( FiltrEnums->Polarity_POSITIVE );    # select only positive unmask
	$f->AddIncludeAtt( ".string", $unMaskAttrVal );

	if ( $f->Select() ) {

		$inCAM->COM('sel_delete');
		CamLayer->ClearLayers($inCAM);
	}

	# 2) Add umask
	my $lNCTmp      = GeneralHelper->GetGUID();
	my $lResizedSMD = GeneralHelper->GetGUID();

	foreach my $nc (@NC) {

		$inCAM->COM( "merge_layers", "source_layer" => $nc, "dest_layer" => $lNCTmp );
	}

	CamLayer->AffectLayers( $inCAM, $padLayers );

	if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, $padAttr ) ) {

		CamLayer->CopySelOtherLayer( $inCAM, [$lResizedSMD], 0, 2 * $minDistHole2Pad );

		my $f2 = FeatureFilter->new( $inCAM, $jobId, $lNCTmp );

		$f2->SetRefLayer($lResizedSMD);

		$f2->SetReferenceMode( FiltrEnums->RefMode_TOUCH );

		$$unMaskedCnt = $f2->Select();

		if ($$unMaskedCnt) {
			$inCAM->COM('sel_reverse');

			$inCAM->COM('get_select_count');
			if ( $inCAM->GetReply() > 0 ) {
				CamLayer->DeleteFeatures($inCAM);
			}

			CamAttributes->DelAllFeatuesAttribute($inCAM);
			CamAttributes->SetFeatuesAttribute( $inCAM, ".string", $unMaskAttrVal );
			CamLayer->CopySelOtherLayer( $inCAM, \@sm, 0, $resize );

			CamLayer->ClearLayers($inCAM);

			# Final check
			my $total = 0;
			foreach my $smL (@sm) {

				my %attHist = CamHistogram->GetAttCountHistogram( $inCAM, $jobId, $step, $smL, 0 );
				$total += $attHist{".string"}->{$unMaskAttrVal};
			}

			die "Error during copy negative feature to solder masks" if ( $total != (scalar(@sm) * $$unMaskedCnt) );

		}
		else {

			$result = 0;
		}
	}
	else {

		$result = 0;
	}

	CamMatrix->DeleteLayer( $inCAM, $jobId, $lNCTmp );
	CamMatrix->DeleteLayer( $inCAM, $jobId, $lResizedSMD );

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::SolderMask::UnMaskNC';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId    = "d272564";
	my $stepName = "o+1";

	my $res = UnMaskNC->UnmaskThroughHole( $inCAM, $jobId, "o+1" );

	die;

}

1;
