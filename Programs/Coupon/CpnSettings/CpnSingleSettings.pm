
#-------------------------------------------------------------------------------------------#
# Description: Default coupon settings
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnSettings::CpnSingleSettings;
use base('Programs::Coupon::CpnSettings::CpnSettingsBase');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;
 
}
 
 sub GetPad2PadDist {
	my $self = shift;

	return $self->_GetVal("trackPad2GNDPad");

}


sub GetTrackPad2TrackPad {
	my $self = shift;

	return $self->_GetVal("trackPad2TrackPad");

}

sub GetCpnSingleWidth {
	my $self = shift;

	return $self->_GetVal("cpnSingleWidth");
}
 
 

sub GetPadTrackSize {
	my $self = shift;

	return $self->_GetVal("padTrackSize");
}

sub GetPadGNDSize {
	my $self = shift;

	return $self->_GetVal("padGNDSize");
}

sub GetPadTrackShape {
	my $self = shift;

	return $self->_GetVal("padTrackShape");
}

sub GetPadGNDShape {
	my $self = shift;

	return $self->_GetVal("padGNDShape");
}

sub GetPadTrackSym {
	my $self = shift;

	return $self->_GetVal("padTrackShape") . $self->_GetVal("padTrackSize");
}

sub GetPadGNDSym {
	my $self = shift;

	return $self->_GetVal("padGNDShape") . $self->_GetVal("padGNDSize");
}

sub GetPadGNDSymNeg {
	my $self = shift;

	return $self->_GetVal("padGNDSymNeg");
} 

sub GetPadDrillSize {
	my $self = shift;

	return $self->_GetVal("padDrillSize");

}


sub GetTrackPad2GNDPad {
	my $self = shift;

	return $self->_GetVal("trackPad2GNDPad");

}


sub GetGroupPadsDist {
	my $self = shift;

	return $self->_GetVal("groupPadsDist");

}


sub GetPoolCnt {
	my $self = shift;

	return $self->_GetVal("poolCnt");

}


sub GetMaxStripsCntH{
	my $self = shift;

	return $self->_GetVal("maxStripsCntH");
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

