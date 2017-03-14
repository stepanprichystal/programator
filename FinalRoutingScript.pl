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
use aliased 'Packages::InCAM::InCAM';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Routing::RoutLayer::RoutOutline::RoutOutline';
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveLine';
use aliased 'Packages::CAM::SymbolDrawing::Point';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

my $inCAM    = InCAM->new();
my $jobId    = "$ENV{JOB}";
my $stepName = "$ENV{STEP}";
my $messMngr = MessageMngr->new($jobId);


my ( $indexFeat, $xdim, $ydim );

my $deleteOriginal = 1;
my $oriLayer       = 'f_original_' . $jobId;

# Get work layer
$inCAM->COM('get_work_layer');
my $workLayer = "$inCAM->{COMANS}";

# Check if final rout is selected
my $f = Features->new();
$f->Parse( $inCAM, $jobId, $stepName, $workLayer, 0, 1 );
my @chainFeatures = $f->GetFeatures();

if ( scalar(@chainFeatures) ) {

	# Test if rout thick is at least 200µm
	#some arcs may do problems, when they are too thin ( around 25um, sometimes around 100um)
	#desgin to rout works properly when route thick is 200um, thus reshape to 200um and design to rout
	#once again
	
	if($chainFeatures[0]->{"thick"} >= 200){
		
		__DoChain();
		
	}else{
		
		# errror
		my @m = ("Obrysov fréza je příliš tenká: ".$chainFeatures[0]->{"thick"}."µm. Minimální tloušťka musí být alespoň 200µm.");
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@m );  
		exit(0);  
	}

}
else {

	die "No rout features selected";
}
 
 
#-------------------------------------------------------------------------------------------#
# Helper function
#-------------------------------------------------------------------------------------------#
 

sub __DoChain {

	__DeletePomLayers();

	my %errors = ( "errors" => undef, "warrings" => undef );

	my $pomLayer = 'f_' . $jobId;

	my @drillHoles = ();

	my ( $x1POLY, $y1POLY ) = ( -1, -1 );

	# 1) Select whole chain

	my $f = Features->new();
	$f->Parse( $inCAM, $jobId, $stepName, $workLayer, 0, 1 );
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
		'sel_move_other',
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

	my $changes    = 0;
	my @features   = $fWork->GetFeatures();    #get all edges of final routing
	my @sorteEdges = ();

	 

	#some arcs may do problems, when they are too thin ( around 25um, sometimes around 100um)
	#desgin to rout works properly when route thick is 200um, thus reshape to 200um and design to rout
	#once again

	@sorteEdges = RouteChainHelper->SortEdges( \@features, \$changes, \%errors );

	if ( $errors{"errors"} ) {
		my @mess = ( $errors{"errors"}{"mess"} );
		new MessageForm( Enums::MessageType->ERROR, \@mess, undef );

		if ( FinalRout::EnumsMess->OPENROUT eq $errors{"errors"}{"mess"} ) {
			my $lName = 'open_route_' . $jobId;
			$inCAM->COM(
				'sel_copy_other',
				target_layer => $lName,
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
						 name    => $lName,
						 display => "yes",
						 number  => 2
			);
			$inCAM->COM( "work_layer", name => $lName );
			$inCAM->COM('sel_delete');
			$inCAM->COM(
						 'add_pad',
						 attributes => 'no',
						 x          => $errors{"errors"}{"val"}{"x"},
						 y          => $errors{"errors"}{"val"}{"y"},
						 symbol     => 'r5000'
			);
			$inCAM->COM(
						 "display_layer",
						 name    => $pomLayer,
						 display => "yes",
						 number  => 3
			);
			$inCAM->COM( "work_layer", name => $pomLayer );

			#$inCAM->COM("display_layer",name=>$lName, display=>"yes",number=>3);
		}

		__UndoRoute( $workLayer, $pomLayer );
		exit;
	}

	# Check narror places

	my %resultNP = RoutOutline->CheckNarrowPlaces( \@sorteEdges  );

	unless ( $resultNP{"result"} ) {
		
		my @m = ("Obrysová fréza obsahuje příliš úzká místa pro nástroj obrysové frézy 2mm. Zpracuj frézu ručně.");
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@m );  
		
		my $lName = 'narrow_places_' . $jobId;
		$inCAM->COM( 'create_layer', "layer" => $lName, "context" => 'misc', "type" => 'document', "polarity" => 'positive', "ins_layer" => '' );
 
		CamLayer->WorkLayer( $inCAM, $lName );

		my $draw = SymbolDrawing->new( $inCAM, $jobId );
 

		foreach my $line (@{$resultNP{"places"}}) {

			my $p1 = @{$line}[0];
			my $p2 = @{$line}[1];
			
			my $pLine = PrimitiveLine->new( Point->new( $p1->[0],  $p1->[1] ),  Point->new( $p2->[0],  $p2->[1] ), "r400");
			$draw->AddPrimitive($pLine);
		}

		$draw->Draw();
		
		CamLayer->WorkLayer($inCAM, $pomLayer);

		__UndoRoute( $workLayer, $pomLayer );
		
		exit(0);  
	}
	
	# Check small radiuses

	RouteChainHelper->CheckRadius( \@sorteEdges, \%errors );

	if ( $errors{"errors"} ) {

		my @btns = ( "Repair and check", "Repair radiuses", "Don't repair" );
		my @mess1 = ( $errors{"errors"}{"mess"}, "Do you want to repair these small radiuses?" );
		my $result = -1;

		new MessageForm( Enums::MessageType->INFORMATION, \@mess1, \@btns, \$result );

		if ( $result == 2 || $result == 3 ) {
			%errors = ( "errors" => undef, "warrings" => undef );

			@sorteEdges = RouteRadiusHelper->RemoveRadiuses( \@sorteEdges, \%errors );

			if ( $errors{"errors"}
				 && FinalRout::EnumsMess->BOUNDEDARCS eq $errors{"errors"}{"mess"} )
			{

				my @mess = ( $errors{"errors"}{"mess"} );
				new MessageForm( Enums::MessageType->ERROR, \@mess, undef );

				my $lName = 'bounded_arcs_' . $jobId;
				$inCAM->COM(
					'sel_copy_other',
					target_layer => $lName,
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
							 name    => $lName,
							 display => "yes",
							 number  => 2
				);
				$inCAM->COM( "work_layer", name => $lName );
				$inCAM->COM('sel_delete');
				$inCAM->COM(
							 'add_pad',
							 attributes => 'no',
							 x          => $errors{"errors"}{"val"}{"x"},
							 y          => $errors{"errors"}{"val"}{"y"},
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

			if ( $errors{"warnings"}
				 && FinalRout::EnumsMess->NEWDRILLHOLE eq $errors{"warnings"}{"mess"} )
			{
				@drillHoles = @{ $errors{"warnings"}{"val"} };

			}

			if ( $result == 3 ) {

				$deleteOriginal = 0;

			}
		}
		else {
			__UndoRoute( $workLayer, $pomLayer );
			exit;
		}

	}

	@sorteEdges = RouteChainHelper->CheckChanges( \@sorteEdges, \$changes );    #update edges, add new edge etc..

	$inCAM->COM('sel_delete');
	$inCAM->COM('sel_clear_feat');
	my $lastIdx = -1;

	#if ( $changes == 1 ) {

	#switch start and end point of edges
	for ( my $i = 0 ; $i < scalar(@sorteEdges) ; $i++ ) {

		#sleep(0.01);

		if ( $sorteEdges[$i]{"type"} eq "L" ) {

			$lastIdx = $inCAM->COM(
									'add_line',
									attributes => 'no',
									xs         => $sorteEdges[$i]{"x1"},
									ys         => $sorteEdges[$i]{"y1"},
									xe         => $sorteEdges[$i]{"x2"},
									ye         => $sorteEdges[$i]{"y2"},
									"symbol"   => "r200.123"
			);
		}
		elsif ( $sorteEdges[$i]{"type"} eq "A" ) {

			$lastIdx = $inCAM->COM(
				'add_arc',
				attributes  => 'no',
				xs          => $sorteEdges[$i]{"x1"},
				ys          => $sorteEdges[$i]{"y1"},
				xe          => $sorteEdges[$i]{"x2"},
				ye          => $sorteEdges[$i]{"y2"},
				xc          => $sorteEdges[$i]{"xmid"},
				yc          => $sorteEdges[$i]{"ymid"},
				"symbol"    => "r200.123",
				"direction" => $sorteEdges[$i]{"newDir"}

			);
		}
		$sorteEdges[$i]{"id"} = $lastIdx;
	}

	if ( scalar(@drillHoles) > 0 ) {
		foreach my $h (@drillHoles) {

			#sleep(0.01);
			my %hole = %{$h};

			#$inCAM->PAUSE('r'.$hole{"tool"});

			$inCAM->COM(
						 'add_pad',
						 attributes => 'no',
						 x          => $hole{"x"},
						 y          => $hole{"y"},
						 symbol     => 'r' . $hole{"tool"}
			);
		}

		my @mess = ( FinalRout::EnumsMess->NEWDRILLHOLE );
		new MessageForm( Enums::MessageType->INFORMATION, \@mess, undef );
	}

	#}

	my $startId = RouteChainHelper->SetPlunge( \@sorteEdges, \$changes, \%errors );    #find suitable start of chain

	if ( $errors{"errors"} ) {

		if ( FinalRout::EnumsMess->NOSTARTCHAINPOINT eq $errors{"errors"}{"mess"} ) {

			my @mess = ( $errors{"errors"}{"mess"} );
			my @btns = ( "Don't do rout", "Do rout" );
			my $res;

			new MessageForm( Enums::MessageType->ERROR, \@mess, \@btns, \$res );

			if ( $res == 2 ) {
				__UndoRoute( $workLayer, $pomLayer );
				exit;
			}

		}
	}

	$fFeatures = $inCAM->INFO(
							   'units'       => 'mm',
							   'entity_type' => 'layer',
							   'entity_path' => "$jobId/$stepName/" . $pomLayer,
							   'data_type'   => 'FEATURES',
							   'options'     => 'feat_index',
							   parse         => 'no'
	);

	my $id = 1;

	$inCAM->COM(
				 'sel_polyline_feat',
				 operation => 'select',
				 x         => $sorteEdges[0]{"x1"},
				 y         => $sorteEdges[0]{"y1"},
				 tol       => 1.00
	);

	#if start wasn't find but user wants do route, take first edge as start
	if ( $startId == -1 ) {
		$startId = $sorteEdges[0]{"id"};
	}

	$inCAM->COM(
				 'chain_add',
				 layer          => $pomLayer,
				 chain          => $id,
				 size           => 2,
				 comp           => "none",
				 flag           => 0,
				 feed           => 0,
				 speed          => 0,
				 first          => "$startId",
				 chng_direction => 0
	);

	$inCAM->COM('chain_list_reset');
	$inCAM->COM( 'chain_list_add', chain => $id );
	$inCAM->COM(
				 'chain_change',
				 layer => $pomLayer,
				 size  => 2,
				 comp  => "left",
				 flag  => 0,
				 feed  => 0,
				 speed => 0
	);

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

##delte helper layers
sub __DeletePomLayers {

	my @names = CamJob->GetAllLayers( $inCAM, $jobId );

	foreach my $l (@names) {
		if (    $l =~ m/open_route/
			 || $l =~ m/narrow_places/
			 || $l =~ m/bounded_arcs_/
			 || ( $l =~ m/f_original_/ && $deleteOriginal ) )
		{

			$inCAM->COM( 'delete_layer', layer => $l );

		}

	}

}

