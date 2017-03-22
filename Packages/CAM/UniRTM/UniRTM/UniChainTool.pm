#-------------------------------------------------------------------------------------------#
# Description: Contain listo of all tools in layer, regardless it is tool from surface, pad,
# lines..
# Responsible for tools are unique (diameter + typeProc)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniRTM::UniRTM::UniChainTool;

#3th party library
use strict;
use warnings;
use XML::Simple;

#local library
use aliased 'Packages::CAM::UniRTM::Enums';
 

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"chainOrder"} = shift;
	$self->{"chainSize"}  = shift;    # size of tool in µm
	$self->{"comp"}       = shift;
 
	return $self;
}

# Helper methods -------------------------------------
 

# GET/SET Properties -------------------------------------
 

sub GetChainOrder {
	my $self = shift;

	return $self->{"chainOrder"};

}
 
 
sub GetComp {
	my $self = shift;

	return $self->{"comp"};
}
 

sub GetChainSize {
	my $self = shift;

	return $self->{"chainSize"};
}
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

