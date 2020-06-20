
#-------------------------------------------------------------------------------------------#
# Description: Class cover sorting chain tools in flatenned layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::FlattenRout::SRFlatten::ToolsOrder::ToolsOrder;

#3th party library
use utf8;
use strict;
use warnings;
use Storable qw(dclone);
use List::Util qw(first);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Packages::CAM::UniRTM::UniRTM';
use aliased 'CamHelpers::CamLayer';
use aliased 'Packages::Routing::RoutLayer::FlattenRout::SRFlatten::ToolsOrder::SortTools';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}       = shift;
	$self->{"jobId"}       = shift;
	$self->{"chainGroups"} = shift;

	# contain hash, where key is old step chain nuber and value is GUID represent new chain in flatenned layer
	# Theses values are available by "group chain guid", which represent all chains in step
	$self->{"convTable"}  = shift;
	$self->{"step"}       = shift;
	$self->{"flatLayer"}  = shift;
	$self->{"resultItem"} = shift;

	$self->{"toolOrderNum"} = 1;    # start renumber chain from number one

	return $self;
}

sub SetInnerOrder {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};

	# create tool queue
	my %toolQueues = ();

	foreach my $chGroup ( @{ $self->{"chainGroups"} } ) {

		# get not outline chain tool list
		my @chainList = $chGroup->GetGroupUniRTM()->GetChainListByOutline(0);

		if ( $chGroup->GetOnBridges() ) {

			# remove potentional rout on bridges UniChanTool
			my @chainListOnBridges = $chGroup->GetGroupUniRTM()->GetChainListByOutlineOnBridges();

			for ( my $i = scalar(@chainList) - 1 ; $i >= 0 ; $i-- ) {

				if ( scalar( grep { $_->GetChainOrder() == $chainList[$i]->GetChainOrder() } @chainListOnBridges ) ) {
					splice @chainList, $i, 1;
				}
			}
		}

		$toolQueues{ $chGroup->GetGroupId() } = \@chainList;

	}

	# check if outline tools are same diameter,
	# if so consider this tool in  NO outline tool sorting
	my $outlineTool = $self->__GetOutlineTool();

	my @finalOrder = SortTools->SortNotOutlineTools( \%toolQueues, $outlineTool );

	# renumber chains

	$self->__RenumberTools( \@finalOrder );

}

sub SetOutlineOrder {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# create tool queue
	my @outlineChains = ();

	foreach my $chGroup ( @{ $self->{"chainGroups"} } ) {

		# get not outline chain tool list

		my @chainList = $chGroup->GetGroupUniRTM()->GetChainListByOutline(1);

		if ( $chGroup->GetOnBridges() ) {

			# remove potentional rout on bridges UniChanTool
			my @chainListOnBridges = $chGroup->GetGroupUniRTM()->GetChainListByOutlineOnBridges();

			push( @chainList, @chainListOnBridges ) if ( scalar(@chainListOnBridges) );
		}

		my @chainListStarts = ();

		# get all start for specific  "step place"

		foreach my $chainTool (@chainList) {

			my $chain = $chGroup->GetGroupUniRTM()->GetChainByChainTool($chainTool);
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
				  "chainGroupId" => $chGroup->GetGroupId(),
				  "chainTool"    => $chainTool,
				  "coord" =>
					{ "x" => $startEdges[$minIdx]->{"x1"} + $chGroup->GetGroupPosX(), "y" => $startEdges[$minIdx]->{"y1"} + $chGroup->GetGroupPosY() }
			);
			push( @outlineChains, \%inf );
		}
	}

	my @finalOrder = SortTools->SortOutlineTools( \@outlineChains );

	# renumber chains

	$self->__RenumberTools( \@finalOrder );

	# Set result of sorting to result item for later display to user

	my @chainIds = ();
	foreach my $rout (@finalOrder) {

		push( @chainIds, $self->{"convTable"}->{ $rout->{"chainGroupId"} }->{ $rout->{"chainOrder"} } );

	}

	$self->{"resultItem"}->{"chainOrderIds"} = \@chainIds;

}

sub ToolRenumberCheck {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $unitRTM = UniRTM->new( $inCAM, $jobId, $self->{"step"}, $self->{"flatLayer"} );

	# 1) Check if features with same tool chain order has same value of attribute "feat_group_id"
	# Test on preview operation - set new chain order
	foreach my $ch ( $unitRTM->GetChains() ) {

		my @feats = $ch->GetFeatures();

		# check if first value is same as other
		my $feat_group_id = $feats[0]->{"att"}->{"feat_group_id"};

		my @wrongVal = grep { $_->{"att"}->{"feat_group_id"} ne $feat_group_id } @feats;

		if ( scalar(@wrongVal) ) {
			$self->{"resultItem"}->AddError(   "Error during sorting tools in fsch layer. Not all chain features has same \"feat_group_id\". Chain: "
											 . $ch->GetChainOrder()
											 . "\n" );
		}
	}

	# 2) Order of tools has to by 1,2,3,4,5 increased by "1"

	my $expectOrd = 1;
	foreach my $chainTool ( $unitRTM->GetChainList() ) {

		if ( $chainTool->GetChainOrder() != $expectOrd ) {

			$self->{"resultItem"}->AddError("Error during sorting tools in fsch layer. Chain tools are not sorted correctly. \n");
			last;
		}

		$expectOrd++;
	}

	# 3) Check if tool with foot down are last
	my @outlines = $unitRTM->GetOutlineChainSeqs();

	my $outlineStart = 0;
	foreach my $ch ( $unitRTM->GetChains() ) {

		foreach my $chSeq ( $ch->GetChainSequences() ) {

			if ( $chSeq->IsOutline() && !$outlineStart ) {

				$outlineStart = 1;
				next;
			}

			# if first outline was passed, all chain after has to be outline
			if ($outlineStart) {

				# Checki if chain is rout on bridges
				my $featGroupId = ( $ch->GetFeatures() )[0]->{"att"}->{"feat_group_id"};

				# Search for group id
				my $chainGroup = undef;
				foreach my $gId ( keys %{ $self->{"convTable"} } ) {

					foreach my $toolOrder ( keys %{ $self->{"convTable"}->{$gId} } ) {

						if ( $self->{"convTable"}->{$gId}->{$toolOrder} eq $featGroupId ) {
							$chainGroup = first { $_->GetGroupId() eq $gId } @{ $self->{"chainGroups"} };
							last;
						}
						last if ( defined $chainGroup );
					}
				}

				if ( !$chSeq->IsOutline() &&  !$chainGroup->GetOnBridges() ) {

					$self->{"resultItem"}->AddError("Error during sorting tools in fsch layer. Some outline chain is not last in rout list.\n");
					last;
				}
			}
		}
	}

}

# Renumber tool chain order in flatenned layer by newlz acquired order
sub __RenumberTools {
	my $self       = shift;
	my @finalOrder = @{ shift(@_) };

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	CamHelper->SetStep( $inCAM, $self->{"step"} );

	foreach my $stepChain (@finalOrder) {

		my $chainGroupId = $stepChain->{"chainGroupId"};
		my $oriChainNum  = $stepChain->{"chainOrder"};

		# Get chain tool guid
		my $chainToolId = $self->{"convTable"}->{$chainGroupId}->{$oriChainNum};

		my $f = FeatureFilter->new( $inCAM, $jobId, $self->{"flatLayer"} );

		$f->AddIncludeAtt( "feat_group_id", $chainToolId );

		if ( $f->Select() ) {
			CamAttributes->SetFeaturesAttribute( $inCAM, $jobId, ".rout_chain", $self->{"toolOrderNum"} );
		}
		else {
			die "No chain selected, when changing chain order";
		}

		$self->{"toolOrderNum"}++;
	}

	$inCAM->COM("sel_clear_feat");

}

# If all groups has same outline tool, return tool diameter
sub __GetOutlineTool {
	my $self = shift;

	my $tool = undef;

	# outline chains
	my @outlineTools = ();

	foreach my $chGroup ( @{ $self->{"chainGroups"} } ) {

		# check if outline tools are same diameter,
		# if so consider this tool in  NO outline tool sorting
		push( @outlineTools, $chGroup->GetGroupUniRTM()->GetChainListByOutline(1) );
	}

	if ( scalar(@outlineTools) ) {

		# find if tools are all same
		my @sameTools = grep { $_->GetChainSize() == $outlineTools[0]->GetChainSize() } @outlineTools;

		if ( scalar(@outlineTools) == scalar(@sameTools) ) {
			$tool = dclone( $outlineTools[0] );
		}
	}

	return $tool;
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
