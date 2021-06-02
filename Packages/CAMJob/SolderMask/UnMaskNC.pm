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




# If uncover solder mask on the rout path missing, then will be copy.
sub UnMaskNpltRout {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $stepId     = shift;
	my @layers     = qw (f r rs score);
	my @maskLayers = ();

	CamLayer->ClearLayers($inCAM);

	CamHelper->SetStep($inCAM, $stepId );

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
our $unMaskBGAAttrVal = "unmask_through_hole_bga";  # make var accesible out of package
sub UnMaskThroughHoleNearBGA {
	my $self             = shift;
	my $inCAM            = shift;
	my $jobId            = shift;
	my $step             = shift;
	my $resize           = shift // -50;    # -50µm resize drill holes copied to solder mask
	my $minDistHole2Pad  = shift // 2000;
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
 
	my $unMasked;

	$result = $self->__UnMaskThroughHoleNearPads( $inCAM, $jobId, $step, ".bga", \@sigLayers, $unMaskBGAAttrVal, $resize, $minDistHole2Pad, \$unMasked );

	$$unMaskedCntRef   = $unMasked      if ( defined $unMaskedCntRef );
	$$unMaskAttrValRef = $unMaskBGAAttrVal if ( defined $unMaskAttrValRef );

	return $result;

}

# UnMask through hole near SMD
our $unMaskSMDAttrVal = "unmask_through_hole_smd"; # make var accesible out of package
sub UnMaskThroughHoleNearSMD {
	my $self             = shift;
	my $inCAM            = shift;
	my $jobId            = shift;
	my $step             = shift;
	my $resize           = shift // -50;    # -50µm resize drill holes copied to solder mask
	my $minDistHole2Pad  = shift // 2000;
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
 
	my $unMasked;

	$result = $self->__UnMaskThroughHoleNearPads( $inCAM, $jobId, $step, ".smd", \@sigLayers, $unMaskSMDAttrVal, $resize, $minDistHole2Pad, \$unMasked );

	$$unMaskedCntRef   = $unMasked      if ( defined $unMaskedCntRef );
	$$unMaskAttrValRef = $unMaskSMDAttrVal if ( defined $unMaskAttrValRef );

	return $result;

}

sub __UnMaskThroughHoleNearPads {
	my $self            = shift;
	my $inCAM           = shift;
	my $jobId           = shift;
	my $step            = shift;
	my $padAttr         = shift;
	my $padLayers       = shift;
	my $unMaskAttrVal   = shift;    # value of .string attribute which unmasked pads will have
	my $resize          = shift;
	my $minDistHole2Pad = shift;
	my $unMaskedCnt     = shift;

	die "Unmask size is not defiend"              unless ( defined $resize );
	die "Pad attribute is not defined"            unless ( defined $padAttr );
	die "Unmask feature attribute is not defined" unless ( defined $unMaskAttrVal );

	my $result = 1;

	# Restricted area from gold connector
	my $goldConDist = 3000;

	my @NC = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nDrill );
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@NC );
	@NC = map { $_->{"gROWname"} } grep { $_->{"NCSigStartOrder"} == 1 } @NC;

	my @sm =
	  map { $_->{"gROWname"} }
	  grep { $_->{"gROWlayer_type"} eq "solder_mask" && $_->{"gROWname"} !~ /flex/ } CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	die "No NC layers exist"          if ( !scalar(@NC) );
	die "No solder mask layers exist" if ( !scalar(@sm) );

	CamHelper->SetStep( $inCAM, $step );

	my $lNCTmp = GeneralHelper->GetGUID();

	foreach my $nc (@NC) {

		$inCAM->COM( "merge_layers", "source_layer" => $nc, "dest_layer" => $lNCTmp );
	}

	# 1) Check if unmask features alread exist and delete it

	my $f = FeatureFilter->new( $inCAM, $jobId, undef, \@sm );
	$f->SetRefLayer($lNCTmp);
	$f->SetReferenceMode( FiltrEnums->RefMode_COVER );
	$f->SetFeatureTypes( "pad" => 1 );    # select only pad umnask
	$f->SetPolarity( FiltrEnums->Polarity_POSITIVE );    # select only positive unmask
	$f->AddIncludeAtt( ".string", $unMaskAttrVal );

	if ( $f->Select() ) {

		$inCAM->COM('sel_delete');
		CamLayer->ClearLayers($inCAM);
	}

	# 2) Add umask
	my $lResizedSMD = GeneralHelper->GetGUID();

	CamLayer->AffectLayers( $inCAM, $padLayers );

	if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, $padAttr ) ) {

		CamLayer->CopySelOtherLayer( $inCAM, [$lResizedSMD], 0, 2 * $minDistHole2Pad );

		# Consider gold connector. Copy negative of resized gold connector
		my $goldConnAttr = ".gold_plating";
		CamLayer->AffectLayers( $inCAM, $padLayers );
		if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, $goldConnAttr ) ) {
			
			CamLayer->CopySelOtherLayer( $inCAM, [$lResizedSMD], 1, 2 * $goldConDist );
			CamLayer->Contourize($inCAM, $lResizedSMD);
		}

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

			#			Check was removed, because after optimization features which touch unmask pads with attr $unMaskAttrVal
			# 			inehrit atribut $unMaskAttrVal

			#			# Final check
			#			my $total = 0;
			#			foreach my $smL (@sm) {
			#
			#				my %attHist = CamHistogram->GetAttCountHistogram( $inCAM, $jobId, $step, $smL, 0 );
			#				$total += $attHist{".string"}->{$unMaskAttrVal};
			#			}
			#
			#			die "Error during copy negative feature to solder masks" if ( $total != ( scalar(@sm) * $$unMaskedCnt ) );

		}
		else {

			$result = 0;
		}
	}
	else {

		$result = 0;
	}

	CamLayer->ClearLayers($inCAM);

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

	my $jobId    = "d301316";
	my $stepName = "o+1";

	my $res = UnMaskNC->UnMaskThroughHoleNearSMD( $inCAM, $jobId, "o+1" );

	die;

}

1;
