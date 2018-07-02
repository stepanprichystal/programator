
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
use aliased 'Packages::Coupon::CpnGenerator::ModelBuilders::Coated';
use aliased 'Packages::Coupon::CpnGenerator::ModelBuilders::Uncoated';
use aliased 'Packages::Coupon::CpnGenerator::ModelBuilders::Stripline';
use aliased 'Packages::Coupon::CpnGenerator::ModelBuilders::CoatedUpperEmbedded';
use aliased 'Packages::Coupon::CpnGenerator::ModelBuilders::UncoatedUpperEmbedded';

use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::CAMJob::Panelization::SRStep';
use aliased 'Packages::Coupon::CpnGenerator::CpnLayers::InfoTextLayer';
use aliased 'Packages::Coupon::CpnGenerator::CpnLayers::InfoTextMaskLayer';
use aliased 'Packages::Coupon::CpnGenerator::CpnLayers::GuardTracksLayer';
use aliased 'Packages::Coupon::CpnGenerator::CpnLayers::ShieldingLayer';
use aliased 'Packages::Coupon::CpnGenerator::CpnLayers::TitleLayer';

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
	my $leftMargin = $self->{"settings"}->GetCouponMargin() / 1000;
	my $topMargin  = $self->{"settings"}->GetCouponMargin() / 1000;

	if ( $self->{"settings"}->GetTitle() ) {

		if ( $layout->GetTitleLayout()->GetHeight() > $self->{"settings"}->GetCouponMargin() / 1000 ) {

			$leftMargin = $layout->GetTitleLayout()->GetHeight() if ( $self->{"settings"}->GetTitleType() eq "left" );
			$topMargin  = $layout->GetTitleLayout()->GetHeight() if ( $self->{"settings"}->GetTitleType() eq "top" );
		}
	}

	$self->{"couponStep"} = SRStep->new( $inCAM, $jobId, $layout->GetStepName() );
	$self->{"couponStep"}->Create( $layout->GetWidth(), $layout->GetHeight(), $topMargin, $self->{"settings"}->GetCouponMargin() / 1000,
								   $leftMargin, $self->{"settings"}->GetCouponMargin() / 1000 );

	CamHelper->SetStep( $inCAM, $self->{"settings"}->GetStepName() );

	# Create single oupon steps

	my $yCurrent = $self->{"settings"}->GetCouponMargin() / 1000;

	for ( my $i = 0 ; $i < scalar( $layout->GetCouponsSingle() ) ; $i++ ) {

		my $cpnSignleLayout = ( $layout->GetCouponsSingle() )[$i];

		my $srStep = $self->{"settings"}->GetStepName() . "_$i";

		$self->__GenerateSingle( $cpnSignleLayout, $srStep );

		$self->{"couponStep"}->AddSRStep( $srStep, $leftMargin, $yCurrent, 0, 1, 1, 1, 1 );

		$yCurrent += $cpnSignleLayout->GetHeight() + $self->{"settings"}->GetCouponSpace() / 1000;
	}

	# Process title
	if ( $self->{"settings"}->GetTitle() ) {

		my $tLayer = TitleLayer->new("c");

		$tLayer->Init( $inCAM, $jobId, $layout->GetStepName(), $self->{"settings"} );
		$tLayer->Build( $layout->GetTitleLayout() );

		CamHelper->SetStep( $inCAM, $layout->GetStepName() );
		CamLayer->WorkLayer( $inCAM, $tLayer->GetLayerName() );
		$tLayer->Draw();

		if ( $self->{"settings"}->GetTitleUnMask() ) {

			my $tLayer = TitleLayer->new("mc");

			$tLayer->Init( $inCAM, $jobId, $layout->GetStepName(), $self->{"settings"} );
			$tLayer->Build( $layout->GetTitleLayout() );

			CamHelper->SetStep( $inCAM, $layout->GetStepName() );
			CamLayer->WorkLayer( $inCAM, $tLayer->GetLayerName() );
			$tLayer->Draw();

		}

	}

	return $result;
}

sub __GenerateSingle {
	my $self      = shift;
	my $cpnLayout = shift;
	my $stepName  = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# coupon layers
	my @layers = map { $_->{"gROWname"} } CamJob->GetBoardBaseLayers( $inCAM, $jobId );    # silks, mask, signal
	push( @layers, "m" );                                                                  # Drill

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

			case Enums->Model_COATED_MICROSTRIP { $modelBuilder = Coated->new() }
			
			  case Enums->Model_UNCOATED_MICROSTRIP { $modelBuilder = Uncoated->new() }

			  case Enums->Model_STRIPLINE { $modelBuilder = Stripline->new() }
			  
			  case Enums->Model_COATED_UPPER_EMBEDDED { $modelBuilder = CoatedUpperEmbedded->new() }
			  
			   case Enums->Model_UNCOATED_UPPER_EMBEDDED { $modelBuilder = UncoatedUpperEmbedded->new() }
			  
			  

			  else { die "Microstirp model: " . $stripLayout->GetModel() . " is not implemented"; }
		}

		$modelBuilder->Init( $inCAM, $jobId, $stepName, $self->{"settings"} );

		$modelBuilder->Build( $stripLayout, $cpnLayout->GetLayersLayout() );

		push( @builders, $modelBuilder );
	}

	# Draw layout layer by layer

	foreach my $l (@layers) {

		CamLayer->WorkLayer( $inCAM, $l );

		foreach my $builder (@builders) {

			my @curLayers = grep { $_->GetLayerName() eq $l } $builder->GetLayers();

			$_->Draw() foreach (@curLayers);
		}
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

	# Proces text layout

	# Shielding layout
	if ( $cpnLayout->GetShieldingLayout() ) {

		foreach my $l ( CamJob->GetSignalLayerNames( $inCAM, $jobId ) ) {

			my $shieldingLayer = ShieldingLayer->new($l);
			$shieldingLayer->Init( $inCAM, $jobId, $stepName, $self->{"settings"} );
			$shieldingLayer->Build( $cpnLayout->GetShieldingLayout() );

			CamLayer->WorkLayer( $inCAM, $shieldingLayer->GetLayerName() );
			$shieldingLayer->Draw();

		}
	}

	# Proces info text layout
	if ( $cpnLayout->GetInfoTextLayout() ) {

		my $textLayer = InfoTextLayer->new("c");
		$textLayer->Init( $inCAM, $jobId, $stepName, $self->{"settings"} );
		$textLayer->Build( $cpnLayout->GetInfoTextLayout() );

		CamLayer->WorkLayer( $inCAM, $textLayer->GetLayerName() );
		$textLayer->Draw();

	}

	# infot text unmask
	if ( $self->{"settings"}->GetInfoTextUnmask() ) {

		foreach my $l ( grep { $_ =~ /^m[cs]$/ } @layers ) {

			my $textMaskLayer = InfoTextMaskLayer->new($l);
			$textMaskLayer->Init( $inCAM, $jobId, $stepName, $self->{"settings"} );
			$textMaskLayer->Build( $cpnLayout->GetInfoTextLayout() );

			CamLayer->WorkLayer( $inCAM, $textMaskLayer->GetLayerName() );
			$textMaskLayer->Draw();
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

