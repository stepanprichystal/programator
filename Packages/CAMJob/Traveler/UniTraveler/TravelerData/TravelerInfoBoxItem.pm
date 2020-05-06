
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::UniTraveler::TravelerData::TravelerInfoBoxItem;

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

	$self->{"text"}  = shift;
	$self->{"value"} = shift;

	return $self;
}

sub GetText {
	my $self = shift;

	return $self->{"text"};
}

sub GetValue {
	my $self = shift;

	return $self->{"value"};
}

1;

