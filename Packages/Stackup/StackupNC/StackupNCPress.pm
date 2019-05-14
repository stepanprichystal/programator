
#-------------------------------------------------------------------------------------------#
# Description: Represent one specific "pressing" and its NC operations
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupNC::StackupNCPress;
use base(Packages::Stackup::StackupNC::StackupNCItemBase);

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $stackupNC      = shift;
	my $topSignalLayer = shift;
	my $botSignalLayer = shift;

	my $self = $class->SUPER::new( $stackupNC, $topSignalLayer, $botSignalLayer );
	bless $self;

	$self->{"pressOrder"} = shift;    # tell order of pressing if exist
	return $self;
}

sub GetSignalLayer {
	my $self = shift;
	my $side = shift;                 #top/bot
	
	die "not implemented";
}

sub GetPressOrder {
	my $self = shift;

	return $self->{"pressOrder"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

