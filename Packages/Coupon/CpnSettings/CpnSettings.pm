
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

	return $self->__GetVal("tracePad2GNDPad");

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

sub GetAreaWidth {
	my $self = shift;

	return $self->__GetVal("w") - 2 * $self->__GetVal("marginCoupon");

}

sub GetWidth {
	my $self = shift;

	return $self->__GetVal("w");

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

sub GetGroupPadsDist {
	my $self = shift;

	return $self->__GetVal("groupPadsDist");

}

sub GetPadsTopTextDist {
	my $self = shift;

	return $self->__GetVal("padsTopTextDist");

}

sub GetTopTextHeight {
	my $self = shift;

	return $self->__GetVal("topTextHeight");

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

