
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::MicrostripBuilders::MicrostripBuilderBase;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::Point';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;
	
	$self->{"inCAM"} = undef;
	$self->{"jobId"} = undef;
	$self->{"modelBuilder"} = undef;
	$self->{"settings"} = undef;
	$self->{"settingsConstr"} = undef;
	
	$self->{"origin"} = Point->new();
	
	$self->{"layers"} = [];
	
	return $self;
}

sub Init{
	my $self = shift;
	
	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"modelBuilder"} = shift;
	$self->{"settings"} = shift;
	$self->{"constrainParams"} = shift;
	
}
 
 
 
 
sub Draw{
	
	
	
} 
 
sub GetLayers{
	my $self = shift;
	
	return @{$self->{"layers"}};
} 


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

