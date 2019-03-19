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
use List::Util qw[max min];

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamSymbolSurf';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Packages::Stackup::StackupOperation';
use aliased 'Packages::Stackup::Enums' => 'EnumsStack';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Packages::CAMJob::FlexiLayers::BendAreaParser::BendAreaParser';
use aliased 'Enums::EnumsDrill';
use aliased 'CamHelpers::CamDTM';

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

	my $parser = BendAreaParser->new( $inCAM, $jobId, $step );
	my $errMess = "";
	die $errMess unless ( $parser->CheckBendArea( \$errMess ) );

	my @bendAreas = $parser->GetBendAreas();

	# put Cu only to rigid signal layer
	my @layers = ();

	my @lamPackages = StackupOperation->GetJoinedFlexRigidPackages($jobId);

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

		foreach my $bendArea (@bendAreas) {

			my @points = map { { "x" => $_->[0], "y" => $_->[1] } } $bendArea->GetPoints();
			my @pointsSurf = @points[ 0 .. scalar(@points) - 2 ];

			#CamSymbolSurf->AddSurfaceSolidPattern( $inCAM, 1, 2000, 1 );
			CamSymbolSurf->AddSurfacePolyline( $inCAM, \@pointsSurf, 1, $l->[1] );
			CamSymbol->AddPolyline( $inCAM, \@points, "r" . ( 2 * $clearance ), ( $l->[1] eq "positive" ? "negative" : "positive" ) );
		}
	}

	CamLayer->ClearLayers($inCAM);

	return $result;
}


# If pcb contain soldermask an coverlay, unmask bend area in c,s
sub UnMaskBendArea {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $clearance = shift // 100;    # Default clearance of solder mask from bend area

	my $result = 1;

	
	
	my @layers = CamJob->GetBoardBaseLayers($inCAM, $jobId);
	
	my @mask = grep { $_->{"gROWlayer_type"} eq "solder_mask" } @layers;
	my @coverlay = grep { $_->{"gROWlayer_type"} eq "coverlay" } @layers;
	
	return 0 if(!(@mask && @coverlay));
	
	my $parser = BendAreaParser->new( $inCAM, $jobId, $step );
	my $errMess = "";
	die $errMess unless ( $parser->CheckBendArea( \$errMess ) );

	my @bendAreas = $parser->GetBendAreas();
 

	CamHelper->SetStep( $inCAM, $step );

	foreach my $l (@mask) {

		CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );

		foreach my $bendArea (@bendAreas) {

			my @points = map { { "x" => $_->[0], "y" => $_->[1] } } $bendArea->GetPoints();
			my @pointsSurf = @points[ 0 .. scalar(@points) - 2 ];

			CamSymbolSurf->AddSurfacePolyline( $inCAM, \@pointsSurf, 1 );
			CamSymbol->AddPolyline( $inCAM, \@points, "r" . ( 2 * $clearance ), "positive");
		}
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

	my $parser = BendAreaParser->new( $inCAM, $jobId, $step );
	my $errMess = "";
	die $errMess unless ( $parser->CheckBendArea( \$errMess ) );

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

		foreach my $bendArea ( $parser->GetBendAreas() ) {

			CamLayer->WorkLayer( $inCAM, $l );

			my @points = map { { "x" => $_->[0], "y" => $_->[1] } } $bendArea->GetPoints();
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
	my $coverlayClearance = shift // 1000;    # clearance from rigid area profile (except transition zone)

	my $result = 1;

	my $parser = BendAreaParser->new( $inCAM, $jobId, $step );
	my $errMess = "";
	die $errMess unless ( $parser->CheckBendArea( \$errMess ) );

	# create pom layer with resiyed areas by $coverlayOverlap size
	my $bendResizedL = GeneralHelper->GetGUID();
	CamMatrix->CreateLayer( $inCAM, $jobId, $bendResizedL, "document", "positive", 0 );
	CamLayer->WorkLayer( $inCAM, $bendResizedL );
	foreach my $bendArea ( $parser->GetBendAreas() ) {
		my @points = map { { "x" => $_->[0], "y" => $_->[1] } } $bendArea->GetPoints();
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

			$routLName .= "c" . ($coverTop == 1 ? "" : $coverTop);
			$coverTop++;

		}
		else {

			$routLName .= "s" .  ($coverBot == 1 ? "" : $coverBot);
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

	my $parser = BendAreaParser->new( $inCAM, $jobId, $step );
	my $errMess = "";
	die $errMess unless ( $parser->CheckBendArea( \$errMess ) );

	foreach my $bendArea ( $parser->GetBendAreas() ) {

		CamLayer->WorkLayer( $inCAM, $prepregL );

		my @points = map { { "x" => $_->[0], "y" => $_->[1] } } $bendArea->GetPoints();
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

sub CreateRoutTransitionPart1 {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $recreate = shift // 1;    # recreate rout layer with used name

	my $parser = BendAreaParser->new( $inCAM, $jobId, $step );
	my $errMess = "";
	die $errMess unless ( $parser->CheckBendArea( \$errMess ) );

	# define depth  overlap of rout tool in transition zone
	my $overlap = 0.2;            # 0,2mm

	# Rout tool info
	my $toolSize         = 2;           # 2mm
	my $toolMagazineInfo = "d2.0a30";
	my $toolComp         = "none";

	$self->__CreateRoutTransition( $inCAM, $jobId, $step, 1, $toolSize, $toolMagazineInfo, $toolComp );

}

sub CreateRoutTransitionPart2 {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $recreate = shift // 1;    # recreate rout layer with used name

	my $parser = BendAreaParser->new( $inCAM, $jobId, $step );
	my $errMess = "";
	die $errMess unless ( $parser->CheckBendArea( \$errMess ) );

	# define depth  overlap of rout tool in transition zone
	my $overlap = 0.2;            # 0,2mm

	# Rout tool info
	my $toolSize         = 1;         # 2mm
	my $toolMagazineInfo = undef;
	my $toolComp         = "right";

	$self->__CreateRoutTransition( $inCAM, $jobId, $step, 2, $toolSize, $toolMagazineInfo, $toolComp );

}

sub __CreateRoutTransition {
	my $self             = shift;
	my $inCAM            = shift;
	my $jobId            = shift;
	my $step             = shift;
	my $routPart         = shift;           # 1 = core depth rout, 2 = final depth rout
	my $toolSize         = shift;
	my $toolMagazineInfo = shift;
	my $toolComp         = shift;           # right / left / none
	my $recreate         = shift // 1;      # recreate rout layer with used name
	my $roolOverlap      = shift // 0.2;    # 0,2mm # define depth  overlap of rout tool in transition zone
	my $extendZone       = shift // 0.5;    # 0,5mm transition rout slots will be exteneded on both ends

	my $parser = BendAreaParser->new( $inCAM, $jobId, $step );
	my $errMess = "";
	die $errMess unless ( $parser->CheckBendArea( \$errMess ) );

	# Rout tool info

	my @packages = StackupOperation->GetJoinedFlexRigidPackages($jobId);

	my $top2BotOrder = "";
	my $bot2TopOrder = "";

	# Take highest number of layer type plus 1
	if ( !$recreate ) {

		my @t2b = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_nplt_bMillTop );
		my $maxt2b = max( map { ( $_->{"gROWname"} =~ /\w(\d*)/ )[0] } @t2b );

		if ( defined $maxt2b && $maxt2b > 0 ) {
			$top2BotOrder = $maxt2b + 1;
		}
		elsif (@t2b) {

			$top2BotOrder = 1;
		}

		my @b2t = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_nplt_bMillBot );
		my $maxb2t = max( map { ( $_->{"gROWname"} =~ /\w(\d*)/ )[0] } @b2t );

		if ( defined $maxb2t && $maxb2t > 0 ) {
			$bot2TopOrder = $maxb2t + 1;
		}
		elsif (@b2t) {

			$bot2TopOrder = 1;
		}
	}

	foreach my $joinPackgs (@packages) {

		my $topPckgs = $joinPackgs->{"packageTop"};
		my $botPckgs = $joinPackgs->{"packageBot"};

		my $routDir;
		my $routStart;
		my $routEnd;
		my $routName;
		my $packageThick;

		if ( $routPart == 1 ) {

			if ( $topPckgs->{"coreType"} eq StackEnums->CoreType_RIGID ) {

				$routName  = "jfzs" . $bot2TopOrder;
				$routDir   = "bottom_to_top";
				$routStart = $topPckgs->{"layers"}->[ scalar( @{ $topPckgs->{"layers"} } ) - 1 ]->GetCopperName();
				$routEnd   = $topPckgs->{"layers"}->[0]->GetCopperName();
				$packageThick += $_->GetThick() foreach ( @{ $topPckgs->{"layers"} } );

				$bot2TopOrder++;

			}
			else {

				$routName  = "jfzc" . $top2BotOrder;
				$routDir   = "top_to_bottom";
				$routStart = $botPckgs->{"layers"}->[0]->GetCopperName();
				$routEnd   = $botPckgs->{"layers"}->[ scalar( @{ $botPckgs->{"layers"} } ) - 1 ]->GetCopperName();
				$packageThick += $_->GetThick() foreach ( @{ $botPckgs->{"layers"} } );

				$top2BotOrder++;
			}
		}
		else {

			if ( $topPckgs->{"coreType"} eq StackEnums->CoreType_RIGID ) {

				$routName  = "fzc" . $top2BotOrder;
				$routDir   = "top_to_bottom";
				$routStart = $topPckgs->{"layers"}->[0]->GetCopperName();
				$routEnd   = $topPckgs->{"layers"}->[ scalar( @{ $topPckgs->{"layers"} } ) - 1 ]->GetCopperName();
				$packageThick += $_->GetThick() foreach ( @{ $topPckgs->{"layers"} } );

				$top2BotOrder++;

			}
			else {

				$routName  = "fzs" . $bot2TopOrder;
				$routDir   = "bottom_to_top";
				$routStart = $botPckgs->{"layers"}->[ scalar( @{ $botPckgs->{"layers"} } ) - 1 ]->GetCopperName();
				$routEnd   = $botPckgs->{"layers"}->[0]->GetCopperName();
				$packageThick += $_->GetThick() foreach ( @{ $botPckgs->{"layers"} } );

				$bot2TopOrder++;
			}
		}

		if ( $recreate && CamHelper->LayerExists( $inCAM, $jobId, $routName ) ) {
			CamMatrix->DeleteLayer( $inCAM, $jobId, $routName );
			CamMatrix->CreateLayer( $inCAM, $jobId, $routName, "rout", "positive", 1 );
		}

		unless ( CamHelper->LayerExists( $inCAM, $jobId, $routName ) ) {
			CamMatrix->CreateLayer( $inCAM, $jobId, $routName, "rout", "positive", 1 );
		}

		CamMatrix->SetNCLayerStartEnd( $inCAM, $jobId, $routName, $routStart, $routEnd );
		CamMatrix->SetLayerDirection( $inCAM, $jobId, $routName, $routDir );

		# Draw transition features
		CamLayer->WorkLayer( $inCAM, $routName );

		foreach my $transZone ( map { $_->GetTransitionZones() } $parser->GetBendAreas() ) {

			# transition
			my %startP = $transZone->GetStartPoint();
			my %endP   = $transZone->GetEndPoint();

			CamSymbol->AddLine( $inCAM, \%startP, \%endP, "r200" );
		}

		if ($extendZone) {
			$inCAM->COM( "sel_extend_slots", "mode" => "ext_by", "size" => ( 2 * $extendZone * 1000 ), "from" => "center" );
		}

		# Add chain
		$inCAM->COM(
					 'chain_add',
					 "layer"          => $routName,
					 "chain"          => 1,
					 "size"           => $toolSize,
					 "comp"           => $toolComp,
					 "first"          => 0,
					 "chng_direction" => ( $toolComp eq "right" ) ? 1 : 0
		);

		# Set tool magazine info
		my @DTMTools = CamDTM->GetDTMTools( $inCAM, $jobId, $step, $routName );
		$DTMTools[0]->{"userColumns"}->{ EnumsDrill->DTMclmn_DEPTH } = ( $packageThick / 2 ) / 1000 + $roolOverlap / 2;
		$DTMTools[0]->{"userColumns"}->{ EnumsDrill->DTMclmn_MAGINFO } = $toolMagazineInfo if ( defined $toolMagazineInfo );

		CamDTM->SetDTMTools( $inCAM, $jobId, $step, $routName, \@DTMTools );
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::FlexiLayers::FlexiBendArea';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d222776";

	my $mess = "";

	my $result = FlexiBendArea->PutCuToBendArea( $inCAM, $jobId, "o+1" );
	 
	print STDERR "Result is: $result, error message: $mess\n";

}

1;
