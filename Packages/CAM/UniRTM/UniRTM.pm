#-------------------------------------------------------------------------------------------#
# Description: Represent Universal Drill tool manager
# This manager contain general information about all tools in NC layer
# Each tool contain
# - DrillSize
# - Process type
# - Depth
# - Magazine
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniRTM::UniRTM;
use base("Packages::CAM::UniRTM::UniRTM::UniRTMBase");

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::CAM::UniRTM::Enums';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

# Get left cycle chain
sub GetOutlineChains {
	my $self = shift;

	my @seqs = map { $_->GetChainSequences() } @{ $self->{"chains"} };
	@seqs = grep { $_->IsOutline() } @seqs;

	return @seqs;
}

# Get max chain number
sub GetMaxChainNumber {
	my $self = shift;

	my @chainList = $self->GetChainList();

	if ( scalar(@chainList) ) {
		return $chainList[ scalar(@chainList) - 1 ]->GetChainOrder();
	}
	else {
		return 0;
	}

}

# Get left cycle chain
sub GetChainListByOutline {
	my $self    = shift;
	my $outline = shift;    # if 1, return only outline chain tool. If 0, return all except outline tool

	my @chainList = $self->GetChainList();

	for ( my $i = scalar(@chainList) - 1 ; $i >= 0 ; $i-- ) {

		# get chain woth actual chainTool
		my $chainTool = $chainList[$i];

		my $ch = $self->GetChainByChainTool($chainTool);

		# test if given chai contain outline rout, if so remove from chainlist

		my $exist = scalar( grep { $_->IsOutline() } $ch->GetChainSequences() );

		if ($outline) {
			unless ($exist) {
				splice @chainList, $i, 1;
			}
		}
		else {
			if ($exist) {
				splice @chainList, $i, 1;
			}
		}

	}

	return @chainList;
}

sub GetChainByChainTool {
	my $self      = shift;
	my $chainTool = shift;

	my @chains = $self->GetChains();
	my $ch = (
		grep {
			     $_->{"chainTool"}->GetChainOrder() == $chainTool->GetChainOrder()
			  && $_->{"chainTool"}->GetComp() eq $chainTool->GetComp()
			  && $_->{"chainTool"}->GetChainSize() eq $chainTool->GetChainSize()
		} @chains
	)[0];

	return $ch;

}

# return all chan sequences, which are cycle
# If chain seq is type of:
# - FeatType_SURF: Chain seq contain on surface feature which is circle
# - FeatType_LINEARC: Chain seq contain only arc and is cyclic
sub GetCircleChainSeq {
	my $self     = shift;
	my $chanType = shift;    # FeatType_SURF, FeatType_LINEARC

	my @circleChainSeq = ();

	if ( $chanType eq Enums->FeatType_SURF ) {

		my @chainSeq = grep { $_->GetFeatureType eq Enums->FeatType_SURF } $self->GetChainSequences();

		my @cyclChains = grep {
			     scalar( $_->GetFeatures() ) == 1
			  && scalar( @{ ( $_->GetFeatures() )[0]->{"surfaces"} } ) == 1
			  && ( $_->GetFeatures() )[0]->{"surfaces"}->[0]->{"circle"}
		} @chainSeq;

		push( @circleChainSeq, @cyclChains );

	}

	if ( $chanType eq Enums->FeatType_LINEARC ) {

		my @cyclChains = grep { $_->GetFeatureType() eq Enums->FeatType_LINEARC && $_->GetCyclic() } $self->GetChainSequences();

		# only arcs
		for ( my $i = scalar(@cyclChains) - 1 ; $i >= 0 ; $i-- ) {

			my $chain = $cyclChains[$i];
			my @notArc = grep { $_->{"type"} !~ /^a$/i } $chain->GetFeatures();
			if (@notArc) {

				splice @cyclChains, $i, 1;
			}
		}

		push( @circleChainSeq, @cyclChains );

	}

	return @circleChainSeq;
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAM::UniRTM::UniRTM';
	use aliased 'Packages::CAM::UniDTM::UniDTM';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d113609";
	my $step  = "o+1";
	my $layer = 'f';

	my $rtm = UniRTM->new( $inCAM, $jobId, $step, $layer, 1, 0, 1 );
	
	my @outline = $rtm->GetMultiChainSeqList();

	die;
}

1;
