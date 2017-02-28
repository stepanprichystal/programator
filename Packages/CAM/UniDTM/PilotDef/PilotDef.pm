
#-------------------------------------------------------------------------------------------#
# Description:  Class represent universal tool regardless it is tool from surface, pad, slot..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniDTM::PilotDef::PilotDef;

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"drillSize"} = shift; # drill size, which will be pre-drilled

	# Diameters, which hole will be pre-drilled
	my @d = ();
	$self->{"pilotDiameters"} = \@d; 
 
	return $self;
}
 
 
sub GetDrillSize {
	my $self = shift;

	return $self->{"drillSize"};
}  
 
sub GetPilotDiameters {
	my $self = shift;

	return @{$self->{"pilotDiameters"}};
} 
 
sub AddPilotDiameter {
	my $self = shift;
	my $diameter = shift;

	push(@{$self->{"pilotDiameters"}}, $diameter );
}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

