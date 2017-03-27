
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers as gerber274x
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ExportPool::Routing::ToolsOrder::ToolsOrder;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::ItemResult::ItemResult';

#use aliased 'Enums::EnumsPaths';
#use aliased 'Helpers::JobHelper';
#use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamAttributes';

#use aliased 'Packages::Gerbers::Export::ExportLayers' => 'Helper';
use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';
#use aliased 'Enums::EnumsRout';

use aliased 'Packages::ExportPool::Routing::ToolsOrder::SortTools';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"stepList"} = shift;

	return $self;
}

sub SetInnerOrder {
	my $self       = shift;
	my $convTable  = shift;
	my $toolOrderNum = shift;
	my $resultItem = ItemResult->new("Inner chain order");

	my $inCAM = $self->{"inCAM"};

	# create tool queue
	my %toolQueues = ();

	foreach my $s ( $self->{"stepList"}->GetSteps() ) {

		foreach my $sRot ( $s->GetStepRotations() ) {

			foreach my $sPlc ( $sRot->GetStepPlaces() ) {

				# get not outline chain tool list
				my @chainList = $sRot->GetUniRTM()->GetChainListByOutline(0);
				$toolQueues{ $sPlc->GetStepId() } = \@chainList;
			}
		}
	}

	my @finalOrder = SortTools->SortNotOutlineTools( \%toolQueues );

	# renumber chains

	$self->__RenumberTools( \@finalOrder, $convTable, $toolOrderNum );

	return $resultItem;
}

sub SetOutlineOrder {
	my $self       = shift;
	my $convTable  = shift;
	my $toolOrderNum = shift;
	my $resultItem = ItemResult->new("Outline chain order");

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $fschLayer = "fsch";

	# create tool queue
	my @outlineChains = ();

	foreach my $s ( $self->{"stepList"}->GetSteps() ) {

		foreach my $sRot ( $s->GetStepRotations() ) {

			foreach my $sPlc ( $sRot->GetStepPlaces() ) {

				# get not outline chain tool list

				my @chainList       = $sRot->GetUniRTM()->GetChainListByOutline(1);
				my @chainListStarts = ();

				# get all start for specific  "step place"

				foreach my $chainTool (@chainList) {

					my $chain = $sRot->GetUniRTM()->GetChainByChainTool($chainTool);
					my @startEdges = map { $_->GetStartEdge() } $chain->GetChainSequences();

					# take most left placed start edge for specific tool
					my $minX   = undef;
					my $minIdx = undef;

					for ( my $i = 0 ; $i < scalar(@startEdges) ; $i++ ) {

						if ( !defined $minX || $minX > $startEdges[$i]->{"x1"} ) {
							$minX   = $startEdges[$i]->{"x1"};
							$minIdx = $i;
						}
					}

					my %inf = (
						 "stepId"    => $sPlc->GetStepId(),
						 "chainTool" => $chainTool,
						 "coord" => { "x" => $startEdges[$minIdx]->{"x1"} + $sPlc->GetPosX(), "y" => $startEdges[$minIdx]->{"y1"} + $sPlc->GetPosY() }
					);
					push( @outlineChains, \%inf );
				}
			}
		}
	}

	my @finalOrder = SortTools->SortOutlineTools( \@outlineChains );

	# renumber chains
 

	$self->__RenumberTools( \@finalOrder, $convTable, $toolOrderNum );
	
	# Set result of sorting to result item for later display to user
	my @allStepPlc = 
	my @stepPlcOrder = map { $ste } @finalOrder;
 
	
	
	$resultItem->{"stepPlcOrder"} = 

	return $resultItem;
}

sub ToolRenumberCheck {
	my $self = shift;

	my $resultItem = ItemResult->new("Tools renumber check");

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $fschLayer = "fsch";

	my $unitRTM = UniRTM->new( $inCAM, $jobId, $self->{"stepList"}->GetStep(), $fschLayer );

	# 1) Check if features with same tool chain order has same value of attribute "feat_group_id"
	# Test on preview operation - set new chain order
	foreach my $ch ( $unitRTM->GetChains() ) {

		my @feats = $ch->GetFeatures();

		# check if first value is same as other
		my $feat_group_id = $feats[0]->{"att"}->{"feat_group_id"};

		my @wrongVal = grep { $_->{"att"}->{"feat_group_id"} ne $feat_group_id } @feats;

		if ( scalar(@wrongVal) ) {
			$resultItem->AddError(   "Error during sorting tools in fsch layer. Not all chain features has same \"feat_group_id\". Chain: "
								   . $ch->GetChainOrder()
								   . "\n" );
		}
	}

	# 2) Order of tools has to by 1,2,3,4,5 increased by "1"

	my $expectOrd = 1;
	foreach my $chainTool ( $unitRTM->GetChainList() ) {

		if ( $chainTool->GetChainOrder() != $expectOrd ) {

			$resultItem->AddError("Error during sorting tools in fsch layer. Chain tools are not sorted correctly. \n");
			last;
		}

		$expectOrd++;
	}

	# 3) Check if tool with foot down are last
	my @outlines = $unitRTM->GetOutlineChains();

	my $outlineStart = 0;
	foreach my $ch ( $unitRTM->GetChains() ) {

		foreach my $chSeq ( $ch->GetChainSequences() ) {

			if ( $chSeq->IsOutline() && !$outlineStart ) {

				$outlineStart = 1;
				next;
			}

			# if first outline was passed, all chain after has to be outline
			if ($outlineStart) {
				unless ( $chSeq->IsOutline() ) {

					$resultItem->AddError("Error during sorting tools in fsch layer. Some outline chain is not last in rout list.\n");
					last;
				}
			}
		}
	}

	return $resultItem;

}

sub __RenumberTools {
	my $self        = shift;
	my @finalOrder  = @{ shift(@_) };
	my $convTable   = shift;
	my $chainOrder = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $fschLayer = "fsch";

	CamHelper->SetStep( $inCAM, $self->{"stepList"}->GetStep() );
 

	foreach my $stepChain (@finalOrder) {

		my $stepId      = $stepChain->{"stepId"};
		my $oriChainNum = $stepChain->{"chainOrder"};

		# Get real "fsch chain order" by convert
		#my $realChainNum = $convTable->{$stepId}->{$oriChainNum};

		# Get chain tool guid
		my $chainToolId = $convTable->{$stepId}->{$oriChainNum};

		my $f = FeatureFilter->new( $inCAM, $jobId, $fschLayer );

		#my %idVal = ( "min" => $realChainNum, "max" => $realChainNum );
		#$f->AddIncludeAtt( ".rout_chain",   \%idVal );
		$f->AddIncludeAtt( "feat_group_id", $chainToolId );

		if ( $f->Select() ) {
			CamAttributes->SetFeaturesAttribute( $inCAM, $jobId, ".rout_chain", $$chainOrder );
		}
		else {
			die "No chain selected, when changing chain order";
		}

		$$chainOrder++;
	}

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
