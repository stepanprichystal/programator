
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
use aliased 'Helpers::JobHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# Create fake layers necesserz for export
# All fake layers has attribut "export_fake_layer" set to: yes
sub CreateFakeLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift // "panel";

	$self->RemoveFakeLayers( $inCAM, $jobId, $step );

	my @smFake = $self->__CreateFakeSMLayers( $inCAM, $jobId, $step );
	my @outerFake = $self->__CreateFakeOuterCoreLayers( $inCAM, $jobId, $step );

	my @fake = ();
	push( @fake, @smFake )    if (@smFake);
	push( @fake, @outerFake ) if (@outerFake);

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

# Create special step, which IPC will be exported from
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

sub __CreateFakeOuterCoreLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $step = "panel";

	my @fakeLayers = ();

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	return @fakeLayers if ( $layerCnt <= 2 );
 
	my $side;    # top/bot/both
	if ( StackupOperation->OuterCore( $jobId, \$side ) ) {

		CamHelper->SetStep( $inCAM, $step );

		my $topL = "v1outer";
		my $botL = "v$layerCnt" . "outer";

		# check if outer core are on both side (top and bot)

		push( @fakeLayers, $topL ) if ( $side eq "both" || $side eq "top" );
		push( @fakeLayers, $botL ) if ( $side eq "both" || $side eq "bot" );

		# Create fake layers
		foreach my $l (@fakeLayers) {
			CamMatrix->DeleteLayer( $inCAM, $jobId, $l );
			CamMatrix->CreateLayer( $inCAM, $jobId, $l, "document", "positive", 1 );
		}

		# Put surface over whole panel (full sopper)

		CamLayer->AffectLayers( $inCAM, \@fakeLayers );
		my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );
		my @pointsLim = ();
		push( @pointsLim, { "x" => $lim{"xMin"}, "y" => $lim{"yMin"} } );
		push( @pointsLim, { "x" => $lim{"xMin"}, "y" => $lim{"yMax"} } );
		push( @pointsLim, { "x" => $lim{"xMax"}, "y" => $lim{"yMax"} } );
		push( @pointsLim, { "x" => $lim{"xMax"}, "y" => $lim{"yMin"} } );

		CamSymbolSurf->AddSurfacePolyline( $inCAM, \@pointsLim, 1, "positive" );

		# frame 100µm width around pcb (fr frame coordinate)
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

		if ( $side eq "both" || $side eq "top" ) {

			# Put info text
			CamLayer->WorkLayer( $inCAM, $topL );

			my $x = 205;
			my $y = 6;

			CamSymbol->AddPad( $inCAM, "inner-bg-nomenclat", { "x" => $x + 27, "y" => $y + 5 }, 0, "negative" );
			CamSymbol->AddText( $inCAM, '$$JOB V1 (C) TOP', { "x" => $x + 1.5, "y" => $y + 1.8 }, 2.5, 2.5, 1 );

			CamSymbol->AddText( $inCAM, '$$user_name', { "x" => $x + 1.5, "y" => $y + 5.5 }, 2.5, 2.5, 1 );
			CamSymbol->AddText( $inCAM, 'TIME',        { "x" => $x + 10,  "y" => $y + 5.5 }, 2.5, 2.5, 1 );
			CamSymbol->AddText( $inCAM, 'DATE-DDMMYY', { "x" => $x + 24,  "y" => $y + 5.5 }, 2.5, 2.5, 1 );
			#CamSymbol->AddText( $inCAM, 'DDD',         { "x" => $x + 46,  "y" => $y + 5.5 }, 2.5, 2.5, 1 );
		}

		if ( $side eq "both" || $side eq "bot" ) {

			# Put info text
			CamLayer->WorkLayer( $inCAM, $botL );

			my $x = 205;
			my $y = 6;

			CamSymbol->AddPad( $inCAM, "inner-bg-nomenclat", { "x" => $x + 27, "y" => $y + 5 }, 0, "negative" );
			CamSymbol->AddText( $inCAM, '$$JOB V' . $layerCnt . ' (S) BOT', { "x" => $x + 52, "y" => $y + 1.8 }, 2.5, 2.5, 1, 1 );

			CamSymbol->AddText( $inCAM, '$$user_name', { "x" => $x + 52, "y" => $y + 5.5 }, 2.5, 2.5, 1, 1 );
			CamSymbol->AddText( $inCAM, 'TIME',        { "x" => $x + 43, "y" => $y + 5.5 }, 2.5, 2.5, 1, 1 );
			CamSymbol->AddText( $inCAM, 'DATE-DDMMYY', { "x" => $x + 29, "y" => $y + 5.5 }, 2.5, 2.5, 1, 1 );
			#CamSymbol->AddText( $inCAM, 'DDD',         { "x" => $x + 8,  "y" => $y + 5.5 }, 2.5, 2.5, 1, 1 );
		}

	}

	CamLayer->ClearLayers($inCAM);

	return @fakeLayers;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::PreExport::FakeLayers';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId    = "d147721";
	my $stepName = "panel";

	my %types = FakeLayers->CreateFakeLayers( $inCAM, $jobId, "panel" );

	print %types;
}

1;

