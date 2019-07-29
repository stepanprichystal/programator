
#-------------------------------------------------------------------------------------------#
# Description: Helper for exporting MDI files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::Mdi::ExportFiles::Helper;

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

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
# Return layer types which should be exported by default
sub GetDefaultLayerTypes {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my %mdiInfo = ();

	my @layers = CamJob->GetAllLayers( $inCAM, $jobId );

	my $signal = scalar( grep { $_->{"gROWname"} eq "c" } @layers );

	if ( HegMethods->GetTypeOfPcb($jobId) eq "Neplatovany" ) {
		$signal = 0;
	}

	$mdiInfo{ Enums->Type_SIGNAL } = $signal;

	if ( scalar( grep { $_->{"gROWname"} =~ /m[cs]/ } @layers ) )    # && CamJob->GetJobPcbClass( $inCAM, $jobId ) >= 8
	{
		$mdiInfo{ Enums->Type_MASK } = 1;
	}
	else {
		$mdiInfo{ Enums->Type_MASK } = 0;
	}

	$mdiInfo{ Enums->Type_PLUG } =
	  scalar( grep { $_->{"gROWname"} =~ /plg[cs]/ } @layers ) ? 1 : 0;
	$mdiInfo{ Enums->Type_GOLD } =
	  scalar( grep { $_->{"gROWname"} =~ /gold[cs]/ } @layers ) ? 1 : 0;

	return %mdiInfo;
}

# Create special step, which IPC will be exported from
sub CreateFakeLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;

	my @smFake = $self->__CreateFakeSMLayers( $inCAM, $jobId, $step );
	my @outerFake = $self->__CreateFakeOuterCoreLayers( $inCAM, $jobId, $step );

	my @fake = ();
	push( @fake, @smFake )    if (@smFake);
	push( @fake, @outerFake ) if (@outerFake);

	return @fake;
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

	return @fake;
}

sub __CreateFakeOuterCoreLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $step = "panel";

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	return 0 if ( $layerCnt <= 2 );

	my @fakeLayers = ();

	my $side;    # top/bot/both
	if ( StackupOperation->OuterCore($inCAM,  $jobId, \$side ) ) {

		CamHelper->SetStep( $inCAM, $step );

		my $topL = "v1outer";
		my $botL = "v$layerCnt" . "outer";

		# check if outer core are on both side (top and bot)

		push( @fakeLayers, $topL ) if ( $side eq "both" || $side eq "top" );
		push( @fakeLayers, $botL ) if ( $side eq "both" || $side eq "bot" );

		# Create fake layers
		foreach my $l (@fakeLayers) {
			CamMatrix->DeleteLayer( $inCAM, $jobId, $l );
			CamMatrix->CreateLayer( $inCAM, $jobId, $l, "signal", "positive", 1 );
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
		my $f = Features->new();
		$f->Parse( $inCAM, $jobId, $step, "v2" );    # layer v2 should already exist in multilayer pcb

		my @cross = grep { defined $_->{"symbol"} && $_->{"symbol"} =~ /^schmoll_cross_10$/i } $f->GetFeatures();

		die "All schmol crosees (four, symbol name: schmoll_cross_10) were not found in layer: v2" unless ( scalar(@cross) == 4 );

		foreach my $c (@cross) {

			#CamSymbol->AddPad( $inCAM, "s12000", { "x" => $c->{"x1"}, "y" => $c->{"y1"} }, 0, "positive" );
			CamSymbol->AddPad( $inCAM, "schmoll_cross_10", { "x" => $c->{"x1"}, "y" => $c->{"y1"} }, 0, "negative" );
			
		}

		if ( $side eq "both" || $side eq "top" ) {

			# Put info text
			CamLayer->WorkLayer( $inCAM, $topL );

			my $x = 205;
			my $y = 6;

			CamSymbol->AddPad( $inCAM, "inner-bg-nomenclat", { "x" => $x + 27, "y" => $y + 5 }, 0, "negative" );
			CamSymbol->AddText( $inCAM, '$$JOB V1 TOP', { "x" => $x + 1.5, "y" => $y + 1.8 }, 2.5, 2.5, 1 );

			CamSymbol->AddText( $inCAM, '$$user_name',   { "x" => $x + 1.5, "y" => $y + 5.5 }, 2.5, 2.5, 1 );
			CamSymbol->AddText( $inCAM, '$$TIME',        { "x" => $x + 10,  "y" => $y + 5.5 }, 2.5, 2.5, 1 );
			CamSymbol->AddText( $inCAM, '$$DATE-DDMMYY', { "x" => $x + 24,  "y" => $y + 5.5 }, 2.5, 2.5, 1 );
			CamSymbol->AddText( $inCAM, '$$DDD',         { "x" => $x + 46,  "y" => $y + 5.5 }, 2.5, 2.5, 1 );
		}

		if ( $side eq "both" || $side eq "bot" ) {

			# Put info text
			CamLayer->WorkLayer( $inCAM, $botL );

			my $x = 205;
			my $y = 6;

			CamSymbol->AddPad( $inCAM, "inner-bg-nomenclat", { "x" => $x + 27, "y" => $y + 5 }, 0, "negative" );
			CamSymbol->AddText( $inCAM, '$$JOB V' . $layerCnt . ' BOT', { "x" => $x + 52, "y" => $y + 1.8 }, 2.5, 2.5, 1, 1 );

			CamSymbol->AddText( $inCAM, '$$user_name',   { "x" => $x + 52, "y" => $y + 5.5 }, 2.5, 2.5, 1, 1 );
			CamSymbol->AddText( $inCAM, '$$TIME',        { "x" => $x + 43, "y" => $y + 5.5 }, 2.5, 2.5, 1, 1 );
			CamSymbol->AddText( $inCAM, '$$DATE-DDMMYY', { "x" => $x + 29, "y" => $y + 5.5 }, 2.5, 2.5, 1, 1 );
			CamSymbol->AddText( $inCAM, '$$DDD',         { "x" => $x + 8,  "y" => $y + 5.5 }, 2.5, 2.5, 1, 1 );
		}

	}

	return @fakeLayers;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Gerbers::Mdi::ExportFiles::Helper';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId    = "d246713";
	my $stepName = "panel";

	my %types = Helper->CreateFakeLayers( $inCAM, $jobId, "panel" );

	print %types;
}

1;

