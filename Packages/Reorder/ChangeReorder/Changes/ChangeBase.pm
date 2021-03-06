#-------------------------------------------------------------------------------------------#
# Description:  Class fotr testing application

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ChangeReorder::Changes::ChangeBase;

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self        = shift;
	my $checkKey    = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $orderId     = shift;
	my $reorderType = shift;

	$self = {};
	bless $self;

	$self->{"key"}         = $checkKey;
	$self->{"inCAM"}       = $inCAM;
	$self->{"jobId"}       = $jobId;
	$self->{"orderId"}     = $orderId;
	$self->{"reorderType"} = $reorderType;

	return $self;
}

sub GetChangeKey {
	my $self  = shift;
	my $pcbId = shift;

	return $self->{"key"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	print "ee";
}

1;

