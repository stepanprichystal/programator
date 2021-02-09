#-------------------------------------------------------------------------------------------#
# Description: Contain listo of all tools in layer, regardless it is tool from surface, pad,
# lines..
# Responsible for tools are unique (diameter + typeProc)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniRTM::UniRTM::UniRTMBase;

#3th party library
use strict;
use warnings;
use XML::Simple;

#local library

use aliased 'Packages::Polygon::Enums' => "PolyEnums";
use aliased 'Packages::CAM::UniRTM::UniRTM::Parser::RoutParser';
use aliased 'Packages::CAM::UniRTM::UniRTM::Parser::ChainParser';
use aliased 'Packages::Polygon::Polygon::PolygonPoints';
use aliased 'Packages::CAM::UniRTM::UniRTM::Parser::ChainToolParser';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	my $inCAM = shift;
	my $jobId = shift;
	$self->{"step"}  = shift;
	$self->{"layer"} = shift;

	$self->{"breakSR"}        = shift;
	$self->{"uniDTM"}         = shift;         # if passed, UniDTMTools def will be assign to UniDTMTools def
	$self->{"multiChainInit"} = shift // 0;    # Init UniMultiChainSeq list, default no, it takes extra time

	$self->{"features"}          = [];
	$self->{"chains"}            = [];
	$self->{"chainList"}         = [];
	$self->{"multiChainSeqList"} = [];

	$self->{"innerRout"}     = undef;
	$self->{"outerRout"}     = undef;
	$self->{"outerBrdgRout"} = undef;

	$self->__InitUniRTM($inCAM, $jobId);

	return $self;
}

# return chains sorted by chain order
sub GetChains {
	my $self = shift;

	my @chains = @{ $self->{"chains"} };

	@chains = sort { $a->GetChainOrder() <=> $b->GetChainOrder() } @chains;

	return @chains;
}

sub GetChainSequences {
	my $self = shift;

	my @seqs = map { $_->GetChainSequences() } @{ $self->{"chains"} };

	return @seqs;
}

sub GetChainList {
	my $self = shift;

	return @{ $self->{"chainList"} };
}

sub GetMultiChainSeqList {
	my $self = shift;

	die "Multi chain sequences are not initialized" unless ( $self->{"multiChainInit"} );

	return @{ $self->{"multiChainSeqList"} };
}

sub __InitUniRTM {
	my $self = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	
	my $step    = $self->{"step"};
	my $layer   = $self->{"layer"};
	my $breakSR = $self->{"breakSR"};

	# 1) Parse features
	my @features = RoutParser->GetFeatures( $inCAM, $jobId, $step, $layer, $breakSR );
	$self->{"features"} = \@features;

	# 2) Get route chain list
	my @chainList = ChainToolParser->GetChainList( \@features, $self->{"uniDTM"} );
	$self->{"chainList"} = \@chainList;

	# 2) Get route chains by same .rout_tool atribute
	my @chains = ChainParser->GetChains( \@chainList, \@features );
	$self->{"chains"} = \@chains;

	# 4) Get information about mutual position of chain sequences
	# If chain is inside another chain, save this information

	my @seqs = map { $_->GetChainSequences() } @chains;    # all chain sequences
	
	# Desiding if cyclic rout is inside or outside another chain maz take long time
	print STDERR "Too much rout sequence (".scalar(@seqs)."), takes time" if(scalar(@seqs) > 1000);

	for ( my $i = 0 ; $i < scalar(@seqs) ; $i++ ) {

		for ( my $j = 0 ; $j < scalar(@seqs) ; $j++ ) {

			if ( $i == $j ) {
				next;
			}

			#print STDERR "$i-$j\n";

			my $seqIn  = $seqs[$i];
			my $seqOut = $seqs[$j];

			if ( $seqOut->GetCyclic() ) {

				my @seqInPoints  = $seqIn->GetShapePoints();
				my @seqOutPoints = $seqOut->GetShapePoints();

				my $pos = undef;

				if ( $seqIn->GetCyclic() ) {
					$pos = PolygonPoints->GetPoly2PolyIntersect( \@seqInPoints, \@seqOutPoints );
				}
				else {
					$pos = PolygonPoints->GetPoints2PolygonPosition( \@seqInPoints, \@seqOutPoints );
				}

				if ( $pos ne PolyEnums->Pos_OUTSIDE ) {
					$seqIn->SetIsInside(1);
					$seqIn->AddOutsideChainSeq($seqOut);
				}
			}
		}
	}

	# 5) Init multi chain seq
	if ( $self->{"multiChainInit"}  && scalar(@{$self->{"chains"}})) {

		my @uniMChSeq = ChainParser->GetMultiChainSequences( $self->{"chains"} );
		$self->{"multiChainSeqList"} = \@uniMChSeq;

		# Get information about mutual position of chain sequences
		# If chain is inside another chain, save this information
		for ( my $i = 0 ; $i < scalar(@uniMChSeq) ; $i++ ) {

			for ( my $j = 0 ; $j < scalar(@uniMChSeq) ; $j++ ) {

				if ( $i == $j ) {
					next;
				}

				my $seqIn  = $uniMChSeq[$i];
				my $seqOut = $uniMChSeq[$j];

				if ( $seqOut->GetCyclic() ) {

					my @seqInPoints  = $seqIn->GetShapePoints();
					my @seqOutPoints = $seqOut->GetShapePoints();

					my $pos = undef;

					if ( $seqIn->GetCyclic() ) {
						$pos = PolygonPoints->GetPoly2PolyIntersect( \@seqInPoints, \@seqOutPoints );
					}
					else {
						$pos = PolygonPoints->GetPoints2PolygonPosition( \@seqInPoints, \@seqOutPoints );
					}

					if ( $pos ne PolyEnums->Pos_OUTSIDE ) {
						$seqIn->SetIsInside(1);
						$seqIn->AddOutsideMultiChainSeq($seqOut);
					}
				}
			}

		}
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

