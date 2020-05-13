
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::UniTravelerTmpl::TravelerData::TravelerInfoBox;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAMJob::Traveler::UniTravelerTmpl::TravelerData::TravelerInfoBoxItem';

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

sub AddItem {
	my $self  = shift;
	my $text  = shift;
	my $value = shift;

	my $it = TravelerInfoBoxItem->new( $text, $value );

	push( @{ $self->{"items"} }, $it );

	return $it;

}

sub GetTitle {
	my $self = shift;

	return $self->{"title"};
}

sub GetAllItems {
	my $self = shift;

	return @{ $self->{"items"} };
}

1;

