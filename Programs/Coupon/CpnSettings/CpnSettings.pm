
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

sub SetStepName {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("stepName", $val);
}

sub GetCouponSingleMargin {
	my $self = shift;

	return $self->_GetVal("couponSingleMargin");

}

sub SetCouponSingleMargin {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("couponSingleMargin", $val);
}

sub GetCouponMargin {
	my $self = shift;

	return $self->_GetVal("couponMargin");

}

sub SetCouponMargin {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("couponMargin", $val);
}

sub GetCouponSpace {
	my $self = shift;

	return $self->_GetVal("couponSpace");

}

sub Set {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("", $val);
}

sub GetTrackPadIsolation {
	my $self = shift;

	return $self->_GetVal("trackPadIsolation");
}

sub SetTrackPadIsolation {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("trackPadIsolation", $val);
}

sub GetXmlUnits {

	return "INCH";
}

sub GetMaxTrackCnt {
	my $self = shift;

	return $self->_GetVal("maxTrackCnt");
}

sub SetMaxTrackCnt {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("maxTrackCnt", $val);
}

sub GetShareGNDPads {
	my $self = shift;

	return $self->_GetVal("shareGNDPads");
}

sub SetShareGNDPads {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("shareGNDPads", $val);
}

sub GetRouteBetween {
	my $self = shift;

	return $self->_GetVal("routeBetween");
}

sub SetRouteBetween {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("routeBetween", $val);
}

sub GetRouteAbove {
	my $self = shift;

	return $self->_GetVal("routeAbove");
}

sub SetRouteAbove {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("routeAbove", $val);
}

sub GetRouteBelow {
	my $self = shift;

	return $self->_GetVal("routeBelow");
}

sub SetRouteBelow {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("routeBelow", $val);
}

sub GetRouteStraight {
	my $self = shift;

	return $self->_GetVal("routeStraight");
}

sub SetRouteStraight {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("routeStraight", $val);
}

sub GetTwoEndedDesign {
	my $self = shift;

	return $self->_GetVal("twoEndedDesign");
}

sub SetTwoEndedDesign {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("twoEndedDesign", $val);
}

# Info text settings

sub GetPadsTopTextDist {
	my $self = shift;

	return $self->_GetVal("padsTopTextDist");

}

sub SetPadsTopTextDist {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("padsTopTextDist", $val);
}

sub GetInfoText {
	my $self = shift;

	return $self->_GetVal("infoText");

}

sub SetInfoText {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("infoText", $val);
}

sub GetInfoTextPosition {
	my $self = shift;

	return $self->_GetVal("infoTextPosition");

}

sub SetInfoTextPosition {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("infoTextPosition", $val);
}

sub GetInfoTextNumber {
	my $self = shift;

	return $self->_GetVal("infoTextNumber");

}

sub SetInfoTextNumber {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("infoTextNumber", $val);
}

sub GetInfoTextTrackImpedance {
	my $self = shift;

	return $self->_GetVal("infoTextTrackImpedance");

}

sub SetInfoTextTrackImpedance {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("infoTextTrackImpedance", $val);
}

sub GetInfoTextTrackWidth {
	my $self = shift;

	return $self->_GetVal("infoTextTrackWidth");

}

sub SetInfoTextTrackWidth {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("infoTextTrackWidth", $val);
}

sub GetInfoTextTrackSpace {
	my $self = shift;

	return $self->_GetVal("infoTextTrackSpace");

}

sub SetInfoTextTrackSpace {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("infoTextTrackSpace", $val);
}

sub GetInfoTextTrackLayer {
	my $self = shift;

	return $self->_GetVal("infoTextTrackLayer");

}

sub SetInfoTextTrackLayer {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("infoTextTrackLayer", $val);
}

sub GetInfoTextHSpacing {
	my $self = shift;

	return $self->_GetVal("infoTextHSpacing");

}

sub SetInfoTextHSpacing {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("infoTextHSpacing", $val);
}

sub GetInfoTextVSpacing {
	my $self = shift;

	return $self->_GetVal("infoTextVSpacing");

}

sub SetInfoTextVSpacing {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("infoTextVSpacing", $val);
}

sub GetInfoTextWidth {
	my $self = shift;

	return $self->_GetVal("infoTextWidth");

}

sub SetInfoTextWidth {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("infoTextWidth", $val);
}

sub GetInfoTextHeight {
	my $self = shift;

	return $self->_GetVal("infoTextHeight");

}

sub SetInfoTextHeight {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("infoTextHeight", $val);
}

sub GetInfoTextWeight {
	my $self = shift;

	return $self->_GetVal("infoTextWeight");

}

sub SetInfoTextWeight {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("infoTextWeight", $val);
}

sub GetInfoTextRightCpnDist {
	my $self = shift;

	return $self->_GetVal("infoTextRightCpnDist");

}

sub SetInfoTextRightCpnDist {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("infoTextRightCpnDist", $val);
}

sub GetInfoTextUnmask {
	my $self = shift;

	return $self->_GetVal("infoTextUnmask");

}

sub SetInfoTextUnmask {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("infoTextUnmask", $val);
}

# pad text settings

sub GetPadTextWidth {
	my $self = shift;

	return $self->_GetVal("padTextWidth");

}

sub SetPadTextWidth {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("padTextWidth", $val);
}

sub GetPadTextHeight {
	my $self = shift;

	return $self->_GetVal("padTextHeight");

}

sub SetPadTextHeight {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("padTextHeight", $val);
}

sub GetPadTextWeight {
	my $self = shift;

	return $self->_GetVal("padTextWeight");

}

sub SetPadTextWeight {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("padTextWeight", $val);
}

sub GetPadTextDist {
	my $self = shift;

	return $self->_GetVal("padTextDist");

}

sub SetPadTextDist {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("padTextDist", $val);
}

sub GetPadText {
	my $self = shift;

	return $self->_GetVal("padText");

}

sub SetPadText {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("padText", $val);
}

sub GetPadTextUnmask {
	my $self = shift;

	return $self->_GetVal("padTextUnmask");

}

sub SetPadTextUnmask {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("padTextUnmask", $val);
}

# Guard track settings

sub GetGuardTracks {
	my $self = shift;

	return $self->_GetVal("guardTracks");

}

sub SetGuardTracks {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("guardTracks", $val);
}

sub GetGuardTracksType {
	my $self = shift;

	return $self->_GetVal("guardTracksType");

}

sub SetGuardTracksType {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("guardTracksType", $val);
}

sub GetGuardTrack2TrackDist {
	my $self = shift;

	return $self->_GetVal("guardTrack2TrackDist");

}

sub SetGuardTrack2TrackDist {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("guardTrack2TrackDist", $val);
}

sub GetGuardTrack2PadDist {
	my $self = shift;

	return $self->_GetVal("guardTrack2PadDist");

}

sub SetGuardTrack2PadDist {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("guardTrack2PadDist", $val);
}

sub GetGuardTrack2Shielding {
	my $self = shift;

	return $self->_GetVal("guardTrack2Shielding");

}

sub SetGuardTrack2Shielding {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("guardTrack2Shielding", $val);
}

sub GetGuardTrackWidth {
	my $self = shift;

	return $self->_GetVal("guardTrackWidth");

}

sub SetGuardTrackWidth {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("guardTrackWidth", $val);
}

# Shielding settings

sub GetShielding {
	my $self = shift;

	return $self->_GetVal("shielding");

}

sub SetShielding {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("shielding", $val);
}

sub GetShieldingType {
	my $self = shift;

	return $self->_GetVal("shieldingType");

}

sub SetShieldingType {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("shieldingType", $val);
}

sub GetShieldingSymbol {
	my $self = shift;

	return $self->_GetVal("shieldingSymbol");

}

sub SetShieldingSymbol {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("shieldingSymbol", $val);
}

sub GetShieldingSymbolDX {
	my $self = shift;

	return $self->_GetVal("shieldingSymbolDX");

}

sub SetShieldingSymbolDX {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("shieldingSymbolDX", $val);
}

sub GetShieldingSymbolDY {
	my $self = shift;

	return $self->_GetVal("shieldingSymbolDY");

}

sub SetShieldingSymbolDY {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("shieldingSymbolDY", $val);
}

# Title (logo + job id)

sub GetTitle {
	my $self = shift;

	return $self->_GetVal("title");
}

sub SetTitle {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("title", $val);
}

sub GetTitleTextWidth {
	my $self = shift;

	return $self->_GetVal("titleTextWidth");

}

sub SetTitleTextWidth {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("titleTextWidth", $val);
}

sub GetTitleTextHeight {
	my $self = shift;

	return $self->_GetVal("titleTextHeight");

}

sub SetTitleTextHeight {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("titleTextHeight", $val);
}

sub GetTitleTextWeight {
	my $self = shift;

	return $self->_GetVal("titleTextWeight");

}

sub SetTitleTextWeight {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("titleTextWeight", $val);
}

sub GetTitleMargin {
	my $self = shift;

	return $self->_GetVal("titleMargin");

}

sub SetTitleMargin {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("titleMargin", $val);
}

sub GetTitleType {
	my $self = shift;

	return $self->_GetVal("titleType");

}

sub SetTitleType {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("titleType", $val);
}

sub GetTitleLogoJobIdHDist {
	my $self = shift;

	return $self->_GetVal("titleLogoJobIdHDist");

}

sub SetTitleLogoJobIdHDist {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("titleLogoJobIdHDist", $val);
}

sub GetTitleLogoJobIdVDist {
	my $self = shift;

	return $self->_GetVal("titleLogoJobIdVDist");

}

sub SetTitleLogoJobIdVDist {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("titleLogoJobIdVDist", $val);
}

sub GetLogoWidth {
	my $self = shift;

	return $self->_GetVal("logoWidth");

}

sub SetLogoWidth {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("logoWidth", $val);
}

sub GetLogoHeight {
	my $self = shift;

	return $self->_GetVal("logoHeight");

}

sub SetLogoHeight {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("logoHeight", $val);
}

sub GetLogoSymbol {
	my $self = shift;

	return $self->_GetVal("logoSymbol");

}

sub SetLogoSymbol {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("logoSymbol", $val);
}

sub GetLogoSymbolWidth {
	my $self = shift;

	return $self->_GetVal("logoSymbolWidth");

}

sub SetLogoSymbolWidth {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("logoSymbolWidth", $val);
}

sub GetLogoSymbolHeight {
	my $self = shift;

	return $self->_GetVal("logoSymbolHeight");

}

sub SetLogoSymbolHeight {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("logoSymbolHeight", $val);
}

sub GetTitleUnMask {
	my $self = shift;

	return $self->_GetVal("titleUnMask");

}

sub SetTitleUnMask {
	my $self = shift;
	my $val  = shift;

	$self->_SetVal("titleUnMask", $val);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Coupon::CpnSettings::CpnSettings';
	
	my $sett =CpnSettings->new();
	print $sett->GetHelpText("stepName");
	print $sett->GetLabelText("stepName");
	
	my $v = $sett->GetStepName();
	die;

}

1;

