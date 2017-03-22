#-------------------------------------------------------------------------------------------#
# Description: Contain listo of all tools in layer, regardless it is tool from surface, pad,
# lines..
# Responsible for tools are unique (diameter + typeProc)
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::ExportPool::Routing::StepList::StepPlace;
#3th party library
use strict;
use warnings;
 

#local library
use aliased 'Packages::CAM::UniRTM::Enums';


use aliased 'Helpers::GeneralHelper';


#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"posX"} = shift;
	$self->{"posY"}  = shift;    # size of tool in �m
	
	$self->{"id"}  = GeneralHelper->GetGUID();
 
	return $self;
}
 
sub GetPosX {
	my $self = shift;
	
	return $self->{"posX"};
}

sub GetPosY {
	my $self = shift;
	
	return $self->{"posY"};
}

sub GetStepId {
	my $self = shift;
	
	return $self->{"id"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

