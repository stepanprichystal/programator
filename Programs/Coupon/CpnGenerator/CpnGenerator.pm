
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
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'Programs::Coupon::Enums';
use aliased 'Enums::EnumsImp';
use aliased 'Programs::Coupon::Helper';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Programs::Coupon::CpnBuilder::MicrostripBuilders::SEBuilder';
use aliased 'Programs::Coupon::CpnGenerator::ModelBuilders::CoatedMicrostrip';
use aliased 'Programs::Coupon::CpnGenerator::ModelBuilders::CoatedMicrostrip2B';
use aliased 'Programs::Coupon::CpnGenerator::ModelBuilders::UncoatedMicrostrip';
use aliased 'Programs::Coupon::CpnGenerator::ModelBuilders::Stripline';
use aliased 'Programs::Coupon::CpnGenerator::ModelBuilders::Stripline2T';
use aliased 'Programs::Coupon::CpnGenerator::ModelBuilders::Stripline2B';
use aliased 'Programs::Coupon::CpnGenerator::ModelBuilders::CoatedUpperEmbedded';
use aliased 'Programs::Coupon::CpnGenerator::ModelBuilders::CoatedUpperEmbedded2T';
use aliased 'Programs::Coupon::CpnGenerator::ModelBuilders::CoatedLowerEmbedded';
use aliased 'Programs::Coupon::CpnGenerator::ModelBuilders::CoatedLowerEmbedded2B';
use aliased 'Programs::Coupon::CpnGenerator::ModelBuilders::UncoatedUpperEmbedded';
use aliased 'Programs::Coupon::CpnGenerator::ModelBuilders::UncoatedUpperEmbedded2T';
use aliased 'Programs::Coupon::CpnGenerator::ModelBuilders::UncoatedLowerEmbedded';
use aliased 'Programs::Coupon::CpnGenerator::ModelBuilders::UncoatedLowerEmbedded2B';

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
use aliased 'Packages::CAM::SymbolDrawing::Enums'    => 'DrawEnums';
use aliased 'Packages::CAMJob::Microsection::Helper' => "CouponRoute";

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

			# frame 100µm width around pcb (fr frame coordinate)
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

	# Do outline rout
	if ( $layout->GetRoutLayout() ) {

		my $routLayout = $layout->GetRoutLayout();

		my $countorTypeH = $routLayout->GetCountourTypeX();
		my $countorTypeV = $routLayout->GetCountourTypeY();

		CamHelper->SetStep( $inCAM, $layout->GetStepName() );

		# 1) process routed edges

		CouponRoute->PrepareProfileRoutOnBridges(
												  $inCAM, $jobId,
												  $layout->GetStepName(), ( $countorTypeH =~ /rout/i ? 1 : 0 ),
												  ( $countorTypeV =~ /rout/i ? 1 : 0 ), $routLayout->GetCountourBridgesCntX(),
												  $routLayout->GetCountourBridgesCntY(), $routLayout->GetBridgesWidth()
		);

		# 2) process scored edges

		if ( $countorTypeH =~ /score/ || $countorTypeV =~ /score/ ) {

			CamMatrix->CreateLayer( $inCAM, $jobId, "score", "rout", "positive", 1 )
			  unless ( CamHelper->LayerExists( $inCAM, $jobId, "score" ) );
			CamLayer->WorkLayer( $inCAM, "score" );

			if ( $countorTypeH =~ /score/i ) {

				# Draw TOP horizontal edge
				CamSymbol->AddLine( $inCAM,
									{ "x" => 0,                   "y" => $layout->GetHeight() },
									{ "x" => $layout->GetWidth(), "y" => $layout->GetHeight() },
									"r200", "positive" );

				# Draw BOT horizontal edge
				CamSymbol->AddLine( $inCAM, { "x" => $layout->GetWidth(), "y" => 0 }, { "x" => 0, "y" => 0 }, "r200", "positive" );
			}

			if ( $countorTypeV =~ /score/i ) {

				# Draw LEFT verticall edge
				CamSymbol->AddLine( $inCAM, { "x" => 0, "y" => 0 }, { "x" => 0, "y" => $layout->GetHeight() }, "r200", "positive" );

				# Draw RIGHT horizontal edge
				CamSymbol->AddLine( $inCAM,
									{ "x" => $layout->GetWidth(), "y" => 0 },
									{ "x" => $layout->GetWidth(), "y" => $layout->GetHeight() },
									"r200", "positive" );
			}
		}
	}

	# Clear all layers
	CamLayer->ClearLayers($inCAM);

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
	my @layers = keys %{$layersLayout};    # silks, mask, signal
 
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
	foreach my $lName ( keys %{$layersLayout} ) {

		my $l = $layersLayout->{$lName};

		if ( $l->GetPolarity() eq DrawEnums->Polar_NEGATIVE ) {

			my $negLayer = NegSignalLayer->new($lName);
			$negLayer->Init( $inCAM, $jobId, $stepName );
			$negLayer->Build();

			CamLayer->WorkLayer( $inCAM, $negLayer->GetLayerName() );
			$negLayer->Draw();
			$negLayer->MoveFillSurf();
			push( @negLayerBuilders, $negLayer );
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

			case EnumsImp->Model_COATED_MICROSTRIP { $modelBuilder = CoatedMicrostrip->new() }

			  case EnumsImp->Model_COATED_MICROSTRIP_2B { $modelBuilder = CoatedMicrostrip2B->new() }

			  case EnumsImp->Model_UNCOATED_MICROSTRIP { $modelBuilder = UncoatedMicrostrip->new() }

			  case EnumsImp->Model_STRIPLINE { $modelBuilder = Stripline->new() }

			  case EnumsImp->Model_STRIPLINE_2T { $modelBuilder = Stripline2T->new() }

			  case EnumsImp->Model_STRIPLINE_2B { $modelBuilder = Stripline2B->new() }

			  case EnumsImp->Model_COATED_UPPER_EMBEDDED { $modelBuilder = CoatedUpperEmbedded->new() }

			  case EnumsImp->Model_COATED_UPPER_EMBEDDED_2T { $modelBuilder = CoatedUpperEmbedded2T->new() }

			  case EnumsImp->Model_COATED_LOWER_EMBEDDED { $modelBuilder = CoatedLowerEmbedded->new() }

			  case EnumsImp->Model_COATED_LOWER_EMBEDDED_2B { $modelBuilder = CoatedLowerEmbedded2B->new() }

			  case EnumsImp->Model_UNCOATED_UPPER_EMBEDDED { $modelBuilder = UncoatedUpperEmbedded->new() }

			  case EnumsImp->Model_UNCOATED_UPPER_EMBEDDED_2T { $modelBuilder = UncoatedUpperEmbedded2T->new() }

			  case EnumsImp->Model_UNCOATED_LOWER_EMBEDDED { $modelBuilder = UncoatedLowerEmbedded->new() }

			  case EnumsImp->Model_UNCOATED_LOWER_EMBEDDED_2B { $modelBuilder = UncoatedLowerEmbedded2B->new() }

			  else { die "Microstirp model: " . $stripLayout->GetModel() . " is not implemented"; }
		}

		$modelBuilder->Init( $inCAM, $jobId, $stepName );

		$modelBuilder->Build( $stripLayout, $cpnSingleLayout, $layersLayout );

		push( @builders, $modelBuilder );
	}

	# Draw layout layer by specific layer

	foreach my $l (@layers) {

		CamLayer->WorkLayer( $inCAM, $l );

		# In current layer draw by ordered layer builders
		# We need to sort layer builders of all model builders
		# In other case, layer builder can be drawed in wronf order and cause
		# undesirable covering/cutting features by negative
		#
		# Example:
		# Model builder 1. contains layer builders: (TrackClearanceLayer, TrackLayer)
		# Model builder 2. contains layer builders: (TrackClearanceLayer, TrackLayer)
		# We need to acheive drawing order:
		#	1.TrackClearanceLayer (Model builder 1)
		#	2.TrackClearanceLayer (Model builder 2)
		#	3.TrackLayer (Model builder 1)
		#	4.TrackLayer (Model builder 2)
		# NOT order:
		#	1.TrackClearanceLayer (Model builder 1)
		#	2.TrackLayer (Model builder 1)
		#	3.TrackClearanceLayer (Model builder 2)
		#	4.TrackLayer (Model builder 2)

		my @layerBuilders = ();
		foreach my $builder (@builders) {

			my @curLayers = grep { $_->GetLayerName() eq $l } $builder->GetLayers();
			push( @layerBuilders, @curLayers );
		}

		# Sort layer builders by given priority
		@layerBuilders = sort { $a->GetDrawPriority() <=> $b->GetDrawPriority() } @layerBuilders;

		# Draw
		$_->Draw() foreach (@layerBuilders);
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
	foreach my $builder (@negLayerBuilders) {

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

