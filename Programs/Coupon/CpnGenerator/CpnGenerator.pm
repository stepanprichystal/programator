
#-------------------------------------------------------------------------------------------#
# Description: Generate InCAM coupon step based on coupon layout, created bz coupon Builders
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::CpnGenerator;

#3th party library
use strict;
use warnings;
use Switch;

#local library

use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'Programs::Coupon::Enums';
use aliased 'Programs::Coupon::Helper';
use aliased 'Programs::Coupon::CpnBuilder::MicrostripBuilders::SEBuilder';
use aliased 'Programs::Coupon::CpnGenerator::ModelBuilders::CoatedMicrostrip';
use aliased 'Programs::Coupon::CpnGenerator::ModelBuilders::UncoatedMicrostrip';
use aliased 'Programs::Coupon::CpnGenerator::ModelBuilders::Stripline';
use aliased 'Programs::Coupon::CpnGenerator::ModelBuilders::Stripline2T';
use aliased 'Programs::Coupon::CpnGenerator::ModelBuilders::CoatedUpperEmbedded';
use aliased 'Programs::Coupon::CpnGenerator::ModelBuilders::UncoatedUpperEmbedded';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::CAMJob::Panelization::SRStep';
use aliased 'Programs::Coupon::CpnGenerator::CpnLayers::InfoTextLayer';
use aliased 'Programs::Coupon::CpnGenerator::CpnLayers::InfoTextMaskLayer';
use aliased 'Programs::Coupon::CpnGenerator::CpnLayers::GuardTracksLayer';
use aliased 'Programs::Coupon::CpnGenerator::CpnLayers::ShieldingLayer';
use aliased 'Programs::Coupon::CpnGenerator::CpnLayers::TitleLayer';
use aliased 'Programs::Coupon::CpnGenerator::CpnLayers::NegSignalLayer';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamDTM';
use aliased 'Enums::EnumsDrill';
use aliased 'Packages::CAM::SymbolDrawing::Enums' => 'DrawEnums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"couponStep"} = undef;

	return $self;
}

sub Generate {
	my $self   = shift;
	my $layout = shift;    # layout of complete coupon

	my $result = 1;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# CreateStep
	my $cpnMargin = $layout->GetCpnMargin();

	# if step coupon exist and is not currently set in editor, it gives error
	# Set step solve this problem..
	if ( CamHelper->StepExists( $inCAM, $jobId, $layout->GetStepName() ) ) {
		CamHelper->SetStep( $inCAM, $layout->GetStepName() );
	}

	$self->{"couponStep"} = SRStep->new( $inCAM, $jobId, $layout->GetStepName() );
	$self->{"couponStep"}
	  ->Create( $layout->GetWidth(), $layout->GetHeight(), $cpnMargin->{"top"}, $cpnMargin->{"bot"}, $cpnMargin->{"left"}, $cpnMargin->{"right"} );

	CamHelper->SetStep( $inCAM, $layout->GetStepName() );

	# 1) If exist drill layer "m", set DTM type = vysledne
	if ( defined $layout->GetLayersLayout()->{"m"} ) {
		CamDTM->SetDTMTable( $inCAM, $jobId, $layout->GetStepName(), "m", EnumsDrill->DTM_VYSLEDNE );
	}
 
	# Process title
	if ( $layout->GetTitleLayout() ) {

		my $tLayer = TitleLayer->new("c");

		$tLayer->Init( $inCAM, $jobId, $layout->GetStepName() );
		$tLayer->Build( $layout->GetTitleLayout() );

		CamHelper->SetStep( $inCAM, $layout->GetStepName() );
		CamLayer->WorkLayer( $inCAM, $tLayer->GetLayerName() );
		$tLayer->Draw();

		if ( $layout->GetTitleLayout()->GetTitleUnMask() ) {

			my $tLayer = TitleLayer->new("mc");

			$tLayer->Init( $inCAM, $jobId, $layout->GetStepName() );
			$tLayer->Build( $layout->GetTitleLayout() );

			CamHelper->SetStep( $inCAM, $layout->GetStepName() );
			CamLayer->WorkLayer( $inCAM, $tLayer->GetLayerName() );
			$tLayer->Draw();

		}
	}

	# Unmask coupon border
	my @masks = grep { $_ =~ /^m[cs]$/ } keys %{ $layout->GetLayersLayout() };
	if ( scalar(@masks) > 0 ) {

		foreach my $l (@masks) {

			CamLayer->WorkLayer( $inCAM, $l );

			my @coord = ();
			push( @coord, { "x" => 0,                   "y" => 0 } );
			push( @coord, { "x" => 0,                   "y" => $layout->GetHeight() } );
			push( @coord, { "x" => $layout->GetWidth(), "y" => $layout->GetHeight() } );
			push( @coord, { "x" => $layout->GetWidth(), "y" => 0 } );

			# frame 100�m width around pcb (fr frame coordinate)
			CamSymbol->AddPolyline( $inCAM, \@coord, "r100", "positive", 1 );
		}
	}

	# Create single oupon steps

	for ( my $i = 0 ; $i < scalar( $layout->GetCouponsSingle() ) ; $i++ ) {

		my $cpnSignleLayout = ( $layout->GetCouponsSingle() )[$i];

		my $srStep = $layout->GetStepName() . "_$i";

		$self->__GenerateSingle( $cpnSignleLayout, $layout->GetLayersLayout(), $srStep );

		my $p = $cpnSignleLayout->GetPosition();

		$self->{"couponStep"}->AddSRStep( $srStep, $p->X(), $p->Y(), 0, 1, 1, 1, 1 );
	}
	
	
	# Check negative signal layers, if exists fill layer with ground
	foreach my $lName ( keys %{ $layout->GetLayersLayout() } ) {

		my $l = $layout->GetLayersLayout()->{$lName};

		if ( $l->GetPolarity() eq DrawEnums->Polar_NEGATIVE ) {

			my $negLayer = NegSignalLayer->new($lName);
			$negLayer->Init( $inCAM, $jobId, $layout->GetStepName() );
			$negLayer->Build(0.3);

			CamHelper->SetStep( $inCAM, $layout->GetStepName() );
			CamLayer->WorkLayer( $inCAM, $negLayer->GetLayerName() );
			$negLayer->Draw();
		}
	}

	return $result;
}

sub FlattenCpn {
	my $self   = shift;
	my $layout = shift;    # layout of complete coupon

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $tmpName = GeneralHelper->GetGUID();

	CamStep->RenameStep( $inCAM, $jobId, $layout->GetStepName(), $tmpName );

	my @layers = keys %{ $layout->GetLayersLayout() };

	CamStep->CreateFlattenStep( $inCAM, $jobId, $tmpName, $layout->GetStepName(), 0, \@layers );

	# remove old steps - nested + main coupon
	CamStep->DeleteStep( $inCAM, $jobId, $tmpName );

	for ( my $i = 0 ; $i < scalar( $layout->GetCouponsSingle() ) ; $i++ ) {

		CamStep->DeleteStep( $inCAM, $jobId, $layout->GetStepName() . "_$i" );
	}

}

sub __GenerateSingle {
	my $self            = shift;
	my $cpnSingleLayout = shift;
	my $layersLayout    = shift;
	my $stepName        = shift;

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
	my %rt = ( "x" => $cpnSingleLayout->GetWidth(), "y" => $cpnSingleLayout->GetHeight() );

	CamStep->CreateProfileRect( $inCAM, $stepName, \%lb, \%rt );

	#  Check negative signal layers, if exists fill layer with positive surf
	# After filling is surface move out of coupon, because of proper working of another layer filling (GND layer, Shielding, etc)
	# In the end, when layer is complete, positive surf is returned back "under" another symbols
	my @negLayerBuilders = ();
	foreach my $lName ( keys %{ $layersLayout } ) {

		my $l = $layersLayout->{$lName};

		if ( $l->GetPolarity() eq DrawEnums->Polar_NEGATIVE ) {

			my $negLayer = NegSignalLayer->new($lName);
			$negLayer->Init( $inCAM, $jobId, $stepName );
			$negLayer->Build();
 
			CamLayer->WorkLayer( $inCAM, $negLayer->GetLayerName() );
			$negLayer->Draw();
			$negLayer->MoveFillSurf();
			push(@negLayerBuilders, $negLayer);
		}
	}

	# Proces guard tracks - clearance

	if ( defined $cpnSingleLayout->GetGuardTracksLayout() ) {

		foreach my $layout ( @{ $cpnSingleLayout->GetGuardTracksLayout() } ) {

			my $gtLayer = GuardTracksLayer->new( $layout->GetLayer() );
			$gtLayer->Init( $inCAM, $jobId, $stepName );
			$gtLayer->Build( $layout, $layersLayout->{ $layout->GetLayer() }, 1 );

			CamLayer->WorkLayer( $inCAM, $gtLayer->GetLayerName() );
			$gtLayer->Draw();
		}
	}

	# Process all microstrip layouts in single coupon
	my @builders = ();

	foreach my $stripLayout ( $cpnSingleLayout->GetMicrostripLayouts() ) {

		# Init model builder
		my $modelBuilder = undef;

		switch ( $stripLayout->GetModel() ) {

			case Enums->Model_COATED_MICROSTRIP { $modelBuilder = CoatedMicrostrip->new() }

			  case Enums->Model_UNCOATED_MICROSTRIP { $modelBuilder = UncoatedMicrostrip->new() }

			  case Enums->Model_STRIPLINE { $modelBuilder = Stripline->new() }

			  case Enums->Model_STRIPLINE_2T { $modelBuilder = Stripline2T->new() }

			  case Enums->Model_COATED_UPPER_EMBEDDED { $modelBuilder = CoatedUpperEmbedded->new() }

			  case Enums->Model_UNCOATED_UPPER_EMBEDDED { $modelBuilder = UncoatedUpperEmbedded->new() }

			  else { die "Microstirp model: " . $stripLayout->GetModel() . " is not implemented"; }
		}

		$modelBuilder->Init( $inCAM, $jobId, $stepName );

		$modelBuilder->Build( $stripLayout, $cpnSingleLayout, $layersLayout );

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

	# Proces guard tracks

	if ( defined $cpnSingleLayout->GetGuardTracksLayout() ) {

		foreach my $layout ( @{ $cpnSingleLayout->GetGuardTracksLayout() } ) {

			my $gtLayer = GuardTracksLayer->new( $layout->GetLayer() );
			$gtLayer->Init( $inCAM, $jobId, $stepName );
			$gtLayer->Build( $layout, $layersLayout->{ $layout->GetLayer() } );

			CamLayer->WorkLayer( $inCAM, $gtLayer->GetLayerName() );
			$gtLayer->Draw();
		}
	}

	# Shielding layout
	if ( defined $cpnSingleLayout->GetShieldingLayout() ) {

		foreach my $l ( CamJob->GetSignalLayerNames( $inCAM, $jobId ) ) {

			my $shieldingLayer = ShieldingLayer->new($l);
			$shieldingLayer->Init( $inCAM, $jobId, $stepName );
			$shieldingLayer->Build( $cpnSingleLayout->GetShieldingLayout(), $cpnSingleLayout, $layersLayout->{$l} );

			CamLayer->WorkLayer( $inCAM, $shieldingLayer->GetLayerName() );
			$shieldingLayer->Draw();

		}
	}

	# Proces info text layout
	if ( $cpnSingleLayout->GetInfoTextLayout() ) {

		my $textLayer = InfoTextLayer->new("c");
		$textLayer->Init( $inCAM, $jobId, $stepName );
		$textLayer->Build( $cpnSingleLayout->GetInfoTextLayout() );

		CamLayer->WorkLayer( $inCAM, $textLayer->GetLayerName() );
		$textLayer->Draw();

		# infot text unmask
		print STDERR $cpnSingleLayout->GetInfoTextLayout()->GetInfoTextUnmask();
		if ( $cpnSingleLayout->GetInfoTextLayout()->GetInfoTextUnmask() ) {

			foreach my $l ( grep { $_ =~ /^mc$/ } @layers ) {

				my $textMaskLayer = InfoTextMaskLayer->new($l);
				$textMaskLayer->Init( $inCAM, $jobId, $stepName );
				$textMaskLayer->Build( $cpnSingleLayout->GetInfoTextLayout() );

				CamLayer->WorkLayer( $inCAM, $textMaskLayer->GetLayerName() );
				$textMaskLayer->Draw();

			}
		}

	}
	
	# If exist negative layers, move back positive surface created on begining of this function
	foreach my $builder  (@negLayerBuilders){
		
		CamLayer->WorkLayer( $inCAM, $builder->GetLayerName() );
		$builder->MoveFillSurfBack();
	
	}
			 
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
