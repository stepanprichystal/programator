#-------------------------------------------------------------------------------------------#
# Description: Clearance check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::SolderMask::ClearenceCheck;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamStepRepeat';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#
# Return 1/0 if rout clearence is ok or not
# Min clearance is 80µm
# Rout rs and r are checked behind profile too
sub RoutClearenceCheck {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $step        = shift;
	my $layerFilter = shift;    # array layers
	my $result      = shift;    # array of results hash: name => layer name, mask => "top/bot"

	my $srExist = CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $step );

	my @layers = CamJob->GetLayerByType( $inCAM, $jobId, "rout" );
	CamDrilling->AddNCLayerType( \@layers );

	# Choose only requested layers
	my %tmp;
	@tmp{ @{$layerFilter} } = ();
	@layers = grep { exists $tmp{ $_->{"gROWname"} } } @layers;

	CamDrilling->AddNCLayerType( \@layers );

	foreach my $l (@layers) {

		if ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop || $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop ) {

			if ( !$self->__IsClearanceOk( $inCAM, $jobId, $step, $l, "top", $srExist ) ) {

				my %inf = ( "layer" => $l->{"gROWname"}, "mask" => "mc" );
				push( @{$result}, \%inf );
			}

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot || $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot ) {

			if ( !$self->__IsClearanceOk( $inCAM, $jobId, $step, $l, "bot", $srExist ) ) {

				my %inf = ( "layer" => $l->{"gROWname"}, "mask" => "ms" );
				push( @{$result}, \%inf );
			}

		}
		elsif (    $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nMill
				|| $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nMill
				|| $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_rsMill
				|| $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_kMill
				|| $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_score )
		{

			# check clearance form top and bot too
			if ( !$self->__IsClearanceOk( $inCAM, $jobId, $step, $l, "top", $srExist ) ) {

				my %inf = ( "layer" => $l->{"gROWname"}, "mask" => "mc" );
				push( @{$result}, \%inf );
			}

			if ( !$self->__IsClearanceOk( $inCAM, $jobId, $step, $l, "bot", $srExist ) ) {

				my %inf = ( "layer" => $l->{"gROWname"}, "mask" => "ms" );
				push( @{$result}, \%inf );
			}
		}
	}

	if ( scalar( @{$result} ) ) {
		return 0;
	}
	else {
		return 1;
	}

}

sub __IsClearanceOk {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $l       = shift;
	my $side    = shift;
	my $srExist = shift;

	my $result = 1;

	my $maskLayer = $side eq "top" ? "mc" : "ms";

	if ( CamHelper->LayerExists( $inCAM, $jobId, $maskLayer ) ) {

		my $minComp = 75;    #min clearence of mask

		my $lTmp = undef;

		# flatten if SR exist
		if ($srExist) {

			my $tmpLayer = GeneralHelper->GetGUID();
			$inCAM->COM( 'flatten_layer', "source_layer" => $l->{"gROWname"}, "target_layer" => $tmpLayer );
			$lTmp = CamLayer->RoutCompensation( $inCAM, $tmpLayer, "document" );
			$inCAM->COM( 'delete_layer', layer => $tmpLayer );

		}
		else {

			$lTmp = CamLayer->RoutCompensation( $inCAM, $l->{"gROWname"}, "document" );
		}

		# clip around profile, because behind profile clearance is not necesary
		if (    $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nMill
			 || $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_kMill )
		{
			CamLayer->ClipAreaByProf( $inCAM, $lTmp, 0 );
		}

		# flatten if SR exist

		if ($srExist) {
			my $tmpLayer = GeneralHelper->GetGUID();
			$inCAM->COM( 'flatten_layer', "source_layer" => $maskLayer, "target_layer" => $tmpLayer );
			$maskLayer = $tmpLayer;
		}

		CamLayer->WorkLayer( $inCAM, $maskLayer );

		# copy mask to rout
		if ( CamFilter->SelectByReferenece( $inCAM, $jobId, "touch", $maskLayer, undef, undef, undef, $lTmp ) ) {

			$inCAM->COM(
						 "sel_copy_other",
						 "dest"         => "layer_name",
						 "target_layer" => $lTmp,
						 "invert"       => "yes",
						 "size"         => -$minComp
			);

			CamLayer->Contourize( $inCAM, $lTmp );

		}

		my %fHist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $lTmp );

		if ( $fHist{"total"} > 0 ) {

			$result = 0;
		}

		CamLayer->WorkLayer( $inCAM, $lTmp );

		$inCAM->COM( 'delete_layer', layer => $lTmp );
		if ($srExist) {
			$inCAM->COM( 'delete_layer', layer => $maskLayer );

		}

	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::SolderMask::ClearenceCheck';
	use Data::Dump qw(dump);
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52457";

	my $mess = "";

	my @res = ();

	my $result = ClearenceCheck->RoutClearenceCheck( $inCAM, $jobId, "o+1", ["score"], \@res );

	print STDERR "Result is $result \n";

	dump(@res);

}

1;
