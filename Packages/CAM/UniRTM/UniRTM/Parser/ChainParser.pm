#-------------------------------------------------------------------------------------------#
# Description: Do checks of tool in Universal DTM
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniRTM::UniRTM::Parser::ChainParser;

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamDTMSurf';
use aliased 'Packages::CAM::UniRTM::UniRTM::UniChainSeq';
use aliased 'Packages::CAM::UniRTM::UniRTM::UniChain';
use aliased 'Packages::CAM::UniRTM::Enums';
use aliased 'Enums::EnumsDrill';
use aliased 'Packages::Routing::RoutLayer::RoutParser::RoutCyclic';
use List::MoreUtils qw(uniq);

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

# Check if tools parameters are ok
# When some errors occure here, proper NC export is not possible

sub GetChains {
	my $self     = shift;
	my @features = @{ shift(@_) };

	my @chains = ();

	# 1) Detect Chain
	foreach my $f (@features) {

		# if no attributes
		unless ( $f->{"att"} ) {
			next;
		}

		my %attr = %{ $f->{"att"} };

		# if features contain attribute rout chain
		if ( $attr{".rout_chain"} && $attr{".rout_chain"} > 0 ) {

			my $uniChain = undef;

			$uniChain = ( grep { $_->GetChainOrder() eq $attr{".rout_chain"} } @chains )[0];

			#  unless chain with given routchain, exist, add feature
			unless ($uniChain) {

				#
				#				unless(defined $attr{".rout_tool"}){
				#
				#					print "dd";
				#				}
				#
				my $chainOrder = $attr{".rout_chain"};

				#				my $chainSize = sprintf( "%.1f", $attr{".rout_tool"} * 25.4 ) * 1000;

				$uniChain = UniChain->new($chainOrder);

				push( @chains, $uniChain );

			}

			# Add features
			$uniChain->AddFeature($f);
		}

	}

	# 2) Complete chain information
	foreach my $ch (@chains) {

		# 1) Set chain property
		$self->__SetChainProperties($ch);

		my @features = $ch->GetFeatures();

		my @sequences = RoutCyclic->GetRoutSequences( \@features );

		foreach my $seqPoints (@sequences) {

			my $chSeq = UniChainSeq->new($ch);

			$chSeq->SetFeatures($seqPoints);
			$self->__SetChainSeqProperties($chSeq);

			$ch->AddChainSeq($chSeq);
		}
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
	
	if($result{"result"}){

		$uniChainSeq->SetCyclic(1);
		$uniChainSeq->SetFeatures( $result{"edges"} );
		$uniChainSeq->SetModified( $result{"changes"} );

	}
	else {

		$uniChainSeq->SetCyclic(0);
	}

	# 4) find if chain has foot down
	my @foots = grep { defined $_->{"att"}->{".foot_down"} } @features;

	if ( scalar(@foots) ) {

		$uniChainSeq->SetFootsDown(\@foots);
	}

	# 5) Set features type
	if ( $features[0]->{"type"} =~ /s/i ) {
		$uniChainSeq->SetFeatureType( Enums->FeatType_SURF );
	}
	else {
		$uniChainSeq->SetFeatureType( Enums->FeatType_LINEARC );
	}
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

	my @types = ( "surface", "pad" );
	$f->SetTypes( \@types );

	my @syms = ( "r500", "r1" );
	$f->AddIncludeSymbols( \[ "r500", "r1" ] );

	print $f->Select();

	print "fff";

}

1;

