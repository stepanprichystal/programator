
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnBuilder::MicrostripBuilders::MicrostripBuilderBase;

#3th party library
use strict;
use warnings;
use Math::Trig;

#local library
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::Coupon::CpnBuilder::CpnLayout::MicrostripLayout';
use aliased 'Packages::Coupon::Enums';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Coupon::Helper';
use aliased 'Packages::Coupon::CpnBuilder::CpnLayout::PadTextLayout';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}        = undef;
	$self->{"jobId"}        = undef;
	$self->{"settings"}     = undef;
	$self->{"stripVariant"} = undef;
	$self->{"layout"}    = MicrostripLayout->new();
	$self->{"padPosCnt"} = undef;                     # number of pad postitions placed horizontally side by side (1 or two) in probe measure area

	$self->{"layerCnt"} = undef;

	return $self;
}

sub Init {
	my $self = shift;

	$self->{"inCAM"}        = shift;
	$self->{"jobId"}        = shift;
	$self->{"settings"}     = shift;
	$self->{"stripVariant"} = shift;
	$self->{"cpnSingle"}    = shift;

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );
	
	my %activeArea = $self->{"cpnSingle"}->GetActiveArea();
	
	$self->{"activeArea"} = \%activeArea;

	my $xmlConstr = $self->_GetXmlConstr();

	# Set microstrip layout properties common for all microstrip types

	$self->{"layout"}->SetModel( $xmlConstr->GetModel() );    # model
 

	$self->{"layout"}->SetTrackLayer( Helper->GetInCAMLayer( $xmlConstr->GetOption("TRACE_LAYER"), $self->{"layerCnt"} ) );            #
	$self->{"layout"}->SetTopRefLayer( Helper->GetInCAMLayer( $xmlConstr->GetOption("TOP_MODEL_LAYER"), $self->{"layerCnt"} ) );       #
	$self->{"layout"}->SetBotRefLayer( Helper->GetInCAMLayer( $xmlConstr->GetOption("BOTTOM_MODEL_LAYER"), $self->{"layerCnt"} ) );    #

}

sub GetLayout {
	my $self = shift;

	return $self->{"layout"};

}

sub GetStripVariant {
	my $self = shift;

	return $self->{"stripVariant"};
}

#sub GetHeight{
#	my $self   = shift;
#
#	$self->{"stripVariant"}
#
#
#}

sub _GetPadText {
	my $self   = shift;
	my $origin = shift;
 
	my $text = Helper->GetLayerNum( $self->{"layout"}->GetTrackLayer(), $self->{"layerCnt"} );

	# built text positioon + negative rect position
	my $x    = $origin->X() - ( $self->{"settings"}->GetPadTextWidth() * length($text) ) / 2.5;
	my $xMir = $origin->X() + ( $self->{"settings"}->GetPadTextWidth() * length($text) ) / 2.5;
	my $y    = 0;

	if ( $self->{"stripVariant"}->Pool() == 0 ) {

		$y =  $self->{"activeArea"}->{"pos"}->Y() -  ($self->{"settings"}->GetPadTextDist() + $self->{"settings"}->GetPadTextHeight());

	}
	elsif ( $self->{"stripVariant"}->Pool() == 1 ) {

		$y =  $self->{"activeArea"}->{"pos"}->Y() +$self->{"activeArea"}->{"h"} +   $self->{"settings"}->GetPadTextDist();

	}

	# Built negative rectangle (for text putted to copper)
	my $rectW = $self->{"settings"}->GetPadTextWidth() * length($text) + 0.2;
	my $rectH = $self->{"settings"}->GetPadTextHeight()  + 0.2;
	my $rectPos =  Point->new( $x-0.1,   $y-0.1 );
	my $rectPosMir =  Point->new( $x+0.1,   $y-0.1 );

	return PadTextLayout->new( $text, Point->new( $x,   $y ), Point->new( $xMir, $y ), $rectW, $rectH, $rectPos, $rectPosMir);

}

sub _GetXmlConstr {
	my $self = shift;

	return $self->{"stripVariant"}->Data()->{"xmlConstraint"};
}

sub _GetSEStraightTrack {
	my $self   = shift;
	my $origin = shift;

	my @track = ();
	my $cpnSingleWidth = $self->{"settings"}->GetCpnSingleWidth();

	# start point
	push( @track, Point->new( $origin->X(), $origin->Y() ) );

	# end point

	if ( $self->{"settings"}->GetTwoEndedDesign() ) {

		push( @track, Point->new( $cpnSingleWidth - $origin->X(), $origin->Y() ) );
	}
	else {

		die "not implemented";
	}

	return @track;
}

sub _GetSingleDIFFTrack {
	my $self   = shift;
	my $origin = shift;
	my $type   = shift;    # upper/lower

	die "Only single strip " if ( $self->{"cpnSingle"}->IsMultistrip() );

	my $yTrackDir = ( $type eq "upper" ? -1 : 1 );

	my $p2pDist = $self->{"settings"}->GetTrackPad2TrackPad() / 1000;

	my $xmlConstr = $self->{"stripVariant"}->Data()->{"xmlConstraint"};
	my $w         = $xmlConstr->GetParamDouble("WB") / 1000;              # track width in mm
	my $s         = $xmlConstr->GetParamDouble("S") / 1000;               # track space in mm
	
	my $cpnSingleWidth = $self->{"settings"}->GetCpnSingleWidth();

	# Outer track
	my @track = ();

	# start point
	push( @track, Point->new( $origin->X(), $origin->Y() ) );

	# second point
	my $x2 = $origin->X() + ( $p2pDist / 2 - $s / 2 - $w / 2 ) * tan( deg2rad(45) );
	my $y2 = $origin->Y() + $yTrackDir * ( $p2pDist / 2 - $s / 2 - $w / 2 );
	push( @track, Point->new( $x2, $y2 ) );

	# third
	my $x3 = $cpnSingleWidth - $x2;
	my $y3 = $y2;
	push( @track, Point->new( $x3, $y3 ) );

	if ( $self->{"settings"}->GetTwoEndedDesign() ) {

		push( @track, Point->new( $cpnSingleWidth - $origin->X(), $origin->Y() ) );
	}
	else {

		die "not implemented";
	}

	return @track;
}

sub _GetMultistripSETrack {
	my $self   = shift;
	my $origin = shift;

	die "Only multistrip" if ( !$self->{"cpnSingle"}->IsMultistrip() );

	my @track = ();
	
	my $cpnSingleWidth = $self->{"settings"}->GetCpnSingleWidth();

	if ( $self->{"stripVariant"}->Route() eq Enums->Route_STREIGHT ) {

		@track = $self->_GetSEStraightTrack($origin);

	}
	else {

		my $yTrackDir = $self->{"stripVariant"}->Route() eq Enums->Route_ABOVE ? 1 : -1;

		# start point
		push( @track, Point->new( $origin->X(), $origin->Y() ) );

		# second point
		my $x2 = $origin->X() + $self->{"stripVariant"}->RouteDist() * tan( deg2rad(45) );
		my $y2 = $origin->Y() + $yTrackDir * $self->{"stripVariant"}->RouteDist();
		push( @track, Point->new( $x2, $y2 ) );

		# third
		my $x3 = $cpnSingleWidth - $x2;
		my $y3 = $y2;
		push( @track, Point->new( $x3, $y3 ) );

		if ( $self->{"settings"}->GetTwoEndedDesign() ) {

			push( @track, Point->new( $cpnSingleWidth - $origin->X(), $origin->Y() ) );
		}
		else {

			die "not implemented";
		}
	}

	return @track;
}

sub _GetMultistripDIFFTrackOuter {
	my $self   = shift;
	my $origin = shift;

	die "Only multistrip" if ( !$self->{"cpnSingle"}->IsMultistrip() );

	my $yTrackDir = $self->{"stripVariant"}->Route() eq Enums->Route_ABOVE ? 1 : -1;

	my $xmlConstr = $self->{"stripVariant"}->Data()->{"xmlConstraint"};
	my $w         = $xmlConstr->GetParamDouble("WB") / 1000;              # track width in mm
	my $s         = $xmlConstr->GetParamDouble("S") / 1000;               # track space in mm
	
	my $cpnSingleWidth = $self->{"settings"}->GetCpnSingleWidth();

	# Outer track
	my @track = ();

	# start point
	push( @track, Point->new( $origin->X(), $origin->Y() ) );

	# second point
	my $x2 = $origin->X() + ( $self->{"stripVariant"}->RouteDist() + $s / 2 + $w / 2 ) * tan( deg2rad(45) );
	my $y2 = $origin->Y() + $yTrackDir * ( $self->{"stripVariant"}->RouteDist() + $s / 2 + $w / 2 );
	push( @track, Point->new( $x2, $y2 ) );

	# third
	my $x3 = $cpnSingleWidth - $x2;
	my $y3 = $y2;
	push( @track, Point->new( $x3, $y3 ) );

	if ( $self->{"settings"}->GetTwoEndedDesign() ) {

		push( @track, Point->new( $cpnSingleWidth - $origin->X(), $origin->Y() ) );
	}
	else {

		die "not implemented";
	}

	return @track;
}

sub _GetMultistripDIFFTrackInner {
	my $self     = shift;
	my $origin   = shift;
	my $routeDir = shift;

	die "Only multistrip" if ( !$self->{"cpnSingle"}->IsMultistrip() );

	my $yTrackDir = $self->{"stripVariant"}->Route() eq Enums->Route_ABOVE ? 1 : -1;

	my $p2pDist = $self->{"settings"}->GetTrackPad2TrackPad() / 1000;    # in mm

	my $xmlConstr = $self->{"stripVariant"}->Data()->{"xmlConstraint"};
	my $w         = $xmlConstr->GetParamDouble("WB") / 1000;              # track width in mm
	my $s         = $xmlConstr->GetParamDouble("S") / 1000;               # track space in mm
	
	my $cpnSingleWidth = $self->{"settings"}->GetCpnSingleWidth();

	# Outer track
	my @track = ();

	# start point
	push( @track, Point->new( $origin->X(), $origin->Y() ) );

	# second point
	my $x2 = $origin->X() + ( $self->{"stripVariant"}->RouteDist() - $s / 2 - $w / 2 ) * tan( deg2rad(45) );
	my $y2 = $origin->Y() + $yTrackDir * ( $self->{"stripVariant"}->RouteDist() - $s / 2 - $w / 2 );
	push( @track, Point->new( $x2, $y2 ) );

	# third
	my $x3 = $cpnSingleWidth - $x2;
	my $y3 = $y2;
	push( @track, Point->new( $x3, $y3 ) );

	if ( $self->{"settings"}->GetTwoEndedDesign() ) {

		push( @track, Point->new( $cpnSingleWidth - $origin->X(), $origin->Y() ) );
	}

	return @track;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

