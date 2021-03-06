
#-------------------------------------------------------------------------------------------#
# Description: Settings for coupon strip
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnSettings::CpnStripSettings;
use base('Programs::Coupon::CpnSettings::CpnSettingsBase');

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

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
	my $self  = $class->SUPER::new("CpnStripSettings.txt");
	bless $self;

}

sub GetPad2GND {
	my $self = shift;

	return $self->_GetVal("pad2GND");

}

sub SetPad2GND {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("pad2GND", $val);
}

sub GetTrackToCopper {
	my $self = shift;

	return $self->_GetVal("trackToCopper");
}

sub SetTrackToCopper {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("trackToCopper", $val);
}

sub GetPadClearance {
	my $self = shift;

	return $self->_GetVal("padClearance");

}

sub SetPadClearance {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("padClearance", $val);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

