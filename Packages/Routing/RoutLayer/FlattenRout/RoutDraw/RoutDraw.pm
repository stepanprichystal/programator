#-------------------------------------------------------------------------------------------#
# Description: Create/draw result  of flattened layer to new layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::FlattenRout::RoutDraw::RoutDraw;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::Routing::RoutLayer::RoutDrawing::RoutDrawing';
use aliased 'Packages::Polygon::Features::RouteFeatures::RouteFeatures';
use aliased 'Packages::Polygon::PointsTransform';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveLine';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveText';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}     = shift;
	$self->{"jobId"}     = shift;
	$self->{"step"}      = shift;
	$self->{"flatLayer"} = shift;

	return $self;
}

sub CreateResultLayer {
	my $self         = shift;
	my $notFound     = shift;
	my $stepPlcOrder = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Create result layer

	my $lName = "rout_order_result";

	if ( CamHelper->LayerExists( $inCAM, $jobId, $lName ) ) {
		$inCAM->COM( 'delete_layer', "layer" => $lName );
	}

	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'rout', polarity => 'positive', ins_layer => '' );

	# Draw foots
	$self->__DrawRoutFoots( $lName, $notFound );

	# Draw tool order
	$self->__DrawOutlineOrder( $lName, $stepPlcOrder );

}

# draw layer, where are signed start routs
sub __DrawRoutFoots {
	my $self     = shift;
	my $layer    = shift;
	my @notFound = @{ shift(@_) };

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Get all edges, where is attribute foot down
	my $parse = RouteFeatures->new();
	$parse->Parse( $inCAM, $jobId, $self->{"step"}, $self->{"flatLayer"} );
	my @features = $parse->GetFeatures();

	my @foots = grep { defined $_->{"att"}->{".foot_down"} } @features;

	my @footsInf = ();
	foreach my $f (@foots) {

		my %inf = ( "angle" => 0, "result" => 1, "footEdge" => $f );
		push( @footsInf, \%inf );
	}

	my $routDrawing = RoutDrawing->new( $inCAM, $jobId, $self->{"step"}, $layer );
	$routDrawing->DrawFootRoutResult( \@footsInf, 0, 1 );

	# Draw, where foot was not found
	CamLayer->WorkLayer( $inCAM, $layer );

	# hash contain:
	# stepRotation - object of StepRotation
	# outlineChaibSeq - UniChainSeq
	foreach my $inf (@notFound) {

		#get limit of rout points
		my @points = ();
		foreach my $e ( $inf->{"outlineChaibSeq"}->GetFeatures() ) {

			my %p1 = ( "x" => $e->{"x1"}, "y" => $e->{"y1"} );
			my %p2 = ( "x" => $e->{"x2"}, "y" => $e->{"y2"} );
			push( @points, ( \%p1, \%p2 ) );
		}

		my %lim = PointsTransform->GetLimByPoints( \@points );

		my @repeatsSR = CamStepRepeat->GetRepeatStep( $inCAM, $jobId, $self->{"step"} );

		@repeatsSR = grep { $_->{"stepName"} eq $inf->{"stepRotation"}->GetStepName()  && $_->{"angle"} eq $inf->{"stepRotation"}->GetAngle() } @repeatsSR;

		foreach my $rStep (@repeatsSR) {

			#foreach my $stepPlc ( $inf->{"stepRotation"} ) {
			my $draw = SymbolDrawing->new( $inCAM, $jobId, Point->new( $rStep->{"originX"}, $rStep->{"originY"} ) );

			my $l1 =
			  PrimitiveLine->new( Point->new( $lim{"xMin"}, $lim{"yMax"} ), Point->new( $lim{"xMax"}, $lim{"yMin"} ), "r800" );

			my $l2 =
			  PrimitiveLine->new( Point->new( $lim{"xMin"}, $lim{"yMin"} ), Point->new( $lim{"xMax"}, $lim{"yMax"} ), "r800" );

			$draw->AddPrimitive($l1);
			$draw->AddPrimitive($l2);

			$draw->Draw();
		}

	}
}

# draw layer, where are signed start routs
sub __DrawOutlineOrder {
	my $self         = shift;
	my $layer        = shift;
	my @chainOrderId = @{ shift(@_) };

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Get all edges, where is attribute foot down
	my $parse = RouteFeatures->new();
	$parse->Parse( $inCAM, $jobId, $self->{"step"}, $self->{"flatLayer"} );

	# Draw, where foot was not found
	CamLayer->WorkLayer( $inCAM, $layer );
	my $draw = SymbolDrawing->new( $inCAM, $jobId );

	my $order = 1;
	foreach my $chainId (@chainOrderId) {

		#get limit of rout points
		my @points = ();
		foreach my $e ( $parse->GetFeatureByGroupGUID($chainId) ) {
			my %p1 = ( "x" => $e->{"x1"}, "y" => $e->{"y1"} );
			my %p2 = ( "x" => $e->{"x2"}, "y" => $e->{"y2"} );
			push( @points, ( \%p1, \%p2 ) );
		}

		my %lim = PointsTransform->GetLimByPoints( \@points );

		my $txt = PrimitiveText->new(
									  $order,
									  Point->new(
												  ( ( $lim{"xMax"} - $lim{"xMin"} ) / 2 ) + $lim{"xMin"},
												  ( ( $lim{"yMax"} - $lim{"yMin"} ) / 2 ) + $lim{"yMin"}
									  ),
									  8, 3
		);
		$draw->AddPrimitive($txt);

		$order++;
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

