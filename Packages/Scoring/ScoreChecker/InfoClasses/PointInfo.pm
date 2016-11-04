
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers for particular machine, which can procces given nc file
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
	
	# distance from profile
	# if pointType = first -> from TOP/LEFT profile edge
	# if pointType = middle -> undef
	# if pointType = last -> from BOTTOM/RIGHT profile edge
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

	#use aliased 'Packages::Export::NCExport::NCExportGroup';

	#print $test;

}

1;

