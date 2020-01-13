
#-------------------------------------------------------------------------------------------#
# Description: Cerate fake layers which are necessarz for export modules and export settings
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::PreExport::FakeLayers;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::Gerbers::Mdi::ExportFiles::Enums';
use aliased 'Packages::Stackup::StackupOperation';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamSymbolSurf';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamFilter';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAM::FeatureFilter::Enums' => 'EnumsFiltr';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::Polygon::PolygonFeatures';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Packages::CAMJob::ViaFilling::PlugLayer';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# Create fake layers necesserz for export
# All fake layers has attribut "export_fake_layer" set to: yes
sub CreateFakeLayers {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $step        = shift // "panel";
	my $emptyLayers = shift // 0;         # Create layer without any data

	$self->RemoveFakeLayers( $inCAM, $jobId, $step );

	my @smFake = $self->__CreateFakeSMLayers( $inCAM, $jobId, $step, $emptyLayers );
	my @outerFake = $self->__CreateFakeOuterCoreLayers( $inCAM, $jobId, $step, $emptyLayers );
	my @smOLECFake = $self->__CreateFakeSMOLECLayers( $inCAM, $jobId, $step, $emptyLayers );
	my @coreDrillFake = $self->__CreateCoreDrillLayers( $inCAM, $jobId, $step, $emptyLayers );
	my @plgFake = $self->__CreateFakePLGLayers( $inCAM, $jobId, $step, $emptyLayers );

	my @fake = ();
	push( @fake, @smFake )     if (@smFake);
	push( @fake, @outerFake )  if (@outerFake);
	push( @fake, @smOLECFake ) if (@smOLECFake);
	push( @fake, @plgFake )    if (@plgFake);

	foreach my $l (@fake) {

		CamAttributes->SetLayerAttribute( $inCAM, "export_fake_layer", "yes", $jobId, $step, $l );

	}

	return @fake;
}

sub RemoveFakeLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift // "panel";

	foreach my $l ( CamJob->GetBoardLayers( $inCAM, $jobId ) ) {

		my %attr = CamAttributes->GetLayerAttr( $inCAM, $jobId, $step, $l->{"gROWname"} );

		if ( $attr{"export_fake_layer"} =~ /^yes$/i ) {

			CamMatrix->DeleteLayer( $inCAM, $jobId, $l->{"gROWname"} );
		}
	}

	return 0;
}

# Create fake layers for PCB where is second mask
sub __CreateFakeSMLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;

	my %mask = HegMethods->GetSolderMaskColor2($jobId);

	my @fake = ();

	push( @fake, "mc2" ) if ( defined $mask{"top"} && $mask{"top"} ne "" );
	push( @fake, "ms2" ) if ( defined $mask{"bot"} && $mask{"bot"} ne "" );

	my @steps = ($step);

	if ( CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $step ) ) {

		push( @steps, map { $_->{"stepName"} } CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, $step ) );
	}

	foreach my $fl (@fake) {

		CamMatrix->DeleteLayer( $inCAM, $jobId, $fl );
		CamMatrix->CreateLayer( $inCAM, $jobId, $fl, "solder_mask", "positive", 1 );
	}

	foreach my $s (@steps) {

		CamHelper->SetStep( $inCAM, $s );

		foreach my $fl (@fake) {

			my ($source) = $fl =~ m/(m[cs])/;
			$inCAM->COM( "merge_layers", "source_layer" => $source, "dest_layer" => $fl );
		}
	}

	CamLayer->ClearLayers($inCAM);

	return @fake;
}

# Fake layers, where soldermask is only from one side.
# But OLEC machine need films from both side in order register films
# For Multilayer PCB only (rest of PCB is exposed without cameras??)
sub __CreateFakeSMOLECLayers {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $step        = shift;
	my $emptyLayers = shift // 0;    # Create layer without any data

	my @fakeLayers = ();

	my @layers = CamJob->GetBoardLayers( $inCAM, $jobId );

	my $mcExist = scalar( grep { $_->{"gROWname"} eq "mc" } @layers ) ? 1 : 0;
	my $msExist = scalar( grep { $_->{"gROWname"} eq "ms" } @layers ) ? 1 : 0;

	my $fakeSM = ();
	my $sourceL;

	if ( $mcExist && !$msExist ) {

		$fakeSM  = "msolec";
		$sourceL = "mc";

	}
	elsif ( !$mcExist && $msExist ) {

		$fakeSM  = "mcolec";
		$sourceL = "ms";

	}
	else {

		return @fakeLayers;
	}

	return @fakeLayers unless ( CamJob->GetSignalLayerCnt( $inCAM, $jobId ) > 2 );

	CamMatrix->DeleteLayer( $inCAM, $jobId, $fakeSM );
	CamMatrix->CreateLayer( $inCAM, $jobId, $fakeSM, "solder_mask", "positive", 1 );

	$inCAM->COM( "merge_layers", "source_layer" => $sourceL, "dest_layer" => $fakeSM );

	if ( !$emptyLayers ) {

		CamLayer->WorkLayer( $inCAM, $sourceL );

		# Rotate OLEC marks

		CamLayer->WorkLayer( $inCAM, $fakeSM );
		if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".geometry", "OLEC*" ) == 4 ) {
			$inCAM->COM( "sel_change_sym", "symbol" => ( $sourceL eq "mc" ? "cross_mask" : "cross_mask_x" ) );
		}
		else {
			die "All OLEC crosees (four, symbol name: cross_mask) were not found in layer: $sourceL";
		}

		# Move centre moire
		my $f = FeatureFilter->new( $inCAM, $jobId, $fakeSM );
		$f->AddIncludeSymbols( ["s5000"] );
		$f->AddIncludeAtt( ".geometry", "centre-moire*" );
		$f->SetPolarity( EnumsFiltr->Polarity_NEGATIVE );
		if ( $f->Select() ) {
			$inCAM->COM("sel_delete");
		}

		$f->Reset();
		my $sign = ( $sourceL eq "mc" ) ? -1 : 1;
		$f->AddIncludeSymbols( ["center-moire"] );
		$f->AddIncludeAtt( ".pnl_place", "*right-top*" );
		if ( $f->Select() ) {
			$inCAM->COM( "sel_move", "dx" => 0, "dy" => $sign * 6 );
		}

		$f->Reset();
		$f->AddIncludeSymbols( ["center-moire"] );
		$f->AddIncludeAtt( ".pnl_place", "*right-bot*" );
		$f->AddIncludeAtt( ".pnl_place", "*left-bot*" );
		$f->SetIncludeAttrCond( EnumsFiltr->Logic_OR );
		if ( $f->Select() ) {
			$inCAM->COM( "sel_move", "dx" => 0, "dy" => $sign * -6 );
		}

		# Remove film description and put new
		$f->Reset();
		$f->AddIncludeAtt( ".pnl_place", "T-*" );
		if ( $f->Select() ) {
			$inCAM->COM("sel_delete");
		}

		my $xPos = 205;
		my $yPos = 6;
		$yPos += 20 if ( CamJob->GetSignalLayerCnt( $inCAM, $jobId ) > 2 );

		$self->__PutInfoText( $inCAM, $jobId, $fakeSM, ( $sourceL eq "mc" ? "bot" : "top" ),
							  $xPos, $yPos, ( $sourceL eq "mc" ? "Spoje MASKA" : "Soucastky MASKA" ) );

	}

	push( @fakeLayers, $fakeSM );

	return @fakeLayers;

}

# Fake layers, where soldermask is only from one side.
# But OLEC machine need films from both side in order register films
# For Multilayer PCB only (rest of PCB is exposed without cameras??)
sub __CreateFakePLGLayers {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $step        = shift;
	my $emptyLayers = shift // 0;    # Create layer without any data

	my @fakeLayers = ();

	my @layers = CamJob->GetBoardLayers( $inCAM, $jobId );

	if ( CamDrilling->GetViaFillExists( $inCAM, $jobId ) ) {

		@fakeLayers = PlugLayer->CreateCopperPlugLayersAllSteps( $inCAM, $jobId, undef, $emptyLayers );

	}

	return @fakeLayers;

}

# Outer layers for PCB with outer core at stackup
sub __CreateFakeOuterCoreLayers {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $step        = shift;
	my $emptyLayers = shift // 0;    # Create layer without any data

	my @fakeLayers = ();

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	return @fakeLayers if ( $layerCnt <= 2 );

	my @IProducts = ();              # top/bot/both
	if ( StackupOperation->OuterCore( $inCAM, $jobId, \@IProducts ) ) {

		CamHelper->SetStep( $inCAM, $step );

		foreach my $IProduct (@IProducts) {

			my @layers = ();

			# check if outer core are on both side (top and bot)
			if ( $IProduct->GetOuterCoreTop() ) {

				my $name = JobHelper->BuildSignalLayerName( $IProduct->GetTopCopperLayer(), 1, $IProduct->GetPlugging() );
				push( @layers, $name );
			}

			if ( $IProduct->GetOuterCoreBot() ) {

				my $name = JobHelper->BuildSignalLayerName( $IProduct->GetBotCopperLayer(), 1, $IProduct->GetPlugging() );
				push( @layers, $name );
			}

			# Create fake layers
			foreach my $l (@layers) {
				CamMatrix->DeleteLayer( $inCAM, $jobId, $l );
				CamMatrix->CreateLayer( $inCAM, $jobId, $l, "document", "positive", 1 );
			}

			# Put surface over whole panel (full sopper)
			if ( !$emptyLayers ) {

				# Add frame and fiduc for OLEC (take it from c2)
				CamLayer->WorkLayer( $inCAM, "v2" );

				my $f = FeatureFilter->new( $inCAM, $jobId, "v2" );
				$f->SetProfile( EnumsFiltr->ProfileMode_OUTSIDE );
				if ( $f->Select() ) {

					CamLayer->CopySelOtherLayer( $inCAM, \@layers );

				}
				else {
					die "No frame and fiducials was found in v2 layer outside profile";
				}

				# Add frame 100µm width around pcb (fr frame coordinate)
				my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );
				my @pointsLim = ();
				push( @pointsLim, { "x" => $lim{"xMin"}, "y" => $lim{"yMin"} } );
				push( @pointsLim, { "x" => $lim{"xMin"}, "y" => $lim{"yMax"} } );
				push( @pointsLim, { "x" => $lim{"xMax"}, "y" => $lim{"yMax"} } );
				push( @pointsLim, { "x" => $lim{"xMax"}, "y" => $lim{"yMin"} } );
				push( @pointsLim, { "x" => $lim{"xMin"}, "y" => $lim{"yMin"} } );

				CamLayer->AffectLayers( $inCAM, \@layers );
				CamSymbolSurf->AddSurfacePolyline( $inCAM, \@pointsLim, 1, "positive" );
				CamSymbol->AddPolyline( $inCAM, \@pointsLim, "r200", "negative", 1 );

				# Put schmoll crosses
				if ( JobHelper->GetIsFlex($jobId) ) {

					my $f = Features->new();
					$f->Parse( $inCAM, $jobId, $step, "v2" );    # layer v2 should already exist in multilayer pcb

					my @cross = grep { defined $_->{"symbol"} && $_->{"symbol"} =~ /^schmoll_cross_10$/i } $f->GetFeatures();

					die "All schmol crosees (four, symbol name: schmoll_cross_10) were not found in layer: v2" unless ( scalar(@cross) == 4 );

					foreach my $c (@cross) {

						#CamSymbol->AddPad( $inCAM, "s12000", { "x" => $c->{"x1"}, "y" => $c->{"y1"} }, 0, "positive" );
						CamSymbol->AddPad( $inCAM, "schmoll_cross_10", { "x" => $c->{"x1"}, "y" => $c->{"y1"} }, 0, "negative" );
					}
				}

				# Put OLEC crosses

				my $olecSym = undef;
				if ( $IProduct->GetOuterCoreTop() ) {

					$olecSym = "cross_inner_x";
				}
				elsif ( $IProduct->GetOuterCoreBot() ) {

					$olecSym = "cross_inner";
				}

				my $fv = Features->new();
				$fv->Parse( $inCAM, $jobId, $step, "v1" );

				my @olecFeats = grep { defined $_->{"att"}->{".geometry"} && $_->{"att"}->{".geometry"} =~ /^OLEC_otvor_IN$/ } $fv->GetFeatures();
				die "All fiducial marks (four marks, attribut: OLEC_otvor_IN) were not found in layer: v1"
				  unless ( scalar(@olecFeats) == 4 );

				foreach my $c (@olecFeats) {
					
					CamSymbol->AddPad( $inCAM, $olecSym, { "x" => $c->{"x1"}, "y" => $c->{"y1"} }, 0, "negative" );
				}

				# Put info text

				my $xPos = 205;
				my $yPos = 6;

				if ( $IProduct->GetOuterCoreTop() ) {
					my $name = JobHelper->BuildSignalLayerName( $IProduct->GetTopCopperLayer(), 1, $IProduct->GetPlugging() );
					$self->__PutInfoText( $inCAM, $jobId, $name, "top", $xPos, $yPos, "Outer " . $IProduct->GetTopCopperLayer() . " TOP" );
				}

				if ( $IProduct->GetOuterCoreBot() ) {

					my $name = JobHelper->BuildSignalLayerName( $IProduct->GetBotCopperLayer(), 1, $IProduct->GetPlugging() );
					$self->__PutInfoText( $inCAM, $jobId, $name, "bot", $xPos, $yPos, "Outer " . $IProduct->GetBotCopperLayer() . " BOT" );
				}

			}

			push( @fakeLayers, @layers );
		}

	}

	CamLayer->ClearLayers($inCAM);

	return @fakeLayers;

}

sub __CreateCoreDrillLayers {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $step        = shift;
	my $emptyLayers = shift // 0;    # Create layer without any data

	my @fakeLayers = ();

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	return @fakeLayers if ( $layerCnt <= 2 || !JobHelper->GetIsFlex($jobId) );

	my $stackup = Stackup->new( $inCAM, $jobId );

	my @products = $stackup->GetInputChildProducts();

	foreach my $coreProdut ( sort { $b->GetCoreNumber() <=> $a->GetCoreNumber() } @products ) {

		my $lName = "v1j" . $coreProdut->GetCoreNumber();

		CamMatrix->DeleteLayer( $inCAM, $jobId, $lName );
		CamMatrix->CreateLayer( $inCAM, $jobId, $lName, "drill", "positive", 1, "v1", "after" );
		CamMatrix->SetNCLayerStartEnd( $inCAM, $jobId, $lName, $coreProdut->GetTopCopperLayer(), $coreProdut->GetBotCopperLayer() );

		push( @fakeLayers, $lName );
	}

	unless ($emptyLayers) {
		CamHelper->SetStep( $inCAM, $step );

		CamLayer->WorkLayer( $inCAM, "v1" );
		CamLayer->CopySelOtherLayer( $inCAM, \@fakeLayers );

		CamLayer->ClearLayers($inCAM);
	}

	return @fakeLayers;
}

sub __PutInfoText {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $layer = shift;
	my $side  = shift;    # top/bot
	my $x     = shift;    # left down corner of info text in panel
	my $y     = shift;
	my $text  = shift;

	# Put info text
	CamLayer->WorkLayer( $inCAM, $layer );

	my $xPos = 205;
	my $yPos = 6;

	if ( $side eq "top" ) {

		CamSymbol->AddPad( $inCAM, "inner-bg-nomenclat", { "x" => $x + 27, "y" => $y + 5 }, 0, "negative" );

		CamSymbol->AddText( $inCAM, '$$user_name', { "x" => $x + 1.5, "y" => $y + 1.8 }, 2.5, 2.5, 1 );
		CamSymbol->AddText( $inCAM, 'HH:MM',       { "x" => $x + 10,  "y" => $y + 1.8 }, 2.5, 2.5, 1 );
		CamSymbol->AddText( $inCAM, 'DD/MM/YY',    { "x" => $x + 24,  "y" => $y + 1.8 }, 2.5, 2.5, 1 );
		CamSymbol->AddText( $inCAM, 'DDD',         { "x" => $x + 46,  "y" => $y + 1.8 }, 2.5, 2.5, 1 );

		CamSymbol->AddText( $inCAM, '$$JOB ' . $text, { "x" => $x + 1.5, "y" => $y + 5.5 }, 2.5, 2.5, 1 );

	}
	else {

		CamSymbol->AddPad( $inCAM, "inner-bg-nomenclat", { "x" => $x + 27, "y" => $y + 5 }, 0, "negative" );

		CamSymbol->AddText( $inCAM, '$$user_name', { "x" => $x + 52, "y" => $y + 1.8 }, 2.5, 2.5, 1, 1 );
		CamSymbol->AddText( $inCAM, 'HH:MM',       { "x" => $x + 43, "y" => $y + 1.8 }, 2.5, 2.5, 1, 1 );
		CamSymbol->AddText( $inCAM, 'DD/MM/YY',    { "x" => $x + 29, "y" => $y + 1.8 }, 2.5, 2.5, 1, 1 );
		CamSymbol->AddText( $inCAM, 'DDD',         { "x" => $x + 8,  "y" => $y + 1.8 }, 2.5, 2.5, 1, 1 );

		CamSymbol->AddText( $inCAM, '$$JOB ' . $text, { "x" => $x + 52, "y" => $y + 5.5 }, 2.5, 2.5, 1, 1 );
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::PreExport::FakeLayers';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d262773";

	my $stepName = "panel";

	my %types = FakeLayers->CreateFakeLayers( $inCAM, $jobId, "panel", 0 );

	print %types;
}

1;

