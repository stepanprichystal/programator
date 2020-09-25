
#-------------------------------------------------------------------------------------------#
# Description: Class can flatten arbotrary rout layer and sort tools
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::FlattenRout::SRFlatten::FlattenRout;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::CAM::UniRTM::UniRTM';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::ItemResult::Enums' => "ResEnums";
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Packages::Routing::RoutLayer::FlattenRout::SRFlatten::ToolsOrder::ToolsOrder';
use aliased 'Packages::Routing::RoutLayer::FlattenRout::SRFlatten::SRStep::SRStep';
use aliased 'Packages::Routing::RoutLayer::FlattenRout::SRFlatten::ToolsOrder::GroupChain';
use aliased 'Packages::Routing::RoutLayer::FlattenRout::SRFlatten::SRFlatten::SRStepPos';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}            = shift;
	$self->{"jobId"}            = shift;
	$self->{"flatLayer"}        = shift;    # name of result flatened layer
	$self->{"considerStepRout"} = shift;    # if yes, also rout contained in "flatenned step" will by faltenned
	$self->{"delFlatLayer"}     = shift;    # delete flat layer if exist

	return $self;
}

# Flattened layer can be created by step name
sub CreateFromStepName {
	my $self        = shift;
	my $stepName    = shift;
	my $sourceLayer = shift;
	my $resultItem  = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $srStep = SRStep->new( $inCAM, $jobId, $stepName, $sourceLayer );
	$srStep->Init();

	$self->CreateFromSRStep( $srStep, $resultItem );

	$srStep->Clean();

	return $resultItem;

}

# Flattened layer can be created by special strusture "SRStep"
sub CreateFromSRStep {
	my $self       = shift;
	my $srStep     = shift;
	my $itemResult = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	unless ( defined $itemResult ) {
		$itemResult = ItemResult->new("Final layer flatten");
	}

	# 1) Create structures for creating flatten layer and tool ordering

	my @stepPos = $self->__GetNestedStepsPositions($srStep);

	my @groupChains = $self->__GetGroupChains( $srStep, \@stepPos );

	my %convTable = ();

	# 2) Create flatten layer (copy all rout from nested steps to new flatenned layer)

	$self->__CreateFlatLayer( \%convTable, \@groupChains, $srStep );

	# 3) Sort inner routs chains and than outline rout chains

	my $toolOrder = ToolsOrder->new( $inCAM, $jobId, \@groupChains, \%convTable, $srStep->GetStep(), $self->{"flatLayer"}, $itemResult );

	$toolOrder->SetInnerOrder();
	$toolOrder->SetOutlineOrder();

	# 4) Check if sortin result is what we expected

	$toolOrder->ToolRenumberCheck();

	return $itemResult;

}

sub __GetNestedStepsPositions {
	my $self   = shift;
	my $srStep = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @stepPos = ();

	CamHelper->SetStep( $inCAM, $srStep->GetStep() );

	# init steps
	my @repeatedSteps = CamStepRepeat->GetRepeatStep( $inCAM, $jobId, $srStep->GetStep() );

	foreach my $nestStep ( $srStep->GetNestedSteps() ) {

		foreach ( grep { $_->{"stepName"} eq $nestStep->GetStepName() && $_->{"angle"} eq $nestStep->GetAngle() } @repeatedSteps ) {

			push( @stepPos, SRStepPos->new( $nestStep, $_->{"originX"}, $_->{"originY"} ) );
		}
	}

	return @stepPos;
}

# Return list of "chain groups" - special structure suitable for ordering chainlist
sub __GetGroupChains {
	my $self          = shift;
	my $srStep        = shift;
	my $stepPositions = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @groupChains = ();

	# 1) create group chain from nested steps

	foreach my $stepPos ( @{$stepPositions} ) {

		my $gCh = GroupChain->new(
								   $stepPos->GetStepId(),
								   $stepPos->GetStepName(),
								   $stepPos->GetRoutLayer(),
								   $stepPos->GetPosX(),
								   $stepPos->GetPosY(),
								   $stepPos->GetUniRTM(),
								   CamAttributes->GetStepAttrByName( $inCAM, $jobId, $stepPos->GetStepName(), "rout_on_bridges" ) =~ /^yes$/i
		);

		push( @groupChains, $gCh );
	}

	# 2) create group chain from "top" step rout if requested
	if ( $self->{"considerStepRout"} ) {

		my $unitRTM = UniRTM->new( $inCAM, $jobId, $srStep->GetStep(), $srStep->GetSourceLayer() );

		my $gCh = GroupChain->new( GeneralHelper->GetGUID(),
								   $srStep->GetStep(), $srStep->GetSourceLayer(),
								   0, 0, $unitRTM,
								   CamAttributes->GetStepAttrByName( $inCAM, $jobId, $srStep->GetStep(), "rout_on_bridges" ) =~ /^yes$/i )
		  ;

		push( @groupChains, $gCh );

	}

	return @groupChains;
}

# Copy chains from steps to result flatten layer
sub __CreateFlatLayer {
	my $self        = shift;
	my $convTable   = shift;
	my @groupChains = @{ shift(@_) };
	my $srStep      = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	if ( $self->{"delFlatLayer"} ) {
		if ( CamHelper->LayerExists( $inCAM, $jobId, $self->{"flatLayer"} ) ) {
			$inCAM->COM( 'delete_layer', "layer" => $self->{"flatLayer"} );
		}
	}

	unless ( CamHelper->LayerExists( $inCAM, $jobId, $self->{"flatLayer"} ) ) {

		$inCAM->COM( 'create_layer', layer => $self->{"flatLayer"}, context => 'board', type => 'rout', polarity => 'positive', ins_layer => '' );
	}

	CamHelper->SetStep( $inCAM, $srStep->GetStep() );

	foreach my $groupChain (@groupChains) {

		$self->__CopyRoutToFlatLayer(
									  $groupChain->GetGroupId(),     $groupChain->GetSourceLayer(),
									  $groupChain->GetGroupPosX(),   $groupChain->GetGroupPosY(),
									  $groupChain->GetGroupUniRTM(), $convTable
		);
	}

}

sub __CopyRoutToFlatLayer {
	my $self        = shift;
	my $groupId     = shift;
	my $sourceLayer = shift;
	my $groupPosX   = shift;
	my $groupPosY   = shift;
	my $groupUniRTM = shift;
	my $convTable   = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1) Copy prepared rout to fsch

	CamLayer->WorkLayer( $inCAM, $sourceLayer );

	# 2) Get new chain ids

	# Get new chain number and store to conversion table
	my @oldChains = $groupUniRTM->GetChainList();

	# 3) Generate guid for each new chain and set this guid to all chain features in fsch
	for ( my $i = 0 ; $i < scalar(@oldChains) ; $i++ ) {

		my $oldChain = $oldChains[$i];

		my $chainId = GeneralHelper->GetGUID();    # Guid, which will be signed all features with sam chain

		my $f = FeatureFilter->new( $inCAM, $jobId, $sourceLayer );

		my %idVal = ( "min" => $oldChain->GetChainOrder(), "max" => $oldChain->GetChainOrder() );
		$f->AddIncludeAtt( ".rout_chain", \%idVal );

		# Test if count of selected features in fsch is ok
		my $featCnt = scalar( $groupUniRTM->GetChainByChainTool($oldChain)->GetFeatures() );

		if ( $f->Select() == $featCnt ) {

			CamAttributes->SetFeaturesAttribute( $inCAM, $jobId, "feat_group_id", $chainId );
		}
		else {
			die "not chain featuer selected";
		}

		$convTable->{$groupId}->{ $oldChain->GetChainOrder() } = $chainId;
	}

	$inCAM->COM("sel_clear_feat");
	$inCAM->COM(
				 "sel_copy_other",
				 "target_layer" => $self->{"flatLayer"},
				 "invert"       => "no",
				 "dx"           => $groupPosX,
				 "dy"           => $groupPosY,
				 "size"         => "0",
				 "x_anchor"     => 0,
				 "y_anchor"     => 0,
	);

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

	my $fsch = FlattenRout->new( $inCAM, $jobId, "fsch", 1 );
	$fsch->CreateFromStepName( "mpanel", "f" );
}

1;

