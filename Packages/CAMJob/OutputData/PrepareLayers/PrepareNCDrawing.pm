#-------------------------------------------------------------------------------------------#
# Description: Responsible for prepare layers which contains tool depth drawing
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::PrepareLayers::PrepareNCDrawing;

#3th party library
use strict;
use warnings;
use List::Util qw[max min];
use List::MoreUtils qw(uniq);
use Math::Trig;
use Math::Geometry::Planar;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::OutputData::Enums';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAMJob::OutputData::LayerData::LayerData';
use aliased 'Helpers::ValueConvertor';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamDTM';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAM::UniDTM::UniRTM';
use aliased 'Packages::CAM::UniDTM::Enums' => "DTMEnums";
use aliased 'Packages::CAM::UniRTM::Enums' => "RTMEnums";
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAMJob::OutputData::Drawing::Drawing';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Enums::EnumsDrill';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamSymbol';
use aliased 'Packages::Tooling::CountersinkHelper';
use aliased 'CamHelpers::CamSymbolArc';

#use aliased 'Packages::SystemCall::SystemCall';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}     = shift;
	$self->{"jobId"}     = shift;
	$self->{"step"}      = shift;
	$self->{"layerList"} = shift;

	$self->{"profileLim"} = shift;    # limits of pdf step

	$self->{"platingThick"} = 0.05;   # plating constant is 50µm thick of Cu

	$self->{"pcbThick"} = JobHelper->GetFinalPcbThick( $self->{"jobId"} ) / 1000;    # in mm

	return $self;
}

sub Prepare {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	@layers = grep {
		     $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillBot
	} @layers;

	foreach my $l (@layers) {

		# load UniDTM for layer
		$l->{"uniDTM"} = UniDTM->new( $inCAM, $jobId, $step, $l->{"gROWname"}, 1 );

		# check if depths are ok
		my $mess = "";
		unless ( $l->{"uniDTM"}->GetChecks()->CheckToolDepthSet( \$mess ) ) {
			die $mess;
		}

		$l->{"uniRTM"} = UniRTM->new( $inCAM, $jobId, $step, $l->{"gROWname"}, 1, $l->{"uniDTM"} );

		$self->__ProcessNClayer( $l, $type );

	}

}

# MEthod do necessary stuff for each layer by type
# like resizing, copying, change polarity, merging, ...
sub __ProcessNClayer {
	my $self = shift;
	my $l    = shift;
	my $type = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my @allTools = $l->{"uniDTM"}->GetTools();

	my $enTit = ValueConvertor->GetJobLayerTitle($l);
	my $czTit = ValueConvertor->GetJobLayerTitle( $l, 1 );
	my $enInf = ValueConvertor->GetJobLayerInfo($l);
	my $czInf = ValueConvertor->GetJobLayerInfo( $l, 1 );

	my $drawingPos = Point->new( 0, abs( $self->{"profileLim"}->{"yMax"} - $self->{"profileLim"}->{"yMin"} ) + 50 );    # starts 150

	#my %lines_arcs = %{ $l->{"symHist"}->{"lines_arcs"} };
	#my %pads       = %{ $l->{"symHist"}->{"pads"} };

	# Get if NC operation is from top/bot
	my $side = $l->{"gROWname"} =~ /c/ ? "top" : "bot";

	# ================================
	# 1) Process countersink Surfaces

	#	# get all diameter of surface countersink
	#
	#	my @chainSeq = $l->{"uniRTM"}->GetCircleChainSeq( RTMEnums->FeatType_SURF );
	#
	#	# only special tools with angle
	#	@chainSeq =
	#	  grep { $_->GetChain()->GetChainTool()->GetUniDTMTool()->GetSpecial() && $_->GetChain()->GetChainTool()->GetUniDTMTool()->GetAngle() > 0 }
	#	  @chainSeq;
	#
	#	my @radiuses = ();
	#
	#	for ( my $i = 0 ; < scalar(@chainSeq) ; $i++ ) {
	#
	#		my $r = @chainSeq->[$i]->{"radius"};
	#
	#		unless ( grep { ( $_ - 0.01 ) < $r && ( $_ + 0.01 ) > $r } @radiuses ) {
	#			push( @radiuses, $r );
	#		}
	#	}
	#
	#	my @angles = uniq( map { $_->GetChain()->GetChainTool()->GetUniDTMTool()->GetAngle() } @chainSeq );
	#
	#	foreach my $r (@radiuses) {
	#
	#		# get all chain seq by radius
	#		my @rChainSeq = grep { ( $_->{"radius"} - 0.01 ) < $r && ( $_->{"radius"} + 0.01 ) > $r } @chainSeq;
	#
	#		# get all possible angles for this radius
	#		my @angles = ();
	#
	#		# get id of all features in chain
	#		my @featsId = map { $_->{'id'} } map { $_->GetOriFeatures() } @rChainSeq;
	#
	#	}
	#
	#	# ================================
	#	# 1) Process countersink arcs
	#
	#	# get all diameter of arcs countersink
	#
	#	my @chainSeq = grep { $_->GetFeatureType eq RTMEnums->FeatType_LINEARC } $l->{"uniRTM"}->GetChainSequences();
	#
	#	my @lines_arcs = grep { $_->GetTypeProcess() eq DTMEnums->TypeProc_CHAIN && $_->GetSource() eq DTMEnums->Source_DTM } @allTools;
	#
	#	foreach my $t (@lines_arcs) {
	#
	#		my $depth = $t->GetDepth();
	#		my $lName = $self->__SeparateSymbol( $l, $t );
	#
	#		# if features was selected, continue next
	#		unless ($lName) {
	#			next;
	#		}
	#
	#		my $draw = Drawing->new( $inCAM, $jobId, $lName, $drawingPos, $self->{"pcbThick"}, $side, $l->{"plated"} );
	#
	#		my $toolSize = $t->GetDrillSize();
	#
	#		# Test on special countersink tool
	#		if ( $t->GetSpecial() && defined $t->GetAngle() && $t->GetAngle() > 0 ) {
	#
	#			# if slot/hole is plated, finial depth will be smaller -100µm
	#			if ( $l->{"plated"} ) {
	#				$depth -= 0.1;
	#			}
	#
	#			#compute real milled hole/line diameter
	#			my $angle      = $t->GetAngle();
	#			my $newDiamter = ( tan( deg2rad( $angle / 2 ) ) * $depth * 2 ) * 1000;
	#
	#			# change all symbols in layer to this new diameter
	#			CamLayer->WorkLayer( $inCAM, $lName );
	#			$inCAM->COM( "sel_change_sym", "symbol" => "r" . $newDiamter, "reset_angle" => "no" );
	#
	#			$draw->Create( Enums->Depth_COUNTERSINK, Enums->Symbol_SLOT, $toolSize / 1000, $depth, $angle );
	#
	#		}
	#		else {
	#			$draw->Create( Enums->Depth_ZAXIS, Enums->Symbol_SLOT, $toolSize / 1000, $depth );
	#		}
	#
	#		# Add anew layerData to datalist
	#
	#		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $lName );
	#		$self->{"layerList"}->AddLayer($lData);
	#
	#	}
	#
	#	# 2) Proces holes ( pads )
	#
	#	my @pads = grep { $_->GetTypeProcess() eq DTMEnums->TypeProc_HOLE && $_->GetSource() eq DTMEnums->Source_DTM } @allTools;
	#
	#	foreach my $t (@pads) {
	#
	#		my $toolSize = $t->GetDrillSize();
	#
	#		my $depth = $t->GetDepth();
	#		my $lName = $self->__SeparateSymbol( $l, $t );
	#
	#		# if features was selected, continue next
	#		unless ($lName) {
	#			next;
	#		}
	#
	#		my $draw = Drawing->new( $inCAM, $jobId, $lName, $drawingPos, $self->{"pcbThick"}, $side, $l->{"plated"} );
	#
	#		# Test on special countersink tool
	#		if ( $t->GetSpecial() && defined $t->GetAngle() && $t->GetAngle() > 0 ) {
	#
	#			# if slot/hole is plated, finial depth will be smaller -100µm
	#			if ( $l->{"plated"} ) {
	#				$depth -= 0.1;
	#			}
	#
	#			#compute real milled hole/line diameter
	#			my $angle      = $t->GetAngle();
	#			my $newDiamter = ( tan( deg2rad( $angle / 2 ) ) * $depth * 2 ) * 1000;
	#
	#			# change all symbols in layer to this new diameter
	#			CamLayer->WorkLayer( $inCAM, $lName );
	#			$inCAM->COM( "sel_change_sym", "symbol" => "r" . $newDiamter, "reset_angle" => "no" );
	#
	#			$draw->Create( Enums->Depth_COUNTERSINK, Enums->Symbol_HOLE, $toolSize / 1000, $depth, $angle );
	#
	#		}
	#		else {
	#			$draw->Create( Enums->Depth_ZAXIS, Enums->Symbol_HOLE, $toolSize / 1000, $depth );
	#		}
	#
	#		# Add anew layerData to datalist
	#
	#		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $lName );
	#		$self->{"layerList"}->AddLayer($lData);
	#
	#	}
	#
	#	# 3) Process surfaces
	#
	#	my @surfaces = grep { $_->GetTypeProcess() eq DTMEnums->TypeProc_CHAIN && $_->GetSource() eq DTMEnums->Source_DTMSURF } @allTools;
	#
	#	foreach my $t (@surfaces) {
	#
	#		my $toolSize = $t->GetDrillSize();
	#
	#		my $depth = $t->GetDepth();
	#		my $lName = $self->__SeparateSymbol( $l, $t );
	#
	#		# if features was selected, continue next
	#		unless ($lName) {
	#			next;
	#		}
	#
	#		# if surface is plated, finial depth will be smaller -100µm
	#		if ( $l->{"plated"} ) {
	#			$depth -= 0.1;
	#		}
	#
	#		my $draw = Drawing->new( $inCAM, $jobId, $lName, $drawingPos, $self->{"pcbThick"}, $side, $l->{"plated"} );
	#		$draw->Create( Enums->Depth_ZAXIS, Enums->Symbol_SURFACE, undef, $depth );
	#
	#		# Add anew layerData to datalist
	#
	#		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $lName );
	#		$self->{"layerList"}->AddLayer($lData);
	#
	#	}

	# Do control, if prcesssed layer is empty. All symbols hsould be moved

	my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $l->{"gROWname"} );
	if ( $hist{"total"} > 0 ) {

		die "Some featuers was no processed and left in layer " . $l->{"gROWname"} . "\n.";
	}

}

# Process countersink Surfaces
sub __ProcessCountersinkSurfAndArc {
	my $self  = shift;
	my $lName = shift;
	my $type  = shift;    # RTMEnums->FeatType_SURF OR RTMEnums->FeatType_LINEARC

	my @chainSeq = $l->{"uniRTM"}->GetCircleChainSeq($type);

	# only special tools with angle
	@chainSeq =
	  grep { $_->GetChain()->GetChainTool()->GetUniDTMTool()->GetSpecial() && $_->GetChain()->GetChainTool()->GetUniDTMTool()->GetAngle() > 0 }
	  @chainSeq;

	my @radiuses = ();    # radiuses of whole surface, not

	for ( my $i = 0 ; < scalar(@chainSeq) ; $i++ ) {

		my $r = @chainSeq->[$i]->{"radius"};

		unless ( grep { ( $_ - 0.01 ) < $r && ( $_ + 0.01 ) > $r } @radiuses ) {
			push( @radiuses, $r );
		}
	}

	my @toolSizes = uniq( map { $_->GetChain()->GetChainSize() } @chainSeq );

	foreach my $r (@radiuses) {

		foreach my $tool (@toolSizes) {

			# get all chain seq by radius, by tool diameter (same tool diameters must have same angle)
			my @matchCh =
			  grep { ( $_->{"radius"} - 0.01 ) < $r && ( $_->{"radius"} + 0.01 ) > $r && $_->GetChain()->GetChainSize() == $tool } @chainSeq;

			next unless (@matchCh);

			my $toolDepth = $matchCh[0]->GetChain()->GetChainTool()->GetUniDTMTool()->GetDepth();    # angle of tool
			my $toolAngle = $matchCh[0]->GetChain()->GetChainTool()->GetUniDTMTool()->GetAngle();    # angle of tool

			my $radiusNoDepth = $matchCh[0]->{"radius"};                                             # radius of compensate surface or line/arc
			my $radiusReal = CountersinkHelper->GetSlotRadiusByToolDepth( $radiusNoDepth * 1000, $tool, $toolAngle, $toolDepth * 1000 ) / 1000;

			# if slot/hole is plated, finial depth will be smaller (we want final depth after plating)

			my $dDepth  = 0;                                                                         # difference of depth when countersing is plated
			my $dRadius = 0;                                                                         # difference of radius when countersing is plated

			if ( $l->{"plated"} ) {

				$dDepth = CountersinkHelper->GetExtraDepthIfPlated($toolAngle);
				$radiusReal =
				  CountersinkHelper->GetSlotRadiusByToolDepth( $radiusNoDepth * 1000, $tool, $toolAngle, ( $toolDepth - $dDepth ) * 1000 ) / 1000;
			}

			# get id of all features in chain
			my @featsId = map { $_->{'id'} } map { $_->GetOriFeatures() } @rChainSeq;

			my $drawLayer = $self->__IdentifyFeaturesByIds( $lName, \@featsId );

			unless ($drawLayer) {
				die "Failed when select features (" . join( ";", @featsId ) . ") from NC layer (NC drawing)";
			}

			# 1) adjust copied feature data. Create outlilne from each feature
			CamLayer->WorkLayer( $inCAM, $drawLayer );
			CamLayer->DeleteFeatures($inCAM);

			foreach my $chainS (@chainSeq) {

				if ( $type eq RTMEnums->FeatType_LINEARC ) {

					# get centr point of chain
					my $centerX = ( $chainS->GetOriFeatures() )[0]->{"xmid"};
					my $centerY = ( $chainS->GetOriFeatures() )[0]->{"ymid"};
					CamSymbolArc->AddCircleRadiusCenter( $inCAM, $radiusReal, { "x" => $centerX, "y" => $centerY } );

				}
				elsif ( if ( $type eq RTMEnums->FeatType_SURF ) ) {

					my $centerX = ( $chainS->GetOriFeatures() )[0]->{"surfaces"}->[0];
					my $centerY = ( $chainS->GetOriFeatures() )[0]->{"ymid"};
				}

			}

			CamLayer->Contourize( $inCAM, $drawLayer ) $inCAM->COM( "sel_resize", "size" => $compVal, "corner_ctl" => "no" );

			CamLayer->WorkLayer( $inCAM, $drawLayer );
			$inCAM->COM( "sel_change_sym", "symbol" => "r" . $csRadius, "reset_angle" => "no" );

			# Compute depth of "imagine drill tool"
			# If countersink is done by surface, edge of drill tool goes around according "surface border"
			# Image for this case will show "image tool", where center of tool is same as center of surface, thus "image tool"
			# not go around surface bordr but just like normal drill tool, which drill hole

			my $depthImgTool = cotan( deg2rad( ( $toolAngle / 2 ) ) ) * $radiusReal;

			# 1) adjust copied feature data

			if ( $type eq RTMEnums->FeatType_LINEARC ) {

				$csRadius = ( tan( deg2rad( $angle / 2 ) ) * $depth * 2 ) * 1000;

				CamLayer->WorkLayer( $inCAM, $drawLayer );
				$inCAM->COM( "sel_change_sym", "symbol" => "r" . $csRadius, "reset_angle" => "no" );

			}
			elsif ( if ( $type eq RTMEnums->FeatType_SURF ) ) {

				# do nothing, surface is ok
			}

			#  Consider plating on features
			if ( $l->{"plated"} ) {
				CamLayer->WorkLayer( $inCAM, $drawLayer );
				$inCAM->COM( "sel_resize", "size" => -( 2 * $dRadius ), "corner_ctl" => "no" );
			}

			# 2) New depth, consider plating
			if ( $l->{"plated"} ) {
				$depth -= $dDepth;
				$csRadius -= ( 2 * $dRadius );
			}

			# 3) Draw picture
			$draw->Create( Enums->Depth_COUNTERSINK, Enums->Symbol_HOLE, $csRadius * 2, $depth, $angle );
		}
	}
}

## MEthod do necessary stuff for each layer by type
## like resizing, copying, change polarity, merging, ...
#sub __ProcessNClayer {
#	my $self = shift;
#	my $l    = shift;
#	my $type = shift;
#
#	my $inCAM = $self->{"inCAM"};
#	my $jobId = $self->{"jobId"};
#	my $step  = $self->{"step"};
#
#	my @allTools = $l->{"uniDTM"}->GetTools();
#
#	my $enTit = ValueConvertor->GetJobLayerTitle($l);
#	my $czTit = ValueConvertor->GetJobLayerTitle( $l, 1 );
#	my $enInf = ValueConvertor->GetJobLayerInfo($l);
#	my $czInf = ValueConvertor->GetJobLayerInfo( $l, 1 );
#
#	my $drawingPos = Point->new( 0, abs( $self->{"profileLim"}->{"yMax"} - $self->{"profileLim"}->{"yMin"} ) + 50 );    # starts 150
#
#	#my %lines_arcs = %{ $l->{"symHist"}->{"lines_arcs"} };
#	#my %pads       = %{ $l->{"symHist"}->{"pads"} };
#
#	# Get if NC operation is from top/bot
#	my $side = $l->{"gROWname"} =~ /c/ ? "top" : "bot";
#
#	# 1) Proces slots (lines + arcs)
#
#	my @lines_arcs = grep { $_->GetTypeProcess() eq DTMEnums->TypeProc_CHAIN && $_->GetSource() eq DTMEnums->Source_DTM } @allTools;
#
#	foreach my $t (@lines_arcs) {
#
#		my $depth = $t->GetDepth();
#		my $lName = $self->__SeparateSymbol( $l, $t );
#
#		# if features was selected, continue next
#		unless ($lName) {
#			next;
#		}
#
#		my $draw = Drawing->new( $inCAM, $jobId, $lName, $drawingPos, $self->{"pcbThick"}, $side, $l->{"plated"} );
#
#		my $toolSize = $t->GetDrillSize();
#
#		# Test on special countersink tool
#		if (  $t->GetSpecial() && defined $t->GetAngle() && $t->GetAngle() > 0 ) {
#
#			# if slot/hole is plated, finial depth will be smaller -100µm
#			if ( $l->{"plated"} ) {
#				$depth -= 0.1;
#			}
#
#			#compute real milled hole/line diameter
#			my $angle      = $t->GetAngle();
#			my $newDiamter = ( tan( deg2rad( $angle / 2 ) ) * $depth * 2 ) * 1000;
#
#			# change all symbols in layer to this new diameter
#			CamLayer->WorkLayer( $inCAM, $lName );
#			$inCAM->COM( "sel_change_sym", "symbol" => "r" . $newDiamter, "reset_angle" => "no" );
#
#			$draw->Create( Enums->Depth_COUNTERSINK, Enums->Symbol_SLOT, $toolSize / 1000, $depth, $angle );
#
#		}
#		else {
#			$draw->Create( Enums->Depth_ZAXIS, Enums->Symbol_SLOT, $toolSize / 1000, $depth );
#		}
#
#		# Add anew layerData to datalist
#
#		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $lName );
#		$self->{"layerList"}->AddLayer($lData);
#
#	}
#
#	# 2) Proces holes ( pads )
#
#	my @pads = grep { $_->GetTypeProcess() eq DTMEnums->TypeProc_HOLE && $_->GetSource() eq DTMEnums->Source_DTM } @allTools;
#
#	foreach my $t ( @pads ) {
#
#		my $toolSize = $t->GetDrillSize();
#
#		my $depth = $t->GetDepth();
#		my $lName = $self->__SeparateSymbol( $l, $t );
#
#		# if features was selected, continue next
#		unless ($lName) {
#			next;
#		}
#
#		my $draw = Drawing->new( $inCAM, $jobId, $lName, $drawingPos, $self->{"pcbThick"}, $side, $l->{"plated"} );
#
#		# Test on special countersink tool
#		if (  $t->GetSpecial() && defined $t->GetAngle() && $t->GetAngle() > 0 ) {
#
#			# if slot/hole is plated, finial depth will be smaller -100µm
#			if ( $l->{"plated"} ) {
#				$depth -= 0.1;
#			}
#
#			#compute real milled hole/line diameter
#			my $angle      = $t->GetAngle();
#			my $newDiamter = ( tan( deg2rad( $angle / 2 ) ) * $depth * 2 ) * 1000;
#
#			# change all symbols in layer to this new diameter
#			CamLayer->WorkLayer( $inCAM, $lName );
#			$inCAM->COM( "sel_change_sym", "symbol" => "r" . $newDiamter, "reset_angle" => "no" );
#
#			$draw->Create( Enums->Depth_COUNTERSINK, Enums->Symbol_HOLE, $toolSize / 1000, $depth, $angle );
#
#		}
#		else {
#			$draw->Create( Enums->Depth_ZAXIS, Enums->Symbol_HOLE, $toolSize / 1000, $depth );
#		}
#
#		# Add anew layerData to datalist
#
#		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $lName );
#		$self->{"layerList"}->AddLayer($lData);
#
#	}
#
#	# 3) Process surfaces
#
#	my @surfaces = grep { $_->GetTypeProcess() eq DTMEnums->TypeProc_CHAIN && $_->GetSource() eq DTMEnums->Source_DTMSURF } @allTools;
#
#	foreach my $t ( @surfaces ) {
#
#		my $toolSize = $t->GetDrillSize();
#
#		my $depth = $t->GetDepth();
#		my $lName = $self->__SeparateSymbol( $l, $t );
#
#		# if features was selected, continue next
#		unless ($lName) {
#			next;
#		}
#
#		# if surface is plated, finial depth will be smaller -100µm
#		if ( $l->{"plated"} ) {
#			$depth -= 0.1;
#		}
#
#		my $draw = Drawing->new( $inCAM, $jobId, $lName, $drawingPos, $self->{"pcbThick"}, $side, $l->{"plated"} );
#		$draw->Create( Enums->Depth_ZAXIS, Enums->Symbol_SURFACE, undef, $depth );
#
#		# Add anew layerData to datalist
#
#		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $lName );
#		$self->{"layerList"}->AddLayer($lData);
#
#	}
#
#	# Do control, if prcesssed layer is empty. All symbols hsould be moved
#
#	my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $l->{"gROWname"} );
#	if ( $hist{"total"} > 0 ) {
#
#		die "Some featuers was no processed and left in layer " . $l->{"gROWname"} . "\n.";
#	}
#
#}

sub __IdentifyFeaturesByIds {
	my $self       = shift;
	my $sourceL    = shift;
	my $featuresId = shift;    # by feature ids

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1) copy source layer to

	my $lName = GeneralHelper->GetNumUID();
	my $f = FeatureFilter->new( $inCAM, $jobId, $sourceL->{"gROWname"} );
	$f->AddFeatureIndexes($featuresId);

	if ( $f->Select() > 0 ) {

		$inCAM->COM(
			"sel_move_other",

			# "dest"         => "layer_name",
			"target_layer" => $lName
		);

		CamLayer->WorkLayer( $inCAM, $lName );
		my $lComp = CamLayer->RoutCompensation( $inCAM, $lName, "document" );

		CamLayer->WorkLayer( $inCAM, $lName );
		$inCAM->COM("sel_delete");

		$inCAM->COM( "merge_layers", "source_layer" => $lComp, "dest_layer" => $lName );
		$inCAM->COM( "delete_layer", "layer" => $lComp );

		return $lName;
	}
	else {

		return 0;
	}

}

# Copy features from original layer to new layer intended for drawing
# type of symbols to new layer and return layer name
sub __IdentifyFeaturesByIds {
	my $self       = shift;
	my $sourceL    = shift;
	my $featuresId = shift;    # by feature ids
	my $tool       = shift;    # by  DTM tool

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1) copy source layer to

	my $lName = GeneralHelper->GetNumUID();

	my $f = FeatureFilter->new( $inCAM, $jobId, $sourceL->{"gROWname"} );

	if ( $tool->GetTypeProcess() eq DTMEnums->TypeProc_HOLE ) {

		my @types = ("pad");
		$f->SetTypes( \@types );

		my @syms = ( "r" . $tool->GetDrillSize() );
		$f->AddIncludeSymbols( \@syms );

	}
	elsif ( $tool->GetTypeProcess() eq DTMEnums->TypeProc_CHAIN ) {

		if ( $tool->GetSource() eq DTMEnums->Source_DTM ) {

			my @types = ( "line", "arc" );
			$f->SetTypes( \@types );

			my @syms = ( "r" . $tool->GetDrillSize() );
			$f->AddIncludeSymbols( \@syms );

		}
		elsif ( $tool->GetSource() eq DTMEnums->Source_DTMSURF ) {

			my @types = ("surface");
			$f->SetTypes( \@types );

			# TODO chzba incam,  je v inch misto mm
			my %num = ( "min" => $tool->GetDrillSize() / 1000 / 25.4, "max" => $tool->GetDrillSize() / 1000 / 25.4 );
			$f->AddIncludeAtt( ".rout_tool", \%num );
		}
	}

	unless ( $f->Select() > 0 ) {
		return 0;
	}
	else {

		$inCAM->COM(
			"sel_move_other",

			# "dest"         => "layer_name",
			"target_layer" => $lName
		);

		# if slot or surface, do compensation
		if ( $tool->GetTypeProcess() eq DTMEnums->TypeProc_CHAIN ) {

			CamLayer->WorkLayer( $inCAM, $lName );
			my $lComp = CamLayer->RoutCompensation( $inCAM, $lName, "document" );

			CamLayer->WorkLayer( $inCAM, $lName );
			$inCAM->COM("sel_delete");

			$inCAM->COM( "merge_layers", "source_layer" => $lComp, "dest_layer" => $lName );
			$inCAM->COM( "delete_layer", "layer" => $lComp );
		}

	}

	return $lName;
}

# Copy type of symbols to new layer and return layer name
sub __GetSymbolDepth {
	my $self     = shift;
	my $sourceL  = shift;
	my $symbol   = shift;
	my $toolType = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my ($toolSize) = $symbol =~ /^\w(\d*)/;

	my $depth = $sourceL->{"uniDTM"}->GetToolDepth( $toolSize, $toolType );

	if ( !defined $depth || $depth == 0 ) {
		die "Depth is not defined for tool $symbol in layer " . $sourceL->{"gROWname"} . ".\n";
	}

	return $depth;
}
#
## Return depth of surafaces in given layer
## Layer shoul contain same depth for all surfaces
#sub __GetSurfaceDepth {
#	my $self   = shift;
#	my $l      = shift;
#	my $symbol = shift;
#
#	my $inCAM = $self->{"inCAM"};
#	my $jobId = $self->{"jobId"};
#
#	my %attHist = CamHistogram->GetAttHistogram( $inCAM, $jobId, $self->{"step"}, $l->{"gROWname"} );
#
#	unless ( defined $attHist{".rout_tool"} ) {
#		die "No .rout_tool attribute is defined in surface. \n";
#	}
#
#	# TODO chzba incam, hloubka je v inch misto mm
#	my $toolSize = sprintf( "%.1f", $attHist{".rout_tool"} * 25.4 );
#
#	my $depth = $sourceL->{"uniDTM"}->GetToolDepth( $toolSize, DTMEnums->TypeProc_CHAIN );
#
#	if ( !defined $depth || $depth == 0 ) {
#		die "Depth is not defined for tool $symbol in layer " . $sourceL->{"gROWname"} . ".\n";
#	}
#
#	return $d;
#}

# Create layer and fill profile - simulate pcb material
sub __PrepareNCDEPTHMILL {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	@layers = grep { $_->{"type"} && $_->{"gROWcontext"} eq "board" } @layers;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# all depth nc layers

	@layers = grep {
		     $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillBot
	} @layers;

	foreach my $l (@layers) {

		my $tit = ValueConvertor->GetJobLayerTitle($l);
		my $inf = ValueConvertor->GetJobLayerInfo($l);

		my $lName = GeneralHelper->GetGUID();

		$inCAM->COM(
					 "copy_layer",
					 "source_job"   => $jobId,
					 "source_step"  => $self->{"step"},
					 "source_layer" => $l->{"gROWname"},
					 "dest"         => "layer_name",
					 "dest_step"    => $self->{"step"},
					 "dest_layer"   => $lName,
					 "mode"         => "append"
		);

		$self->__ComputeNewDTMTools( $lName, $l->{"plated"} );

		# add table with depth information
		$self->__InsertDepthTable($lName);

		my $lData = LayerData->new( $type, ValueConvertor->GetFileNameByLayer($l), $tit, $inf, $lName );

		$self->{"layerList"}->AddLayer($lData);
	}

}

sub __PrepareOUTLINE {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	my $inCAM = $self->{"inCAM"};

	my $lName = GeneralHelper->GetGUID();
	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	CamLayer->WorkLayer( $inCAM, $lName );

	$inCAM->COM( "profile_to_rout", "layer" => $lName, "width" => "200" );

	@layers = grep { $_->{"gROWcontext"} eq "board" && $_->{"gROWlayer_type"} ne "drill" && $_->{"gROWlayer_type"} ne "rout" } @layers;

	foreach my $l (@layers) {

		my $tit = "Outline layer";
		my $inf = "";

		my $lData = LayerData->new( $type, "dim", $tit, $inf, $lName );

		$self->{"layerList"}->AddLayer($lData);
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
