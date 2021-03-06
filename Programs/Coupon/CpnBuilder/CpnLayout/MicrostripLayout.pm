
#-------------------------------------------------------------------------------------------#
# Description: Microatrip layout
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::CpnLayout::MicrostripLayout;
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

	# Microstrip layout properties
	$self->{"pads"}         = [];       # GND and Track pads definition
	$self->{"tracks"}       = [];       # Trancks definition
	$self->{"coplanar"}     = 0;        # indicate coplanar type
	$self->{"GNDViaPoints"} = undef;    # positions of GND VIA holes along strip line (coplanar only)

	# Microstript model properties
	$self->{"microstripModel"} = undef;

	$self->{"trackLayer"}      = undef;
	$self->{"topRefLayer"}     = undef;
	$self->{"botRefLayer"}     = undef;
	$self->{"extraTrackLayer"} = undef;

	# Active area width
	$self->{"activeAreaWidth"} = undef;

	$self->{"trackToCopper"}    = undef;
	$self->{"pad2GNDClearance"} = undef;

	$self->{"padClearance"} = undef;

	return $self;
}

sub SetModel {
	my $self = shift;

	$self->{"microstripModel"} = shift;
}

sub GetModel {
	my $self = shift;

	return $self->{"microstripModel"};
}

sub SetTrackLayer {
	my $self = shift;

	$self->{"trackLayer"} = shift;
}

sub GetTrackLayer {
	my $self = shift;

	return $self->{"trackLayer"};
}

sub SetTopRefLayer {
	my $self = shift;

	$self->{"topRefLayer"} = shift;
}

sub GetTopRefLayer {
	my $self = shift;

	return $self->{"topRefLayer"};
}

sub SetBotRefLayer {
	my $self = shift;

	$self->{"botRefLayer"} = shift;
}

sub GetBotRefLayer {
	my $self = shift;

	return $self->{"botRefLayer"};
}

sub SetExtraTrackLayer {
	my $self = shift;

	$self->{"extraTrackLayer"} = shift;
}

sub GetExtraTrackLayer {
	my $self = shift;

	return $self->{"extraTrackLayer"};
}

sub AddPad {
	my $self = shift;

	push( @{ $self->{"pads"} }, shift );
}

sub GetPads {
	my $self = shift;
	my $type = shift;

	my @pads = @{ $self->{"pads"} };

	if ($type) {

		@pads = grep { $_->GetType() eq $type } @pads;
	}

	return @pads;
}

sub AddTrack {
	my $self = shift;

	push( @{ $self->{"tracks"} }, shift );
}

sub GetTracks {
	my $self = shift;

	return @{ $self->{"tracks"} };

}

sub SetCoplanar {
	my $self = shift;

	$self->{"coplanar"} = shift;

}

sub GetCoplanar {
	my $self = shift;

	return $self->{"coplanar"};

}

sub SetTrackToCopper {
	my $self = shift;

	$self->{"trackToCopper"} = shift;

}

sub GetTrackToCopper {
	my $self = shift;

	return $self->{"trackToCopper"};

}

sub AddGNDViaPoint {
	my $self  = shift;
	my $point = shift;

	push( @{ $self->{"GNDViaPoints"} }, $point );

}

sub GetGNDViaPoints {
	my $self = shift;

	if(!defined $self->{"GNDViaPoints"}){
		die ;
	}

	return @{ $self->{"GNDViaPoints"} };
}

sub SetPad2GND {
	my $self = shift;
	my $val  = shift;

	$self->{"pad2GNDClearance"} = $val;

}

sub GetPad2GND {
	my $self = shift;

	return $self->{"pad2GNDClearance"};
}

sub SetPadClearance {
	my $self = shift;
	my $val  = shift;

	$self->{"padClearance"} = $val;

}

sub GetPadClearance {
	my $self = shift;

	return $self->{"padClearance"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

