
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::UniTraveler::TravelerData::TravelerOper;

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"name"}     = shift;     
	$self->{"info"}   = shift;     
 
	return $self;
}

sub GetName {
	my $self = shift;

	return $self->{"name"};
}

sub GetInfo {
	my $self = shift;

	return $self->{"info"};
}
 

1;

