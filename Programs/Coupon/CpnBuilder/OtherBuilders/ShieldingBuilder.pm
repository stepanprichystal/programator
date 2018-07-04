
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::OtherBuilders::ShieldingBuilder;

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
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::ShieldingLayout';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"settings"}     = shift;    # global settings for generating coupon
	$self->{"singleCpnVar"} = shift;
	$self->{"cpnSingle"}    = shift;

	$self->{"layout"} = ShieldingLayout->new();    # Layout of one single coupon

	$self->{"microstrips"} = [];

	$self->{"build"} = 0;                         # indicator if layout was built

	return $self;
}

# Build single coupon layout
# If ok return 1, else 0 + err message
sub Build {
	my $self    = shift;
	my $errMess = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;

	return $result if ( !$self->{"settings"}->GetShielding() );

	 my $t = $self->{"settings"}->GetShieldingType();

	$self->{"layout"}->SetType($t);
	
	if($t eq "symbol"){
	 
 		$self->{"layout"}->SetSymbol($self->{"settings"}->GetShieldingSymbol());
 		$self->{"layout"}->SetSymbolDX($self->{"settings"}->GetShieldingSymbolDX()/1000);
 		$self->{"layout"}->SetSymbolDY($self->{"settings"}->GetShieldingSymbolDY()/1000);
	}

	$self->{"build"} = 1;

	return $result;
}

sub GetLayout {
	my $self = shift;

	return $self->{"layout"};
}

sub GetType {
	my $self = shift;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

