#-------------------------------------------------------------------------------------------#
# Description: Do checks of tool in Universal DTM
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniRTM::UniRTM::Parser::ChainParser;

#3th party library
use strict;
use warnings;
use Storable qw(dclone);
use List::Util;
use Scalar::Util qw(refaddr);
use List::MoreUtils qw(uniq);

#local library
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamDTMSurf';
use aliased 'Packages::CAM::UniRTM::UniChain::UniChainSeq';
use aliased 'Packages::CAM::UniRTM::UniChain::UniChain';
use aliased 'Packages::CAM::UniRTM::UniChain::UniMultiChainSeq';
use aliased 'Packages::CAM::UniRTM::Enums';
use aliased 'Enums::EnumsDrill';
use aliased 'Enums::EnumsRout';
use aliased 'Packages::Routing::RoutLayer::RoutParser::RoutCyclic';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub GetChains {
	my $self      = shift;
	my @chainList = @{ shift(@_) };
	my @features  = @{ shift(@_) };

	my @chains = ();

	# 1) Detect Chain
	foreach my $ch (@chainList) {

		my $uniChain = UniChain->new($ch);

		# 1) Set chain property
		#$self->__SetChainProperties($ch);

		my @featChain = grep { $_->{"att"}->{".rout_chain"} == $ch->GetChainOrder() } @features;

		$uniChain->SetFeatures( \@featChain );

		my @sequences = RoutCyclic->GetRoutSequences( \@featChain );

		foreach my $seqPoints (@sequences) {

			my $chSeq = UniChainSeq->new($uniChain);

			$chSeq->SetOriFeatures( dclone($seqPoints) );
			$chSeq->SetFeatures($seqPoints);
			$self->__SetChainSeqProperties($chSeq);

			$uniChain->AddChainSeq($chSeq);
		}

		push( @chains, $uniChain );
	}
	return @chains;
}

sub __SetChainProperties {
	my $self     = shift;
	my $uniChain = shift;

	my @features = $uniChain->GetFeatures();

	# 1) some attributes are same for all features, this take first
	my $fFirst = $features[0];

	my %fAttr = %{ $fFirst->{"att"} };

	$uniChain->SetComp( $fAttr{".comp"} );

	# Get size of tool
	my $chainSize = undef;
	if ( $fFirst->{"type"} =~ /s/i ) {

		$chainSize = sprintf( "%.1f", $fFirst->{"att"}->{".rout_tool"} * 25.4 ) * 1000;
	}
	else {
		$chainSize = $fFirst->{"thick"};
	}

	$uniChain->SetChainSize($chainSize);

}

sub __SetChainSeqProperties {
	my $self        = shift;
	my $uniChainSeq = shift;

	my @features = $uniChainSeq->GetFeatures();

	# 2) This sort chain featues (sort only cyclic polygon)
	my %result = RoutCyclic->GetSortedRout( \@features );

	if ( $result{"result"} ) {

		$uniChainSeq->SetCyclic(1);
		$uniChainSeq->SetDirection( RoutCyclic->GetRoutDirection( $result{"edges"} ) );
		$uniChainSeq->SetFeatures( $result{"edges"} );
		$uniChainSeq->SetModified( $result{"changes"} );

	}
	else {

		$uniChainSeq->SetCyclic(0);
	}

	# 4) find if chain has foot down
	my @foots = grep { defined $_->{"att"}->{".foot_down"} } @features;

	if ( scalar(@foots) ) {

		$uniChainSeq->SetFootsDown( \@foots );
	}

	# 5) Set features type
	if ( $features[0]->{"type"} =~ /s/i ) {
		$uniChainSeq->SetFeatureType( Enums->FeatType_SURF );
	}
	else {
		$uniChainSeq->SetFeatureType( Enums->FeatType_LINEARC );
	}

	# 6) Set start edge of  chain
	my @feats = $uniChainSeq->GetFeatures();

	my $minEId = undef;
	my $minIdx = undef;

	for ( my $i = 0 ; $i < scalar(@feats) ; $i++ ) {

		if ( !defined $minEId || $minEId > $feats[$i]->{"id"} ) {
			$minEId = $feats[$i]->{"id"};
			$minIdx = $i;
		}
	}

	$uniChainSeq->SetStartEdge( $feats[$minIdx] );

}

# Parse and return list of uni multi chains
sub GetMultiChainSequences {
	my $self   = shift;
	my $chains = shift;    # parsed inited UniChain

	my @multiChainSeq = ();

	my @uniChainSeq = map { $_->GetChainSequences() } @{$chains};
	my @allFeats    = map { $_->GetFeatures() } @uniChainSeq;
	my @sequences   = RoutCyclic->GetRoutSequences( \@allFeats );

	foreach my $seq (@sequences) {

		my @u = ();        # all uniChainSeq of new builded UniMultiChainSeq

		# 1) For each feature search UniChainSeq, where is feature assigned
		foreach my $feat ( @{$seq} ) {

			my $findSeq;

			foreach my $uniChai (@uniChainSeq) {

				if ( grep { $_->{"uid"} eq $feat->{"uid"} } $uniChai->GetFeatures() ) {

					$findSeq = $uniChai;
					last;
				}
			}

			die "UniChainSeq was not found by feat uid: " . $feat->{"uid"} if ( !defined $findSeq );

			# Add seq to list if already not added
			push( @u, $findSeq ) unless ( grep { refaddr($_) == refaddr($findSeq) } @u );
		}

		# 2) Init multiChainSeq object
		my $uniMultiChain = UniMultiChainSeq->new( \@u );

		# 3) Decide if is cyclic
		my @oriFeats = map { $_->GetOriFeatures() } @u;
		my %result = RoutCyclic->GetSortedRout( \@oriFeats );

		if ( $result{"result"} ) {

			$uniMultiChain->SetCyclic(1);

			# if no feature
			if ( $result{"changes"} == 0 ) {
				$uniMultiChain->SetDirection( RoutCyclic->GetRoutDirection( $result{"edges"} ) );
			}
 
		}
		else {

			$uniMultiChain->SetCyclic(0);
		}

		# Set feature type
		if ( $seq->[0]->{"type"} =~ /s/i ) {
			$uniMultiChain->SetFeatureType( Enums->FeatType_SURF );
		}
		else {
			$uniMultiChain->SetFeatureType( Enums->FeatType_LINEARC );
		}

		push( @multiChainSeq, $uniMultiChain );
	}

	return @multiChainSeq;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13608";

	my $f = FeatureFilter->new( $inCAM, "m" );

	$f->SetPolarity("positive");

	my @syms = ( "r500", "r1" );
	$f->AddIncludeSymbols( \[ "r500", "r1" ] );

	print $f->Select();

	print "fff";

}

1;

