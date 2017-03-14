#-------------------------------------------------------------------------------------------#
# Description: Contain listo of all tools in layer, regardless it is tool from surface, pad,
# lines..
# Responsible for tools are unique (diameter + typeProc)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::RoutDrawing::RoutDrawing;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveLine';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveArcSCE';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAM::FeatureFilter::Enums' => "FilterEnums";
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;
	$self->{"layer"} = shift;

	return $self;
}

sub DrawRoute {
	my $self       = shift;
	my @sorteEdges = @{ shift(@_) };
	my $toolSize   = shift;
	my $comp       = shift;
	my $routStart  = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};
	my $layer = $self->{"layer"};

	my $routStartGuid = -1;

	CamHelper->SetStep( $inCAM, $step );
	CamLayer->WorkLayer( $inCAM, $layer );

	my $draw = SymbolDrawing->new( $inCAM, $self->{"jobId"} );

	my @groupGUIDs = ();

	# 1) Fill drawing with rout edges
	for ( my $i = 0 ; $i < scalar(@sorteEdges) ; $i++ ) {

		# draw rout
		my $primitive = undef;
		if ( $sorteEdges[$i]->{"type"} eq "L" ) {

			$primitive = PrimitiveLine->new(
											 Point->new( $sorteEdges[$i]->{"x1"}, $sorteEdges[$i]->{"y1"} ),
											 Point->new( $sorteEdges[$i]->{"x2"}, $sorteEdges[$i]->{"y2"} ),
											 "r400"
			);

			push( @groupGUIDs, $primitive->GetGroupGUID() );
		}
		elsif ( $sorteEdges[$i]{"type"} eq "A" ) {

			$primitive = PrimitiveArcSCE->new(
											   Point->new( $sorteEdges[$i]->{"x1"},   $sorteEdges[$i]->{"y1"} ),
											   Point->new( $sorteEdges[$i]->{"xmid"}, $sorteEdges[$i]->{"ymid"} ),
											   Point->new( $sorteEdges[$i]->{"x2"},   $sorteEdges[$i]->{"y2"} ),
											   $sorteEdges[$i]->{"newDir"},
											   "r400"
			);

			push( @groupGUIDs, $primitive->GetGroupGUID() );
		}

		$draw->AddPrimitive($primitive);

		# save GUID of start rout
		if ( $sorteEdges[$i]->{"id"} eq $routStart->{"id"} ) {

			$routStartGuid = $primitive->GetGroupGUID();
		}

	}

	# 2) get new number of chain (max number from exist chains +1)
	my $unitRTM = UniRTM->new( $inCAM, $jobId, $step, $layer );
	my $newChainNum = $unitRTM->GetMaxChainNumber() + 1;

	# 3) Draw new rout
	$draw->Draw();

	# 4) Select rout and do chain
	my $f = FeatureFilter->new( $inCAM, $jobId, $layer );

	foreach my $guid (@groupGUIDs) {
		$f->AddIncludeAtt( "feat_group_id", $guid );
	}

	$f->SetIncludeAttrCond( FilterEnums->Logic_OR );

	if ( $f->Select() ) {

		# 1) Get id of rout start feature
		my $layerFeat = Features->new();
		$layerFeat->Parse( $inCAM, $jobId, $step, $layer );
		my @feats = $layerFeat->GetFeatureByGroupGUID($routStartGuid);

		# feat for start should be only one
		if ( scalar(@feats) != 1 ) {
			die "Error when finding rout start feature";
		}

		

		$inCAM->COM(
			'chain_add',
			"layer"          => $layer,
			"chain"          => $newChainNum,
			"size"           => $toolSize / 1000,
			"comp"           => $comp,
			"first"          => $feats[0]->{"id"},
			"chng_direction" => 0
		);
	}
	
	$f->Reset();
}

sub DeleteRoute {
	my $self  = shift;
	my @edges = @{ shift(@_) };

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $layer = $self->{"layer"};
	my $step  = $self->{"step"};

	CamHelper->SetStep( $inCAM, $step );

	# Get id of rout start feature
	my $f = FeatureFilter->new( $inCAM, $jobId, $layer );

	my @ids = map { $_->{"id"} } @edges;
	$f->AddFeatureIndexes( \@ids );

	if ( $f->Select() ) {
		$inCAM->COM("sel_delete");
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

