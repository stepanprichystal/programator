#-------------------------------------------------------------------------------------------#
# Description: Contain functions for drawing rout, displaying rout foot etc..
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
use aliased 'CamHelpers::CamAttributes';

use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveLine';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveArcSCE';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitivePad';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAM::FeatureFilter::Enums' => "FilterEnums";
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Packages::CAM::UniRTM::UniRTM';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveText';
use aliased 'Packages::CAM::SymbolDrawing::Symbol::SymbolBase';

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
	my $self        = shift;
	my @sorteEdges  = @{ shift(@_) };
	my $toolSize    = shift;
	my $comp        = shift;
	my $routStart   = shift;
	my $setFootAtt  = shift;            # if set foot down attribute
	my $keepFeatAtt = shift;            # Array of feature attribut name, which will be keepd in new created rout

	my $footDown = undef;

	# determine foot down edge by rout start
	if ($setFootAtt) {

		my $idx = ( grep { $sorteEdges[$_] == $routStart } 0 .. $#sorteEdges )[0];

		if ( $idx == 0 ) {
			$footDown = $sorteEdges[ scalar(@sorteEdges) ];
		}
		else {
			$footDown = $sorteEdges[ $idx - 1 ];
		}

		if ( !defined $footDown ) {
			die "Foot down edge was not found";
		}
	}

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};
	my $layer = $self->{"layer"};

	my $routStartGuid = -1;
	my $footDownGuid  = -1;

	CamHelper->SetStep( $inCAM, $step );
	CamLayer->WorkLayer( $inCAM, $layer );

	my $draw = SymbolDrawing->new( $inCAM, $self->{"jobId"} );

	# 1) create one symbol which will contains all rout edges
	my $routSym = SymbolBase->new();
	$draw->AddSymbol($routSym);

	# contain groupGUID of all edges of rout chain
	# - foot down edge; rout start edge has own guid
	# - other rout edges will contain same "groupGUID" value as symbol
	my @specGroupGUIDs = ();
	push( @specGroupGUIDs, $routSym->GetGroupGUID() );

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

		}
		elsif ( $sorteEdges[$i]{"type"} eq "A" ) {

			$primitive = PrimitiveArcSCE->new(
											   Point->new( $sorteEdges[$i]->{"x1"},   $sorteEdges[$i]->{"y1"} ),
											   Point->new( $sorteEdges[$i]->{"xmid"}, $sorteEdges[$i]->{"ymid"} ),
											   Point->new( $sorteEdges[$i]->{"x2"},   $sorteEdges[$i]->{"y2"} ),
											   $sorteEdges[$i]->{"newDir"},
											   "r400"
			);

		}

		# Check if some attributes shlould be kept
		if ($keepFeatAtt) {

			foreach my $attName ( @{$keepFeatAtt} ) {
				$primitive->AddAttribute( $attName, $sorteEdges[$i]->{"att"}->{$attName} );
			}
		}

		# save GUID of start rout
		if ( $sorteEdges[$i]->{"id"} eq $routStart->{"id"} ) {

			$routSym->SetPassGUID2prim(0);
			$routSym->AddPrimitive($primitive);
			$routSym->SetPassGUID2prim(1);

			$routStartGuid = $primitive->GetGroupGUID();
			push( @specGroupGUIDs, $routStartGuid );
		}

		# save GUID of start rout
		elsif ( $setFootAtt && $sorteEdges[$i]->{"id"} eq $footDown->{"id"} ) {

			$routSym->SetPassGUID2prim(0);
			$routSym->AddPrimitive($primitive);
			$routSym->SetPassGUID2prim(1);

			$footDownGuid = $primitive->GetGroupGUID();
			push( @specGroupGUIDs, $footDownGuid );
		}
		else {

			$routSym->AddPrimitive($primitive);
		}

	}

	# 2) get new number of chain (max number from exist chains +1)
	my $unitRTM = UniRTM->new( $inCAM, $jobId, $step, $layer );
	my $newChainNum = $unitRTM->GetMaxChainNumber() + 1;

	# 3) Draw new rout
	$draw->Draw();

	# 4) Select rout and do chain
	my $f = FeatureFilter->new( $inCAM, $jobId, $layer );

	$f->SetIncludeAttrCond( FilterEnums->Logic_OR );

	foreach my $groupGUID (@specGroupGUIDs) {
		$f->AddIncludeAtt( "feat_group_id", $groupGUID );
	}

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

		# Set foot down attribute

		if ($setFootAtt) {

			my $f = FeatureFilter->new( $inCAM, $jobId, $self->{"layer"} );
			$f->AddIncludeAtt( "feat_group_id", $footDownGuid );

			if ( $f->Select() == 1 ) {
				CamAttributes->SetFeaturesAttribute( $inCAM, $jobId, ".foot_down" );

			}
			else {
				die "One Foot down feature was not selected\n";
			}
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

	# if there is too much feature ids, split it and delete rout in cycle

	my @idsPart = ();

	# each loop delete 20 edges
	for ( my $i = 0 ; $i < scalar(@ids) ; $i++ ) {

		push( @idsPart, $ids[$i] );

		if ( scalar(@idsPart) == 20 ) {
			$f->AddFeatureIndexes( \@idsPart );

			if ( $f->Select() ) {
				$inCAM->COM("sel_delete");
			}
			$f->Reset();
			@idsPart = ();
		}
	}

	# delete rest of edges
	if ( scalar(@idsPart) ) {
		$f->AddFeatureIndexes( \@idsPart );
		if ( $f->Select() ) {

			$inCAM->COM("sel_delete");
			$f->Reset();
		}
	}

}

# draw layer, where are signed start routs
sub DrawFootRoutResult {
	my $self          = shift;
	my @foots         = @{ shift(@_) };
	my $drawLabel     = shift;
	my $drawStartRout = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};
	my $layer = $self->{"layer"};

	CamHelper->SetStep( $inCAM, $step );
	CamLayer->WorkLayer( $inCAM, $layer );

	my $draw = SymbolDrawing->new( $inCAM, $self->{"jobId"} );

	my $primitive = undef;

	# prepare text, no foot find
	my @noFoots = grep { $_->{"result"} == 0 } @foots;

	if ( scalar(@noFoots) ) {
		@noFoots = map { $_->{"angle"} . " deg" } @noFoots;
		my $str = "NOT FIND FOOTS: " . join( "; ", @noFoots );

		$draw->AddPrimitive( PrimitiveText->new( $str, Point->new( 0, -20 ), 5, undef, 2 ) );
	}

	foreach my $foot (@foots) {

		unless ( $foot->{"result"} ) {

			next;
		}

		if ( $foot->{"footEdge"}->{"type"} eq "L" ) {

			$primitive = PrimitiveLine->new(
											 Point->new( $foot->{"footEdge"}->{"x1"}, $foot->{"footEdge"}->{"y1"} ),
											 Point->new( $foot->{"footEdge"}->{"x2"}, $foot->{"footEdge"}->{"y2"} ),
											 "r3000"
			);

		}
		elsif ( $foot->{"footEdge"}->{"type"} eq "A" ) {

			# Direction is defined, depand on which source features come..
			my $dir = $foot->{"footEdge"}->{"newDir"};
			if ( !defined $dir ) {
				$dir = $foot->{"footEdge"}->{"oriDir"};
			}

			$primitive = PrimitiveArcSCE->new(
											   Point->new( $foot->{"footEdge"}->{"x1"},   $foot->{"footEdge"}->{"y1"} ),
											   Point->new( $foot->{"footEdge"}->{"xmid"}, $foot->{"footEdge"}->{"ymid"} ),
											   Point->new( $foot->{"footEdge"}->{"x2"},   $foot->{"footEdge"}->{"y2"} ),
											   $dir,
											   "r3000"
			);

		}

		$draw->AddPrimitive($primitive);

		# ad tect

		if ($drawLabel) {
			my $txt = PrimitiveText->new( "Foot: " . $foot->{"angle"} . "deg",
										  Point->new( $foot->{"footEdge"}->{"x2"} - 30, $foot->{"footEdge"}->{"y2"} - 10 ),
										  2.2, undef, 1.2 );
			$draw->AddPrimitive($txt);
		}

		if ($drawStartRout) {
			my $pad = PrimitivePad->new( "r5000", Point->new( $foot->{"footEdge"}->{"x2"}, $foot->{"footEdge"}->{"y2"} ) );
			$draw->AddPrimitive($pad);
		}

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

