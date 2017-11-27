
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
sub GetLayer {
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
