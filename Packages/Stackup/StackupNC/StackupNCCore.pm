
#-------------------------------------------------------------------------------------------#
# Description: Represent core and his NC operation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupNC::StackupNCCore;
use base(Packages::Stackup::StackupNC::StackupNCItemBase);

#3th party library
use utf8;
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

	$self->{"coreNumber"} = shift;    # tell order of pressing if exist

	return $self;
}

sub GetCoreNumber {
	my $self = shift;

	return $self->{"coreNumber"};
}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

