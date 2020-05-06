
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::UniTraveler::TravelerData::TravelerInfoBox;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAMJob::Traveler::UniTraveler::TravelerData::TravelerInfoBoxItem';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"title"} = shift;
	$self->{"items"} = [];

	return $self;
}

sub GetTitle {
	my $self = shift;

	return $self->{"title"};
}

sub GetAllItems {
	my $self = shift;

	return @{$self->{"items"}};
}

1;

