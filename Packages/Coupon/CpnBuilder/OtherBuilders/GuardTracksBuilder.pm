
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnBuilder::OtherBuilders::GuardTracksBuilder;

use Class::Interface;
&implements('Packages::Coupon::CpnBuilder::ICpnBuilder');

#3th party library
use strict;
use warnings;
use Switch;
use List::Util qw[min max];

#local library
use aliased 'Packages::Coupon::Enums';
use aliased 'Packages::Coupon::Helper';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::Coupon::CpnBuilder::CpnLayout::GuardTracksLayout';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"settings"}     = shift;    # global settings for generating coupon
	$self->{"singleCpnVar"} = shift;
	$self->{"cpnSingle"}    = shift;

	$self->{"layout"} = [];             # Layout of one single coupon

	$self->{"microstrips"} = [];

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	$self->{"build"} = 0;               # indicator if layout was built

	return $self;
}

# Build single coupon layout
# If ok return 1, else 0 + err message
sub Build {
	my $self    = shift;
	my $errMess = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;

	my @layers = Helper->GetAllLayerNames( $self->{"layerCnt"} );

	foreach my $l (@layers) {

		my $layout = GuardTracksLayout->new($l);
		$layout->SetType( $self->{"settings"}->GetGuardTracksType() );

		my @boxes = $self->__GetGuardAreas($l);

		if (@boxes) {

			if ( $self->{"settings"}->GetGuardTracksType() eq "single" ) {

				$self->__SetLayoutTypeLines( $layout, \@boxes );

			}
			elsif ( $self->{"settings"}->GetGuardTracksType() eq "full" ) {

				$self->__SetLayoutTypeFull( $layout, \@boxes );
			}

			push( @{ $self->{"layout"} }, $layout );
		}

	}

	$self->{"build"} = 1;

	return $result;
}

sub GetLayout {
	my $self = shift;

	return $self->{"layout"};
}

sub GetType {
	my $self = shift;

}

sub __SetLayoutTypeLines {
	my $self   = shift;
	my $layout = shift;
	my @boxes  = @{ shift(@_) };

	# for all boxes set line top and bot border of box
	for ( my $i = 0 ; $i < scalar(@boxes) ; $i++ ) {

		my $box = $boxes[$i];

		$box->{"lines"} = [];

		# define bot line

		if ( $i > 0 ) {
			my %lBot = ();

			$lBot{"startP"} = Point->new( $box->{"xMin"}, $box->{"yMin"} + $self->{"settings"}->GetGuardTrackWidth() / 1000 );
			$lBot{"endP"}   = Point->new( $box->{"xMax"}, $box->{"yMin"} + $self->{"settings"}->GetGuardTrackWidth() / 1000 );

			push( @{ $box->{"lines"} }, \%lBot );
		}

		# define top line
		if ( $i != scalar(@boxes) - 1 ) {

			my %lTop = ();

			$lTop{"startP"} = Point->new( $box->{"xMin"}, $box->{"yMax"} - $self->{"settings"}->GetGuardTrackWidth() / 1000 );
			$lTop{"endP"}   = Point->new( $box->{"xMax"}, $box->{"yMax"} - $self->{"settings"}->GetGuardTrackWidth() / 1000 );

			push( @{ $box->{"lines"} }, \%lTop );
		}

		# Check if line are not covering or out of the box

		if ( scalar( @{ $box->{"lines"} } ) > 1 ) {

			# covering
			if (
				 abs( $box->{"lines"}->[0]->{"startP"}->Y() - $box->{"lines"}->[1]->{"startP"}->Y() ) <
				 $self->{"settings"}->GetGuardTrackWidth() / 1000 )
			{

				splice @{ $box->{"lines"} }, 1, 1;
			}

		}

		if ( scalar( @{ $box->{"lines"} } ) > 1 ) {

			# line width is out of box
			if ( $self->{"settings"}->GetGuardTrackWidth() / 1000 > ( $box->{"yMax"} - $box->{"yMin"} ) ) {

				@{ $box->{"lines"} } = ();
			}
		}

		# set layout
		$layout->AddLine($_) foreach @{ $box->{"lines"} };

	}

}

sub __SetLayoutTypeFull {
	my $self   = shift;
	my $layout = shift;
	my @boxes  = @{ shift(@_) };

	# for all boxes set line top and bot border of box
	for ( my $i = 0 ; $i < scalar(@boxes) ; $i++ ) {

		my $box = $boxes[$i];

		my @coord = ();
		push( @coord, Point->new( $box->{"xMin"}, $box->{"yMin"} ) );
		push( @coord, Point->new( $box->{"xMin"}, $box->{"yMax"} ) );
		push( @coord, Point->new( $box->{"xMax"}, $box->{"yMax"} ) );
		push( @coord, Point->new( $box->{"xMax"}, $box->{"yMin"} ) );

		# set layout
		$layout->AddArea( \@coord );
	}
}

sub __GetGuardAreas {
	my $self  = shift;
	my $layer = shift;

	#	my @layers = Helper->GetAllLayerNames( $self->{"layerCnt"} );
	#
	#	foreach my $l (@layers) {

	my $l = Helper->GetInStackLayer( $layer, $self->{"layerCnt"} );

	# 1) Get all strips with cur track layer
	my @lStrips = $self->{"singleCpnVar"}->GetStripsByLayer($l);

	# 2) Sort strip by Y track position on singloe coupon (from bottom to top track line)
	#@lStrips = sort { $self->__SortStrips( $a, $b ) } @lStrips;

	sub __SortStrips {
		my $self = shift;
		my $a    = shift;
		my $b    = shift;

		my $strip1Y = $self->{"cpnSingle"}->GetMicrostripOrigin($a)->Y();

		if ( $a->Route() eq Enums->Route_ABOVE ) {
			$strip1Y += $a->RouteDist();
		}
		elsif ( $a->Route() eq Enums->Route_BELOW ) {
			$strip1Y -= $a->RouteDist();
		}

		my $strip2Y = $self->{"cpnSingle"}->GetMicrostripOrigin($b)->Y();

		if ( $a->Route() eq Enums->Route_ABOVE ) {
			$strip2Y += $a->RouteDist();
		}
		elsif ( $a->Route() eq Enums->Route_BELOW ) {
			$strip2Y -= $a->RouteDist();
		}

		return $strip1Y <=> $strip2Y;
	}

	# 3) Compute max border of guard lines around each track line
	# Border has shape of rectangle (limits of border are cpn single; track lines + track line 2 guard line distance)
	my @boxes = ();

	my $yS = $self->{"settings"}->GetCouponSingleMargin();
	my $xS;
	my $curPos = "routeBelow";
	foreach my $s (@lStrips) {

		my %boxLim = ();

		my $ori = $self->{"cpnSingle"}->GetMicrostripOrigin($s);

		# compute limits of border in Y axis
		my $yE = $ori->Y();

		if ( !$self->{"cpnSingle"}->IsMultistrip() && ( $s->GetType() eq Enums->Type_DIFF || $s->GetType() eq Enums->Type_CODIFF ) ) {
			$yE += $self->{"settings"}->GetPad2PadDist() / 1000 / 2;    # single diff has two rows
		}

		$yE += $self->{"settings"}->GetPad2PadDist() / 1000 if ( $s->Pool() == 1 );

		# consider route type + width + distance track to gguard tracks
		if ( $s->Route() eq Enums->Route_ABOVE ) {
			$yE += $s->RouteDist();
		}
		elsif ( $s->Route() eq Enums->Route_BELOW ) {
			$yE -= $s->RouteDist();
		}

		$yE -= $s->RouteWidth() / 1000 / 2 + $self->{"settings"}->GetGuardTrackDist();

		# compute limits in X axis

		# get origin of last strip in current pool
		my $oriLast =
		  $self->{"cpnSingle"}->GetMicrostripOrigin( $self->{"singleCpnVar"}->GetPoolByOrder( $s->Pool() )->GetLastStrip() );

		$xS =
		  $oriLast->X() +
		  $self->{"settings"}->GetPadTrackSize() / 1000 / 2 +
		  $self->{"settings"}->GetGuardTrackDist() +
		  $self->{"settings"}->GetGuardTrackWidth() / 1000 / 2;

		$xS += $self->{"settings"}->GetPad2PadDist() / 1000
		  if ( !$self->{"cpnSingle"}->IsMultistrip() );    # single strips has track pad on as 2nd pad on the left

		my $xE = $self->{"settings"}->GetCpnSingleWidth() - $xS;

		# if box has non zero height
		if ( $yS < $yE ) {

			$boxLim{"xMin"} = $xS;
			$boxLim{"xMax"} = $xE;
			$boxLim{"yMin"} = $yS;
			$boxLim{"yMax"} = $yE;

			push( @boxes, \%boxLim );
		}

		$yS = $yE + 2 * $self->{"settings"}->GetGuardTrackDist() + $s->RouteWidth() / 1000;

	}

	if (@lStrips) {

		# add last box (from last top track to top border of single cpn)
		my %boxLim = ();
		$boxLim{"xMin"} = $xS;
		$boxLim{"xMax"} = $self->{"settings"}->GetCpnSingleWidth() - $xS;
		$boxLim{"yMin"} = $yS;

		my %cpnArea = $self->{"cpnSingle"}->GetCpnSingleArea();
		$boxLim{"yMax"} = $cpnArea{"h"};

		push( @boxes, \%boxLim );
	}

	return @boxes;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

