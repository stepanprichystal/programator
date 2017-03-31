
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers as gerber274x
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::FlattenRout::FlattenRout::FlattenRout;

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
use aliased 'Packages::Routing::RoutLayer::FlattenRout::FlattenRout::ToolsOrder';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}     = shift;
	$self->{"jobId"}     = shift;
	$self->{"step"}      = shift;
	$self->{"stepList"}  = shift;
	$self->{"flatLayer"} = shift;

	return $self;
}

sub Create {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $itemResult = ItemResult->new();

	my $toolOrder = ToolsOrder->new( $inCAM, $jobId, $self->{"stepList"}, $self->{"flatLayer"}, $itemResult );

	my %convTable = ();

	$self->__CreateFlatLayer( \%convTable );

	my $toolOrderStart = 1;

	$toolOrder->SetInnerOrder( \%convTable, \$toolOrderStart );

	$toolOrder->SetOutlineOrder( \%convTable, \$toolOrderStart );

	$toolOrder->ToolRenumberCheck();

	return $itemResult;

}

sub __CreateFlatLayer {
	my $self      = shift;
	my $convTable = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	if ( CamHelper->LayerExists( $inCAM, $jobId, $self->{"flatLayer"} ) ) {
		$inCAM->COM( 'delete_layer', "layer" => $self->{"flatLayer"} );
	}

	$inCAM->COM( 'create_layer', layer => $self->{"flatLayer"}, context => 'board', type => 'rout', polarity => 'positive', ins_layer => '' );

	CamHelper->SetStep( $inCAM, $self->{"stepList"}->GetStep() );

	foreach my $s ( $self->{"stepList"}->GetSteps() ) {

		foreach my $sRot ( $s->GetStepRotations() ) {

			foreach my $sPlc ( $sRot->GetStepPlaces() ) {

				$self->__CopyToFlatLayer( $sRot, $sPlc, $convTable );

			}
		}
	}
 
}

sub __CopyToFlatLayer {
	my $self      = shift;
	my $sRot      = shift;
	my $sPlc      = shift;
	my $convTable = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1) Copy prepared rout to fsch

	CamLayer->WorkLayer( $inCAM, $sRot->GetRoutLayer() );

	#my %convTmp = ();    # temporary convert table

	# 2) Get new chain ids

	# Get new chain number and store to conversion table
	my @oldChains = $sRot->GetUniRTM()->GetChainList();

	# 3) Generate guid for each new chain and set this guid to all chain features in fsch
	for ( my $i = 0 ; $i < scalar(@oldChains) ; $i++ ) {

		my $oldChain = $oldChains[$i];

		my $chainId = GeneralHelper->GetGUID();    # Guid, which will be signed all features with sam chain

		my $f = FeatureFilter->new( $inCAM, $jobId, $sRot->GetRoutLayer() );

		my %idVal = ( "min" => $oldChain->GetChainOrder(), "max" => $oldChain->GetChainOrder() );
		$f->AddIncludeAtt( ".rout_chain", \%idVal );

		# Test if count of selected features in fsch is ok
		my $featCnt = scalar( $sRot->GetUniRTM()->GetChainByChainTool($oldChain)->GetFeatures() );

		if ( $f->Select() == $featCnt ) {

			CamAttributes->SetFeaturesAttribute( $inCAM, $jobId, "feat_group_id", $chainId );
		}
		else {
			die "not chain featuer selected";
		}

		$convTable->{ $sPlc->GetStepId() }->{ $oldChain->GetChainOrder() } = $chainId;
	}

	$inCAM->COM("sel_clear_feat");

	$inCAM->COM(
				 "sel_copy_other",
				 "target_layer" => $self->{"flatLayer"},
				 "invert"       => "no",
				 "dx"           => $sPlc->GetPosX(),
				 "dy"           => $sPlc->GetPosY(),
				 "size"         => "0",
				 "x_anchor"     => -$sPlc->GetXMin(),
				 "y_anchor"     => -$sPlc->GetYMin(),
	);

	#my $unitRTM = UniRTM->new( $inCAM, $jobId, $self->{"stepList"}->GetStep(), $fschLayer );

	#	my @newChains = ( $unitRTM->GetChainList() )[ -scalar(@oldChains) .. -1 ];
	#
	#	# 3) Generate guid for each new chain and set this guid to all chain features in fsch
	#	for ( my $i = 0 ; $i < scalar(@oldChains) ; $i++ ) {
	#
	#		my $oldChain = $oldChains[$i];
	#		my $newChain = $newChains[$i];
	#
	#		my $chainId = GeneralHelper->GetGUID();    # Guid, which will be signed all features with sam chain
	#
	#		my $f = FeatureFilter->new( $inCAM, $jobId, $fschLayer );
	#
	#		my %idVal = ( "min" => $newChain->GetChainOrder(), "max" => $newChain->GetChainOrder() );
	#		$f->AddIncludeAtt( ".rout_chain", \%idVal );
	#
	#		# Test if count of selected features in fsch is ok
	#		my $featCnt = scalar( $sRot->GetUniRTM()->GetChainByChainTool($oldChain)->GetFeatures() );
	#
	#		if ( $f->Select() == $featCnt ) {
	#
	#			CamAttributes->SetFeaturesAttribute( $inCAM, $jobId, "feat_group_id", $chainId );
	#		}
	#		else {
	#			die "not chain featuer selected";
	#		}
	#
	#		$convTable->{ $sPlc->GetStepId() }->{ $oldChain->GetChainOrder() } = $chainId;
	#	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Packages::Export::NCExport::NCExportGroup';

	#print $test;

}

1;

