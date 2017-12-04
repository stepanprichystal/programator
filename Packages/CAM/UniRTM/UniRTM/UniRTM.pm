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
package Packages::CAM::UniRTM::UniRTM::UniRTM;
use base("Packages::CAM::UniRTM::UniRTM::UniRTMBase");

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::CAM::UniDTM::Enums';
use aliased 'Enums::EnumsRout';

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
	
	if(scalar(@chainList)){
		return $chainList[scalar(@chainList)-1]->GetChainOrder();
	}else{
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
	my $ch = ( grep { $_->{"chainTool"} == $chainTool } @chains )[0];

	return $ch;
}


 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Packages::Routing::RoutLayer::RoutStart::RoutStart';
	use aliased 'Packages::Routing::RoutLayer::RoutStart::RoutRotation';
	use aliased 'Packages::Routing::RoutLayer::RoutDrawing::RoutDrawing';

	my $inCAM = InCAM->new();
	my $jobId = "f90576";
  
  
  	my $rtm = UniRTM->new($inCAM, $jobId, "o+1", "f", 1);
  
	my @outline = $rtm->GetOutlineChains();

 
	print scalar(@outline)."fff";

}

 

1;

