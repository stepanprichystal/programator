#!/usr/bin/perl

#-------------------------------------------------------------------------------------------#
# Description: Do final routing = 2mm with compensation left and suitable start of chain
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use utf8;
use strict;
use warnings;
use Time::HiRes qw (sleep);

#local library

#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Packages::InCAM::InCAM';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsRout';
use aliased 'Packages::Routing::RoutLayer::RoutOutline::RoutOutline';
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveLine';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveText';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::Routing::RoutLayer::RoutOutline::RoutRadiusHelper';
use aliased 'Packages::Routing::RoutLayer::RoutDrawing::RoutDrawing';
use aliased 'Packages::Routing::RoutLayer::RoutParser::RoutCyclic';
use aliased 'Packages::Routing::RoutLayer::RoutParser::RoutParser';
use aliased 'Packages::Routing::RoutLayer::RoutStart::RoutStart';
use aliased 'Packages::Routing::RoutOutline' => "Outline";
use aliased 'Packages::Routing::RoutLayer::RoutStart::RoutStartAdjust';
use aliased 'CamHelpers::CamMatrix';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

my $inCAM    = InCAM->new();
my $jobId    = "d293788";
my $stepName = "o+1";
my $messMngr = MessageMngr->new($jobId);

my ( $indexFeat, $xdim, $ydim );

my $deleteOriginal = 1;
my $oriLayer       = 'foutline_ori_' . $jobId;

my $workLayer = "f";              # layer where rout is original rout
my $pomLayer  = 'f_' . $jobId;    # layer where is created new rout / help layer

# Check if final rout is selected
my $f = Features->new();
$f->Parse( $inCAM, $jobId, $stepName, $workLayer, 0, 1 );
my @chainFeatures = $f->GetFeatures();

__DoChain();

#-------------------------------------------------------------------------------------------#
# Helper function
#-------------------------------------------------------------------------------------------#

sub __DoChain {

	__DeletePomLayers();

	my %errors = ( "errors" => undef, "warrings" => undef );

	my @drillHoles = ();

	my ( $x1POLY, $y1POLY ) = ( -1, -1 );

	# 1) Select whole chain

	my $f = Features->new();
	$f->Parse( $inCAM, $jobId, $stepName, $workLayer, 0, 0 );
	my @chainFeatures = $f->GetFeatures();

	$inCAM->COM(
				 'sel_polyline_feat',
				 operation => 'select',
				 x         => $chainFeatures[0]{"x2"},
				 y         => $chainFeatures[0]{"y2"},
				 tol       => 10.00
	);

	# 2) copz them to helper layer
	$inCAM->COM(
		'sel_copy_other',
		target_layer => $pomLayer,
		invert       => "no",
		dx           => 0,
		dy           => 0,
		"size"       => 0,
		"x_anchor"   => 0,
		"y_anchor"   => 0,
		"rotation"   => 0,

	);

	CamLayer->SetLayerTypeLayer( $inCAM, $jobId, $pomLayer, "rout" );
	CamLayer->WorkLayer( $inCAM, $pomLayer );

	# Create backup of original layer
	$inCAM->COM(
				 'sel_copy_other',
				 target_layer => $oriLayer,
				 invert       => "no",
				 dx           => 0,
				 dy           => 0,
				 "size"       => 0,
				 "x_anchor"   => 0,
				 "y_anchor"   => 0,
				 "rotation"   => 0,
	);

	$inCAM->COM(
				 'sel_design2rout',
				 det_tol => '25.4',
				 con_tol => '25.4',
				 rad_tol => '52'
	);

	my $fWork = Features->new();
	$fWork->Parse( $inCAM, $jobId, $stepName, $pomLayer, 0 );

	my $changes  = 0;
	my @features = $fWork->GetFeatures();    #get all edges of final routing

	# Add geometric attributes
	foreach my $f (@features) {
		RoutParser->AddGeometricAtt($f);
	}

	#some arcs may do problems, when they are too thin ( around 25um, sometimes around 100um)
	#desgin to rout works properly when route thick is 200um, thus reshape to 200um and design to rout
	#once again

	my %sortResult = RoutCyclic->GetSortedRout( \@features, \$changes, \%errors );

	TestOpenRout( $sortResult{"result"}, $sortResult{"openPoint"} );

	my @sorteEdges = @{ $sortResult{"edges"} };

	my $defRoutDir = Outline->GetDefRoutDirection($jobId);

	RoutCyclic->SetRoutDirection( \@sorteEdges, $defRoutDir );

	#	TestNarrowPlaces( \@sorteEdges );
	#
	#	my %radiusResult = TestSmallRadius( \@sorteEdges );

	my %radiusResult = ();

	my %footResult = FindRoutStart( \@sorteEdges );

	DrawNewRout( \@sorteEdges, \%radiusResult, \%footResult );
 

	# Show information message

	my @m = ();

	#	if ( $radiusResult{"radiusRepaired"} ) {
	#		push( @m, "V obrysové fréze byly eliminovány některé arky. Zkontroluj to." );
	#	}

	if ( $radiusResult{"newDrillHole"} ) {
		push( @m, "Do obrysové frézy byly přidány otvory, které nahradily některé arky. Zkontrolu správnost." );
	}

	unless ( $footResult{"result"} ) {
		push( @m, "Nebyl nalezen vhodný počátek frézy. Počátek byl nastaven náhodně. Zkontroluj to." );
	}

	if ( scalar(@m) ) {
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@m );
	}

}

sub DrawNewRout {
	my @sorteEdges   = @{ shift(@_) };
	my $radiusResult = shift;
	my $footResult   = shift;

	$inCAM->COM('sel_delete');
	$inCAM->COM('sel_clear_feat');

	my $draw = RoutDrawing->new( $inCAM, $jobId, $stepName, $pomLayer );

	my $startEdge = undef;

	if ( $footResult->{"result"} ) {
		$startEdge = $footResult->{"edge"};

	}
	else {
		#take arbitrary
		$startEdge = $sorteEdges[0];
	}

	# 1) Draw new rout
	$draw->DrawRoute( \@sorteEdges, 2000, EnumsRout->Comp_LEFT, $startEdge );    # draw new

	# 2) Add new rout hole
	if ( $radiusResult->{"newDrillHole"} ) {
		foreach my $h ( @{ $radiusResult->{"newDrillHoleVal"} } ) {

			my %hole = %{$h};

			$inCAM->COM(
						 'add_pad',
						 attributes => 'no',
						 x          => $hole{"x"},
						 y          => $hole{"y"},
						 symbol     => 'r' . $hole{"tool"}
			);
		}

	}
	$inCAM->COM(
		'sel_move_other',
		target_layer => $workLayer,
		invert       => "no",
		dx           => 0,
		dy           => 0,
		"size"       => 0,
		"x_anchor"   => 0,
		"y_anchor"   => 0,
		"rotation"   => 0,

	);

	$inCAM->COM(
				 "display_layer",
				 name    => $workLayer,
				 display => "yes",
				 number  => 1
	);
	$inCAM->COM( "work_layer",   name  => $workLayer );
	$inCAM->COM( 'delete_layer', layer => $pomLayer );
	$inCAM->COM(
				 'chain_change_num',
				 layer                 => $workLayer,
				 chain                 => "1",
				 new_chain             => "1",
				 renumber_sequentially => "yes"
	);

	__DeletePomLayers();

	#let ori layer showed
	if ( !$deleteOriginal ) {
		$inCAM->COM(
					 "display_layer",
					 name    => $oriLayer,
					 display => "yes",
					 number  => 1
		);

		$inCAM->COM(
					 "display_layer",
					 name    => $workLayer,
					 display => "yes",
					 number  => 2
		);

		$inCAM->COM( "work_layer",    name    => $workLayer );
		$inCAM->COM( "display_width", mode    => 'outline' );
		$inCAM->COM( "display_chain", display => 'no' );
	}

}

# Show error message, and draw open point
sub TestOpenRout {
	my $resultSorting = shift;
	my $point         = shift;

	unless ($resultSorting) {

		my @m = ("Obrysová fréza je otevřená. Obrys musí být cyklický, oprav to.");
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@m );

		my $lName = 'open_route_' . $jobId;

		$inCAM->COM( 'create_layer', "layer" => $lName, "context" => 'misc', "type" => 'document', "polarity" => 'positive', "ins_layer" => '' );

		$inCAM->COM(
					 "display_layer",
					 name    => $lName,
					 display => "yes",
					 number  => 2
		);
		$inCAM->COM( "work_layer", name => $lName );

		$inCAM->COM(
					 'add_pad',
					 attributes => 'no',
					 x          => $point->{"x"},
					 y          => $point->{"y"},
					 symbol     => 'r5000'
		);
		$inCAM->COM(
					 "display_layer",
					 name    => $pomLayer,
					 display => "yes",
					 number  => 3
		);
		$inCAM->COM( "work_layer", name => $pomLayer );

		__UndoRoute( $workLayer, $pomLayer );
		exit;
	}

}

# Show error message, and draw open point
sub TestNarrowPlaces {
	my @sorteEdges = @{ shift(@_) };

	# Check narror places

	my %resultNP = RoutOutline->CheckNarrowPlaces( \@sorteEdges );

	unless ( $resultNP{"result"} ) {

		my @m = ("Obrysová fréza obsahuje příliš úzká místa pro nástroj obrysové frézy 2mm. Zpracuj frézu ručně.");
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@m );

		my $lName = 'narrow_places_' . $jobId;
		$inCAM->COM( 'create_layer', "layer" => $lName, "context" => 'misc', "type" => 'document', "polarity" => 'positive', "ins_layer" => '' );

		$inCAM->COM(
					 "display_layer",
					 name    => $lName,
					 display => "yes",
					 number  => 2
		);
		$inCAM->COM( "work_layer", name => $lName );

		my $draw = SymbolDrawing->new( $inCAM, $jobId );

		foreach my $line ( @{ $resultNP{"places"} } ) {

			my $p1 = @{$line}[0];
			my $p2 = @{$line}[1];

			my $pLine = PrimitiveLine->new( Point->new( $p1->[0], $p1->[1] ), Point->new( $p2->[0], $p2->[1] ), "r400" );
			$draw->AddPrimitive($pLine);

			# Add length of line

			my $pText = ( $p1->[0] > $p2->[0] ) ? Point->new( $p1->[0], $p1->[1] ) : Point->new( $p2->[0], $p2->[1] );
			$pText->Move( 2, 0 );

			my $len = sprintf( "%.1f", sqrt( ( $p1->[0] - $p2->[0] )**2 + ( $p1->[1] - $p2->[1] )**2 ) );

			$draw->AddPrimitive( PrimitiveText->new( $len . "mm", $pText, 2, undef, 1 ) );

		}

		$draw->Draw();

		$inCAM->COM(
					 "display_layer",
					 name    => $pomLayer,
					 display => "yes",
					 number  => 3
		);
		$inCAM->COM( "work_layer", name => $pomLayer );

		__UndoRoute( $workLayer, $pomLayer );

		exit(0);
	}

}

# Test on small radiuses
# Return result of reparation of small radiuses
sub TestSmallRadius {
	my $sorteEdges = shift;

	# Check small radiuses

	my %result = ( "radiusRepaired" => 0 );

	# if small radiuses, repair it
	unless ( RoutOutline->CheckSmallRadius($sorteEdges) ) {

		my @btns = ( "Ano opravit + kontrola", "Ano opravit", "Neopravovat" );
		my @m = ("V obrysové fréze jsou arky s rádiusem menším jak 2mm. Chceš tyto arky eliminovat?");
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@m, \@btns );

		my $messRes = $messMngr->Result();

		if ( $messRes == 0 || $messRes == 1 ) {

			my %resultRepair = RoutRadiusHelper->RemoveRadiuses($sorteEdges);

			# 1) Test on bounded arcs
			if ( $resultRepair{"boundArc"} ) {

				@m = ("V obrysové fréze jsou arky, které neumím ellimenivat (ark spojený/vytvořený z více arků)");
				$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@m );

				my $lName = 'bounded_arcs_' . $jobId;
				$inCAM->COM(
							 'create_layer',
							 "layer"     => $lName,
							 "context"   => 'misc',
							 "type"      => 'document',
							 "polarity"  => 'positive',
							 "ins_layer" => ''
				);

				$inCAM->COM(
							 "display_layer",
							 name    => $lName,
							 display => "yes",
							 number  => 2
				);
				$inCAM->COM( "work_layer", name => $lName );

				$inCAM->COM(
							 'add_pad',
							 attributes => 'no',
							 x          => $resultRepair{"boundArcVal"}->{"x"},
							 y          => $resultRepair{"boundArcVal"}->{"y"},
							 symbol     => 's5000'
				);
				$inCAM->COM(
							 "display_layer",
							 name    => $pomLayer,
							 display => "yes",
							 number  => 3
				);
				$inCAM->COM( "work_layer", name => $pomLayer );

				__UndoRoute( $workLayer, $pomLayer );
				exit;
			}

			if ( $messRes == 0 ) {

				$deleteOriginal = 0;

			}

			# complete return hash
			$result{"radiusRepaired"}  = 1;
			$result{"boundArc"}        = $resultRepair{"boundArc"};
			$result{"boundArcVal"}     = $resultRepair{"boundArcVal"};
			$result{"newDrillHole"}    = $resultRepair{"newDrillHole"};
			$result{"newDrillHoleVal"} = $resultRepair{"newDrillHoleVal"};

		}
		else {
			__UndoRoute( $workLayer, $pomLayer );
			exit;
		}

	}

	return %result;
}

sub FindRoutStart {
	my $sorteEdges = shift;

	my %startResult = ();

	my $defRoutComp  = Outline->GetDefRoutComp($jobId);
	my $defRoutStart = Outline->GetDefRoutStart($jobId);

	my $defRoutDir = Outline->GetDefRoutDirection($jobId);

	# Try to find rout start for followinf PCB rotation in panel
	my @PCBrotation = ( 0, 270 );
	if ( $defRoutDir eq EnumsRout->Dir_CCW && $defRoutComp eq EnumsRout->Comp_RIGHT ) {
		@PCBrotation = ( 0, 90, 180, 270 );
	}

	foreach my $angle (@PCBrotation) {

		# 1) Transform outline to default position in order to find rout start
		my $routAdjust = RoutStartAdjust->new($sorteEdges);

		$routAdjust->Transform( RoutStartAdjust->GetCorner2Transform( $defRoutStart, $defRoutDir, $angle ) );

		# 2) Check if rout need modify in order find rout start
		my %modify = RoutStart->RoutNeedModify($sorteEdges);
		if ( $modify{"result"} ) {

			RoutStart->ProcessModify( \%modify, $sorteEdges );
		}

		# 3) Try to get rout start edge
		my %startResAngle = RoutStart->GetRoutStart($sorteEdges);
		$startResult{$angle} = \%startResAngle;

		# 4) Transform outline rout back to original shape
		$routAdjust->TransformBack();

		#		CamMatrix->DeleteLayer( $inCAM, $jobId, "adjust${angle}" );
		#		CamMatrix->CreateLayer( $inCAM, $jobId, "adjust${angle}", "rout", "positive", 0 );
		#		my $draw = RoutDrawing->new( $inCAM, $jobId, $stepName, "adjust${angle}" );
		#
		#		my $startEdge = $sorteEdges->[0];

		#			if ( $startResAngle{"result"} ) {
		#				$startEdge = $startResAngle{"edge"};
		#
		#			}
		#			else {
		#				#take arbitrary
		#				$startEdge = $sorteEdges->[0];
		#			}

		#		# 1) Draw new rout
		#		$draw->DrawRoute( $sorteEdges, 2000, $defRoutComp, $startEdge );    # draw new
		#
		#
		#
		#		CamMatrix->DeleteLayer( $inCAM, $jobId, "adjust${angle}back" );
		#		CamMatrix->CreateLayer( $inCAM, $jobId, "adjust${angle}back", "rout", "positive", 0 );
		#		my $drawBakc = RoutDrawing->new( $inCAM, $jobId, $stepName, "adjust${angle}back" );
		#		$drawBakc->DrawRoute( $sorteEdges, 2000, $defRoutComp, $startEdge );    # draw new
	}

	return %startResult;

}

#return route outline back
sub __UndoRoute {

	my $workLayer = shift;
	my $pomLayer  = shift;

	$inCAM->COM(
				 "display_layer",
				 name    => $oriLayer,
				 display => "yes",
				 number  => 1
	);
	$inCAM->COM( "work_layer", name => $oriLayer );

	$inCAM->COM(
		'sel_move_other',
		target_layer => $workLayer,
		invert       => "no",
		dx           => 0,
		dy           => 0,
		"size"       => 0,
		"x_anchor"   => 0,
		"y_anchor"   => 0,
		"rotation"   => 0,

	);

	$inCAM->COM( 'delete_layer', layer => $pomLayer );
	$inCAM->COM( 'delete_layer', layer => $oriLayer );

	$inCAM->COM(
				 "display_layer",
				 name    => $workLayer,
				 display => "yes",
				 number  => 1
	);
	$inCAM->COM( "work_layer", name => $workLayer );
}

#Detecting of thin route outline
sub CheckRouteThick {
	my $self       = shift;
	my @sorteEdges = @{ shift(@_) };
	my $errors     = shift;

	if ( scalar(@sorteEdges) > 0 ) {

		if ( grep { $_->{"thick"} < 10 } @sorteEdges ) {
			GeneralHelper->AddError( $errors, FinalRout::EnumsMess->TOOTHINROUTE );
		}
	}
}

# delte helper layers
sub __DeletePomLayers {

	my @names = CamJob->GetAllLayers( $inCAM, $jobId );

	foreach my $l (@names) {

		if (    $l->{"gROWname"} =~ m/open_route/
			 || $l->{"gROWname"} =~ m/narrow_places/
			 || $l->{"gROWname"} =~ m/bounded_arcs_/
			 || ( $l->{"gROWname"} =~ m/foutline_ori_/ && $deleteOriginal ) )
		{

			$inCAM->COM( 'delete_layer', layer => $l->{"gROWname"} );

		}

	}

}

