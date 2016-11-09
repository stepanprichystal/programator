
#-------------------------------------------------------------------------------------------#
# Description: Contain information about point poisiton, where score lines are placed
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreChecker::InfoClasses::ScorePosInfo;

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

	$self->{"position"} = shift;
	$self->{"dir"}      = shift;

	return $self;
}

sub SetPosition {
	my $self = shift;

	$self->{"position"} = sprintf( "%." . $self->{"dec"} . "f", shift );

}

sub GetPosition {
	my $self = shift;
	return $self->{"position"};
}

sub GetDirection {
	my $self = shift;
	return $self->{"dir"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 

}

1;

