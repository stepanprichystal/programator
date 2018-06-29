
#-------------------------------------------------------------------------------------------#
# Description: Default coupon settings
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnSettings::CpnSettings;

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
	my $self  = {};
	bless $self;

	# Load settings if defined

	$self->{"sett"} = {};

	# use default settings
	my $p = GeneralHelper->Root() . "\\Packages\\Coupon\\CpnSettings\\GlobalSettings.txt";
	die "Global settings file: $p deosn't exist" unless ( -e $p );

	my @lines = @{ FileHelper->ReadAsLines($p) };

	foreach my $l (@lines) {

		if ( $l =~ /.*=.*/ ) {

			my @splited = split( "=", $l );

			$splited[0] =~ s/\s//g;
			$splited[1] =~ s/\s//g;

			$splited[1] =~ s/#.*//i;

			$self->{"sett"}->{ $splited[0] } = $splited[1];
		}
	}

	return $self;

}
 

sub GetStepName {
	my $self = shift;

	return $self->__GetVal("stepName");

}

sub GetPad2PadDist {
	my $self = shift;

	return $self->__GetVal("trackPad2GNDPad");

}


sub GetTrackPad2TrackPad {
	my $self = shift;

	return $self->__GetVal("trackPad2TrackPad");

}


sub GetCouponSingleMargin {
	my $self = shift;

	return $self->__GetVal("marginSingle");

}

sub GetCouponMargin {
	my $self = shift;

	return $self->__GetVal("marginCoupon");

}

sub GetCouponSpace {
	my $self = shift;

	return $self->__GetVal("couponSpace");

}

#sub GetAreaWidth {
#	my $self = shift;
#
#	return $self->__GetVal("w") - 2 * $self->__GetVal("marginCoupon");
#
#}

sub GetCpnSingleWidth {
	my $self = shift;

	return $self->__GetVal("cpnSingleWidth");
}
 
sub GetStackupJobXml {
	my $self = shift;

	return $self->__GetVal("inplanJobPath");
}

sub GetXmlParser {
	my $self = shift;

	return $self->__GetVal("xmlParser");
}

sub GetXmlUnits {

	return "INCH";
}

sub GetPadTrackSize {
	my $self = shift;

	return $self->__GetVal("padTrackSize");
}

sub GetPadGNDSize {
	my $self = shift;

	return $self->__GetVal("padGNDSize");
}

sub GetPadTrackShape {
	my $self = shift;

	return $self->__GetVal("padTrackShape");
}

sub GetPadGNDShape {
	my $self = shift;

	return $self->__GetVal("padGNDShape");
}

sub GetPadTrackSym {
	my $self = shift;

	return $self->__GetVal("padTrackShape") . $self->__GetVal("padTrackSize");
}

sub GetPadGNDSym {
	my $self = shift;

	return $self->__GetVal("padGNDShape") . $self->__GetVal("padGNDSize");
}

sub GetPadGNDSymNeg {
	my $self = shift;

	return $self->__GetVal("padGNDSymNeg");
}

sub GetPadClearance {
	my $self = shift;

	return $self->__GetVal("padClearance");

}

sub GetPad2GNDClearance {
	my $self = shift;

	return $self->__GetVal("pad2GNDClearance");

}

sub GetPadDrillSize {
	my $self = shift;

	return $self->__GetVal("padDrillSize");

}

sub GetTracePad2GNDPad {
	my $self = shift;

	return $self->__GetVal("trackPad2GNDPad");

}

sub GetTrackToCopper {
	my $self = shift;

	return $self->__GetVal("trackToCopper");
}




sub GetGroupPadsDist {
	my $self = shift;

	return $self->__GetVal("groupPadsDist");

}

sub GetMaxTrackCnt {
	my $self = shift;

	return $self->__GetVal("maxTrackCnt");

}

sub GetPoolCnt {
	my $self = shift;

	return $self->__GetVal("poolCnt");

}

 

sub GetTrackPadIsolation {
	my $self = shift;

	return $self->__GetVal("trackPadIsolation");
}


sub GetShareGNDPads {
	my $self = shift;

	return $self->__GetVal("shareGNDPads");
}

sub GetRouteBetween {
	my $self = shift;

	return $self->__GetVal("routeBetween");
}

sub GetRouteAbove {
	my $self = shift;

	return $self->__GetVal("routeAbove");
}

sub GetRouteBelow {
	my $self = shift;

	return $self->__GetVal("routeBelow");
}

sub GetRouteStraight {
	my $self = shift;

	return $self->__GetVal("routeStraight");
}

sub GetTwoEndedDesign{
	my $self = shift;

	return $self->__GetVal("twoEndedDesign");
}

sub GetMaxStripsCntH{
	my $self = shift;

	return $self->__GetVal("maxStripsCntH");
}


# Info text settings

sub GetPadsTopTextDist{
	my $self = shift;

	return $self->__GetVal("padsTopTextDist");
	
}

sub GetInfoText{
	my $self = shift;

	return $self->__GetVal("infoText");
	
}

sub GetInfoTextPosition{
	my $self = shift;

	return $self->__GetVal("infoTextPosition");
	
}

sub GetInfoTextNumber{
	my $self = shift;

	return $self->__GetVal("infoTextNumber");
	
}

sub GetInfoTextTrackImpedance{
	my $self = shift;

	return $self->__GetVal("infoTextTrackImpedance");
	
}

sub GetInfoTextTrackWidth{
	my $self = shift;

	return $self->__GetVal("infoTextTrackWidth");
	
}

sub GetInfoTextTrackSpace{
	my $self = shift;

	return $self->__GetVal("infoTextTrackSpace");
	
}

sub GetInfoTextTrackLayer{
	my $self = shift;

	return $self->__GetVal("infoTextTrackLayer");
	
}

sub GetInfoTextHSpacing{
	my $self = shift;

	return $self->__GetVal("infoTextHSpacing");
	
}

sub GetInfoTextVSpacing{
	my $self = shift;

	return $self->__GetVal("infoTextVSpacing");
	
}
 
sub GetInfoTextWidth{
	my $self = shift;

	return $self->__GetVal("infoTextWidth");
	
}

sub GetInfoTextHeight{
	my $self = shift;

	return $self->__GetVal("infoTextHeight");
	
}

sub GetInfoTextWeight{
	my $self = shift;

	return $self->__GetVal("infoTextWeight");
	
} 

sub GetInfoTextRightCpnDist{
	my $self = shift;

	return $self->__GetVal("infoTextRightCpnDist");
	
} 

sub GetInfoTextUnmask{
	my $self = shift;

	return $self->__GetVal("infoTextUnmask");
	
} 

 
 
# pad text settings

sub GetPadTextWidth{
	my $self = shift;

	return $self->__GetVal("padTextWidth");
	
} 

sub GetPadTextHeight{
	my $self = shift;

	return $self->__GetVal("padTextHeight");
	
} 

sub GetPadTextWeight{
	my $self = shift;

	return $self->__GetVal("padTextWeight");
	
} 

sub GetPadTextDist{
	my $self = shift;

	return $self->__GetVal("padTextDist");
	
} 

sub GetPadText{
	my $self = shift;

	return $self->__GetVal("padText");
	
}

sub GetPadTextUnmask{
	my $self = shift;

	return $self->__GetVal("padTextUnmask");
	
} 

 
 

# Guard track settings

sub GetGuardTracks{
	my $self = shift;

	return $self->__GetVal("guardTracks");
	
} 

sub GetGuardTracksType{
	my $self = shift;

	return $self->__GetVal("guardTracksType");
	
} 


sub GetGuardTrack2TrackDist{
	my $self = shift;

	return $self->__GetVal("guardTrack2TrackDist");
	
} 

sub GetGuardTrack2PadDist{
	my $self = shift;

	return $self->__GetVal("guardTrack2PadDist");
	
} 

sub GetGuardTrack2Shielding{
	my $self = shift;

	return $self->__GetVal("guardTrack2Shielding");
	
} 


sub GetGuardTrackWidth{
	my $self = shift;

	return $self->__GetVal("guardTrackWidth");
	
} 

# Shielding settings

sub GetShielding{
	my $self = shift;

	return $self->__GetVal("shielding");
	
} 

sub GetShieldingType{
	my $self = shift;

	return $self->__GetVal("shieldingType");
	
} 


sub GetShieldingSymbol{
	my $self = shift;

	return $self->__GetVal("shieldingSymbol");
	
} 


sub GetShieldingSymbolDX{
	my $self = shift;

	return $self->__GetVal("shieldingSymbolDX");
	
} 

sub GetShieldingSymbolDY{
	my $self = shift;

	return $self->__GetVal("shieldingSymbolDY");
	
} 
 
 

sub __GetVal {
	my $self = shift;
	my $key  = shift;

	my $v = $self->{"sett"}->{$key};

	die "Value of key: $key is not defined" unless ( defined $v );

	return $v;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

