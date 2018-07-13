
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

sub SetPad2PadDist {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("trackPad2GNDPad") = $val;
}


sub GetTrackPad2TrackPad {
	my $self = shift;

	return $self->_GetVal("trackPad2TrackPad");

}

sub SetTrackPad2TrackPad {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("trackPad2TrackPad") = $val;
}

sub GetCpnSingleWidth {
	my $self = shift;

	return $self->_GetVal("cpnSingleWidth");
}
 
sub SetCpnSingleWidth {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("") = $val;
} 

sub GetPadTrackSize {
	my $self = shift;

	return $self->_GetVal("padTrackSize");
} 

sub Set {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("cpnSingleWidth") = $val;
}

sub GetPadGNDSize {
	my $self = shift;

	return $self->_GetVal("padGNDSize");
}
 
sub SetPadGNDSize {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("padGNDSize") = $val;
}

sub GetPadTrackShape {
	my $self = shift;

	return $self->_GetVal("padTrackShape");
}
 
sub SetPadTrackShape {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("padTrackShape") = $val;
}

sub GetPadGNDShape {
	my $self = shift;

	return $self->_GetVal("padGNDShape");
}
 
sub SetPadGNDShape {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("padGNDShape") = $val;
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
 
sub SetPadGNDSymNeg {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("padGNDSymNeg") = $val;
}

sub GetPadDrillSize {
	my $self = shift;

	return $self->_GetVal("padDrillSize");

}
 
sub SetPadDrillSize {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("padDrillSize") = $val;
}


sub GetTrackPad2GNDPad {
	my $self = shift;

	return $self->_GetVal("trackPad2GNDPad");

}

 
sub SetTrackPad2GNDPad {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("trackPad2GNDPad") = $val;
}

sub GetGroupPadsDist {
	my $self = shift;

	return $self->_GetVal("groupPadsDist");

}

 
sub SetGroupPadsDist {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("groupPadsDist") = $val;
}

sub GetPoolCnt {
	my $self = shift;

	return $self->_GetVal("poolCnt");

}

 
sub SetPoolCnt {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("poolCnt") = $val;
}

sub GetMaxStripsCntH{
	my $self = shift;

	return $self->_GetVal("maxStripsCntH");
}
 
sub SetMaxStripsCntH {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("maxStripsCntH") = $val;
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

