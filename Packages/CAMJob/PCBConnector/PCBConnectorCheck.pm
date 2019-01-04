#-------------------------------------------------------------------------------------------#
# Description: GoldFingerChecks check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::PCBConnector::PCBConnectorCheck;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use Math::Polygon;
use List::Util qw[max min];

#local library
use aliased 'Packages::Polygon::Enums' => "PolyEnums";
use aliased 'Packages::Polygon::PolygonFeatures';
use aliased 'Packages::Polygon::Polygon::PolygonPoints';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamFilter';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::Polygon::Line::SegmentLineIntersection';
use aliased 'Packages::Polygon::Line::LineTransform';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAM::FeatureFilter::Enums' => "FilterEnums";
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAM::UniDTM::Enums' => 'DTMEnums';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Try to detect connector in specific side
# Connector fingers has to be pad and has to have "smd" attribute
sub ConnectorDetection {
	my $self           = shift;
	my $inCAM          = shift;
	my $jobId          = shift;
	my $step           = shift;
	my $layer          = shift;
	my $connectorEdges = shift // [];    # ref where all connector edges info for specified layer was stored

	my $MAXFINGERGAP      = shift // 10;     # max gap 10mm
	my $MAXFINGERPROFDIST = shift // 3.0;    # max finger dist from board edge 3.0mm

	my $result = 0;

	# Set step
	CamHelper->SetStep( $inCAM, $step );

	# 1) Pprepare potentional connector edges (from connector mill layer, board outline, etc,..)
	my @edgesOri = $self->__GetConnEdges( $inCAM, $jobId, $step, $layer );

	# move edges $MAXFINGERPROFDIST from profile direct to center of pcb
	my @edgesWork = $self->__GetConnWorkingEdges( \@edgesOri, $MAXFINGERPROFDIST );

	#	# DELETE -  Drawing boxes
	#	my $test = GeneralHelper->GetGUID();
	#	CamMatrix->CreateLayer( $inCAM, $jobId, $test, "document", "positive", 0 );
	#	CamLayer->WorkLayer( $inCAM, $test );
	#
	#	foreach my $edge (@edgesWork) {
	#
	#		CamSymbol->AddPolyline( $inCAM, $edge->{"box"}, "r500", "positive", 1 );
	#	}
	#
	#	sleep(2);
	#	CamMatrix->DeleteLayer( $inCAM, $jobId, $test );
	#
	#	# DELETE -  Drawing boxes

	@edgesWork = sort { $b->{"l"} <=> $a->{"l"} } @edgesWork;

	# 2) Prepare signal layer where could be connector

	my $workL = GeneralHelper->GetGUID();
	CamLayer->WorkLayer( $inCAM, $layer );
	CamLayer->CopySelOtherLayer( $inCAM, [$workL] );
	my $f = FeatureFilter->new( $inCAM, $jobId, $workL );
	$f->SetFeatureTypes( "pad" => 1, "line" => 1 );    # fingers has to be pad

	$f->AddIncludeAtt(".smd");                         # pads has to have attribute smd
	$f->AddIncludeAtt(".gold_plating");                # pads has to have attribute smd
	$f->SetIncludeAttrCond( FilterEnums->Logic_OR );
	$f->SetLineLength( 0.1, 10 );

	# SMD pads exist
	if ( $f->Select() ) {

		$inCAM->COM("sel_reverse");
		$inCAM->COM('get_select_count');
		if ( $inCAM->GetReply() > 0 ) {
			CamLayer->DeleteFeatures($inCAM);
		}

		$f->Reset();
		CamLayer->WorkLayer( $inCAM, $workL );
		CamLayer->Contourize( $inCAM, $workL );

		# parse potential fingers
		my $fConn = Features->new();
		$fConn->Parse( $inCAM, $jobId, $step, $workL );
		my @fingersFeat = $fConn->GetFeatures();

		my @fingers = ();
		foreach my $fFeat (@fingersFeat) {

			my %currFInf = $self->__GetFingerFeatInfo($fFeat);
			push( @fingers, \%currFInf );
		}

		# store to pad which profile edges go through it
		foreach my $e (@edgesWork) {

			my @box = map { [ $_->{"x"}, $_->{"y"} ] } @{ $e->{"box"} };

			foreach my $f (@fingers) {

				next
				  if (
					   !(
						     ( $f->{"dir"} eq "h" && $e->{"dir"} eq "v" )
						  || ( $f->{"dir"} eq "v" && $e->{"dir"} eq "h" )
						  || ( $f->{"dir"} eq "d" && $e->{"dir"} eq "d" )
					   )
				  );

				my $fAxisS = [ $f->{"axis"}->{"x1"}, $f->{"axis"}->{"y1"} ];
				my $fAxisE = [ $f->{"axis"}->{"x2"}, $f->{"axis"}->{"y2"} ];

				my $pos = PolygonPoints->GetPoly2SegmentLineIntersect( \@box, $fAxisS, $fAxisE );

				if ( $pos eq PolyEnums->Pos_INTERSECT || $pos eq PolyEnums->Pos_INSIDE ) {
					push( @{ $f->{"allEdges"} }, $e );
				}
			}
		}

		@fingers = grep { scalar( @{ $_->{"allEdges"} } ) > 0 } @fingers;
		return 0 unless (@fingers);

		# compute count of fingers for each edge
		foreach my $e (@edgesWork) {
			$e->{"fingerCnt"} = grep {
				grep { $_->{"id"} eq $e->{"id"} }
				  @{ $_->{"allEdges"} }
			} @fingers;
		}

		# select neearest edge. If finger more edges, choose edges which has more fingers
		foreach my $f (@fingers) {

			if ( scalar( @{ $f->{"allEdges"} } ) == 1 ) {
				$f->{"edge"} = $f->{"allEdges"}->[0];
			}
			else {

				$f->{"edge"} = ( sort { $b->{"fingerCnt"} <=> $a->{"fingerCnt"} } @{ $f->{"allEdges"} } )[0];
			}
		}

		# 3 )Detect connector finger groups (fingers which has same orientation and similar size)
		my @connectors = ();
		my %currFinger = ();

		while (1) {

			my @conn = ();

			# get lim of finger
			unless (%currFinger) {
				%currFinger = %{ shift(@fingers) };
				my %cp = %currFinger;
				push( @conn, \%cp );
			}

			for ( my $i = scalar(@fingers) - 1 ; $i >= 0 ; $i-- ) {

				my %fInf = %{ $fingers[$i] };

				# width and height has to be simmilar, max 1mm difference
				if (    $fInf{"dir"} eq $currFinger{"dir"}
					 && abs( $fInf{"w"} - $currFinger{"w"} ) < 1
					 && abs( $fInf{"h"} - $currFinger{"h"} ) < 1
					 && $fInf{"edge"}->{"id"} == $currFinger{"edge"}->{"id"} )
				{
					push( @conn, \%fInf );
					splice @fingers, $i, 1;
				}

			}

			push( @connectors, \@conn );
			%currFinger = ();

			last unless (@fingers);

		}

		# RULE 1: remove groups where are less than 3 fingers (smallest connector has 2 fingers)
		@connectors = grep { scalar( @{$_} ) >= 2 } @connectors;

		return 0 unless (@connectors);

		# RULE 2: check if fingers central axis is oriented 90degree to pcb edge direction
		for ( my $i = scalar(@connectors) - 1 ; $i >= 0 ; $i-- ) {

			my $frstFinger = $connectors[$i]->[0];    # test on first finger

			if (
				 !(
					   ( $frstFinger->{"dir"} eq "h" && $frstFinger->{"edge"}->{"dir"} eq "v" )
					|| ( $frstFinger->{"dir"} eq "v" && $frstFinger->{"edge"}->{"dir"} eq "h" )
					|| ( $frstFinger->{"dir"} eq "d" && $frstFinger->{"edge"}->{"dir"} eq "d" )
				 )
			  )
			{
				splice @connectors, $i, 1;
			}
		}

		# RULE 3: check if fingers are placed along more than 50% of connector edge width
		for ( my $i = scalar(@connectors) - 1 ; $i >= 0 ; $i-- ) {

			next if ( scalar(@connectors) < 5 );    # test only for connector bigger than

			my $frstFinger = $connectors[$i]->[0];  # test on first finger

			next if ( $frstFinger->{"edge"}->{"dir"} eq "d" );

			my $conEdgeLen = $frstFinger->{"edge"}->{"l"};
			my $fingerConLen;

			my $axis = $frstFinger->{"edge"}->{"dir"} eq "h" ? "x" : "y";

			$fingerConLen = abs( max( map { $_->{$axis} } @{ $connectors[$i] } ) - min( map { $_->{$axis} } @{ $connectors[$i] } ) );

			if ( $fingerConLen / $conEdgeLen < 0.5 ) {
				splice @connectors, $i, 1;
				next;
			}
		}

		# RULE 4: Check max gap between fingers. If bigger than maxFingerGap, remove group
		for ( my $i = scalar(@connectors) - 1 ; $i >= 0 ; $i-- ) {

			my $frstFinger = $connectors[$i]->[0];    # test on first finger

			next if ( $frstFinger->{"edge"}->{"dir"} eq "d" );

			my $axis = $frstFinger->{"edge"}->{"dir"} eq "h" ? "x" : "y";
			my @sorted = sort { $a->{$axis} <=> $b->{$axis} } @{ $connectors[$i] };

			my $gapOk = 1;
			for ( my $j = 0 ; $j < scalar(@sorted) - 1 ; $j++ ) {

				if ( ( $sorted[ $j + 1 ]->{$axis} - $sorted[$j]->{$axis} ) > $MAXFINGERGAP ) {

					$gapOk = 0;
					next;
				}
			}

			splice @connectors, $i, 1 unless ($gapOk);
		}

		# If some connector edges suits all rules, build info about each connector edge
		if (@connectors) {
			$result = 1;

			# build result data

			foreach my $conn (@connectors) {

				my $edge = $conn->[0]->{"edge"};

				my %conInf = ();
				$conInf{"dir"}    = $edge->{"dir"};
				$conInf{"length"} = $edge->{"l"};
				$conInf{"x1"}     = $edge->{"ori"}->{"x1"};
				$conInf{"y1"}     = $edge->{"ori"}->{"y1"};
				$conInf{"x2"}     = $edge->{"ori"}->{"x2"};
				$conInf{"y2"}     = $edge->{"ori"}->{"y2"};

				$conInf{"fingerFeats"} = $conn;

				push( @{$connectorEdges}, \%conInf );

			}
		}
		else {
			return 0;
		}

	}

	CamMatrix->DeleteLayer( $inCAM, $jobId, $workL );

	return $result;
}

sub __GetConnEdges {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;

	my $fEdgeOri = Features->new();
	my @edgesOri = ();

	# decide which source of edges we use

	# Take FK if exist
	my @fkLayers = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_kMill ] );

	if (@fkLayers) {

		foreach my $l (@fkLayers) {

			$fEdgeOri->Parse( $inCAM, $jobId, $step, $l->{"gROWname"} );

			my @fb = grep { $_->{"type"} eq "L" } $fEdgeOri->GetFeatures();
			$_->{"fingerSide"} = "both" foreach (@fb);
			push( @edgesOri, @fb );
		}
	}

	# Take lines from board profile
	if ( !@edgesOri ) {

		my $profileL = GeneralHelper->GetGUID();
		CamStep->ProfileToLayer( $inCAM, $step, $profileL, 1 );
		CamLayer->WorkLayer( $inCAM, $profileL );

		my $fEdgeOri = Features->new();
		$fEdgeOri->Parse( $inCAM, $jobId, $step, $profileL );

		my @fL = grep { $_->{"type"} eq "L" } $fEdgeOri->GetFeatures();
		$_->{"fingerSide"} = "right" foreach (@fL);
		push( @edgesOri, @fL );

		CamMatrix->DeleteLayer( $inCAM, $jobId, $profileL );
	}

	# if not fk exist, add lines from depth milling
	if ( !@fkLayers ) {

		my @fzLayers = CamDrilling->GetNCLayersByTypes(
														$inCAM, $jobId,
														[
														   ( $layer eq "c" )
														   ? EnumsGeneral->LAYERTYPE_nplt_bMillTop
														   : EnumsGeneral->LAYERTYPE_nplt_bMillBot
														]
		);

		foreach my $l (@fzLayers) {

			my $unitDTM = UniDTM->new( $inCAM, $jobId, $step, $l->{"gROWname"} );

			my @tools = $unitDTM->GetUniqueTools();

			next unless ( grep { $_->GetSpecial() && $_->GetAngle() > 0 } @tools );

			$fEdgeOri->Parse( $inCAM, $jobId, $step, $l->{"gROWname"} );

			my @fb = grep { $_->{"type"} eq "L" } $fEdgeOri->GetFeatures();
			$_->{"fingerSide"} = "both" foreach (@fb);
			push( @edgesOri, @fb );

		}
	}

	return @edgesOri;

}

sub __GetConnWorkingEdges {
	my $self              = shift;
	my @edgesOri          = @{ shift(@_) };
	my $MAXFINGERPROFDIST = shift;

	my @edgesWork = ();

	foreach my $edge ( grep { $_->{"type"} eq "L" } @edgesOri ) {

		if ( $edge->{"fingerSide"} eq "right" ) {

			push( @edgesWork, $self->__GetConnWorkingEdge( $edge, $MAXFINGERPROFDIST, "right" ) );
		}
		elsif ( $edge->{"fingerSide"} eq "both" ) {

			push( @edgesWork, $self->__GetConnWorkingEdge( $edge, $MAXFINGERPROFDIST, "left" ) );
			push( @edgesWork, $self->__GetConnWorkingEdge( $edge, $MAXFINGERPROFDIST, "right" ) );
		}
	}

	return @edgesWork;
}

sub __GetConnWorkingEdge {
	my $self              = shift;
	my $edge              = shift;
	my $MAXFINGERPROFDIST = shift;
	my $fingerSide        = shift;

	my @line = LineTransform->ParallelSegmentLine( { "x" => $edge->{"x1"}, "y" => $edge->{"y1"} },
												   { "x" => $edge->{"x2"}, "y" => $edge->{"y2"} },
												   $MAXFINGERPROFDIST, $fingerSide );

	# build  "rectangle box" from 4 points - area where connector could be pottentionally placed
	my @box = ();
	push( @box, { "x" => $edge->{"x1"},   "y" => $edge->{"y1"} } );
	push( @box, { "x" => $line[0]->{"x"}, "y" => $line[0]->{"y"} } );
	push( @box, { "x" => $line[1]->{"x"}, "y" => $line[1]->{"y"} } );
	push( @box, { "x" => $edge->{"x2"},   "y" => $edge->{"y2"} } );

	my %edgeInf = ();
	$edgeInf{"id"}  = $edge->{"id"};
	$edgeInf{"box"} = \@box;

	$edgeInf{"ori"} = $edge;                                                                                # store original profile edge
	$edgeInf{"l"} = sqrt( ( $edge->{"x1"} - $edge->{"x2"} )**2 + ( $edge->{"y2"} - $edge->{"y1"} )**2 );    # original edge length

	my $x = abs( $edge->{"x1"} - $edge->{"x2"} );
	my $y = abs( $edge->{"y1"} - $edge->{"y2"} );

	# Orientation v: vertical, h: horizontal, d: not vertical and not horizontal
	# if boundarz box is not rectangle, but rather square, assume line is not strictly horizontal or verticall
	if ( $x > 0 && $y > 0 && ( abs( $x - $y ) / $x < 0.3 || abs( $y - $x ) / $y < 0.3 ) ) {
		$edgeInf{"dir"} = "d";
	}
	elsif ( abs( $edge->{"x1"} - $edge->{"x2"} ) < abs( $edge->{"y1"} - $edge->{"y2"} ) ) {
		$edgeInf{"dir"} = "v";
	}
	else {
		$edgeInf{"dir"} = "h";
	}

	return \%edgeInf;
}

# Parse finger feat
sub __GetFingerFeatInfo {
	my $self = shift;
	my $feat = shift;

	my %inf          = ();
	my $envelop      = ( PolygonFeatures->GetSurfaceEnvelops( $feat, 0.1 ) )[0];
	my @envelopPoint = map { [ $_->{"x"}, $_->{"y"} ] } @{$envelop};
	my @box          = PolygonPoints->GetPolygonLim( \@envelopPoint );

	$inf{"x"} = ( $box[2] + $box[0] ) / 2;
	$inf{"y"} = ( $box[3] + $box[1] ) / 2;

	$inf{"w"}   = abs( $box[0] - $box[2] );
	$inf{"h"}   = abs( $box[1] - $box[3] );
	$inf{"dir"} = $inf{"w"} > $inf{"h"} ? "h" : "v";

	# if boundarz box is not rectangle, but rather square, assume finger is rotated
	if ( abs( $inf{"h"} - $inf{"w"} ) / $inf{"h"} < 0.3 || abs( $inf{"w"} - $inf{"h"} ) / $inf{"w"} < 0.3 ) {

		$inf{"dir"} = "d";
	}

	$inf{"id"} = $feat->{"id"};

	# define center axis (line which go through finger in center and is paralel with longer side of finger)
	$inf{"axis"} = ();
	if ( $inf{"dir"} eq "v" ) {

		$inf{"axis"}->{"x1"} = $inf{"x"};
		$inf{"axis"}->{"y1"} = $inf{"y"} - $inf{"h"} / 2;
		$inf{"axis"}->{"x2"} = $inf{"x"};
		$inf{"axis"}->{"y2"} = $inf{"y"} + $inf{"h"} / 2;
	}
	else {

		$inf{"axis"}->{"x1"} = $inf{"x"} - $inf{"w"} / 2;
		$inf{"axis"}->{"y1"} = $inf{"y"};
		$inf{"axis"}->{"x2"} = $inf{"x"} + $inf{"w"} / 2;
		$inf{"axis"}->{"y2"} = $inf{"y"};
	}

	$inf{"allEdges"} = [];    # all edges which finger is near

	return %inf;
}

# Draw connector edge and finger axis
sub DrawConnectorResult {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $edges = shift;
	my $l     = shift // "connector_edges";

	unless ( CamHelper->LayerExists( $inCAM, $jobId, $l ) ) {
		CamMatrix->CreateLayer( $inCAM, $jobId, $l, "document", "positive", 0 );
	}

	CamLayer->WorkLayer( $inCAM, $l );
	CamLayer->DeleteFeatures($inCAM);

	foreach my $edge ( @{$edges} ) {

		CamSymbol->AddLine( $inCAM, { "x" => $edge->{"x1"}, "y" => $edge->{"y1"} }, { "x" => $edge->{"x2"}, "y" => $edge->{"y2"} }, "r500" );

		foreach my $finger ( map { $_->{"axis"} } @{ $edge->{"fingerFeats"} } ) {

			CamSymbol->AddLine( $inCAM,
								{ "x" => $finger->{"x1"}, "y" => $finger->{"y1"} },
								{ "x" => $finger->{"x2"}, "y" => $finger->{"y2"} }, "r200" );
		}

	}

}

# Look to depth milling layers (top and bot) and search slot tool with angles. If same angel from both sides,
# it is probably tool for chamfering edge
sub ConnectorToolDetection {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $finAngle = shift;    # if tool si found, sotore tool angle

	my $result = 0;

	# if exist fz layers, get angle from fzc + fzs

	my @fzLayers =
	  CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_bMillTop, EnumsGeneral->LAYERTYPE_nplt_bMillBot ] );

	my @angles = ();

	foreach my $l (@fzLayers) {

		my $unitDTM = UniDTM->new( $inCAM, $jobId, $step, $l->{"gROWname"} );

		my @tools = grep { $_->GetTypeProcess() eq DTMEnums->TypeProc_CHAIN } $unitDTM->GetUniqueTools();

		my @a = uniq( map { $_->GetAngle() } grep { $_->GetSpecial() && $_->GetAngle() > 0 } @tools );

		push( @angles, @a ) if ( scalar(@a) );
	}

	my %h;
	$h{$_}++ foreach (@angles);

	foreach my $angle ( keys %h ) {

		# if two same angle (same from top and bot) it is probably tool for chamfering connector
		if ( $h{$angle} == 2 ) {
			$$finAngle = $angle;
			$result    = 1;
			last;
		}
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::PCBConnector::PCBConnectorCheck';
	use Data::Dump qw(dump);
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d228881";
	my $layer = "c";
	my $mess  = "";

	#	my @edges = ();
	#	my $result = PCBConnectorCheck->ConnectorDetection( $inCAM, $jobId, "o+1", $layer, \@edges );
	#
	#	print STDERR "Result is $result, number of edfes:" . scalar(@edges) . " \n";
	#
	#	if ($result) {
	#
	#		PCBConnectorCheck->DrawConnectorResult( $inCAM, $jobId, \@edges );
	#	}

	my $tool = 1;

	my $res = PCBConnectorCheck->ConnectorToolDetection( $inCAM, $jobId, "o+1", \$tool );

	print "Result = $res, tool = $tool\n";

}

1;
