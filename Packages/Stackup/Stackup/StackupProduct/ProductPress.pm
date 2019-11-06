
#-------------------------------------------------------------------------------------------#
# Description: Contain inforamtion about stacku layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::Stackup::StackupProduct::ProductPress;
use base('Packages::Stackup::Stackup::StackupProduct::ProductBase');

use Class::Interface;
&implements('Packages::Stackup::Stackup::StackupProduct::IProduct');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Stackup::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"productType"} = Enums->Product_PRESS;

	#Pressing order
	$self->{"order"} = shift;

	return $self;
}

sub GetPressOrder {
	my $self = shift;

	return $self->{"order"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

