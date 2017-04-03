#-------------------------------------------------------------------------------------------#
# Description: Special structure used for flatenning step. 
# Represent nested step and keep layer, where is coppied original layer rotated by records in SR table
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::FlattenRout::SRFlatten::SRStep::SRNestedStep;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::UniRTM::Enums';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"stepName"} = shift;
	$self->{"angle"} = shift;
	$self->{"routLayer"} = GeneralHelper->GetGUID();

	$self->{"uniRTM"}   = undef;
	$self->{"userFoot"} = undef;
	$self->{"userRoutOnBridges"} = undef;
 
	return $self;
}


sub SetUniRTM {
	my $self = shift;
	my $type = shift;

	$self->{"uniRTM"} = $type;
}

sub GetUniRTM {
	my $self = shift;

	return $self->{"uniRTM"};
}

sub GetRoutLayer {
	my $self = shift;

	return $self->{"routLayer"};
}

sub GetAngle {
	my $self = shift;

	return $self->{"angle"};
}

 
sub GetStepName {
	my $self = shift;

	return $self->{"stepName"};
}

sub GetUserRoutOnBridges {
	my $self = shift;

	return $self->{"userRoutOnBridges"};
}

sub SetUserRoutOnBridges {
	my $self = shift;
	my $routOnBridges = shift;

	$self->{"userRoutOnBridges"} = $routOnBridges;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

