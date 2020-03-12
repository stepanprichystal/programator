
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb no copper
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::BlockBuilders::BuilderThickHelper;

#3th party library
use strict;
use warnings;
use Time::localtime;
use Storable qw(dclone);

#local library
use aliased 'Enums::EnumsGeneral';
 

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

 
	$self->{"stackupMngr"} = shift;
	$self->{"sectionMngr"} = shift;
  
	return $self;
}

sub GetCompThickness{
	my $self = shift;
	my $section = shift;
	
	return 1000;
}

sub GetReqThickness{
	my $self = shift;
	my $section = shift;
	
	return 1000;
}
 
1;

