
#-------------------------------------------------------------------------------------------#
# Description: Prepare NC layers to finla output
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::OutputLayer::OutputResult::OutputLayer;

#3th party library
use strict;
use warnings;

#local library

#use aliased 'Packages::SystemCall::SystemCall';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;
 
	$self->{"layer"} = shift; #layer name
	 

	return $self;
}

sub SetLayerName{
	my $self = shift;
	my $layer = shift;
	
	$self->{"layer"} = $layer;
}

sub GetLayerName {
	my $self = shift;

	return $self->{"layer"};
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
