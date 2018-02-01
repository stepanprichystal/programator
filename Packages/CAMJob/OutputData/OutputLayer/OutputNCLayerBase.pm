
#-------------------------------------------------------------------------------------------#
# Description: Prepare NC layers to finla output
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::OutputLayer::OutputNCLayerBase;

#3th party library
use strict;
use warnings;
use List::Util qw[max min];
use Math::Trig;

#local library
use aliased 'Helpers::GeneralHelper';

#use aliased 'Enums::EnumsPaths';
#use aliased 'Enums::EnumsGeneral';
#use aliased 'Packages::CAMJob::OutputData::Enums';
#use aliased 'CamHelpers::CamLayer';
#use aliased 'CamHelpers::CamJob';
#use aliased 'Packages::CAMJob::OutputData::LayerData::LayerData';
#use aliased 'Helpers::ValueConvertor';
#use aliased 'CamHelpers::CamFilter';
#use aliased 'CamHelpers::CamDTM';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';

#use aliased 'Packages::CAMJob::OutputData::PrepareLayers::PrepareNCDrawing';
#use aliased 'Packages::CAMJob::OutputData::PrepareLayers::PrepareNCStandard';
#use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamHistogram';

#use aliased 'CamHelpers::CamAttributes';
#use aliased 'CamHelpers::CamSymbol';
#use aliased 'CamHelpers::CamHistogram';
#use aliased 'Packages::CAMJob::Drilling::DrillChecking::LayerCheckError';
#use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
#use aliased 'Enums::EnumsDrill';
#use aliased 'Packages::SystemCall::SystemCall';
use aliased 'Packages::CAMJob::OutputData::OutputLayer::Enums';
use aliased 'Packages::CAMJob::OutputData::OutputLayer::OutputResult::OutputResult';
use aliased 'CamHelpers::CamMatrix';
use aliased 'Packages::CAMJob::OutputData::OutputLayer::OutputParser';
use aliased 'Enums::EnumsGeneral';

use aliased 'Packages::CAMJob::OutputData::OutputLayer::OutputClasses::COUNTERSINKSURFBase';
use aliased 'Packages::CAMJob::OutputData::OutputLayer::OutputClasses::COUNTERSINKARCBase';
use aliased 'Packages::CAMJob::OutputData::OutputLayer::OutputClasses::COUNTERSINKPADBase';
use aliased 'Packages::CAMJob::OutputData::OutputLayer::OutputClasses::ZAXISSLOTCHAMFERBase';
use aliased 'Packages::CAMJob::OutputData::OutputLayer::OutputClasses::ZAXISSURFCHAMFERBase';
use aliased 'Packages::CAMJob::OutputData::OutputLayer::OutputClasses::ZAXISSURFBase';
use aliased 'Packages::CAMJob::OutputData::OutputLayer::OutputClasses::ZAXISSLOTBase';
use aliased 'Packages::CAMJob::OutputData::OutputLayer::OutputClasses::ZAXISPADBase';
use aliased 'Packages::CAMJob::OutputData::OutputLayer::OutputClasses::DRILLBase';
use aliased 'Packages::CAMJob::OutputData::OutputLayer::OutputClasses::ROUTBase';
use aliased 'Packages::CAMJob::OutputData::OutputLayer::OutputClasses::SCOREBase';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;
	
	$self->{"results"} = [];

	return $self;
}

sub Prepare {
	my $self  = shift;
	my $layer = shift;    # hash reference

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	CamDrilling->AddNCLayerType( [$layer] );

	my $backUp = $self->_BackupLayer( $layer->{"gROWname"} );

	my $parser  = $self->__GetParser($layer);
	my @results = $parser->Parse();

	unless ( $self->_FinalCheck( $layer, $backUp ) ) {
		die "NC output data - Layer was not fully parsed: ".$layer->{"gROWname"};
	}

	my $result = OutputResult->new( $inCAM, $jobId, $step, $layer, 1, \@results );

	# store reuslt
	push(@{$self->{"results"}}, $result);

	return $result;
}

sub __GetParser {
	my $self = shift;
	my $l    = shift;

	my $NCType = $l->{"type"};

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	# Init layer with some info

	# load UniDTM for layer
	$l->{"uniDTM"} = UniDTM->new( $inCAM, $jobId, $step, $l->{"gROWname"}, 0 );

	if ( $l->{"gROWlayer_type"} eq "rout" ) {

		# load UniRTM
		if ( $NCType ne EnumsGeneral->LAYERTYPE_nplt_score ) {
			$l->{"uniRTM"} = UniRTM->new( $inCAM, $jobId, $step, $l->{"gROWname"}, 0, $l->{"uniDTM"} );
		}
	}

	my $parser = OutputParser->new();
 

	return $parser;

}

#-------------------------------------------------------------------------------------------#
#  Protected methods
#-------------------------------------------------------------------------------------------#

sub _BackupLayer {
	my $self     = shift;
	my $oriLayer = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my $workLayer = GeneralHelper->GetGUID();

	$inCAM->COM(
				 'copy_layer',
				 "source_job"   => $jobId,
				 "source_step"  => $step,
				 "source_layer" => $oriLayer,
				 "dest"         => 'layer_name',
				 "dest_layer"   => $workLayer,
				 "mode"         => 'replace',
				 "invert"       => 'no'
	);

	return $workLayer;

}

# Remove all layers used in result
sub _FinalCheck {
	my $self        = shift;
	my $layer       = shift;
	my $backupLayer = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};
	
	my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $layer->{"gROWname"} );
	my %symHist = CamHistogram->GetSymHistogram( $inCAM, $jobId, $step, $layer->{"gROWname"}, 1, 1 );
	
	my $featsLeftCnt = $hist{"total"};
	
	# all feats cnt - r0 pads cnt
	if(defined $symHist{"pads"}->{"r0"} && $layer->{"gROWlayer_type"} eq "rout"){
		
		$featsLeftCnt -= $symHist{"pads"}->{"r0"};
	}
	
	
	if ( $featsLeftCnt == 0 ) {
 
		# Restore backup layer
		$inCAM->COM(
					 'copy_layer',
					 "source_job"   => $jobId,
					 "source_step"  => $step,
					 "source_layer" => $backupLayer,
					 "dest"         => 'layer_name',
					 "dest_layer"   => $layer->{"gROWname"},
					 "mode"         => 'replace',
					 "invert"       => 'no'
		);

		CamMatrix->DeleteLayer( $inCAM, $jobId, $backupLayer );

		return 1;
	}
	else {

		return 0;
	}
}

# Remove all layers used in result
sub Clear {
	my $self   = shift;
	my $result = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	foreach my $resultL ( @{ $self->{"results"} } ) {
 
			$resultL->Clear();
	 
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::OutputData::OutputLayer::OutputNCLayer';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "f52456";

	my $mess = "";

	my $control = OutputNCLayer->new( $inCAM, $jobId, "data_o+1" );

	my %lInfo = ( "gROWname" => "f", "gROWlayer_type" => "rout" );

	my $result = $control->Prepare( \%lInfo );
	
	$control->Clear();

}

1;
