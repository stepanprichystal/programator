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

	CamHelper->SetStep( $inCAM, $step );
	CamLayer->WorkLayer( $inCAM, $layer );

	my $draw = SymbolDrawing->new($inCAM);

	#switch start and end point of edges
	for ( my $i = 0 ; $i < scalar(@sorteEdges) ; $i++ ) {

		# draw rout

		if ( $sorteEdges[$i]->{"type"} eq "L" ) {

			my $line = PrimitiveLine->new(
										   Point->new( $sorteEdges[$i]->{"x1"}, $sorteEdges[$i]->{"y1"} ),
										   Point->new( $sorteEdges[$i]->{"x2"}, $sorteEdges[$i]->{"y2"} ),
										   "r400"
			);

			$draw->AddPrimitive($line);

		}
		elsif ( $sorteEdges[$i]{"type"} eq "A" ) {

			my $arc = PrimitiveArcSCE->new(
											Point->new( $sorteEdges[$i]->{"x1"},   $sorteEdges[$i]->{"y1"} ),
											Point->new( $sorteEdges[$i]->{"xmid"}, $sorteEdges[$i]->{"ymid"} ),
											Point->new( $sorteEdges[$i]->{"x2"},   $sorteEdges[$i]->{"y2"} ),
											$sorteEdges[$i]->{"newDir"},
											"r400"
			);

			$draw->AddPrimitive($arc);
		}

	}

	my @ids = $draw->Draw();

	my $f = FeatureFilter->new( $inCAM, $jobId, $step );
	$f->AddFeatureIndexes( \@ids );
	if ( $f->Select() ) {

		$inCAM->COM(
			'chain_add',
			"layer" => $layer,
			"chain" => 1,
			"size"  => $toolSize / 1000,
			"comp"  => $comp,

			#first          => "$startId",
			"chng_direction" => 0
		);
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

