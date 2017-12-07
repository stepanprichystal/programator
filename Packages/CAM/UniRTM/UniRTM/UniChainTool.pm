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
use overload '""' => \&stringify;

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

	$self->{"chainOrder"} = shift;
	$self->{"chainSize"}  = shift;    # size of tool in µm
	$self->{"comp"}       = shift;
	$self->{"uniDTMTool"} = shift;
	
	 
 
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
 

sub GetUniDTMTool{
	my $self = shift;

	unless(defined $self->{"uniDTMTool"}){
		die "UniDTMTool was not initialized for this Chain tool: ".$self;
	}

	return $self->{"uniDTMTool"};
}



sub stringify {
    my ($self) = @_;
    return "UniChainTool - ChainOrder: ".$self->GetChainOrder().", ChainComp: ".$self->GetComp().", ChainSize: ".$self->GetChainSize();
}


 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

