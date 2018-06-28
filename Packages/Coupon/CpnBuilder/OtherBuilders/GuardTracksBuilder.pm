
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
use Array::IntSpan;
use List::MoreUtils qw(uniq);

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

	#@boxes = grep {$_->{"type"} eq "tracks"} @boxes;

	# for all boxes set line top and bot border of box
	for ( my $i = 0 ; $i < scalar(@boxes) ; $i++ ) {

		my $box = $boxes[$i];

		$box->{"lines"} = [];

		# define bot line

		if ( $i > 0 && !$boxes[ $i - 1 ]->{"breakLine"} ) {

			my %lBot = ();

			$lBot{"startP"} = Point->new( $box->{"xMin"}, $box->{"yMin"} + $self->{"settings"}->GetGuardTrackWidth() / 1000 / 2 );
			$lBot{"endP"}   = Point->new( $box->{"xMax"}, $box->{"yMin"} + $self->{"settings"}->GetGuardTrackWidth() / 1000 / 2 );

			push( @{ $box->{"lines"} }, \%lBot );
		}

		# define top line
		if ( $i < ( scalar(@boxes) - 1 ) && ( !$box->{"breakLine"} ) ) {

			my %lTop = ();

			$lTop{"startP"} = Point->new( $box->{"xMin"}, $box->{"yMax"} - $self->{"settings"}->GetGuardTrackWidth() / 1000 / 2 );
			$lTop{"endP"}   = Point->new( $box->{"xMax"}, $box->{"yMax"} - $self->{"settings"}->GetGuardTrackWidth() / 1000 / 2 );

			push( @{ $box->{"lines"} }, \%lTop );
		}

		# Check if line are not covering or out of the box

		#		if ( scalar( @{ $box->{"lines"} } ) > 1 ) {
		#
		#			# overlaping
		#			if (
		#				 abs( $box->{"lines"}->[0]->{"startP"}->Y() - $box->{"lines"}->[1]->{"startP"}->Y() ) <
		#				 $self->{"settings"}->GetGuardTrackWidth() / 1000 )
		#			{
		#
		#				splice @{ $box->{"lines"} }, 1, 1;
		#			}
		#
		#		}
		#
		if ( scalar( @{ $box->{"lines"} } ) ) {

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

	my @boxes = ();

	my $l = Helper->GetInStackLayer( $layer, $self->{"layerCnt"} );

	my @lStrips = $self->{"singleCpnVar"}->GetStripsByLayer($l);
	my %cpnArea = $self->{"cpnSingle"}->GetCpnSingleArea();

	return unless ( scalar(@lStrips) );

	# Build structures, which return X position where guard areas should be started, based on its Y position

	# 1) Get very right pads position in all pools (left side of strip)
	my @xBorders = ();

	foreach my $pool ( $self->{"singleCpnVar"}->GetPools() ) {

		my $lastS   = $pool->GetLastStrip();
		my $posXCnt = $self->{"cpnSingle"}->GetMicrostripPosCnt( $lastS, "x" );
		my $oriLast = $self->{"cpnSingle"}->GetMicrostripOrigin($lastS);

		my $endPos =
		  $oriLast->X() +
		  $self->{"settings"}->GetPad2PadDist() / 1000 * ( $posXCnt - 1 ) +
		  $self->{"settings"}->GetPadTrackSize() / 1000 / 2 +
		  $self->{"settings"}->GetGuardTrack2PadDist() +
		  $self->{"settings"}->GetGuardTrackWidth() / 1000 / 2;

		push( @xBorders, $endPos );
	}

	# musltistrip - ad pos of gnd pad
	if ( scalar( $self->{"singleCpnVar"}->GetPools() == 2 ) ) {

		# keep order of pads from bottom to top
		# insert gnd pad pas into middle of array
		splice @xBorders, 1, 0, max(@xBorders);
	}

	# 2) Define break lines

	my @limits = ();

	# one on bottom of coupon
	push( @limits, 0 );

	#  if more pools, 1 line on bot of gnd, 1 on top of gnd pad
	if ( scalar( $self->{"singleCpnVar"}->GetPools() == 2 ) ) {

		my $oriLast = $self->{"cpnSingle"}->GetMicrostripOrigin( ( $self->{"singleCpnVar"}->GetPools() )[1]->GetLastStrip() );

		# bott of gnd pad
		push( @limits, $oriLast->Y() - $self->{"settings"}->GetPadTrackSize() / 1000 / 2 - $self->{"settings"}->GetGuardTrack2TrackDist() );

		die "Too large value of 'track-guard 2 tracks distance'" if ( $limits[1] < $limits[0] );

		# top of gnd pad
		push( @limits, $oriLast->Y() + $self->{"settings"}->GetPadTrackSize() / 1000 / 2 + $self->{"settings"}->GetGuardTrack2TrackDist() );

		die "Too large value of 'track-guard 2 tracks distance'" if ( $limits[2] > $cpnArea{"h"} );

	}

	# one on top of coupon

	push( @limits, $cpnArea{"h"} );    # 1 - bottom of coupon

	#	# convert to µm
	#	for ( my $i = 0 ;$i < scalar(@limits) ; $i++ ) {
	#		$limits[$i] = int( $limits[$i] * 1000 );
	#	}

	# 3) Defines interval
	my $intervals = Array::IntSpan->new();

	my $yIntS = undef;
	for ( my $i = 0 ; $i < scalar(@limits) ; $i++ ) {
		my $bLine = $limits[$i];
		my $yIntE = $bLine;

		if ( defined $yIntS ) {

			#			my %range = (
			#						  "x"      => shift @xBorders,
			#						  "yStart" => $yS,
			#						  "yEnd"   => $yE,
			#						  "tracks" => []
			#			);
			#			$intervals->set_range( $yS, $yE, \%range );

			$intervals->set_range( $yIntS, $yIntE, shift @xBorders );

		}

		$yIntS = $yIntE + 0.001;    # add one micron - start of next interval
	}

	# 4) create Guard area, limited by break lines and by track lines

	# 2) Sort strip by Y track position on singloe coupon (from bottom to top track line)
	@lStrips = sort { $self->__SortStrips( $a, $b ) } @lStrips;

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

		if ( $b->Route() eq Enums->Route_ABOVE ) {
			$strip2Y += $b->RouteDist();
		}
		elsif ( $b->Route() eq Enums->Route_BELOW ) {
			$strip2Y -= $b->RouteDist();
		}

		return $strip1Y <=> $strip2Y;
	}

	# 3) Compute guard boxes based on track line and break line (+ limits of coupon -top/bot)
 

	my @breakLines = ();
	if ( scalar( $self->{"singleCpnVar"}->GetPools() == 2 ) ) {
		push( @breakLines, @limits[ 1 .. 2 ] );
	}

	my $yS = 0;
	while ( scalar(@lStrips) || scalar(@breakLines) ) {

		#foreach my $s (@lStrips) {
		my %boxLim = ( "breakLine" => 0 );

		# remove unused break lines
		for ( my $i = scalar(@breakLines) - 1 ; $i >= 0 ; $i-- ) {
			splice @breakLines, $i, 1 if ( $breakLines[$i] < $yS );
		}

		# search min break line
		my $min    = undef;
		my $minIdx = undef;
		for ( my $i = 0 ; $i < scalar(@breakLines) ; $i++ ) {

			if ( !defined $min || $breakLines[$i] < $min ) {
				$minIdx = $i;
				$min    = $breakLines[$i];
			}
		}

		# if t
		my $sPos = undef;
		if ( scalar(@lStrips) ) {
			$sPos = $self->__GetAbsoluteRouteDist( $lStrips[0] ) - $lStrips[0]->RouteWidth() / 2 - $self->{"settings"}->GetGuardTrack2TrackDist();
		}

		# if break line pos is lower than track line OR if all track lines are processed
		# Create box based on break line
		if ( ( scalar(@lStrips) &&  scalar(@breakLines) && $min < $sPos ) || ( !scalar(@lStrips) && scalar(@breakLines) ) ) {

			# remove minimal break line

			my $breakLine = splice @breakLines, $minIdx, 1;
			my $yE        = $breakLine;
			my $xS        = $intervals->lookup($yE);
			my $xE        = $self->{"settings"}->GetCpnSingleWidth() - $xS;

			if ( $yS < $yE ) {

				$boxLim{"xMin"}      = $xS;
				$boxLim{"xMax"}      = $xE;
				$boxLim{"yMin"}      = $yS;
				$boxLim{"yMax"}      = $yE;
				$boxLim{"breakLine"} = 1;

				push( @boxes, \%boxLim );
			}
			$yS = $yE;
			next;
		}

		my $s = shift @lStrips;

		my $ori = $self->{"cpnSingle"}->GetMicrostripOrigin($s);

		# compute limits of border in Y axis
		my $yE = $self->__GetAbsoluteRouteDist($s);
		$yE -= $s->RouteWidth() / 2 + $self->{"settings"}->GetGuardTrack2TrackDist();

		# compute limits in X axis

		# get origin of last strip in current pool

		my $xS = $intervals->lookup($yE);
		my $xE = $self->{"settings"}->GetCpnSingleWidth() - $xS;

		# if box has non zero height
		if ( $yS < $yE ) {

			$boxLim{"xMin"} = $xS;
			$boxLim{"xMax"} = $xE;
			$boxLim{"yMin"} = $yS;
			$boxLim{"yMax"} = $yE;

			push( @boxes, \%boxLim );
		}

		$yS = $yE + 2 * $self->{"settings"}->GetGuardTrack2TrackDist() + $s->RouteWidth();
	}

	# Define last box
	my $yE = $cpnArea{"h"};    # 1 - bottom of coupon

	if ( $yS < $yE ) {

		# add last box (from last top track to top border of single cpn)
		my %boxLim = ( "breakLine" => 0 );
		$boxLim{"xMin"} = $intervals->lookup($yE);
		$boxLim{"xMax"} = $self->{"settings"}->GetCpnSingleWidth() - $intervals->lookup($yE);
		$boxLim{"yMin"} = $yS;
		$boxLim{"yMax"} = $yE;

		push( @boxes, \%boxLim );
	}

	return @boxes;

	#	#  Get all strips with cur track layer
	#	my @lStrips = $self->{"singleCpnVar"}->GetStripsByLayer($l);
	#
	#	foreach my $s (@lStrips) {
	#
	#		my %trackInf = ();
	#
	#		my $ori  = $self->{"cpnSingle"}->GetMicrostripOrigin($s);
	#		my $yPos = $ori->Y();
	#		if ( !$self->{"cpnSingle"}->IsMultistrip() && ( $s->GetType() eq Enums->Type_DIFF || $s->GetType() eq Enums->Type_CODIFF ) ) {
	#			$yPos += $self->{"settings"}->GetPad2PadDist() / 1000 / 2;    # single diff has two rows
	#		}
	#
	#		$yPos += $self->{"settings"}->GetPad2PadDist() / 1000 if ( $s->Pool() == 1 );
	#
	#		# consider route type + width + distance track to gguard tracks
	#		if ( $s->Route() eq Enums->Route_ABOVE ) {
	#			$yPos += $s->RouteDist();
	#		}
	#		elsif ( $s->Route() eq Enums->Route_BELOW ) {
	#			$yPos -= $s->RouteDist();
	#		}
	#
	#		my @affectIntervals = ();
	#		push( @affectIntervals, $intervals->lookup( $yPos + $s->RouteWidth() / 2 ) );
	#		push( @affectIntervals, $intervals->lookup( $yPos - $s->RouteWidth() / 2 ) );
	#
	#		# if lines belong to guard box
	#		foreach my $interv ( uniq( grep { defined $_ } @affectIntervals ) ) {
	#
	#			my %routInf = ( "y" => $yPos, "w" => $s->RouteWidth() );
	#
	#			push( @{ $interv->{"tracks"} }, \%routInf );
	#
	#		}
	#	}
	#
	#	# go through interval and create guard area by interval splited bz strip track
	#
	#	foreach my $interval ( map { $_->[2] } @{$intervals} ) {
	#
	#		my @tracks = @{ $interval->{"tracks"} };
	#
	#		# interval contain tracks
	#		if (@tracks) {
	#
	#			@tracks = sort { $a->{"y"} <=> $b->{"y"} } @tracks;
	#
	#			my $yS = $interval->{"yStart"};
	#			foreach my $track (@tracks) {
	#
	#				my %boxLim = ( "type" => "tracks" );
	#
	#				# compute limits of border in Y axis
	#
	#				my $yE = $track->{"y"} - $track->{"w"} / 2 - $self->{"settings"}->GetGuardTrack2TrackDist();
	#
	#				# compute limits in X axis
	#
	#				my $xS = $interval->{"x"};
	#				my $xE = $self->{"settings"}->GetCpnSingleWidth() - $xS;
	#
	#				# if box has non zero height
	#				if ( $yS < $yE ) {
	#
	#					$boxLim{"xMin"} = $xS;
	#					$boxLim{"xMax"} = $xE;
	#					$boxLim{"yMin"} = $yS;
	#					$boxLim{"yMax"} = $yE;
	#
	#					push( @boxes, \%boxLim );
	#				}
	#
	#				$yS = $yE + 2 * $self->{"settings"}->GetGuardTrack2TrackDist() + $track->{"w"};
	#			}
	#
	#			if ( $yS < $interval->{"yEnd"} ) {
	#
	#				# add last box (from last top track to top border of single cpn)
	#				my %boxLim = ( "type" => "tracks" );
	#				$boxLim{"xMin"} = $interval->{"x"};
	#				$boxLim{"xMax"} = $self->{"settings"}->GetCpnSingleWidth() - $interval->{"x"};
	#				$boxLim{"yMin"} = $yS;
	#
	#				$boxLim{"yMax"} = $interval->{"yEnd"};
	#
	#				push( @boxes, \%boxLim );
	#
	#			}
	#
	#		}
	#
	#		# empty box
	#		else {
	#
	#			my %boxLim = ( "type" => "empty" );
	#			$boxLim{"xMin"} = $interval->{"x"};
	#			$boxLim{"xMax"} = $self->{"settings"}->GetCpnSingleWidth() - $interval->{"x"};
	#			$boxLim{"yMin"} = $interval->{"yStart"};
	#			$boxLim{"yMax"} = $interval->{"yEnd"};
	#
	#			push( @boxes, \%boxLim );
	#
	#		}
	#
	#	}
	#	return @boxes;

	#	# 2) Sort strip by Y track position on singloe coupon (from bottom to top track line)
	#	#@lStrips = sort { $self->__SortStrips( $a, $b ) } @lStrips;
	#
	#	sub __SortStrips {
	#		my $self = shift;
	#		my $a    = shift;
	#		my $b    = shift;
	#
	#		my $strip1Y = $self->{"cpnSingle"}->GetMicrostripOrigin($a)->Y();
	#
	#		if ( $a->Route() eq Enums->Route_ABOVE ) {
	#			$strip1Y += $a->RouteDist();
	#		}
	#		elsif ( $a->Route() eq Enums->Route_BELOW ) {
	#			$strip1Y -= $a->RouteDist();
	#		}
	#
	#		my $strip2Y = $self->{"cpnSingle"}->GetMicrostripOrigin($b)->Y();
	#
	#		if ( $a->Route() eq Enums->Route_ABOVE ) {
	#			$strip2Y += $a->RouteDist();
	#		}
	#		elsif ( $a->Route() eq Enums->Route_BELOW ) {
	#			$strip2Y -= $a->RouteDist();
	#		}
	#
	#		return $strip1Y <=> $strip2Y;
	#	}
	#
	#	# 3) Compute max border of guard lines around each track line
	#	# Border has shape of rectangle (limits of border are cpn single; track lines + track line 2 guard line distance)
	#	my @boxes = ();
	#
	#	my $yS = $self->{"settings"}->GetCouponSingleMargin();
	#	my $xS;
	#	my $curPos = "routeBelow";
	#	foreach my $s (@lStrips) {
	#
	#		my %boxLim = ();
	#
	#		my $ori = $self->{"cpnSingle"}->GetMicrostripOrigin($s);
	#
	#		# compute limits of border in Y axis
	#		my $yE = $ori->Y();
	#
	#		if ( !$self->{"cpnSingle"}->IsMultistrip() && ( $s->GetType() eq Enums->Type_DIFF || $s->GetType() eq Enums->Type_CODIFF ) ) {
	#			$yE += $self->{"settings"}->GetPad2PadDist() / 1000 / 2;    # single diff has two rows
	#		}
	#
	#		$yE += $self->{"settings"}->GetPad2PadDist() / 1000 if ( $s->Pool() == 1 );
	#
	#		# consider route type + width + distance track to gguard tracks
	#		if ( $s->Route() eq Enums->Route_ABOVE ) {
	#			$yE += $s->RouteDist();
	#		}
	#		elsif ( $s->Route() eq Enums->Route_BELOW ) {
	#			$yE -= $s->RouteDist();
	#		}
	#
	#		$yE -= $s->RouteWidth() / 1000 / 2 + $self->{"settings"}->GetGuardTrack2TrackDist();
	#
	#		# compute limits in X axis
	#
	#		# get origin of last strip in current pool
	#		my $oriLast =
	#		  $self->{"cpnSingle"}->GetMicrostripOrigin( $self->{"singleCpnVar"}->GetPoolByOrder( $s->Pool() )->GetLastStrip() );
	#
	#		$xS =
	#		  $oriLast->X() +
	#		  $self->{"settings"}->GetPadTrackSize() / 1000 / 2 +
	#		  $self->{"settings"}->GetGuardTrack2TrackDist() +
	#		  $self->{"settings"}->GetGuardTrackWidth() / 1000 / 2;
	#
	#		$xS += $self->{"settings"}->GetPad2PadDist() / 1000
	#		  if ( !$self->{"cpnSingle"}->IsMultistrip() );    # single strips has track pad on as 2nd pad on the left
	#
	#		my $xE = $self->{"settings"}->GetCpnSingleWidth() - $xS;
	#
	#		# if box has non zero height
	#		if ( $yS < $yE ) {
	#
	#			$boxLim{"xMin"} = $xS;
	#			$boxLim{"xMax"} = $xE;
	#			$boxLim{"yMin"} = $yS;
	#			$boxLim{"yMax"} = $yE;
	#
	#			push( @boxes, \%boxLim );
	#		}
	#
	#		$yS = $yE + 2 * $self->{"settings"}->GetGuardTrack2TrackDist() + $s->RouteWidth() / 1000;
	#
	#	}
	#
	#	if (@lStrips) {
	#
	#		# add last box (from last top track to top border of single cpn)
	#		my %boxLim = ();
	#		$boxLim{"xMin"} = $xS;
	#		$boxLim{"xMax"} = $self->{"settings"}->GetCpnSingleWidth() - $xS;
	#		$boxLim{"yMin"} = $yS;
	#
	#		my %cpnArea = $self->{"cpnSingle"}->GetCpnSingleArea();
	#		$boxLim{"yMax"} = $cpnArea{"h"};
	#
	#		push( @boxes, \%boxLim );
	#	}
	#
	#	return @boxes;
}

sub __GetAbsoluteRouteDist {
	my $self = shift;
	my $s    = shift;

	my $ori = $self->{"cpnSingle"}->GetMicrostripOrigin($s);
	my $yE  = $ori->Y();

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

	return $yE;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

