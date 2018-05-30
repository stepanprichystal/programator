
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb POOL
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::MicrostripBuilders::CoatedMicrostrip;
use base('Packages::Coupon::MicrostripBuilders::ModelBuilderBase');

use Class::Interface;
&implements('Packages::Coupon::MicrostripBuilders::IModelBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Coupon::MicrostripBuilders::CouponLayers::MaskLayer';
use aliased 'Packages::Coupon::MicrostripBuilders::CouponLayers::TraceLayer';
use aliased 'Packages::Coupon::Helper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"}   = shift;
	$self->{"jobId"}   = shift;
 	
	
	

	return $self;
}

 
sub Build {
	my $self    = shift;
 	my $data = shift;
 
 	# translate InStack layer name to InCAM layer name
 	
 	$self->{"settingsConstr"}->getAttribute("TOP_MODEL_LAYER");
 	$self->{"settingsConstr"}->getAttribute("TRACE_LAYER");
 	$self->{"settingsConstr"}->getAttribute("BOTTOM_MODEL_LAYER");

 	my $sigL = Helper->GetLayerName($self->{"settingsConstr"}->getAttribute("TRACE_LAYER"),$self->{"settings")->GetXmlParser() );
 	my $gndL = Helper->GetLayerName($self->{"settingsConstr"}->getAttribute("BOTTOM_MODEL_LAYER"),$self->{"settings")->GetXmlParser() );
  
	AddLayer->(MaskLayer->new($sigL eq "c"? "mc" : "ms"));
	AddLayer->(TraceLayer->new($sigL));
	AddLayer->(GNDLayer->new($gndL));
 
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

