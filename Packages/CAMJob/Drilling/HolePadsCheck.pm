#-------------------------------------------------------------------------------------------#
# Description: Function for checking pad in signal layer of holes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Drilling::HolePadsCheck;

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
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamMatrix';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAM::FeatureFilter::Enums' => 'FilterEnums';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Return array of holes which have missing pads
# Not work with SR
sub GetMissingPads {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $step        = shift;
	my $ncLayerType = shift;

	my %wrongPads = ();

	CamHelper->SetStep( $inCAM, $step );

	my $pcbThick = JobHelper->GetFinalPcbThick($jobId);

	#my %h = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $layers[$i] );

	my @layers = CamDrilling->GetNCLayersByType( $inCAM, $jobId, $ncLayerType );
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@layers );

	foreach my $l (@layers) {

		unless ( CamHelper->LayerExists( $inCAM, $jobId, $l->{"gROWname"} ) ) {
			next;
		}

		my $lName = $l->{"gROWname"};

		$wrongPads{$lName} = [];

		my @start = $self->__MissingPadsExsit( $inCAM, $jobId, $step, $l->{"NCSigStart"}, $l->{"gROWname"} );    # start
		my @end   = $self->__MissingPadsExsit( $inCAM, $jobId, $step, $l->{"NCSigEnd"}, $l->{"gROWname"} );    # end

		my @feats = ();

		# Create hash for each feat info
		my %seen;
		foreach my $f ( my @unique = grep { !$seen{ $_->{"id"} }++ } ( @start, @end ) ) {

			push( @{ $wrongPads{$lName} }, { "featId" => $f->{"id"}, "missing" => [] } );
		}

		foreach my $fInfo ( @{ $wrongPads{$lName} } ) {

			if ( grep { $_->{"id"} eq $fInfo->{"featId"} } @start ) {
				push( @{ $fInfo->{"missing"} }, $l->{"NCSigStart"} );
			}

			if ( grep { $_->{"id"} eq $fInfo->{"featId"} } @end ) {
				push( @{ $fInfo->{"missing"} }, $l->{"NCSigEnd"} );
			}
		}
	}

	return %wrongPads;
}

# Return array of holes which have missing pads
# All plated layers (only blind and core drilling)
sub CheckMissingPadsAllLayers {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $step        = shift;
	my $missingPads = shift;

	my $result = 1;

	my @types = ( EnumsGeneral->LAYERTYPE_plt_bDrillTop, EnumsGeneral->LAYERTYPE_plt_bDrillBot, EnumsGeneral->LAYERTYPE_plt_cDrill );

	foreach my $t (@types) {

		%{$missingPads} = ( %{$missingPads}, $self->GetMissingPads( $inCAM, $jobId, $step, $t ) );
	}

	foreach my $lName ( keys %{$missingPads} ) {

		if ( @{ $missingPads->{$lName} } ) {
			$result = 0;
			last;
		}
	}

	return $result;
}

sub __MissingPadsExsit {
	my $self              = shift;
	my $inCAM             = shift;
	my $jobId             = shift;
	my $step              = shift;
	my $sigLayer          = shift;
	my $ncLayer           = shift;

	my @holeFeats = ();

	CamLayer->WorkLayer( $inCAM, $ncLayer );
 
	if ( CamMatrix->GetLayerPolarity($inCAM, $jobId, $sigLayer) eq "positive" ) {

		CamFilter->SelectByReferenece( $inCAM, $jobId, "multi_cover", $ncLayer, undef, undef, undef, $sigLayer );

	}
	else {

		my $f = FeatureFilter->new( $inCAM, $jobId, $ncLayer );

		# 1) select all pads covered by negative features
		$f->SetRefLayer($sigLayer);
		$f->SetPolarityRef( FilterEnums->Polarity_NEGATIVE );
		$f->SetReferenceMode( FilterEnums->RefMode_MULTICOVER );
		$f->Select();
		
		# 2) select all pads which are not touched with positive features
		$f->SetRefLayer($sigLayer);
		$f->SetPolarityRef( FilterEnums->Polarity_POSITIVE );
		$f->SetReferenceMode( FilterEnums->RefMode_DISJOINT );
		$f->Select();
 
	}
	
	$inCAM->COM('sel_reverse');

	$inCAM->COM('get_select_count');

	if ( $inCAM->GetReply() > 0 ) {

		my $f = Features->new();

		$f->Parse( $inCAM, $jobId, $step, $ncLayer, 0, 1 );

		@holeFeats = $f->GetFeatures();
	}

	return @holeFeats;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::Drilling::HolePadsCheck';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d237874";
	my $step  = "o+1";

	my @childs = CamStepRepeatPnl->GetUniqueDeepestSR( $inCAM, $jobId);

	my %allLayers = ();

	foreach my $step (@childs) {

		my $mess = "";

		my %pads = ();
		unless ( HolePadsCheck->CheckMissingPadsAllLayers( $inCAM, $jobId, $step->{"stepName"}, \%pads ) ) {

			foreach my $l ( keys %pads ) {

				if ( @{ $pads{$l} } ) {

					$mess .= "\nMissing pads for drilling in layer: \"$l\", holes:";

					my @pads =
					  map { "\n- Pad id: \"" . $_->{"featId"} . "\", missing pads in signal layers: \"" . join( ", ", @{ $_->{"missing"} } ) . "\"" }
					  @{ $pads{$l} };

					$mess .= join( "", @pads );
				}
			}

			print $mess;
		}
	}

	print "ddd";

}

1;
