
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers for particular machine, which can procces given nc file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreChecker::PcbInfo;

#3th party library
use strict;
use warnings;

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

	my @sco = $self->GetScoresOnPos();

	my @s = map { $_->GetStartP() } @sco;
	my @e = map { $_->GetEndP() } @sco;

	my @points = ( @s, @e );

	if ( $posInfo->GetDirection() eq Enums->Dir_HSCORE ) {

		@points = sort { $a->{"x"} <=> $b->{"x"} } @points;
	}
	elsif ( $posInfo->GetDirection() eq Enums->Dir_VSCORE ) {

		@points = sort { $b->{"x"} <=> $a->{"x"} } @points;
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

sub ScoreOnSamePos {
	my $self = shift;

	my @positions = $self->GetScorePos();

	my $exist = 0;

	foreach my $pos (@positions) {

		my @scores = $self->GetScoresOnPos($pos);
		if ( scalar(@scores) > 1 ) {

			$exist = 1;
			last;
		}

	}

	return $exist;
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

