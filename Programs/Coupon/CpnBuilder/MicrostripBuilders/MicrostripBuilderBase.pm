
#-------------------------------------------------------------------------------------------#
# Description: Microstrip builder is responsible for compute microstrip layout
# Pad, track, texts positions, etc..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::MicrostripBuilders::MicrostripBuilderBase;

#3th party library
use strict;
use warnings;
use Math::Trig;

#local library
use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::PointLayout';
use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::MicrostripLayout';
use aliased 'Programs::Coupon::Enums';
use aliased 'CamHelpers::CamJob';
use aliased 'Programs::Coupon::Helper';
use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::PadTextLayout';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = undef;
	$self->{"jobId"} = undef;

	$self->{"layout"}       = MicrostripLayout->new();    # Layout of one single strip
	$self->{"build"}        = 0;                          # indicator if layout was built
	$self->{"stripVariant"} = undef;

	# Settings references
	$self->{"cpnSett"}       = undef;
	$self->{"cpnSingleSett"} = undef;
	$self->{"cpnStripSett"}  = undef;

	# Other helper properties

	$self->{"layerCnt"}  = undef;
	$self->{"cpnSingle"} = undef;

	return $self;
}

sub Init {
	my $self = shift;

	$self->{"inCAM"}     = shift;
	$self->{"jobId"}     = shift;
	$self->{"cpnSingle"} = shift;

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	my %activeArea = $self->{"cpnSingle"}->GetActiveArea();

	$self->{"activeArea"} = \%activeArea;

}

sub Build {
	my $self          = shift;
	my $stripVariant  = shift;
	my $cpnSett       = shift;
	my $cpnSingleSett = shift;

	$self->{"stripVariant"}  = $stripVariant;
	$self->{"cpnSett"}       = $cpnSett;
	$self->{"cpnSingleSett"} = $cpnSingleSett;

	my $cpnStripSett = $stripVariant->GetCpnStripSettings();

	# build common settings for all st
	$self->{"layout"}->SetTrackToCopper( $cpnStripSett->GetTrackToCopper() );
	$self->{"layout"}->SetPad2GND( $cpnStripSett->GetPad2GND() );
	$self->{"layout"}->SetPadClearance( $cpnStripSett->GetPadClearance() );

	my $xmlConstr = $self->_GetXmlConstr();

	$self->{"layout"}->SetModel( $xmlConstr->GetModel() );    # model
	$self->{"layout"}->SetTrackLayer( Helper->GetInCAMLayer( $xmlConstr->GetOption("TRACE_LAYER"), $self->{"layerCnt"} ) );    #
	$self->{"layout"}->SetTopRefLayer( Helper->GetInCAMLayer( $xmlConstr->GetOption("TOP_MODEL_LAYER"),    $self->{"layerCnt"} ) );    #
	$self->{"layout"}->SetBotRefLayer( Helper->GetInCAMLayer( $xmlConstr->GetOption("BOTTOM_MODEL_LAYER"), $self->{"layerCnt"} ) );    #
	$self->{"layout"}->SetExtraTrackLayer( Helper->GetInCAMLayer( $xmlConstr->GetOption("EXTRA_SIGNAL_LAYER"), $self->{"layerCnt"} ) );    #

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
	my $x    = $origin->X() - ( $self->{"cpnSett"}->GetPadTextWidth() / 1000 * length($text) ) / 2.5;
	my $xMir = $origin->X() + ( $self->{"cpnSett"}->GetPadTextWidth() / 1000 * length($text) ) / 2.5;
	my $y    = 0;

	if ( $self->{"stripVariant"}->Pool() == 0 ) {

		$y = $self->{"activeArea"}->{"pos"}->Y() - ( $self->{"cpnSett"}->GetPadTextDist() / 1000 + $self->{"cpnSett"}->GetPadTextHeight() / 1000 );

	}
	elsif ( $self->{"stripVariant"}->Pool() == 1 ) {

		$y = $self->{"activeArea"}->{"pos"}->Y() + $self->{"activeArea"}->{"h"} + $self->{"cpnSett"}->GetPadTextDist() / 1000;

	}

	# Built negative rectangle (for text putted to copper)
	my $rectW      = $self->{"cpnSett"}->GetPadTextWidth() / 1000 * length($text) + 0.2;
	my $rectH      = $self->{"cpnSett"}->GetPadTextHeight() / 1000 + 0.2;
	my $rectPos    = PointLayout->new( $x - 0.1, $y - 0.1 );
	my $rectPosMir = PointLayout->new( $x + 0.1, $y - 0.1 );

	my $padTextLayout = PadTextLayout->new( $text, PointLayout->new( $x, $y ), PointLayout->new( $xMir, $y ), $rectW, $rectH, $rectPos, $rectPosMir );

	$padTextLayout->SetPadTextHeight( $self->{"cpnSett"}->GetPadTextHeight() );
	$padTextLayout->SetPadTextWidth( $self->{"cpnSett"}->GetPadTextWidth() );
	$padTextLayout->SetPadTextWeight( $self->{"cpnSett"}->GetPadTextWeight() );
	$padTextLayout->SetPadTextUnmask( $self->{"cpnSett"}->GetPadTextUnmask() );

	return $padTextLayout;

}

sub _GetXmlConstr {
	my $self = shift;

	return $self->{"stripVariant"}->Data()->{"xmlConstraint"};
}

sub _GetSEStraightTrack {
	my $self   = shift;
	my $origin = shift;

	my @track          = ();
	my $cpnSingleWidth = $self->{"cpnSingleSett"}->GetCpnSingleWidth();

	# start point
	push( @track, PointLayout->new( $origin->X(), $origin->Y() ) );

	# end point

	if ( $self->{"cpnSett"}->GetTwoEndedDesign() ) {

		push( @track, PointLayout->new( $cpnSingleWidth - $origin->X(), $origin->Y() ) );
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

	my $p2pDist = $self->{"cpnSingleSett"}->GetTrackPad2TrackPad() / 1000;

	my $xmlConstr = $self->{"stripVariant"}->Data()->{"xmlConstraint"};
	my $w         = $xmlConstr->GetParamDouble("WB") / 1000;              # track width in mm
	my $s         = $xmlConstr->GetParamDouble("S") / 1000;               # track space in mm

	my $cpnSingleWidth = $self->{"cpnSingleSett"}->GetCpnSingleWidth();

	# Outer track
	my @track = ();

	# start point
	push( @track, PointLayout->new( $origin->X(), $origin->Y() ) );

	# second point
	my $x2 = $origin->X() + ( $p2pDist / 2 - $s / 2 - $w / 2 ) * tan( deg2rad(45) );
	my $y2 = $origin->Y() + $yTrackDir * ( $p2pDist / 2 - $s / 2 - $w / 2 );
	push( @track, PointLayout->new( $x2, $y2 ) );

	# third
	my $x3 = $cpnSingleWidth - $x2;
	my $y3 = $y2;
	push( @track, PointLayout->new( $x3, $y3 ) );

	if ( $self->{"cpnSett"}->GetTwoEndedDesign() ) {

		push( @track, PointLayout->new( $cpnSingleWidth - $origin->X(), $origin->Y() ) );
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

	my $cpnSingleWidth = $self->{"cpnSingleSett"}->GetCpnSingleWidth();

	if ( $self->{"stripVariant"}->Route() eq Enums->Route_STREIGHT ) {

		@track = $self->_GetSEStraightTrack($origin);

	}
	else {

		my $yTrackDir = $self->{"stripVariant"}->Route() eq Enums->Route_ABOVE ? 1 : -1;

		# start point
		push( @track, PointLayout->new( $origin->X(), $origin->Y() ) );

		# second point
		my $x2 = $origin->X() + $self->{"stripVariant"}->RouteDist() * tan( deg2rad(45) );
		my $y2 = $origin->Y() + $yTrackDir * $self->{"stripVariant"}->RouteDist();
		push( @track, PointLayout->new( $x2, $y2 ) );

		# third
		my $x3 = $cpnSingleWidth - $x2;
		my $y3 = $y2;
		push( @track, PointLayout->new( $x3, $y3 ) );

		if ( $self->{"cpnSett"}->GetTwoEndedDesign() ) {

			push( @track, PointLayout->new( $cpnSingleWidth - $origin->X(), $origin->Y() ) );
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

	my $cpnSingleWidth = $self->{"cpnSingleSett"}->GetCpnSingleWidth();

	# Outer track
	my @track = ();

	# start point
	push( @track, PointLayout->new( $origin->X(), $origin->Y() ) );

	# second point
	my $x2 = $origin->X() + ( $self->{"stripVariant"}->RouteDist() + $s / 2 + $w / 2 ) * tan( deg2rad(45) );
	my $y2 = $origin->Y() + $yTrackDir * ( $self->{"stripVariant"}->RouteDist() + $s / 2 + $w / 2 );
	push( @track, PointLayout->new( $x2, $y2 ) );

	# third
	my $x3 = $cpnSingleWidth - $x2;
	my $y3 = $y2;
	push( @track, PointLayout->new( $x3, $y3 ) );

	if ( $self->{"cpnSett"}->GetTwoEndedDesign() ) {

		push( @track, PointLayout->new( $cpnSingleWidth - $origin->X(), $origin->Y() ) );
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

	my $p2pDist = $self->{"cpnSingleSett"}->GetTrackPad2TrackPad() / 1000;    # in mm

	my $xmlConstr = $self->{"stripVariant"}->Data()->{"xmlConstraint"};
	my $w         = $xmlConstr->GetParamDouble("WB") / 1000;                  # track width in mm
	my $s         = $xmlConstr->GetParamDouble("S") / 1000;                   # track space in mm

	my $cpnSingleWidth = $self->{"cpnSingleSett"}->GetCpnSingleWidth();

	# Outer track
	my @track = ();

	# start point
	push( @track, PointLayout->new( $origin->X(), $origin->Y() ) );

	# second point
	my $x2 = $origin->X() + ( $self->{"stripVariant"}->RouteDist() - $s / 2 - $w / 2 ) * tan( deg2rad(45) );
	my $y2 = $origin->Y() + $yTrackDir * ( $self->{"stripVariant"}->RouteDist() - $s / 2 - $w / 2 );
	push( @track, PointLayout->new( $x2, $y2 ) );

	# third
	my $x3 = $cpnSingleWidth - $x2;
	my $y3 = $y2;
	push( @track, PointLayout->new( $x3, $y3 ) );

	if ( $self->{"cpnSett"}->GetTwoEndedDesign() ) {

		push( @track, PointLayout->new( $cpnSingleWidth - $origin->X(), $origin->Y() ) );
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

