
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers as gerber274x
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::FlattenRout::SRFlatten::FlattenRout;

#3th party library
use utf8;
use strict;
use warnings;

#local library
#use aliased 'Helpers::GeneralHelper';
#use aliased 'Packages::ItemResult::ItemResult';

#use aliased 'Enums::EnumsRout';
use aliased 'Helpers::GeneralHelper';

#use aliased 'Enums::EnumsPaths';
#use aliased 'Helpers::JobHelper';
#use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';

use aliased 'CamHelpers::CamAttributes';

#use aliased 'Packages::Gerbers::Export::ExportLayers' => 'Helper';
use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';

#use aliased 'Packages::Routing::RoutLayer::RoutStart::RoutStart';
#use aliased 'Packages::Routing::RoutLayer::RoutDrawing::RoutDrawing';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';

use aliased 'Packages::Routing::RoutLayer::FlattenRout::StepList::StepList';
use aliased 'Packages::ItemResult::Enums' => "ResEnums";
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Packages::Routing::RoutLayer::FlattenRout::SRFlatten::ToolsOrder';

use aliased 'Packages::Routing::RoutLayer::FlattenRout::SRFlatten::SRStep::SRStep';
use aliased 'Packages::Routing::RoutLayer::FlattenRout::SRFlatten::SRFlatten::SRFlatten';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}            = shift;
	$self->{"jobId"}            = shift;
	$self->{"flatLayer"}        = shift;
	$self->{"considerStepRout"} = shift;

	return $self;
}

sub CreateFromStepName {
	my $self        = shift;
	my $stepName    = shift;
	my $sourceLayer = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $srStep = SRStep->new( $inCAM, $jobId, $stepName, $sourceLayer );
	$srStep->Init();

	$self->CreateFromSRStep($srStep);

}

sub CreateFromSRStep {
	my $self   = shift;
	my $srStep = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $itemResult = ItemResult->new("Layer flatten");

	my $srFlatten = SRFlatten->new( $inCAM, $jobId, $srStep, $self->{"flatLayer"} );
	$srFlatten->Init();

	my %convTable = ();

	$self->__CreateFlatLayer( \%convTable, $srFlatten );
	
	$self->__GetRout2SortList($srFlatten);

	my $toolOrder = ToolsOrder->new( $inCAM, $jobId, $srFlatten, , $itemResult );

	my $toolOrderStart = 1;

	$toolOrder->SetInnerOrder( \%convTable, \$toolOrderStart );

	$toolOrder->SetOutlineOrder( \%convTable, \$toolOrderStart );

	$toolOrder->ToolRenumberCheck();

	return $itemResult;

}

sub __CreateFlatLayer {
	my $self      = shift;
	my $convTable = shift;
	my $srFlatten = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	if ( CamHelper->LayerExists( $inCAM, $jobId, $self->{"flatLayer"} ) ) {
		$inCAM->COM( 'delete_layer', "layer" => $self->{"flatLayer"} );
	}

	$inCAM->COM( 'create_layer', layer => $self->{"flatLayer"}, context => 'board', type => 'rout', polarity => 'positive', ins_layer => '' );

	# 1) copy nested steps rout to flattened layer

	foreach my $stepPos ( $srFlatten->GetStepPositions() ) {

		$self->__CopyStepRoutToFlatLayer( $stepPos, $convTable );

	}

	# 2) copy rout contained in flattened step to flattenede layer if requested
	if ($self->{"considerStepRout"}) {

		my $unitRTM = UniRTM->new( $inCAM, $jobId, $srFlatten->GetStep(), $srFlatten->GetSourceLayer() );

		$self->__CopyRoutToFlatLayer( $srFlatten->GetStep(), $srFlatten->GetSourceLayer(), $unitRTM, GeneralHelper->GetGUID(), $convTable );

	}

}

sub __CopyStepRoutToFlatLayer {
	my $self      = shift;
	my $stepPos   = shift;
	my $convTable = shift;

	$self->__CopyRoutToFlatLayer( $stepPos->GetStepName(), $stepPos->GetRoutLayer(), $stepPos->GetUniRTM(), $stepPos->GetStepId(), $convTable );
}

sub __CopyRoutToFlatLayer {
	my $self          = shift;
	my $stepName      = shift;
	my $stepRoutLayer = shift;
	my $stepUniRTM    = shift;
	my $stepId        = shift;
	my $convTable     = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1) Copy prepared rout to fsch
	CamHelper->SetStep( $inCAM, $stepName );
	CamLayer->WorkLayer( $inCAM, $stepRoutLayer );

	#my %convTmp = ();    # temporary convert table

	# 2) Get new chain ids

	# Get new chain number and store to conversion table
	my @oldChains = $stepUniRTM->GetChainList();

	# 3) Generate guid for each new chain and set this guid to all chain features in fsch
	for ( my $i = 0 ; $i < scalar(@oldChains) ; $i++ ) {

		my $oldChain = $oldChains[$i];

		my $chainId = GeneralHelper->GetGUID();    # Guid, which will be signed all features with sam chain

		my $f = FeatureFilter->new( $inCAM, $jobId, $stepRoutLayer );

		my %idVal = ( "min" => $oldChain->GetChainOrder(), "max" => $oldChain->GetChainOrder() );
		$f->AddIncludeAtt( ".rout_chain", \%idVal );

		# Test if count of selected features in fsch is ok
		my $featCnt = scalar( $stepUniRTM->GetChainByChainTool($oldChain)->GetFeatures() );

		if ( $f->Select() == $featCnt ) {

			CamAttributes->SetFeaturesAttribute( $inCAM, $jobId, "feat_group_id", $chainId );
		}
		else {
			die "not chain featuer selected";
		}

		$convTable->{ $stepId->GetStepId() }->{ $oldChain->GetChainOrder() } = $chainId;
	}

	#	$inCAM->COM("sel_clear_feat");
	#
	#	$inCAM->COM("sel_buffer_options","mode" => "merge_layers","rotation" => "0","mirror" => "no","polarity" => "no","fixed_datum" => "no");
	#	$inCAM->COM("sel_buffer_clear");
	#	$inCAM->COM("sel_buffer_copy","x_datum" => "0","y_datum" => "0");
	#
	#	CamHelper->SetStep( $inCAM, $stepPos->GetStepName() );
	#	CamLayer->WorkLayer( $inCAM, $stepPos->GetRoutLayer() );
	#
	#
	#	$inCAM->COM("sel_buffer_paste","x" => "0","y" => "0");
	#	$inCAM->COM("sel_buffer_clear");

	#	$inCAM->COM(
	#				 "sel_copy_other",
	#				 "target_layer" => $self->{"flatLayer"},
	#				 "invert"       => "no",
	#				 "dx"           => $stepPos->GetPosX(),
	#				 "dy"           => $stepPos->GetPosY(),
	#				 "size"         => "0",
	#				 "x_anchor"     => 0,
	#				 "y_anchor"     => 0,
	#	);

}


sub __GetRout2SortList{
	
	my $self = shift;
	my $srFlatten = shift;
	
	my @rout2sort = ();
	
	foreach my $stepPos ( $srFlatten->GetStepPositions() ) {
		 
		 
		my $rout2sort = Rout2Sort->new($stepPos->GetStepName(), $stepPos->GetPosX(), $stepPos->GetPosY(), $stepPos->GetUniRTM());
		push(@rout2sort, $rout2sort);
 
		$self->__CopyStepRoutToFlatLayer( $stepPos, $convTable );

	}

	# 2) copy rout contained in flattened step to flattenede layer if requested
	if ($self->{"considerStepRout"}) {
	
	
	
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Routing::RoutLayer::FlattenRout::SRFlatten::FlattenRout';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "f52456";

	my $fsch = FlattenRout->new( $inCAM, $jobId, "fsch" );
	$fsch->CreateFromStepName( "panel", "f" );
}

1;

