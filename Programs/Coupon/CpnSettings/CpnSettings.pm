
#-------------------------------------------------------------------------------------------#
# Description: Default coupon settings
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnSettings::CpnSettings;
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
 

sub GetStepName {
	my $self = shift;

	return $self->_GetVal("stepName");

}



sub GetCouponSingleMargin {
	my $self = shift;

	return $self->_GetVal("marginSingle");

}

sub GetCouponMargin {
	my $self = shift;

	return $self->_GetVal("marginCoupon");

}

sub GetCouponSpace {
	my $self = shift;

	return $self->_GetVal("couponSpace");

}


sub GetTrackPadIsolation {
	my $self = shift;

	return $self->_GetVal("trackPadIsolation");
}

#sub GetAreaWidth {
#	my $self = shift;
#
#	return $self->_GetVal("w") - 2 * $self->_GetVal("marginCoupon");
#
#}

#
# 
#sub GetStackupJobXml {
#	my $self = shift;
#
#	return $self->_GetVal("inplanJobPath");
#}

#sub GetXmlParser {
#	my $self = shift;
#
#	return $self->_GetVal("xmlParser");
#}

sub GetXmlUnits {

	return "INCH";
}





sub GetMaxTrackCnt {
	my $self = shift;

	return $self->_GetVal("maxTrackCnt");
}

sub SetMaxTrackCnt {
	my $self = shift;

	$self->{"sett"}->{"maxTrackCnt"} = shift; 
}


 



sub GetShareGNDPads {
	my $self = shift;

	return $self->_GetVal("shareGNDPads");
}

sub GetRouteBetween {
	my $self = shift;

	return $self->_GetVal("routeBetween");
}

sub GetRouteAbove {
	my $self = shift;

	return $self->_GetVal("routeAbove");
}

sub GetRouteBelow {
	my $self = shift;

	return $self->_GetVal("routeBelow");
}

sub GetRouteStraight {
	my $self = shift;

	return $self->_GetVal("routeStraight");
}

sub GetTwoEndedDesign{
	my $self = shift;

	return $self->_GetVal("twoEndedDesign");
}


# Info text settings

sub GetPadsTopTextDist{
	my $self = shift;

	return $self->_GetVal("padsTopTextDist");
	
}

sub GetInfoText{
	my $self = shift;

	return $self->_GetVal("infoText");
	
}

sub GetInfoTextPosition{
	my $self = shift;

	return $self->_GetVal("infoTextPosition");
	
}

sub GetInfoTextNumber{
	my $self = shift;

	return $self->_GetVal("infoTextNumber");
	
}

sub GetInfoTextTrackImpedance{
	my $self = shift;

	return $self->_GetVal("infoTextTrackImpedance");
	
}

sub GetInfoTextTrackWidth{
	my $self = shift;

	return $self->_GetVal("infoTextTrackWidth");
	
}

sub GetInfoTextTrackSpace{
	my $self = shift;

	return $self->_GetVal("infoTextTrackSpace");
	
}

sub GetInfoTextTrackLayer{
	my $self = shift;

	return $self->_GetVal("infoTextTrackLayer");
	
}

sub GetInfoTextHSpacing{
	my $self = shift;

	return $self->_GetVal("infoTextHSpacing");
	
}

sub GetInfoTextVSpacing{
	my $self = shift;

	return $self->_GetVal("infoTextVSpacing");
	
}
 
sub GetInfoTextWidth{
	my $self = shift;

	return $self->_GetVal("infoTextWidth");
	
}

sub GetInfoTextHeight{
	my $self = shift;

	return $self->_GetVal("infoTextHeight");
	
}

sub GetInfoTextWeight{
	my $self = shift;

	return $self->_GetVal("infoTextWeight");
	
} 

sub GetInfoTextRightCpnDist{
	my $self = shift;

	return $self->_GetVal("infoTextRightCpnDist");
	
} 

sub GetInfoTextUnmask{
	my $self = shift;

	return $self->_GetVal("infoTextUnmask");
	
} 

 
 
# pad text settings

sub GetPadTextWidth{
	my $self = shift;

	return $self->_GetVal("padTextWidth");
	
} 

sub GetPadTextHeight{
	my $self = shift;

	return $self->_GetVal("padTextHeight");
	
} 

sub GetPadTextWeight{
	my $self = shift;

	return $self->_GetVal("padTextWeight");
	
} 

sub GetPadTextDist{
	my $self = shift;

	return $self->_GetVal("padTextDist");
	
} 

sub GetPadText{
	my $self = shift;

	return $self->_GetVal("padText");
	
}

sub GetPadTextUnmask{
	my $self = shift;

	return $self->_GetVal("padTextUnmask");
	
} 

 
 

# Guard track settings

sub GetGuardTracks{
	my $self = shift;

	return $self->_GetVal("guardTracks");
	
} 

sub GetGuardTracksType{
	my $self = shift;

	return $self->_GetVal("guardTracksType");
	
} 


sub GetGuardTrack2TrackDist{
	my $self = shift;

	return $self->_GetVal("guardTrack2TrackDist");
	
} 

sub GetGuardTrack2PadDist{
	my $self = shift;

	return $self->_GetVal("guardTrack2PadDist");
	
} 

sub GetGuardTrack2Shielding{
	my $self = shift;

	return $self->_GetVal("guardTrack2Shielding");
	
} 


sub GetGuardTrackWidth{
	my $self = shift;

	return $self->_GetVal("guardTrackWidth");
	
} 

# Shielding settings

sub GetShielding{
	my $self = shift;

	return $self->_GetVal("shielding");
	
} 

sub GetShieldingType{
	my $self = shift;

	return $self->_GetVal("shieldingType");
	
} 


sub GetShieldingSymbol{
	my $self = shift;

	return $self->_GetVal("shieldingSymbol");
	
} 


sub GetShieldingSymbolDX{
	my $self = shift;

	return $self->_GetVal("shieldingSymbolDX");
	
} 

sub GetShieldingSymbolDY{
	my $self = shift;

	return $self->_GetVal("shieldingSymbolDY");
	
} 
 
# Title (logo + job id)

sub GetTitle{
	my $self = shift;

	return $self->_GetVal("title");	
} 

sub GetTitleTextWidth{
	my $self = shift;

	return $self->_GetVal("titleTextWidth");
	
} 

sub GetTitleTextHeight{
	my $self = shift;

	return $self->_GetVal("titleTextHeight");
	
} 
 
sub GetTitleTextWeight{
	my $self = shift;

	return $self->_GetVal("titleTextWeight");
	
}  

sub GetTitleMargin{
	my $self = shift;

	return $self->_GetVal("titleMargin");
	
}

sub GetTitleType{
	my $self = shift;

	return $self->_GetVal("titleType");
	
}

sub GetTitleLogoJobIdHDist{
	my $self = shift;

	return $self->_GetVal("titleLogoJobIdHDist");
	
}

sub GetTitleLogoJobIdVDist{
	my $self = shift;

	return $self->_GetVal("titleLogoJobIdVDist");
	
} 

sub GetLogoWidth{
	my $self = shift;

	return $self->_GetVal("logoWidth");
	
}

sub GetLogoHeight{
	my $self = shift;

	return $self->_GetVal("logoHeight");
	
}
 
sub GetLogoSymbol{
	my $self = shift;

	return $self->_GetVal("logoSymbol");
	
} 
 
sub GetLogoSymbolWidth{
	my $self = shift;

	return $self->_GetVal("logoSymbolWidth");
	
}

sub GetLogoSymbolHeight{
	my $self = shift;

	return $self->_GetVal("logoSymbolHeight");
	
}

sub GetTitleUnMask{
	my $self = shift;

	return $self->_GetVal("titleUnMask");
	
}

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

