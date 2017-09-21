
#-------------------------------------------------------------------------------------------#
# Description: Special layer - prepreg, contain special propery and operation for this
# type of layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::Stackup::Layer::PrepregLayer;
use base('Packages::Stackup::Stackup::Layer::StackupLayer');


#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	# child prepregs
	my @prepregs = ();
	$self->{"prepregs"} = \@prepregs;
	
	$self->{"parent"} = 0;
	
	# Identification of material by Multicall ml.xml
		
	$self->{"qId"}     = undef;  # quality of material
	
	return $self;  
}

sub AddChildPrepreg{
	my $self= shift;
	my $prepreg = shift;
	
	push (@{$self->{"prepregs"}}, $prepreg);
}


sub GetAllPrepregs{
	my $self= shift;
	
	return @{$self->{"prepregs"}};
}

sub GetQId{
	my $self = shift;
	return $self->{"qId"};
}

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

