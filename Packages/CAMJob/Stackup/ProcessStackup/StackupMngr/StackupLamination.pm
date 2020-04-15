
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::ProcessStackup::StackupMngr::StackupLamination;

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

	$self->{"lamOrder"} = shift;
	$self->{"lamType"}  = shift;
	$self->{"lamData"}     = shift;

	return $self;
}

sub GetLamOrder{
	my $self = shift;
	
	return $self->{"lamOrder"};
}

sub GetLamType{
	my $self = shift;
	
	return $self->{"lamType"};
}

sub GetLamData{
	my $self = shift;
	
	return $self->{"lamData"};
}

1;

