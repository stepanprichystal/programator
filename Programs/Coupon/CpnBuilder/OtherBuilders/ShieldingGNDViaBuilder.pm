
#-------------------------------------------------------------------------------------------#
# Description: Shielding builder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::OtherBuilders::ShieldingGNDViaBuilder;

use Class::Interface;
&implements('Programs::Coupon::CpnBuilder::ICpnBuilder');

#3th party library
use strict;
use warnings;
use Switch;
use List::Util qw[min max];

#local library
use aliased 'Programs::Coupon::Enums';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::PointLayout';
use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::ShieldingLayout';
use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::ShieldingGNDViaLayout';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"layout"}       = ShieldingGNDViaLayout->new();    # Layout of one single coupon
	$self->{"build"}        = 0;                               # indicator if layout was built
	$self->{"singleCpnVar"} = undef;

	# Settings references
	$self->{"cpnSett"} = undef;                                # global settings for generating coupon

	# Other properties

	return $self;
}

# Build single coupon layout
# If ok return 1, else 0 + err message
sub Build {
	my $self         = shift;
	my $cpnSingleVar = shift;
	my $cpnSett      = shift;
	my $errMess      = shift;

	$self->{"singleCpnVar"} = $cpnSingleVar;
	$self->{"cpnSett"}      = $cpnSett;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;

	return $result if ( !$self->{"cpnSett"}->GetGNDViaShielding() );

	$self->{"layout"}->SetGNDViaHoleSize( $self->{"cpnSett"}->GetGNDViaHoleSize() );
	$self->{"layout"}->SetGNDViaHoleRing( $self->{"cpnSett"}->GetGNDViaHoleRing() );
	$self->{"layout"}->SetGNDViaHoleDX( $self->{"cpnSett"}->GetGNDViaHoleDX() / 1000 );
	$self->{"layout"}->SetGNDViaHole2GNDDist( $self->{"cpnSett"}->GetGNDViaHole2GNDDist() / 1000 );
	$self->{"layout"}->SetUnMaskGNDVia( $self->{"cpnSett"}->GetUnMaskGNDVia() );
	$self->{"layout"}->SetFilledGNDVia( $self->{"cpnSett"}->GetFilledGNDVia() );

	$self->{"build"} = 1;

	return $result;
}

sub GetLayout {
	my $self = shift;

	return $self->{"layout"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

