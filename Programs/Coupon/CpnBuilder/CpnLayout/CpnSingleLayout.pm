
#-------------------------------------------------------------------------------------------#
# Description: Layout of single coupon/group
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::CpnLayout::CpnSingleLayout;
use base qw(Programs::Coupon::CpnBuilder::CpnLayout::CpnLayoutBase);

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"h"}                     = undef;    # dynamic heght of single coupon
	$self->{"w"}                     = undef;    # dynamic width of single coupo (active area width + text on rights)
	$self->{"stripsLayouts"}         = [];
	$self->{"infoTextLayout"}        = undef;
	$self->{"guardTracksLayout"}     = undef;
	$self->{"shieldingLayout"}       = undef;
	$self->{"shieldingGNDViaLayout"} = undef;
	$self->{"cpnSingleWidth"}        = undef;
	$self->{"position"}              = undef;

	$self->{"padGNDSymNeg"}  = undef;
	$self->{"padTrackSize"}  = undef;
	$self->{"padTrackSym"}   = undef;
	$self->{"padGNDShape"}   = undef;
	$self->{"padGNDSize"}    = undef;
	$self->{"padGNDSym"}     = undef;
	$self->{"padTrackShape"} = undef;
	$self->{"padDrillSize"}  = undef;

	return $self;
}

sub SetPosition {
	my $self = shift;
	my $pos  = shift;

	$self->{"position"} = $pos;
}

sub GetPosition {
	my $self = shift;

	return $self->{"position"};
}

sub SetHeight {
	my $self = shift;

	$self->{"h"} = shift;
}

sub GetHeight {
	my $self = shift;

	return $self->{"h"};
}

sub SetWidth {
	my $self  = shift;
	my $width = shift;

	$self->{"w"} = $width;

}

sub GetWidth {
	my $self = shift;

	return $self->{"w"};
}

sub AddMicrostripLayout {
	my $self = shift;

	push( @{ $self->{"stripsLayouts"} }, shift );
}

sub GetMicrostripLayouts {
	my $self = shift;

	return @{ $self->{"stripsLayouts"} };

}

sub SetInfoTextLayout {
	my $self       = shift;
	my $textLayout = shift;

	$self->{"infoTextLayout"} = $textLayout;

}

sub GetInfoTextLayout {
	my $self = shift;

	return $self->{"infoTextLayout"};
}

sub SetGuardTracksLayout {
	my $self    = shift;
	my $layouts = shift;

	$self->{"guardTracksLayout"} = $layouts

}

sub GetGuardTracksLayout {
	my $self = shift;

	return $self->{"guardTracksLayout"};
}

sub SetShieldingLayout {
	my $self    = shift;
	my $layouts = shift;

	$self->{"shieldingLayout"} = $layouts

}

sub GetShieldingLayout {
	my $self = shift;

	return $self->{"shieldingLayout"};
}

sub SetShieldingGNDViaLayout {
	my $self    = shift;
	my $layouts = shift;

	$self->{"shieldingGNDViaLayout"} = $layouts

}

sub GetShieldingGNDViaLayout {
	my $self = shift;

	return $self->{"shieldingGNDViaLayout"};
}

sub SetCpnSingleWidth {
	my $self = shift;
	my $w    = shift;

	$self->{"cpnSingleWidth"} = $w

}

sub GetCpnSingleWidth {
	my $self = shift;

	return $self->{"cpnSingleWidth"};
}

# Pad and track dimensions + shapes

sub SetPadGNDSymNeg {
	my $self = shift;
	my $val  = shift;

	$self->{"padGNDSymNeg"} = $val;

}

sub GetPadGNDSymNeg {
	my $self = shift;

	return $self->{"padGNDSymNeg"};
}

sub SetPadTrackSize {
	my $self = shift;
	my $val  = shift;

	$self->{"padTrackSize"} = $val;

}

sub GetPadTrackSize {
	my $self = shift;

	return $self->{"padTrackSize"};
}

sub SetPadTrackSym {
	my $self = shift;
	my $val  = shift;

	$self->{"padTrackSym"} = $val;

}

sub GetPadTrackSym {
	my $self = shift;

	return $self->{"padTrackSym"};
}

sub SetPadGNDShape {
	my $self = shift;
	my $val  = shift;

	$self->{"padGNDShape"} = $val;

}

sub GetPadGNDShape {
	my $self = shift;

	return $self->{"padGNDShape"};
}

sub SetPadGNDSize {
	my $self = shift;
	my $val  = shift;

	$self->{"padGNDSize"} = $val;

}

sub GetPadGNDSize {
	my $self = shift;

	return $self->{"padGNDSize"};
}

sub SetPadGNDSym {
	my $self = shift;
	my $val  = shift;

	$self->{"padGNDSym"} = $val;

}

sub GetPadGNDSym {
	my $self = shift;

	return $self->{"padGNDSym"};
}

sub SetPadTrackShape {
	my $self = shift;
	my $val  = shift;

	$self->{"padTrackShape"} = $val;

}

sub GetPadTrackShape {
	my $self = shift;

	return $self->{"padTrackShape"};
}

sub SetPadDrillSize {
	my $self = shift;
	my $val  = shift;

	$self->{"padDrillSize"} = $val;

}

sub GetPadDrillSize {
	my $self = shift;

	return $self->{"padDrillSize"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

