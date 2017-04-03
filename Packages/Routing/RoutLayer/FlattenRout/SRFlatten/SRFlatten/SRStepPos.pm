#-------------------------------------------------------------------------------------------#
# Description: Special structure for flatenning step. 
# Represent nested step (positiooon, rotation, UniRTM etc)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::FlattenRout::SRFlatten::SRFlatten::SRStepPos;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::UniRTM::Enums';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';


#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"SRStep"} = shift;
	$self->{"posX"}   = shift;
	$self->{"posY"}   = shift;

	$self->{"id"} = GeneralHelper->GetGUID();

	return $self;
}

sub GetStepId {
	my $self = shift;

	return $self->{"id"};
}

sub GetPosX {
	my $self = shift;

	return $self->{"posX"};
}

sub GetPosY {
	my $self = shift;

	return $self->{"posY"};
}

# =======================================
# SRStep methods
# =======================================

sub GetAngle {
	my $self = shift;

	return $self->{"SRStep"}->GetAngle();
}

sub GetRoutLayer {
	my $self = shift;

	return $self->{"SRStep"}->GetRoutLayer();
}

sub GetUniRTM {
	my $self = shift;

	return $self->{"SRStep"}->GetUniRTM();
}

sub GetStepName {
	my $self = shift;

	return $self->{"SRStep"}->GetStepName();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

