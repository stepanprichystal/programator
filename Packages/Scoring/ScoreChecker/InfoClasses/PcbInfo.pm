
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers for particular machine, which can procces given nc file
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

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = {};
	bless $self;

	$self->{"pcbId"}  = shift;
	$self->{"origin"} = shift;

	#$self->{"originY"}     = shift;
	$self->{"width"}  = shift;
	$self->{"height"} = shift;
	$self->{"dec"}    = shift;

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

sub GetScorePos {
	my $self = shift;
	my $dir  = shift;

	my @pos = ();

	my @sco = $self->GetScore($dir);

	foreach my $sInfo (@sco) {

		my $pInfo = ScorePosInfo->new( $sInfo->GetScorePoint(), $sInfo->GetDirection(), $self->{"dec"} );

		push( @pos, $pInfo );
	}

	return @pos;
}

# Return  all points, from score lines
# points are sorted from TOP/LEFT start L1, end L1, start L2, end L2 etc..
sub GetScorePointsOnPos {
	my $self    = shift;
	my $posInfo = shift;

	my @sco = $self->GetScoresOnPos($posInfo);

	my @s = map { $_->GetStartP() } @sco;
	my @e = map { $_->GetEndP() } @sco;

	my @points = ( @s, @e );

	if ( $posInfo->GetDirection() eq Enums->Dir_HSCORE ) {

		@points = sort { $a->{"x"} <=> $b->{"x"} } @points;
	}
	elsif ( $posInfo->GetDirection() eq Enums->Dir_VSCORE ) {

		@points = sort { $b->{"y"} <=> $a->{"y"} } @points;
	}
	
	return @points;

}

sub ScoreExist {

}

sub GetScoresOnPos {
	my $self    = shift;
	my $posInfo = shift;

	my @scores = ();

	my $dir = $posInfo->GetDirection();
	my $pos = $posInfo->GetPosition();

	#consider origin o this position
	# convert to relative to pcbInfo origin
	my $exist = 0;

	foreach my $sco ( @{ $self->{"score"} } ) {

		if ( $sco->ExistOnPosition( $dir, $pos ) ) {

			$exist = 1;
			push( @scores, $sco );
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


sub GetProfileDist {
	my $self    = shift;
	my $point = shift;
	my $scoreDir = shift;

	my $minDist = undef;
	if ( $scoreDir eq Enums->Dir_HSCORE ) {

		$minDist = min($point->{"x"},  $self->{"width"} - $point->{"x"});
 
	}
	elsif ( $scoreDir eq Enums->Dir_VSCORE ) {
		
		 $minDist = min( $self->{"height"} - $point->{"y"},  $point->{"y"});
	}
	 
	 return $minDist;
}
#
#sub ScoreOnSamePos {
#	my $self = shift;
#
#	my @positions = $self->GetScorePos();
#
#	my $exist = 0;
#
#	foreach my $pos (@positions) {
#
#		my @scores = $self->GetScoresOnPos($pos);
#		if ( scalar(@scores) > 1 ) {
#
#			$exist = 1;
#			last;
#		}
#
#	}
#
#	return $exist;
#}

# Some pcb scores we don't want to optimize
# Exist 2 cases
# Case 1) if customer has more then one score on same position
# Case 2) if score is too short, it could mean, customer don't want to score all pcb
sub NoOptimize {
	my $self = shift;
	my $pos  = shift;

	my $noOptimize = 0;

	my @scores= $self->GetScoresOnPos( $pos );  

	# Case 1)
	if ( scalar(@scores) > 1 ) {
		$noOptimize = 1;
	}

	# Case 2) Check ration of gaps, which are between strt/end point of score and profile
	# When there is atio less 70% not optimize
	if ( scalar(@scores) == 1){

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

		my $ratio = min( $gap1, $gap2 ) / max( $gap1, $gap2 );

		# ratioL = 80% if score line is bigger then 80% of pcb size,
		# we don't consider this as "customer" jump scoring
		
		# ratio = 90% this measn, if one gap is smaller more than 10% then second gap
		# consider it as customer jumpscoring
		if ( $ratioL < 0.8 && $ratio < 0.9 ) {
			$noOptimize = 1;
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

