
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers as gerber274x
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreChecker::OriginConvert;

#3th party library
use strict;
use warnings;
use Math::Trig;

#local library
use aliased 'Helpers::GeneralHelper';

use aliased 'Packages::Scoring::ScoreChecker::Enums';
use aliased 'Packages::Scoring::ScoreChecker::InfoClasses::ScorePosInfo';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

 

# Conversion of has with keys x, y
sub DoPoint {
	my $self     = shift;
	my $point    = shift;
	my $pcb      = shift;
	my $dir      = shift;
	my $relToPcb = shift;

	my $x = $point->{"x"};
	my $y = $point->{"y"};

	$self->__ConsiderOrigin( \$x, \$y, $pcb, $relToPcb );

	my %newPoint = ( "x" => $x, "y" => $y );

	return \%newPoint;

}

# Conversion of class:
# Packages::Scoring::ScoreChecker::InfoClasses::ScorePosInfo
sub DoPosInfo {
	my $self     = shift;
	my $pos      = shift;
	my $pcb      = shift;
	my $relToPcb = shift;

	my $sign = 1;

	if ($relToPcb) {
		$sign = -1;
	}

	my $pVal = $pos->GetPosition();
	my $dir  = $pos->GetDirection();

	# consider origin of "panel" and location of pcb
	if ( $dir eq Enums->Dir_HSCORE ) {

		$pVal += $sign * $pcb->GetOrigin()->{"y"};

	}
	elsif ( $dir eq Enums->Dir_VSCORE ) {

		$pVal += $sign * $pcb->GetOrigin()->{"x"};
	}

	my $newPos = ScorePosInfo->new($pVal, $dir);
	
	return $newPos;
}

# Do conversion of position value (inside a step), between "panel" origin and step origin
sub __ConsiderOrigin {
	my $self     = shift;
	 
	my $x        = shift;
	my $y        = shift;
	my $pcb      = shift;
	my $relToPcb = shift;

	my $sign = 1;

	if ($relToPcb) {
		$sign = -1;
	}

	 
		$$x += $sign * $pcb->GetOrigin()->{"x"};
		$$y += $sign * $pcb->GetOrigin()->{"y"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Scoring::ScoreChecker::ScoreChecker';
	use aliased 'Packages::InCAM::InCAM';

	my $jobId = "f52456";

	my $inCAM = InCAM->new();

	my $checker = ScoreChecker->new( $inCAM, $jobId, "panel" );

	print 1;

}

1;

