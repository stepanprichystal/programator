
#-------------------------------------------------------------------------------------------#
# Description: Special structure, whihich is returned by methos GetScorePointsOnPos of PcbInfo class
# contain inforamtion about points which create score line
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreChecker::InfoClasses::PointInfo;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Scoring::ScoreChecker::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = {};
	bless $self;

	$self->{"point"} = shift;
	$self->{"scoreInfo"}   = shift;
	$self->{"pointType"}    = shift; # position of point in whole pcb / first /middle/ last (score is sorted FELT/TOP)
 
	$self->{"dist"}    = shift; 
 
	return $self;
}


sub GetPoint {
	my $self = shift;
	
	return $self->{"point"};
}

sub GetScoreInfo {
	my $self = shift;
	
	return $self->{"scoreInfo"};
}

sub GetType {
	my $self = shift;
	
	return $self->{"pointType"};
}

sub GetDist {
	my $self = shift;
	
	return $self->{"dist"};
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {


}

1;

