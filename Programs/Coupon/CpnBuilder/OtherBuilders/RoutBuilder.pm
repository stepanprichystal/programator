
#-------------------------------------------------------------------------------------------#
# Description: Title builder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::OtherBuilders::RoutBuilder;

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
use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::RoutLayout';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"layout"} = RoutLayout->new();    # Layout of one single coupon
	$self->{"build"}  = 0;                    # indicator if layout was built

	# Settings references
	$self->{"cpnSett"} = undef;               # global settings for generating coupon

	# Other properties

	return $self;
}

# Build single coupon layout
# If ok return 1, else 0 + err message
sub Build {
	my $self    = shift;
	my $cpnSett = shift;
	my $errMess = shift;

	#$self->{"singleCpnVar"} = $cpnSingleVar;
	$self->{"cpnSett"} = $cpnSett;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;

	return $result if ( !$self->{"cpnSett"}->GetCountourMech() );

	$self->{"layout"}->GetCountourMech(1);

	$self->{"layout"}->SetCountourTypeX( $self->{"cpnSett"}->GetCountourTypeX() );
	$self->{"layout"}->SetCountourBridgesCntX( $self->{"cpnSett"}->GetCountourBridgesCntX() );
	$self->{"layout"}->SetCountourTypeY( $self->{"cpnSett"}->GetCountourTypeY() );
	$self->{"layout"}->SetCountourBridgesCntY( $self->{"cpnSett"}->GetCountourBridgesCntY() );
	$self->{"layout"}->SetBridgesWidth( $self->{"cpnSett"}->GetBridgesWidth() );
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

