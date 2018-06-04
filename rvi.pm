
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::Coupon;

#3th party library
use strict;
use warnings;

#local library

use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::Coupon::Enums';

use aliased 'Packages::Coupon::MicrostripBuilders::SEBuilder';
use aliased 'Packages::Coupon::ModelBuilders::CoatedMicrostrip';
use aliased 'Packages::Coupon::CouponSingle';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::CAMJob::Panelization::SRStep';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"settings"} = shift;

	$self->{"prepared"} = 0;

	$self->{"couponsSingle"} = [];

	$self->{"couponStep"} = undef;

	return $self;
}

sub Prepare {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Built miscrostip builers

 
	 
	foreach my $settCouponSingle ( $self->{"settings"}->GetCouponsSingle() ) {

		my @constrsId = $settCouponSingle->GetConstrainsId();

		my $coupon = CouponSingle->new( $inCAM, $jobId, $self->{"settings"}, scalar(@{ $self->{"couponsSingle"} })+1, \@constrsId );

		$coupon->Build();

		push( @{ $self->{"couponsSingle"} }, $coupon );

	}

}

sub Generate {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	#my @coupons = grep { $_ =~ /^coupon_(\d+)$/} StepName->GetAllStepNames($inCAM, $jobId);

	# CreateStep

	$self->{"couponStep"} = SRStep->new( $inCAM, $jobId, $self->{"settings"}->GetStepName() );
	$self->{"couponStep"}->Create(
								   $self->{"settings"}->GetWidth(),        $self->GetCouponHeight(),
								   $self->{"settings"}->GetCouponMargin(), $self->{"settings"}->GetCouponMargin(),
								   $self->{"settings"}->GetCouponMargin(), $self->{"settings"}->GetCouponMargin()
	  );
	 
	CamHelper->SetStep( $inCAM, $self->{"settings"}->GetStepName());

	# profile
 
	my $yCurrent = $self->{"settings"}->GetCouponMargin();

	foreach my $coupon ( @{ $self->{"couponsSingle"} } ) {

		my $origin = Point->new( $self->{"settings"}->GetCouponMargin(), $yCurrent );

		$coupon->Draw($origin);

		$yCurrent += $coupon->GetHeight() + $self->{"settings"}->GetCouponSpace();

	}
}

sub GetCouponHeight {
	my $self = shift;

	my $h = $self->{"settings"}->GetCouponMargin() * 2 + ( scalar( @{ $self->{"couponsSingle"} } ) - 1 ) * $self->{"settings"}->GetCouponSpace();

	$h += $_->GetHeight() foreach @{ $self->{"couponsSingle"} };

	return $h;
}

sub GetCouponWidth {
	my $self = shift;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Packages::Coupon::Coupon';
	use aliased 'Packages::Coupon::CouponSettings::CouponSettings';

	my $inCAM = InCAM->new();
	my $jobId = "d152456";

	my $p = 'c:\Export\CouponSPR\output\SE_Coated_Microstrip\SE_Coated_Microstrip.xml';

	my $sett = CouponSettings->new($p);

	my $coupon = Coupon->new( $inCAM, $jobId, $sett );

	$coupon->Prepare();

	$coupon->Generate();

}

1;

