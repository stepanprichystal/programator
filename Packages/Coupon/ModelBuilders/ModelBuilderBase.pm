
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::MicrostripBuilders::ModelBuilderBase;

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
	
	$self->{"inCAM"} = undef;
	$self->{"jobId"} = undef;
	$self->{"settings"} = undef;
	$self->{"settingsConstr"} = undef;
	
	#require rows in nif section
	$self->{"layers"} = [];
	
	return $self;
}
 
 sub Init{
	my $self = shift;
	
	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"settings"} = shift;
	$self->{"settingsConstr"} = shift;
	
}
 
 
sub AddLayer{
	my $self = shift;
	my $layer = shift;
	
	push(@{$self->{"layers"}}, $layer);
	
}
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

