
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
	
	$self->{"surfacesId"} = [];     # surfaces, which contain this tool

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

sub GetSurfacesId {
	my $self = shift;

	return @{$self->{"surfacesId"}};
}

sub SetSurfacesId {
	my $self = shift;
	my $surfacesId = shift;

	$self->{"surfacesId"} = $surfacesId;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

