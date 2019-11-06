
#-------------------------------------------------------------------------------------------#
# Description: Contain inforamtion about stacku layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::Stackup::StackupProduct::ProductLayer;
 
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

	$self->{"type"} = shift;
	$self->{"data"} = shift;

	return $self;
}
# Enums->ProductL_PRODUCT
# Enums->ProductL_MATERIAL
sub GetType {
	my $self = shift;

	return $self->{"type"};
}

# Data can have one of theses structures:
#Stackup::StackupProduct::IProduct
#StackupBase::Layer::IStackupLayer
sub GetData {
	my $self = shift;

	return $self->{"data"};
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

