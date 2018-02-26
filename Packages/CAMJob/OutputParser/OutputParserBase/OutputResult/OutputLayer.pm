
#-------------------------------------------------------------------------------------------#
# Description: Prepare NC layers to finla output
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputParser::OutputParserBase::OutputResult::OutputLayer;

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
 
	$self->{"layer"} = shift; #layer name with prepared features
	
	$self->{"parseData"} = (); # hash contain information about parsed features in layer
	 

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


sub SetDataVal{
	my $self = shift;
	my $key = shift;
	my $val = shift;
	
	$self->{"parseData"}->{$key} = $val;
	
}

sub GetDataVal{
	my $self = shift;
	my $key = shift;
	 
	
	return $self->{"parseData"}->{$key};
}

sub GetData{
	my $self = shift;
	
	return %{$self->{"parseData"}};
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
