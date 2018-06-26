
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnGenerator::CpnGenerator;

#3th party library
use strict;
use warnings;
use Switch;

#local library

use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'Packages::Coupon::Enums';
use aliased 'Packages::Coupon::Helper';
use aliased 'Packages::Coupon::CpnBuilder::MicrostripBuilders::SEBuilder';
use aliased 'Packages::Coupon::CpnGenerator::ModelBuilders::CoatedMicrostrip';
use aliased 'Packages::Coupon::CpnGenerator::ModelBuilders::StriplineMicrostrip';

use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::CAMJob::Panelization::SRStep';
use aliased 'Packages::Coupon::CpnGenerator::CpnLayers::InfoTextLayer';
use aliased 'Packages::Coupon::CpnGenerator::CpnLayers::GuardTracksLayer';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"settings"} = shift;    # global settings for generating coupon

	$self->{"couponStep"} = undef;

	return $self;
}

sub Generate {
	my $self   = shift;
	my $layout = shift;             # layout of complete coupon

	my $result = 1;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	#my @coupons = grep { $_ =~ /^coupon_(\d+)$/} StepName->GetAllStepNames($inCAM, $jobId);

	# CreateStep

	$self->{"couponStep"} = SRStep->new( $inCAM, $jobId, $layout->GetStepName() );
	$self->{"couponStep"}->Create(
								   $layout->GetWidth(),                    $layout->GetHeight(),
								   $self->{"settings"}->GetCouponMargin(), $self->{"settings"}->GetCouponMargin(),
								   $self->{"settings"}->GetCouponMargin(), $self->{"settings"}->GetCouponMargin()
	);

	CamHelper->SetStep( $inCAM, $self->{"settings"}->GetStepName() );

	# Create single oupon steps

	my $yCurrent = $self->{"settings"}->GetCouponMargin();

	for ( my $i = 0 ; $i < scalar( $layout->GetCouponsSingle() ) ; $i++ ) {

		my $cpnSignleLayout = ( $layout->GetCouponsSingle() )[$i];

		my $srStep = $self->{"settings"}->GetStepName() . "_$i";

		$self->__GenerateSingle( $cpnSignleLayout, $srStep );

		$self->{"couponStep"}->AddSRStep( $srStep, $self->{"settings"}->GetCouponMargin(), $yCurrent, 0, 1, 1, 1, 1 );

		$yCurrent += $cpnSignleLayout->GetHeight() + $self->{"settings"}->GetCouponSpace();

	}

	return $result;
}

sub __GenerateSingle {
	my $self      = shift;
	my $cpnLayout = shift;
	my $stepName  = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Create step

	if ( CamHelper->StepExists( $inCAM, $jobId, $stepName ) ) {
		CamStep->DeleteStep( $inCAM, $jobId, $stepName );
	}

	CamStep->CreateStep( $inCAM, $jobId, $stepName );
	CamHelper->SetStep( $inCAM, $stepName );

	# create profile
	my %lb = ( "x" => 0, "y" => 0 );
	my %rt = ( "x" => $cpnLayout->GetWidth(), "y" => $cpnLayout->GetHeight() );

	CamStep->CreateProfileRect( $inCAM, $stepName, \%lb, \%rt );

	# Process all microstrip layouts in single coupon
	my @builders = ();

	foreach my $stripLayout ( $cpnLayout->GetMicrostripLayouts() ) {

		# Init model builder
		my $modelBuilder = undef;

		switch ( $stripLayout->GetModel() ) {

			case Enums->Model_COATED_MICROSTRIP { $modelBuilder = CoatedMicrostrip->new() }

			  case Enums->Model_UNCOATED_MICROSTRIP { $modelBuilder = UncoatedMicrostrip->new() }

			  case Enums->Model_STRIPLINE { $modelBuilder = StriplineMicrostrip->new() }

			  else { die "Microstirp model: " . $stripLayout->GetModel() . " is not implemented"; }
		}

		$modelBuilder->Init( $inCAM, $jobId, $stepName, $self->{"settings"} );

		$modelBuilder->Build($stripLayout);

		push( @builders, $modelBuilder );
	}

	# Draw layout layer by layer
	my @layers = map { $_->{"gROWname"} } CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	foreach my $l (@layers) {

		CamLayer->WorkLayer( $inCAM, $l );

		foreach my $builder (@builders) {

			my @curLayers = grep { $_->GetLayerName() eq $l } $builder->GetLayers();

			$_->Draw() foreach (@curLayers);
		}
	}

	# Proces text layout

	# build info texts
	# Proces info text layout
	if ( $cpnLayout->GetInfoTextLayout() ) {

		my $textLayer = InfoTextLayer->new("c");
		$textLayer->Init( $inCAM, $jobId, $stepName, $self->{"settings"} );
		$textLayer->Build( $cpnLayout->GetInfoTextLayout() );

		CamLayer->WorkLayer( $inCAM, $textLayer->GetLayerName() );
		$textLayer->Draw();
	}

	if ( $self->{"settings"}->GetGuardTracks() ) {

		foreach my $layout ( @{ $cpnLayout->GetGuardTracksLayout() } ) {

			my $gtLayer = GuardTracksLayer->new( $layout->GetLayer() );
			$gtLayer->Init( $inCAM, $jobId, $stepName, $self->{"settings"} );
			$gtLayer->Build($layout);

			CamLayer->WorkLayer( $inCAM, $gtLayer->GetLayerName() );
			$gtLayer->Draw();

		}

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

