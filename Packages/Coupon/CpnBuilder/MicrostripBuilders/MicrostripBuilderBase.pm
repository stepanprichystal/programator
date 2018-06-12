
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

	$self->{"layers"} = [];

	return $self;
}

sub Init {
	my $self = shift;

	$self->{"inCAM"}        = shift;
	$self->{"jobId"}        = shift;
	$self->{"settings"}     = shift;
	$self->{"stripVariant"} = shift;
	$self->{"cpnSingle"}    = shift;

	# Set microstrip layout properties common for all microstrip types

	$self->{"layout"}->SetModel( $self->{"constrain"}->GetModel() );    # model

	# Get info about layers + translate to inCAM name notation
	my $cpnSource = $self->{"constrain"}->GetCpnSource();

	$self->{"layout"}->SetTrackLayer( $cpnSource->GetInCAMLayer( $self->{"constrain"}->GetOption("TRACE_LAYER") ) );            #
	$self->{"layout"}->SetTopRefLayer( $cpnSource->GetInCAMLayer( $self->{"constrain"}->GetOption("TOP_MODEL_LAYER") ) );       #
	$self->{"layout"}->SetBotRefLayer( $cpnSource->GetInCAMLayer( $self->{"constrain"}->GetOption("BOTTOM_MODEL_LAYER") ) );    #

}

sub GetLayout {
	my $self = shift;

	return $self->{"layout"};

}

sub _GetSEStraightTrack {
	my $self   = shift;
	my $origin = shift;

	my $areaW = $self->{"settings"}->GetAreaWidth();
	my @track = ();

	# start point
	push( @track, Point->new( $origin->X(), $origin->Y() ) );

	# end point

	if ( $self->{"settings"}->GetTwoEndedDesign() ) {

		push( @track, Point->new( $areaW - $origin->X(), $origin->Y() ) );
	}
	else {

		die "not implemented";
	}

	return @track;
}

sub _GetSingleDIFFTrack {
	my $self     = shift;
	my $origin   = shift;
	my $type = shift; # top/bot
	

	die "Only single strip " if ( $self->{"cpnSingle"}->IsMultistrip() );

	my $yTrackDir = ($type eq "top" ? -1 : 1);
	my $areaW = $self->{"settings"}->GetAreaWidth();
	my $p2pDist   = $self->{"settings"}->GetTracePad2tracePad() / 1000;  

	my $xmlConstr = $self->{"stripVariant"}->Data()->{"xmlConstraint"};
	my $w         = $xmlConstr->GetParamDouble("WB") / 1000;              # track width in mm
	my $s         = $xmlConstr->GetParamDouble("S") / 1000;               # track space in mm

	# Outer track
	my @track = ();

	# start point
	push( @track, Point->new( $origin->X(), $origin->Y() ) );

	# second point
	my $x2 = $origin->X() + ( $p2pDist/2 - $s / 2 - $w / 2 ) * tan( deg2rad(45) );
	my $y2 = $origin->Y() + ($type eq "top" ? $p2pDist : 0)   + $yTrackDir*( $p2pDist/2 - $s / 2 - $w / 2);
	push( @track, Point->new( $x2, $y2 ) );

	# third
	my $x3 = $areaW - $x2;
	my $y3 = $y2;
	push( @track, Point->new( $x3, $y3 ) );

	if ( $self->{"settings"}->GetTwoEndedDesign() ) {

		push( @track, Point->new( $areaW - $origin->X(), $origin->Y() ) );
	}
	else {

		die "not implemented";
	}

	return @track;
}



sub _GetMultistripSETrack {
	my $self     = shift;
	my $origin   = shift;
 
	die "Only multistrip" if ( !$self->{"cpnSingle"}->IsMultistrip() );

	my $yTrackDir = $self->{"stripVariant"}->Route() eq Enums->Route_ABOVE ? 1 : -1;
	my $areaW     = $self->{"settings"}->GetAreaWidth();
	my @track     = ();

	# start point
	push( @track, Point->new( $origin->X(), $origin->Y() ) );

	# second point
	my $x2 = $origin->X() + $self->{"stripVariant"}->RouteDist() * tan( deg2rad(45) );
	my $y2 = $origin->Y() + $yTrackDir * $self->{"stripVariant"}->RouteDist();
	push( @track, Point->new( $x2, $y2 ) );

	# third
	my $x3 = $areaW - $x2;
	my $y3 = $y2;
	push( @track, Point->new( $x3, $y3 ) );

	if ( $self->{"settings"}->GetTwoEndedDesign() ) {

		push( @track, Point->new( $areaW - $origin->X(), $origin->Y() ) );
	}
	else {

		die "not implemented";
	}

	return @track;
}

sub _GetMultistripDIFFTrackOuter {
	my $self     = shift;
	my $origin   = shift;
 
	die "Only multistrip" if ( !$self->{"cpnSingle"}->IsMultistrip() );

	my $yTrackDir = $self->{"stripVariant"}->Route() eq Enums->Route_ABOVE ? 1 : -1;
	my $areaW = $self->{"settings"}->GetAreaWidth();

	my $xmlConstr = $self->{"stripVariant"}->Data()->{"xmlConstraint"};
	my $w         = $xmlConstr->GetParamDouble("WB") / 1000;              # track width in mm
	my $s         = $xmlConstr->GetParamDouble("S") / 1000;               # track space in mm

	# Outer track
	my @track = ();

	# start point
	push( @track, Point->new( $origin->X(), $origin->Y() ) );

	# second point
	my $x2 = $origin->X() + ( $self->{"stripVariant"}->RouteDist() + $s / 2 + $w / 2 ) * tan( deg2rad(45) );
	my $y2 = $origin->Y() + $yTrackDir * ( $self->{"stripVariant"}->RouteDist() + $s / 2 + $w / 2 );
	push( @track, Point->new( $x2, $y2 ) );

	# third
	my $x3 = $areaW - $x2;
	my $y3 = $y2;
	push( @track, Point->new( $x3, $y3 ) );

	if ( $self->{"settings"}->GetTwoEndedDesign() ) {

		push( @track, Point->new( $areaW - $origin->X(), $origin->Y() ) );
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
	my $areaW     = $self->{"settings"}->GetAreaWidth();
	my $p2pDist   = $self->{"settings"}->GetTracePad2tracePad() / 1000;                # in mm

	my $xmlConstr = $self->{"stripVariant"}->Data()->{"xmlConstraint"};
	my $w         = $xmlConstr->GetParamDouble("WB") / 1000;                           # track width in mm
	my $s         = $xmlConstr->GetParamDouble("S") / 1000;                            # track space in mm

	# Outer track
	my @track = ();

	# start point
	push( @track, Point->new( $origin->X() + $p2pDist, $origin->Y() ) );

	# second point
	my $x2 = $origin->X() + $p2pDist + ( $self->{"stripVariant"}->RouteDist() - $s / 2 - $w / 2 ) * tan( deg2rad(45) );
	my $y2 = $origin->Y() + $yTrackDir * ( $self->{"stripVariant"}->RouteDist() - $s / 2 - $w / 2 );
	push( @track, Point->new( $x2, $y2 ) );

	# third
	my $x3 = $areaW - $x2;
	my $y3 = $y2;
	push( @track, Point->new( $x3, $y3 ) );

	if ( $self->{"settings"}->GetTwoEndedDesign() ) {

		push( @track, Point->new( $areaW - $origin->X(), $origin->Y() ) );
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

