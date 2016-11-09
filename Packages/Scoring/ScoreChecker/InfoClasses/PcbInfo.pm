
#-------------------------------------------------------------------------------------------#
# Description: Contain information about one psb step
# contain dimension, origin (left, bottom corner), score position, etc
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreChecker::InfoClasses::PcbInfo;

#3th party library
use strict;
use warnings;
use List::Util qw[max min];

#local library

use aliased 'Packages::Scoring::ScoreChecker::Enums';
use aliased 'Packages::Scoring::ScoreChecker::InfoClasses::ScorePosInfo';
use aliased 'Packages::Scoring::ScoreChecker::InfoClasses::PointInfo';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = {};
	bless $self;

	$self->{"pcbId"}  = shift;
	$self->{"origin"} = shift;
	$self->{"width"}  = shift;
	$self->{"height"} = shift;
	$self->{"accuracy"} = shift;

	my %center = ( "x" => $self->{"width"} / 2, "y" => $self->{"height"} / 2 );

	$self->{"center"} = \%center;

	my @sco = ();
	$self->{"score"} = \@sco;

	return $self;
}

sub AddScoreLine {
	my $self = shift;
	my $line = shift;

	push( @{ $self->{"score"} }, $line );

}

sub GetWidth {
	my $self = shift;

	return $self->{"width"};
}

sub GetHeight {
	my $self = shift;

	return $self->{"height"};
}

sub GetOrigin {
	my $self = shift;

	return $self->{"origin"};
}

sub GetCenter {
	my $self = shift;

	return $self->{"center"};
}

sub GetScore {
	my $self = shift;
	my $dir  = shift;

	my @score = @{ $self->{"score"} };

	if ($dir) {
		@score = grep { $_->GetDirection() eq $dir } @score;
	}

	# sort by start points of score lines, if dir is passed
	if ($dir) {

		if ( $dir eq Enums->Dir_HSCORE ) {

			@score = sort { $a->{"startP"}->{"y"} <=> $b->{"startP"}->{"y"} } @score;
		}
		elsif ( $dir eq Enums->Dir_VSCORE ) {

			@score = sort { $a->{"startP"}->{"x"} <=> $b->{"startP"}->{"x"} } @score;
		}
	}

	return @score;

}

# Return all position, where is score located
sub GetScorePos {
	my $self = shift;
	my $dir  = shift;

	my @pos = ();

	my @sco = $self->GetScore($dir);

	foreach my $sInfo (@sco) {

		my $pInfo = ScorePosInfo->new( $sInfo->GetScorePoint(), $sInfo->GetDirection() );

		push( @pos, $pInfo );
	}

	return @pos;
}

# Return  start and end point of each score on this position
# points are sorted from TOP/LEFT start L1, end L1, start L2, end L2 etc..
# point are type of PointInfo class
sub GetScorePointsOnPos {
	my $self    = shift;
	my $posInfo = shift;

	my @points = ();

	my @scores = $self->GetScoresOnPos($posInfo);

	for ( my $i = 0 ; $i < scalar(@scores) ; $i++ ) {

		my $scoInf = $scores[$i];
		my $dir    = $scoInf->GetDirection();

		my %sp = ( "type" => "start", "point" => $scoInf->GetStartP() );
		my %ep = ( "type" => "end",   "point" => $scoInf->GetEndP() );

		my @scoPoints = ( \%sp, \%ep );

		# Create point onfo for start and end point of each score line
		foreach my $p (@scoPoints) {

			my $point = $p->{"point"};

			my $type = undef;
			my $dist = undef;

			if ( $p->{"type"} eq "start" && $i == 0 ) {

				# set type
				$type = "first";

				# set direction
				if ( $dir eq Enums->Dir_HSCORE ) {

					$dist = $point->{"x"};
				}
				elsif ( $dir eq Enums->Dir_VSCORE ) {

					$dist = $self->{"height"} - $point->{"y"};
				}

			}
			elsif ( $p->{"type"} eq "end" && $i == scalar(@scores) - 1 ) {

				# set type
				$type = "last";

				# set direction
				if ( $dir eq Enums->Dir_HSCORE ) {

					$dist = $self->{"width"} - $point->{"x"};
				}
				elsif ( $dir eq Enums->Dir_VSCORE ) {

					$dist = $point->{"y"};
				}
			}
			else {

				$type = "middle";
			}

			my $p = PointInfo->new( $point, $scoInf, $type, $dist );

			push( @points, $p );
		}

	}

	if ( $posInfo->GetDirection() eq Enums->Dir_HSCORE ) {

		@points = sort { $a->GetPoint()->{"x"} <=> $b->GetPoint()->{"x"} } @points;
	}
	elsif ( $posInfo->GetDirection() eq Enums->Dir_VSCORE ) {

		@points = sort { $b->GetPoint()->{"y"} <=> $a->GetPoint()->{"y"} } @points;
	}

	return @points;

}

 
# Return all scores on given poisition
sub GetScoresOnPos {
	my $self    = shift;
	my $posInfo = shift;

	my @scores = ();

	my $dir = $posInfo->GetDirection();
	my $pos = $posInfo->GetPosition();

	#consider origin o this position
	# convert to relative to pcbInfo origin

	my @allScp = grep { $_->GetDirection() eq $dir } @{ $self->{"score"} };

	foreach my $sco (@allScp) {

		my $exist = 0;
		if ( $dir eq Enums->Dir_HSCORE ) {

			if ( abs( $pos - $sco->{"startP"}->{"y"} ) < $self->{"accuracy"} ) {
				push( @scores, $sco );
			}

		}
		elsif ( $dir eq Enums->Dir_VSCORE ) {
			if ( abs( $pos - $sco->{"startP"}->{"x"} ) < $self->{"accuracy"} ) {
				push( @scores, $sco );
			}
		}

	}

	return @scores;

}


sub IsScoreOnPos {
	my $self    = shift;
	my $posInfo = shift;

	my @scores = $self->GetScoresOnPos($posInfo);

	if ( scalar(@scores) ) {
		return 1;
	}
	else {
		return 0;
	}
}

 
# Some pcb scores we don't want to optimize
# Exist 2 cases
# Case 1) if customer has more then one score on same position
# Case 2) if score is too short, it could mean, customer don't want to score all pcb
sub NoOptimize {
	my $self = shift;
	my $pos  = shift;

	my $noOptimize = 0;

	my @scores = $self->GetScoresOnPos($pos);

	# Case 1)
	if ( scalar(@scores) > 1 ) {
		$noOptimize = 1;
	}

	# Case 2) Check ration of gaps, which are between strt/end point of score and profile
	# When there is atio less 70% not optimize
	if ( scalar(@scores) == 1 ) {

		my $sco = $scores[0];

		my $dir = $pos->GetDirection();

		my $gap1   = 0;
		my $gap2   = 0;
		my $ratioL = 0;    # ratio score line lenght/ pcb width or height

		if ( $dir eq Enums->Dir_HSCORE ) {

			my $w = $self->GetWidth();

			# first gap from profile
			$gap1   = $sco->GetStartP()->{"x"};
			$gap2   = $w - $sco->GetEndP()->{"x"};
			$ratioL = $sco->GetLength() / $w;

		}
		elsif ( $dir eq Enums->Dir_VSCORE ) {

			my $h = $self->GetHeight();

			# first gap from profile
			$gap1   = $h - $sco->GetStartP()->{"y"};
			$gap2   = $sco->GetEndP()->{"y"};
			$ratioL = $sco->GetLength() / $h;
		}

		if ( max( $gap1, $gap2 ) > 0 ) {
			my $ratio = min( $gap1, $gap2 ) / max( $gap1, $gap2 );

			# ratioL = 80% if score line is bigger then 80% of pcb size,
			# we don't consider this as "customer" jump scoring

			# ratio = 95% this measn, if one gap is smaller more than 10% then second gap
			# consider it as customer jumpscoring. (standar is gap are same size)
			if ( $ratioL < 0.8 && $ratio < 0.95 ) {
				$noOptimize = 1;
			}
		}

	}

	return $noOptimize;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Packages::Export::NCExport::NCExportGroup';

	#print $test;

}

1;

