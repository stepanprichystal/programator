#-------------------------------------------------------------------------------------------#
# Description: Adjustment of customer schema
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::FlexiLayers::FlexiBendArea;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamMatrix';
use aliased 'Packages::Polygon::Features::PolyLineFeatures::PolyLineFeatures';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamSymbolSurf';
use aliased 'CamHelpers::CamSymbol';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::StackupOperation';
use aliased 'Packages::Stackup::Enums' => 'EnumsStack';
use aliased 'Packages::Polygon::Features::Features::Features';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#
# Check if mpanel contain requsted schema by customer
sub PutCuToBendArea {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $clearance = shift // 250;    # Default clearance of Cu from bend border is 250µm

	my $result = 1;

	my @polygons = $self->GetBendAreas( $inCAM, $jobId, $step );

	# put Cu only to rigid signal layer
	my @layers = ();

	my @lamPackages = StackupOperation->GetLaminatePackages($jobId);

	foreach my $lamPckg (@lamPackages) {

		if (    $lamPckg->{"packageTop"}->{"coreType"} eq EnumsStack->CoreType_FLEX
			 && $lamPckg->{"packageBot"}->{"coreType"} eq EnumsStack->CoreType_RIGID )
		{

			my $lName = $lamPckg->{"packageBot"}->{"layers"}->[0]->GetCopperName();

			die "Not a inner copper layer: $lName" if ( $lName !~ /^v\d+$/ );
			push( @layers, [ $lName, CamMatrix->GetLayerPolarity( $inCAM, $jobId, $lName ) ] );

		}
		elsif (    $lamPckg->{"packageTop"}->{"coreType"} eq EnumsStack->CoreType_RIGID
				&& $lamPckg->{"packageBot"}->{"coreType"} eq EnumsStack->CoreType_FLEX )
		{

			my $lName = $lamPckg->{"packageTop"}->{"layers"}->[-1]->GetCopperName();

			die "Not a inner copper layer: $lName" if ( $lName !~ /^v\d+$/ );

			push( @layers, [ $lName, CamMatrix->GetLayerPolarity( $inCAM, $jobId, $lName ) ] );
		}
	}

	CamHelper->SetStep( $inCAM, $step );

	foreach my $l (@layers) {

		CamLayer->WorkLayer( $inCAM, $l->[0] );

		foreach my $poly (@polygons) {

			my @points = map { { "x" => $_->[0], "y" => $_->[1] } } @{$poly};
			my @pointsSurf = @points[ 0 .. scalar(@points) - 2 ];

			#CamSymbolSurf->AddSurfaceSolidPattern( $inCAM, 1, 2000, 1 );
			CamSymbolSurf->AddSurfacePolyline( $inCAM, \@pointsSurf, 1, $l->[1] );
			CamSymbol->AddPolyline( $inCAM, \@points, "r" . ( 2 * $clearance ), ( $l->[1] eq "positive" ? "negative" : "positive" ) );
		}
	}

	CamLayer->ClearLayers($inCAM);

	return $result;
}

# Check if mpanel contain requsted schema by customer
sub CreateRoutPrepregByBendArea {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $clearance = shift // 300;    # Default clearance of prepreg from rigin/flex transition

	my $result = 1;

	my $bendAreaL = "bend";
	unless ( CamHelper->LayerExists( $inCAM, $jobId, $bendAreaL ) ) {
		die "Benda area layer: $bendAreaL doesn't exists";
	}

	my $prepregL = "fprepreg";

	CamMatrix->DeleteLayer( $inCAM, $jobId, $prepregL );
	CamMatrix->CreateLayer( $inCAM, $jobId, $prepregL, "rout", "positive", 1 );
	CamMatrix->SetNCLayerStartEnd( $inCAM, $jobId, $prepregL, "bend", "bend" );

	my @polygons = $self->GetBendAreas( $inCAM, $jobId, $step );

	foreach my $poly (@polygons) {

		CamLayer->WorkLayer( $inCAM, $prepregL );

		my @points = map { { "x" => $_->[0], "y" => $_->[1] } } @{$poly};
		my @pointsSurf = @points[ 0 .. scalar(@points) - 2 ];

		#CamSymbolSurf->AddSurfaceSolidPattern( $inCAM, 1, 2000, 1 );
		CamSymbolSurf->AddSurfacePolyline( $inCAM, \@pointsSurf, 1 );
		CamSymbol->AddPolyline( $inCAM, \@points, "s" . ( 2 * $clearance ), "positive" );
		CamLayer->WorkLayer( $inCAM, $prepregL );
		CamLayer->Contourize( $inCAM, $prepregL );
	}

	CamLayer->ClearLayers($inCAM);

	return $result;
}

sub PrepareCoverlayMaskByBendArea {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $clearance = shift // 250;    # Default clearance of Cu from bend border is 250µm

	my $result = 1;

	my @polygons = $self->GetBendAreas( $inCAM, $jobId, $step );

	# put Cu only to rigid signal layer
	my @layers = grep { $_ =~ /coverlay/ } map { $_->{"gROWname"} } CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	#push( @layers, "coverlayc" ) if ( CamHelper->LayerExists( $inCAM, $jobId, "coverlayc" ) );
	#push( @layers, "coverlays" ) if ( CamHelper->LayerExists( $inCAM, $jobId, "coverlays" ) );

	foreach my $l (@layers) {

		CamLayer->WorkLayer( $inCAM, $l );
		CamLayer->DeleteFeatures($inCAM);
		my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );
		my @pointsLim = ();

		push( @pointsLim, { "x" => $lim{"xMin"}, "y" => $lim{"yMin"} } );
		push( @pointsLim, { "x" => $lim{"xMin"}, "y" => $lim{"yMax"} } );
		push( @pointsLim, { "x" => $lim{"xMax"}, "y" => $lim{"yMax"} } );
		push( @pointsLim, { "x" => $lim{"xMax"}, "y" => $lim{"yMin"} } );

		CamSymbolSurf->AddSurfacePolyline( $inCAM, \@pointsLim, 1, "positive" );

		CamLayer->ClipAreaByProf( $inCAM, $l, 0 );
		CamLayer->WorkLayer( $inCAM, $l );

		foreach my $poly (@polygons) {

			CamLayer->WorkLayer( $inCAM, $l );

			my @points = map { { "x" => $_->[0], "y" => $_->[1] } } @{$poly};
			my @pointsSurf = @points[ 0 .. scalar(@points) - 2 ];

			#CamSymbolSurf->AddSurfaceSolidPattern( $inCAM, 1, 2000, 1 );
			CamSymbolSurf->AddSurfacePolyline( $inCAM, \@pointsSurf, 1, "negative" );
			CamSymbol->AddPolyline( $inCAM, \@points, "s" . ( 2 * $clearance ), "negative" );

		}

		CamLayer->WorkLayer( $inCAM, $l );
		CamLayer->Contourize( $inCAM, $l );
	}

	CamLayer->ClearLayers($inCAM);

	return $result;
}

sub PrepareRoutCoverlayByBendArea {
	my $self              = shift;
	my $inCAM             = shift;
	my $jobId             = shift;
	my $step              = shift;
	my $coverlayOverlap   = shift // 500;    # Ovelrap of coverlay to rigid area
	my $coverlayClearance = shift // 500;    # clearance from rigid area profile (except transition zone)

	my $result = 1;

	my @polygons = $self->GetBendAreas( $inCAM, $jobId, $step );

	# create pom layer with resiyed areas by $coverlayOverlap size
	my $bendResizedL = GeneralHelper->GetGUID();
	CamMatrix->CreateLayer( $inCAM, $jobId, $bendResizedL, "document", "positive", 0 );
	CamLayer->WorkLayer( $inCAM, $bendResizedL );
	foreach my $poly (@polygons) {
		my @points = map { { "x" => $_->[0], "y" => $_->[1] } } @{$poly};
		my @pointsSurf = @points[ 0 .. scalar(@points) - 2 ];
		CamSymbolSurf->AddSurfacePolyline( $inCAM, \@pointsSurf, 1, "negative" );

	}

	CamLayer->ResizeFeatures( $inCAM, 2 * $coverlayOverlap );

	# put Cu only to rigid signal layer

	my @layers = grep { $_ =~ /coverlay/ } map { $_->{"gROWname"} } CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	my $coverTop = 1;
	my $coverBot = 1;
	my @routL    = ();
	for ( my $i = 0 ; $i < scalar(@layers) ; $i++ ) {

		my $side;

		my ($cuLayer) = $layers[$i] =~ /^coverlay(\w\d*)/;

		if ( $cuLayer eq "c" ) {
			$side = "top";
		}
		elsif ( $cuLayer eq "s" ) {
			$side = "bot";

		}
		else {

			# Rigid flex
			$side = StackupOperation->GetSideByLayer( $jobId, $cuLayer );
		}

		my $routLName = "fcoverlay";

		if ( $side eq "top" ) {

			$routLName .= "c" . $coverTop;
			$coverTop++;

		}
		else {

			$routLName .= "s" . $coverBot;
			$coverBot++;
		}

		CamMatrix->DeleteLayer( $inCAM, $jobId, $routLName );
		CamMatrix->CreateLayer( $inCAM, $jobId, $routLName, "rout", "positive", 1 );
		CamMatrix->SetNCLayerStartEnd( $inCAM, $jobId, $routLName, $layers[$i], $layers[$i] );
		CamMatrix->SetLayerDirection( $inCAM, $jobId, $routLName, ( $side eq "top" ? "top_to_bottom" : "bottom_to_top" ) );

		push( @routL, $routLName );

	}

	foreach my $l (@routL) {

		my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );
		my @pointsLim = ();

		push( @pointsLim, { "x" => $lim{"xMin"} - 2, "y" => $lim{"yMin"} - 2 } );
		push( @pointsLim, { "x" => $lim{"xMin"} - 2, "y" => $lim{"yMax"} + 2 } );
		push( @pointsLim, { "x" => $lim{"xMax"} + 2, "y" => $lim{"yMax"} + 2 } );
		push( @pointsLim, { "x" => $lim{"xMax"} + 2, "y" => $lim{"yMin"} - 2 } );

		CamLayer->WorkLayer( $inCAM, $l );

		CamSymbolSurf->AddSurfacePolyline( $inCAM, \@pointsLim, 1, "positive" );

		CamLayer->ClipAreaByProf( $inCAM, $l, $coverlayClearance );

		CamLayer->WorkLayer( $inCAM, $bendResizedL );
		CamLayer->CopySelOtherLayer( $inCAM, [$l] );

		CamLayer->WorkLayer( $inCAM, $l );
		CamLayer->Contourize( $inCAM, $l );
		CamLayer->WorkLayer( $inCAM, $l );
		$inCAM->COM( "sel_feat2outline", "width" => "200", "location" => "on_edge" );
	}

	CamLayer->ClearLayers($inCAM);
	CamMatrix->DeleteLayer( $inCAM, $jobId, $bendResizedL );
	return $result;
}

sub GetBendAreas {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $bendAreaL = shift // "bend";
	my $

	unless ( CamHelper->LayerExists( $inCAM, $jobId, $bendAreaL ) ) {
		die "Benda area layer: $bendAreaL doesn't exists";
	}

	my $polyLine = PolyLineFeatures->new();
	$polyLine->Parse( $inCAM, $jobId, $step, $bendAreaL );

	my @polygons = $polyLine->GetPolygonsPoints();

	die "No bend area (polygons) found in bend layer: $bendAreaL" unless (@polygons);

	return @polygons;
}

#sub GetTransitionFeats {
#	my $self      = shift;
#	my $inCAM     = shift;
#	my $jobId     = shift;
#	my $step      = shift;
#	my $bendAreaL = shift // "bend";
#	my $feats     = = shift;
# 
#	my $detected = 1;
#
#	my $lProf = GeneralHelper->GetGUID();
#	CamStep->ProfileToLayer( $inCAM, $step, $lProf, 200 );
#
#	my $lTrans = GeneralHelper->GetGUID();
#
#	CamMatrix->CopyLayer( $inCAM, $jobId, $bendAreaL, $step, $lTrans, $step );
#	CamLayer->WorkLayer( $inCAM, $lTrans );
#	$inCAM->COM( "sel_extend_slots", "mode" => "ext_by", "size" => -2000, "from" => "center" );
#
#	if ( CamFilter->SelectByReferenece( $inCAM, $jobId, "cover", $bendAreaL, undef, undef, undef, $lProf ) ) {
#		$inCAM->COM("sel_reverse");
#
#		my $f = Features->new();
# 
#		$f->Parse( $inCAM, $jobId, $step, $layer, 0, 1 );
#		
#		my @feats =  map { $_->{"id"} } $f->GetFeatures();
#		
#		if(scalar(grep{$_->{"type"} eq "lines"} @feats ) != scalar(@feats)){
#			$detected = 0;
#		}else{
#			
#			
#			
#		}
#		
#	 
#	
#	}else{
#		$detected = 0;
#	}
#
#	return $detected
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::FlexiLayers::FlexiBendArea';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d222775";

	my $mess = "";

	my $result = FlexiBendArea->PrepareRoutCoverlayByBendArea( $inCAM, $jobId, "o+1" );

	print STDERR "Result is: $result, error message: $mess\n";

}

1;
