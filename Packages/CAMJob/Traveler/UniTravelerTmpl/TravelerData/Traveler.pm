
#-------------------------------------------------------------------------------------------#
# Description: Represent type + information about specific lamination
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::UniTravelerTmpl::TravelerData::Traveler;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAMJob::Traveler::UniTravelerTmpl::TravelerData::TravelerInfoBox';
use aliased 'Packages::CAMJob::Traveler::UniTravelerTmpl::TravelerData::TravelerOper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"order"}        = shift;    # tarveler page order
	$self->{"operations"}   = [];       # traveler operations
	$self->{"infoBoxes"}    = [];       # traveler info boxes
	$self->{"travelerType"} = undef;

	return $self;
}

sub GetTravelerOrder{
	my $self = shift;

	return $self->{"order"};
	
}

sub SetTravelerType {
	my $self = shift;

	$self->{"travelerType"} = shift;
}

sub GetTravelerType {
	my $self = shift;

	return $self->{"travelerType"};
}

sub AddInfoBox {
	my $self  = shift;
	my $title = shift;

	my $box = TravelerInfoBox->new($title);

	push( @{ $self->{"infoBoxes"} }, $box );

	return $box;
}

sub AddOperation {
	my $self = shift;
	my $name = shift;
	my $info = shift;

	my $oper = TravelerOper->new( $name, $info );

	push( @{ $self->{"operations"} }, $oper );

	return $oper;
}

sub GetAllOperations {
	my $self = shift;

	return @{ $self->{"operations"} };
}

sub GetAllInfoBoxes {
	my $self = shift;

	return @{ $self->{"infoBoxes"} };
}

1;

