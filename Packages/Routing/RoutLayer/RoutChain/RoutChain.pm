#-------------------------------------------------------------------------------------------#
# Description: Contain listo of all tools in layer, regardless it is tool from surface, pad,
# lines..
# Responsible for tools are unique (diameter + typeProc)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::RoutChain::RoutChain;

#3th party library
use strict;
use warnings;

#local library
 

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#
 

sub SetFootDown {
	my $self       = shift;
	my @outlineFeatures = @{ shift(@_) }; 
	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;
	$self->{"layer"}  = shift;

	


	my $footDown = undef;
	
	# determine foot down edge by rout start
	if ($setFootAtt) {
		my @s = @{$serverRef};
		my $idx = ( grep { $sorteEdges[$_] == $routStart } 0 .. $#sorteEdges )[0];

		if ( $idx == 0 ) {
			$footDown = $sorteEdges[ scalar(@sorteEdges) ];
		}
		else {
			$footDown = $sorteEdges[ scalar(@sorteEdges) - 1 ];
		}

		if ( !defined $footDownEdge ) {
			die "Foot down edge was not found";
		}
	}

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};
	my $layer = $self->{"layer"};

	my $routStartGuid = -1;
	my $footDownGuid = -1;

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
		
		 # save GUID of start rout
		if ( $sorteEdges[$i]->{"id"} eq $footDown->{"id"} ) {

			$footDownGuid = $primitive->GetGroupGUID();
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

		
		# 1) Set rout start of chain

		#  Get id of rout start feature
		my $layerFeat = Features->new();
		$layerFeat->Parse( $inCAM, $jobId, $step, $layer );
		my @feats = $layerFeat->GetFeatureByGroupGUID($routStartGuid);

		# feat for start should be only one
		if ( scalar(@feats) != 1 ) {
			die "Error when finding rout start feature";
		}

		# In order rout has proper direction CW
		# First add route as none, then xhange to left

		$inCAM->COM(
			'chain_add',
			"layer"          => $layer,
			"chain"          => $newChainNum,
			"size"           => $toolSize / 1000,
			"comp"           => $comp,
			"first"          => $feats[0]->{"id"} - 1,    # id of edge, which should route start - 1 (-1 is necessary)
			"chng_direction" => 0
		);

		# 2) Set foot down attribute
		#  Get id of rout start feature
		my $layerFeat = Features->new();
		$layerFeat->Parse( $inCAM, $jobId, $step, $layer );
		my @feats = $layerFeat->GetFeatureByGroupGUID($routStartGuid);

		# feat for start should be only one
		if ( scalar(@feats) != 1 ) {
			die "Error when finding rout start feature";
		}
		
		

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

# draw layer, where are signed start routs
sub DrawStartRoutResult {
	my $self   = shift;
	my @starts = @{ shift(@_) };

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};
	my $layer = $self->{"layer"};

	CamHelper->SetStep( $inCAM, $step );
	CamLayer->WorkLayer( $inCAM, $layer );

	my $draw = SymbolDrawing->new( $inCAM, $self->{"jobId"} );

	my $primitive = undef;

	# prepare text, no foot find
	my @noFoots = grep { $_->{"result"} == 0 } @starts;

	if ( scalar(@noFoots) ) {
		@noFoots = map { $_->{"angle"} . " deg" } @noFoots;
		my $str = "NOT FIND FOOTS: " . join( "; ", @noFoots );

		$draw->AddPrimitive( PrimitiveText->new( $str, Point->new( 0, -20 ), 5, 2 ) );
	}

	foreach my $start (@starts) {

		unless ( $start->{"result"} ) {

			next;
		}

		if ( $start->{"startEdge"}->{"type"} eq "L" ) {

			$primitive = PrimitiveLine->new(
											 Point->new( $start->{"startEdge"}->{"x1"}, $start->{"startEdge"}->{"y1"} ),
											 Point->new( $start->{"startEdge"}->{"x2"}, $start->{"startEdge"}->{"y2"} ),
											 "r3000"
			);

		}
		elsif ( $start->{"startEdge"}->{"type"} eq "A" ) {

			$primitive = PrimitiveArcSCE->new(
											   Point->new( $start->{"startEdge"}->{"x1"},   $start->{"startEdge"}->{"y1"} ),
											   Point->new( $start->{"startEdge"}->{"xmid"}, $start->{"startEdge"}->{"ymid"} ),
											   Point->new( $start->{"startEdge"}->{"x2"},   $start->{"startEdge"}->{"y2"} ),
											   $start->{"startEdge"}->{"newDir"},
											   "r3000"
			);

		}

		$draw->AddPrimitive($primitive);

		# ad tect

		my $txt = PrimitiveText->new( "Foot: " . $start->{"angle"} . "deg",
									  Point->new( $start->{"startEdge"}->{"x2"} - 30, $start->{"startEdge"}->{"y2"} - 10 ),
									  2.2, 1.2 );
		$draw->AddPrimitive($txt);

	}

	$draw->Draw();

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

