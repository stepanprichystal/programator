
#-------------------------------------------------------------------------------------------#
# Description:  Class represent universal tool regardless it is tool from surface, pad, slot..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniDTM::UniTool::UniToolDTMSURF;
use base("Packages::CAM::UniDTM::UniTool::UniToolBase");

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"drillSize2"} = undef;    # diameter of rout pocket tool
	
	$self->{"surfaceId"} = undef;     # sign surface where is tool defined

	return $self;
}


sub GetDrillSize2 {
	my $self = shift;

	return $self->{"drillSize2"};
}

sub SetDrillSize2 {
	my $self = shift;

	$self->{"drillSize2"} = shift;
}

sub GetSurfaceId {
	my $self = shift;

	return $self->{"surfaceId"};
}

sub SetSurfaceId {
	my $self = shift;

	$self->{"surfaceId"} = shift;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

