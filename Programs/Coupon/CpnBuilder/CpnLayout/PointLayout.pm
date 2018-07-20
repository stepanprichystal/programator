#-------------------------------------------------------------------------------------------#
# Description: Keep info about point + some helper function with point
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::CpnLayout::PointLayout;
use base qw(Programs::Coupon::CpnBuilder::CpnLayout::CpnLayoutBase);

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;
use Storable qw(dclone);
use Math::Trig;
use Math::Geometry::Planar;

#local library
use aliased 'Packages::CAM::SymbolDrawing::Enums';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	
	my $x = shift;
	my $y = shift;
	
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"x"} = $x;
	$self->{"y"} = $y;

	unless ( defined $self->{"x"} ) {
		$self->{"x"} = 0;
	}

	unless ( defined $self->{"y"} ) {
		$self->{"y"} = 0;
	}

	return $self;
}

sub X {
	my $self = shift;
	return $self->{"x"};
}

sub Y {
	my $self = shift;
	return $self->{"y"};
}

sub Move {
	my $self = shift;
	my $x    = shift;    # number of mm in x axis
	my $y    = shift;    # number of mm in y axis

	$self->{"x"} += $x;
	$self->{"y"} += $y;
}

# do CCW rotation if point
sub Rotate {
	my $self  = shift;
	my $angle = shift;    # angle in degree
	my $cw    = shift;    # angle in degree

	my $y;
	my $x;

	if ($cw) {
		$y = $self->{"y"} * cos( deg2rad($angle) ) - $self->{"x"} * sin( deg2rad($angle) );
		$x = $self->{"y"} * sin( deg2rad($angle) ) + $self->{"x"} * cos( deg2rad($angle) );

	}
	else {
		$y = $self->{"y"} * cos( deg2rad($angle) ) + $self->{"x"} * sin( deg2rad($angle) );
		$x = -$self->{"y"} * sin( deg2rad($angle) ) + $self->{"x"} * cos( deg2rad($angle) );
	}

	$self->{"y"} = $y;
	$self->{"x"} = $x;

}

sub MirrorX {
	my $self  = shift;
	my $point = shift;

	$self->{"y"} = $point->{"y"} - ( $self->{"y"} - $point->{"y"} );
}

sub MirrorY {
	my $self  = shift;
	my $point = shift;

	$self->{"x"} = $point->{"x"} - ( $self->{"x"} - $point->{"x"} );
}

sub Copy {
	my $self = shift;

	return dclone($self);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

