
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb POOL
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnBuilder::MicrostripBuilders::CODiffBuilder;
use base('Packages::Coupon::CpnBuilder::MicrostripBuilders::DiffBuilder');

use Class::Interface;
&implements('Packages::Coupon::CpnBuilder::ICpnBuilder');

#3th party library
use strict;
use warnings;
use Math::Trig;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::Coupon::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	# properties of constrain
 
	return $self;
}

sub Build {
	my $self    = shift;
	my $errMess = shift;
 
 	# 1) Build SE layout
 
	my $result = $self->SUPER::Build($errMess); 

	# 2) Add extra behaviour for conaplanar SE

	$self->{"layout"}->SetCoplanar(1);
	
	my $coSE = $self->_GetXmlConstr()->GetParamDouble("CS");    # �m
 
	foreach my $t  ($self->{"layout"}->GetTracks()){
	
		$t->SetGNDDist($coSE);
	}

	return $result;
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

