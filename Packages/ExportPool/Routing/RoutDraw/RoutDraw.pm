#-------------------------------------------------------------------------------------------#
# Description: Contain listo of all tools in layer, regardless it is tool from surface, pad,
# lines..
# Responsible for tools are unique (diameter + typeProc)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ExportPool::Routing::RoutDraw::RoutDraw;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::Routing::RoutLayer::RoutDrawing::RoutDrawing';
use aliased 'Packages::Polygon::Features::RouteFeatures::RouteFeatures';

#use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';

#use aliased 'CamHelpers::CamAttributes';
#
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveLine';

#use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveArcSCE';
use aliased 'Packages::CAM::SymbolDrawing::Point';

#use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
#use aliased 'Packages::CAM::FeatureFilter::Enums' => "FilterEnums";
#use aliased 'Packages::Polygon::Features::Features::Features';
#use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';
#use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveText';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"stepList"} = shift;

	return $self;
}

# draw layer, where are signed start routs
sub DrawRoutFoots {
	my $self     = shift;
	my $layer    = shift;
	my @notFound = @{ shift(@_) };

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $fschLayer = "fsch";

	# Get all edges, where is attribute foot down
	my $parse = RouteFeatures->new();
	$parse->Parse( $inCAM, $jobId, $self->{"stepList"}->GetStep(), $fschLayer );
	my @features = $parse->GetFeatuers();

	my @foots = grep { defined $_->{"att"}->{".foot_down"} } @features;

	my @footsInf = ();
	foreach my $f (@foots) {

		my %inf = ( "angle" => 0, "result" => 1, "footEdge" => $f );
		push( @footsInf, \%inf );
	}

	my $routDrawing = RoutDrawing->new( $inCAM, $jobId, $self->{"stepList"}->GetStep(), $layer );
	$routDrawing->DrawFootRoutResult( \@footsInf );

	# Draw, where foot was not found
	CamLayer->WorkLayer($layer);
	my $draw = SymbolDrawing->new( $inCAM, $jobId );

	foreach my $stePlc (@notFound) {

		my $l1 =
		  PrimitiveLine->new( Point->new( $stePlc->GetXMin(), $stePlc->GetYMax() ), Point->new( $stePlc->GetXMax(), $stePlc->GetYMin() ), "r2000" );

		my $l2 =
		  PrimitiveLine->new( Point->new( $stePlc->GetXMin(), $stePlc->GetYMin() ), Point->new( $stePlc->GetXMax(), $stePlc->GetYMax() ), "r2000" );

		$draw->AddPrimitive($l1);
		$draw->AddPrimitive($l2);
	}

	$draw->Draw();

}

# draw layer, where are signed start routs
sub DrawOutlineOrder {
	my $self     = shift;
	my $layer    = shift;
	my @notFound = @{ shift(@_) };

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $fschLayer = "fsch";

	# Get all edges, where is attribute foot down
	my $parse = RouteFeatures->new();
	$parse->Parse( $inCAM, $jobId, $self->{"stepList"}->GetStep(), $fschLayer );
	my @features = $parse->GetFeatuers();

	my @foots = grep { defined $_->{"att"}->{".foot_down"} } @features;

	my @footsInf = ();
	foreach my $f (@foots) {

		my %inf = ( "angle" => 0, "result" => 1, "footEdge" => $f );
		push( @footsInf, \%inf );
	}

	my $routDrawing = RoutDrawing->new( $inCAM, $jobId, $self->{"stepList"}->GetStep(), $layer );
	$routDrawing->DrawFootRoutResult( \@footsInf );

	# Draw, where foot was not found
	CamLayer->WorkLayer($layer);
	my $draw = SymbolDrawing->new( $inCAM, $jobId );

	foreach my $stePlc (@notFound) {

		my $l1 =
		  PrimitiveLine->new( Point->new( $stePlc->GetXMin(), $stePlc->GetYMax() ), Point->new( $stePlc->GetXMax(), $stePlc->GetYMin() ), "r2000" );

		my $l2 =
		  PrimitiveLine->new( Point->new( $stePlc->GetXMin(), $stePlc->GetYMin() ), Point->new( $stePlc->GetXMax(), $stePlc->GetYMax() ), "r2000" );

		$draw->AddPrimitive($l1);
		$draw->AddPrimitive($l2);
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

