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

	my $max = 0;
	foreach my $ch ( @{ $self->{"chains"} } ) {

		# set max value
		if ( $ch->GetChainOrder() > $max ) {
			$max = $ch->GetChainOrder();
		}
	}

	return $max;
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
	my $jobId = "f52456";

	my $unitRTM = UniRTM->new( $inCAM, $jobId, "o+1", "d" );

	my @lefts = $unitRTM->GetLeftCycleChains();

	my @features = $lefts[0]->GetFeatures();

	#my %modify = RoutStart->RoutNeedModify( \@features );

	#if ( $modify{"result"} ) {
	#	RoutStart->ProcessModify( \%modify, \@features );
	#}

	#my %foot = RoutStart->GetRoutFootDown( \@features );

	#my %start = RoutStart->GetRoutStart( \@features );

	my $draw = RoutDrawing->new( $inCAM, $jobId, "o+1", "o" );

	my $rotation = RoutRotation->new( \@features );
	$rotation->Rotate( 90, $draw );

	$draw->DrawRoute( \@features );

	$inCAM->COM("sel_delete");

	$rotation->RotateBack();

	$draw->DrawRoute( \@features );

	print STDERR "test";

}

sub Line {
	my @features = @{ shift(@_) };

}

1;

