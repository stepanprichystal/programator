
#-------------------------------------------------------------------------------------------#
# Description: Prepare NC layers to finla output
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::OutputLayer::OutputResult::OutputClassResult;

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

	$self->{"type"}        = shift;
	$self->{"layers"}      = [];
	$self->{"result"} = 0; # 0 - no layers was added, 1 - at least 1 layer was added

	return $self;
}

sub Result{
	my $self = shift;
	
	return $self->{"result"};
}
 
sub GetType {
	my $self = shift;

	return $self->{"type"};
}

sub GetLayers {
	my $self = shift;

	return @{ $self->{"layers"} };
}

sub AddLayer{
	my $self = shift;
	my $outputLayer = shift;
	
	$self->{"result"} = 1;
	
	push(@{$self->{"layers"}}, $outputLayer);
	
}

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
