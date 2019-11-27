
#-------------------------------------------------------------------------------------------#
# Description: Interface for Stackup product
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::Stackup::StackupProduct::IProduct;

#3th party library
use strict;
use warnings;

#use File::Copy;

#local library

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

use Class::Interface;
&interface;

sub GetId;

sub GetTopCopperLayer;

sub GetTopCopperNum;

sub GetBotCopperLayer;

sub GetBotCopperNum;

sub GetProductType;

sub GetIsPlated;

sub GetPltNCLayers;

sub GetPlugging;

sub GetOuterCoreTop;

sub GetOuterCoreBot;

sub GetThick;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

