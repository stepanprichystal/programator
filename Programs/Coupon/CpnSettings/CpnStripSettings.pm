
#-------------------------------------------------------------------------------------------#
# Description: Default coupon settings
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnSettings::CpnStripSettings;
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
  


sub GetPad2GND {
	my $self = shift;

	return $self->_GetVal("pad2GNDClearance");

}

 

sub GetTrackToCopper {
	my $self = shift;

	return $self->_GetVal("trackToCopper");
}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

