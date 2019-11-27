#-------------------------------------------------------------------------------------------#
# Description: Prepare special helper layers for creating coverlay
# and prepreg pins for RigidFlex
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Flex::DoCoverlayPins;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamSymbolSurf';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Packages::CAMJob::FlexiLayers::BendAreaParser::BendAreaParser';
use aliased 'Packages::Polygon::Line::LineTransform';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Polygon::Line::SegmentLineIntersection';
use aliased 'Packages::CAMJob::FlexiLayers::CoverlayPinParser::CoverlayPinParser';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAM::FeatureFilter::Enums'                     => 'EnumsFiltr';
use aliased 'Packages::CAMJob::FlexiLayers::CoverlayPinParser::Enums' => 'PinEnums';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveLine';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveArcSCE';
use aliased 'Packages::CAM::SymbolDrawing::Point';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

my $OPTIMALPINLENGTH = 11;      # 11mm
my $OPTIMALPINWIDTH  = 2.5;     # 2.5mm
my $PINREGISTERDIST  = 3.25;    # 3.25mm from flex part
my $PINSOLDDIST1     = 0.5;     # 0.5mm from flex part
my $PINCUTDIST2      = 6;       # 6mm from flex part
my $CUREGPADSIZE     = 1.2;     # 1.2mm pad in signal flex layers

#	PinString_REGISTER   => "pin_register",      # pad which is used for register coverlay with flex core
#	PinString_SOLDERLINE => "pin_solderline",    # between PinString_SOLDERPIN and PinString_CUTPIN lines is place for soldering
#	PinString_CUTLINE    => "pin_cutline",       # this line marks the area where coverlaz pin should be cutted
#	PinString_ENDLINE    => "pin_endline",       # line marks end border of pin
#	PinString_SIDELINE   => "pin_sideline",      # lines mark side border of pin
#	PinString_BENDLINE   => "pin_bendline"       # lines marks border of bend area

my @messHead = ();
push( @messHead, "<b>=======================================================</b>" );
push( @messHead, "<b>Průvodce vytvořením coverlay pinů. Vrstva: coverlaypins</b>" );
push( @messHead, "<b>=======================================================</b> \n" );

# Set impedance lines
sub CreateCoverlayPins {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;

	my $result = 1;

	my $messMngr = MessageMngr->new($jobId);

	my $lName = "coverlaypins";

	my $type = JobHelper->GetPcbType($jobId);
	return 0 if ( $type ne EnumsGeneral->PcbType_RIGIDFLEXI && $type ne EnumsGeneral->PcbType_RIGIDFLEXO );

	my %coverlayType = HegMethods->GetCoverlayType($jobId);

	# When only top coverlay on outer RigidFlex (without pins)
	if ( !$coverlayType{"top"} && !$coverlayType{"bot"} ) {
		return 0;
	}

	CamHelper->SetStep( $inCAM, $step );

	my $createLayer = 1;
	my $putPinMarks = 1;

	my @mess = (@messHead);
	push( @mess, "Vrstva \"$lName\" již existuje, chceš ji vytvořit znovu?" );

	if ( CamHelper->LayerExists( $inCAM, $jobId, $lName ) ) {

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess, [ "Ne", "Ano, vytvořit" ] );

		$createLayer = 0 if ( $messMngr->Result() == 0 );
	}

	if ($createLayer) {

		my @mess = (@messHead);
		push( @mess, "Vrstva s obrysem ohebné části PCB \"bend\" musí existovat. Vytvoř ji" );

		while ( !CamHelper->LayerExists( $inCAM, $jobId, "bend" ) ) {
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess, [ "Konec", "Vytvořím" ] );

			return 0 if ( $messMngr->Result() == 0 );
		}

		my $errMess = "";

		my $parser = BendAreaParser->new( $inCAM, $jobId, $step );

		while ( !$parser->CheckBendArea( \$errMess ) ) {

			my @mess = (@messHead);
			push( @mess, "Vrstva \"bend\" není správně připravená", "Detail chyby:", $errMess );

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess, [ "Konec", "Opravím" ] );

			return 0 if ( $messMngr->Result() == 0 );

			$inCAM->PAUSE("Oprav vrstvu: \"bend\"");

			$errMess = "";

		}

		CamMatrix->DeleteLayer( $inCAM, $jobId, $lName );
		CamMatrix->CreateLayer( $inCAM, $jobId, $lName, "bend_area", "positive", 1 );

		CamLayer->WorkLayer( $inCAM, "bend" );

		my $f = Features->new();
		$f->Parse( $inCAM, $jobId, $step, "bend" );
		my @features = $f->GetFeatures();

		my $draw = SymbolDrawing->new( $inCAM, $jobId );

		foreach my $f (@features) {

			my $p;

			if ( $f->{"type"} eq "L" ) {

				$p = PrimitiveLine->new( Point->new( $f->{"x1"}, $f->{"y1"} ), Point->new( $f->{"x2"}, $f->{"y2"} ), $f->{"symbol"} );
			}
			elsif ( $f->{"type"} eq "A" ) {
				$p = PrimitiveArc->new( Point->new( $f->{"x1"}, $f->{"y1"} ),
										Point->new( $f->{"xmid"}, $f->{"ymid"} ),
										Point->new( $f->{"x2"},   $f->{"y2"} ),
										$f->{"dir"}, $f->{"symbol"} );
			}
			else {

				die "Not supported feature type: " . $f->{"type"};
			}

			$p->AddAttribute( ".string", $f->{"att"}->{".string"} );
			$p->AddAttribute("transition_zone") if ( defined $f->{"att"}->{"transition_zone"} );

			$draw->AddPrimitive($p);

		}
		CamLayer->WorkLayer( $inCAM, $lName );
		$draw->Draw();

		#
		#		my $draw = FeatureDrawing->new( $inCAM, $jobId );
		#		$draw->Draw( $step, $tmp, \@features );

		#CamLayer->CopySelOtherLayer( $inCAM, [$lName] );

		#CamLayer->WorkLayer( $inCAM, $lName );
		CamAttributes->SetFeaturesAttribute( $inCAM, $jobId, ".string", PinEnums->PinString_BENDLINE );

		my $nextPin = 1;

		while ($nextPin) {

			my $pinCreated = $self->__CreateNextPin( $inCAM, $jobId, $step, \$nextPin, $messMngr );

			if ( $pinCreated && $nextPin == 0 ) {

				$putPinMarks = 1;
				last;
			}
			elsif ( !$pinCreated && $nextPin == 0 ) {

				$putPinMarks = 0;
				last;
			}
		}

	}

	if ($putPinMarks) {

		$self->__PutPinMarks( $inCAM, $jobId, $step, $messMngr );

	}
}

sub __CreateNextPin {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $nextPin = shift;

	my $messMngr = shift;

	my $result = 1;

	my $lName = "coverlaypins";

	CamLayer->WorkLayer( $inCAM, $lName );

	#$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, ["Označ lajnu, kde si přeješ vytvořit coverlay pin"] );
	$inCAM->PAUSE("Oznac lajnu kde bude vytvoren coverlay pin");

	while ( !CamLayer->GetSelFeaturesCnt($inCAM) ) {

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["Není označená žádná lajna"] );

		$inCAM->PAUSE("Oznac lajnu kde bude vytvoren coverlay pin");
	}

	my $f = Features->new();

	#$f->Parse( $inCAM, $jobId, $step, $lName, 0, 0 );

	$f->Parse( $inCAM, $jobId, $step, $lName, 0, 1 );

	my $selLineId = ( $f->GetFeatures() )[0]->{"id"};

	my $pinParser = CoverlayPinParser->new( $inCAM, $jobId, $step, "CW" );
	my $selLine = $pinParser->GetBendAreaLineByLineId($selLineId);

	my $profileLen = $self->__GetPinLength( $inCAM, $jobId, $step, $selLine );

	my @mess = (@messHead);
	push( @mess, "Tvar coverlay pinu:" );
	push( @mess, "=========================================\n" );
	push( @mess, " Délka:" );
	push( @mess, " - Maximální podle profilu: " . sprintf( "%.1f", $profileLen ) . "mm" );
	push( @mess, " - Optimální: " . $OPTIMALPINLENGTH . "mm" );
	push( @mess, "" );
	push( @mess, " Šířka (nezapomeň, že u coverlay se k šířce pinu připočte přesah coverlay do rigid části):" );
	push( @mess, " - $OPTIMALPINWIDTH mm" );

	if ( $profileLen < $OPTIMALPINLENGTH ) {

		push( @mess,
			  "\n<r>Pozor délka podle profilu je menší než doporučená. Pokud vybereš doporučenou, rozestupy mezi DPS musí být alespoň: "
				. sprintf( "%.1f", 4.5 + 2 * ( $OPTIMALPINLENGTH - $profileLen ) )
				. "mm</r>" );
	}

	push( @mess, " Zvol jednu z možností popřípadě uprav šířku pinu." );

	my @params          = ();
	my $parCustPinLen   = $messMngr->GetTextParameter( "Vlastní délka pinu [mm]", $OPTIMALPINLENGTH );
	my $parCustPinWidth = $messMngr->GetTextParameter( "Šířka pinu [mm]", $OPTIMALPINWIDTH );

	push( @params, $parCustPinLen, $parCustPinWidth );

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION,
						  \@mess, [ "Vyberu jinou lajnu", "Vlastní délka", "Délka podle profilu", "Optimální délka" ],
						  undef, \@params );

	my $reply = $messMngr->Result();

	if ( $reply == 0 ) {

		$$nextPin = 1;
		return 0;

	}
	else {

		# Redraw pin areas

		my $tmpLayer = GeneralHelper->GetGUID();
		CamMatrix->CreateLayer( $inCAM, $jobId, $tmpLayer, "document", "positive", 0 );
		CamLayer->WorkLayer( $inCAM, $lName );

		my @idx =
		  grep { $_ != $selLineId }
		  map  { $_->{"id"} } $pinParser->GetFeatures();
		CamFilter->SelectByFeatureIndexes( $inCAM, $jobId, \@idx );

		CamLayer->CopySelOtherLayer( $inCAM, [$tmpLayer] );
		CamLayer->WorkLayer( $inCAM, $tmpLayer );

		my $len;

		if ( $reply == 1 ) {

			$len = $parCustPinLen->GetResultValue();
		}
		elsif ( $reply == 2 ) {

			$len = $profileLen;

		}
		elsif ( $reply == 3 ) {

			$len = $OPTIMALPINLENGTH;
		}

		my $width = $parCustPinWidth->GetValueChanged() ? $parCustPinWidth->GetResultValue() : $OPTIMALPINWIDTH;

		my %pinGeometry = $self->__GetPinLines( $selLine, $len, $width );

		CamSymbol->ResetCurAttributes($inCAM);

		CamSymbol->AddCurAttribute( $inCAM, $jobId, "feat_group_id", GeneralHelper->GetGUID() );

		# Add pin side lines
		for ( my $i = 0 ; $i < scalar( @{ $pinGeometry{"pinSideLines1"} } ) ; $i++ ) {
			CamSymbol->AddCurAttribute( $inCAM, $jobId, ".string", PinEnums->PinString_SIDELINE1 );
			CamSymbol->AddLine( $inCAM, $pinGeometry{"pinSideLines1"}->[$i][0], $pinGeometry{"pinSideLines1"}->[$i][1], "s400", "positive" );
		}

		# Add pin side lines
		for ( my $i = 0 ; $i < scalar( @{ $pinGeometry{"pinSideLines2"} } ) ; $i++ ) {
			CamSymbol->AddCurAttribute( $inCAM, $jobId, ".string", PinEnums->PinString_SIDELINE2 );
			CamSymbol->AddLine( $inCAM, $pinGeometry{"pinSideLines2"}->[$i][0], $pinGeometry{"pinSideLines2"}->[$i][1], "s400", "positive" );
		}

		# Add pin end line
		CamSymbol->AddCurAttribute( $inCAM, $jobId, ".string", PinEnums->PinString_ENDLINE );
		CamSymbol->AddLine( $inCAM, $pinGeometry{"pinEndLine"}->[0], $pinGeometry{"pinEndLine"}->[1], "s400", "positive" );

		# Add register pad
		if ( defined $pinGeometry{"pinRegister"} ) {
			CamSymbol->AddCurAttribute( $inCAM, $jobId, ".string", PinEnums->PinString_REGISTER );
			CamSymbol->AddPad( $inCAM, "r2000", $pinGeometry{"pinRegister"} );
		}

		# Add solder line
		if ( defined $pinGeometry{"pinSolderLines"} ) {
			CamSymbol->AddCurAttribute( $inCAM, $jobId, ".string", PinEnums->PinString_SOLDERLINE );
			CamSymbol->AddLine( $inCAM, $pinGeometry{"pinSolderLines"}->[0], $pinGeometry{"pinSolderLines"}->[1], "r100", "positive" );
		}

		# Add cut line
		if ( defined $pinGeometry{"pinCutLines"} ) {
			CamSymbol->AddCurAttribute( $inCAM, $jobId, ".string", PinEnums->PinString_CUTLINE );
			CamSymbol->AddLine( $inCAM, $pinGeometry{"pinCutLines"}->[0], $pinGeometry{"pinCutLines"}->[1], "r100", "positive" );
		}

		CamSymbol->ResetCurAttributes($inCAM);

		@mess = (@messHead);
		push( @mess, "Kontrola pinu" );
		push( @mess, "--------------\n" );
		push( @mess, "Je coverlay pin OK? Zkontroluj:\n" );
		push( @mess, "- délku pinu vzhledem k profilu" );
		push( @mess, "- pozici pinu, zda nezasahuje do desky" );
		push( @mess, "- ideální umístění pinu je středu hrany (z obou stran) pružné části části" );

		if ( $len > $profileLen ) {
			push( @mess,
				      "\n<r>Pozor pin bude zasahovat mimo desku. Nastav v panelu rozestupy mezi DPS alespoň: "
					. sprintf( "%.1f", 4.5 + 2 * ( $len - $profileLen ) )
					. "mm</r>" );
		}

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess );

		$inCAM->PAUSE("Zkontroluj popripade upravi tvar pinu");

		@mess = (@messHead);

		push( @mess, "Co dál?" );

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION,
							  \@mess, [ "Ukončit", "Vytvořit pin znovu", "Vytvořit další pin", "Dokončit" ] );

		if ( $messMngr->Result() == 0 ) {

			$$nextPin = 0;
			$result   = 0;

		}
		elsif ( $messMngr->Result() == 1 ) {

			$$nextPin = 1;
			$result   = 0;
		}
		elsif ( $messMngr->Result() > 1 ) {

			$$nextPin = $messMngr->Result() == 2 ? 1 : 0;
			$result = 1;

			CamLayer->WorkLayer( $inCAM, $lName );
			$inCAM->COM("sel_clear_feat");
			CamLayer->DeleteFeatures($inCAM);
			CamLayer->WorkLayer( $inCAM, $tmpLayer );
			CamLayer->CopySelOtherLayer( $inCAM, [$lName] );
			CamLayer->WorkLayer( $inCAM, $lName );
		}

		CamMatrix->DeleteLayer( $inCAM, $jobId, $tmpLayer );
	}

	return $result;
}

#      |
#  ----
# |
#  ----
#      |
sub __GetPinLines {
	my $self      = shift;
	my $selLine   = shift;
	my $pinLength = shift;
	my $pinWidth  = shift;

	my $midX = ( $selLine->{"x1"} + $selLine->{"x2"} ) / 2;
	my $midY = ( $selLine->{"y1"} + $selLine->{"y2"} ) / 2;

	my %endP =
	  LineTransform->GetVerticalSegmentLine( { "x" => $midX, "y" => $midY },
											 { "x" => $selLine->{"x2"}, "y" => $selLine->{"y2"} },
											 $pinLength, "left" );

	my $pinLineP1 = { "x" => $midX, "y" => $midY };
	my $pinLineP2 = { "x" => $endP{"x"}, "y" => $endP{"y"} };

	my @line2 = LineTransform->ParallelSegmentLine( $pinLineP1, $pinLineP2, $pinWidth / 2, "left" );
	my @line4 = LineTransform->ParallelSegmentLine( $pinLineP1, $pinLineP2, $pinWidth / 2, "right" );

	my @line1 = ( { "x" => $selLine->{"x1"}, "y" => $selLine->{"y1"} }, { "x" => $line2[0]->{"x"}, "y" => $line2[0]->{"y"} } );
	my @line5 = ( { "x" => $selLine->{"x2"}, "y" => $selLine->{"y2"} }, { "x" => $line4[0]->{"x"}, "y" => $line4[0]->{"y"} } );

	my @line3 = ( { "x" => $line2[1]->{"x"}, "y" => $line2[1]->{"y"} }, { "x" => $line4[1]->{"x"}, "y" => $line4[1]->{"y"} } );

	my %res = ();
	$res{"pinSideLines1"} = [ \@line1, \@line5 ];
	$res{"pinSideLines2"} = [ \@line2, \@line4, ];
	$res{"pinEndLine"}    = \@line3;

	if ( $pinLength > $PINREGISTERDIST ) {
		my %regP =
		  LineTransform->GetVerticalSegmentLine( { "x" => $midX, "y" => $midY },
												 { "x" => $selLine->{"x2"}, "y" => $selLine->{"y2"} },
												 $PINREGISTERDIST );
		$res{"pinRegister"} = \%regP;
	}

	if ( $pinLength > $PINSOLDDIST1 ) {

		my @cutLine1 = LineTransform->ParallelSegmentLine( { "x" => $line2[0]->{"x"}, "y" => $line2[0]->{"y"} },
														   { "x" => $line4[0]->{"x"}, "y" => $line4[0]->{"y"} },
														   $PINSOLDDIST1 );
		$res{"pinSolderLines"} = \@cutLine1;
	}

	if ( $pinLength > $PINCUTDIST2 ) {

		my @cutLine2 = LineTransform->ParallelSegmentLine( { "x" => $line2[0]->{"x"}, "y" => $line2[0]->{"y"} },
														   { "x" => $line4[0]->{"x"}, "y" => $line4[0]->{"y"} }, $PINCUTDIST2 );
		$res{"pinCutLines"} = \@cutLine2;
	}

	return %res;

}

sub __GetPinLength {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $step       = shift;
	my $solderLine = shift;

	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );

	my @pointsLim = ();

	push( @pointsLim, { "x" => $lim{"xMin"}, "y" => $lim{"yMin"} } );
	push( @pointsLim, { "x" => $lim{"xMin"}, "y" => $lim{"yMax"} } );
	push( @pointsLim, { "x" => $lim{"xMax"}, "y" => $lim{"yMax"} } );
	push( @pointsLim, { "x" => $lim{"xMax"}, "y" => $lim{"yMin"} } );

	my $midX = ( $solderLine->{"x1"} + $solderLine->{"x2"} ) / 2;
	my $midY = ( $solderLine->{"y1"} + $solderLine->{"y2"} ) / 2;

	my %endP =
	  LineTransform->GetVerticalSegmentLine( { "x" => $midX, "y" => $midY }, { "x" => $solderLine->{"x2"}, "y" => $solderLine->{"y2"} }, 200 );

	my $pinLineP1 = { "x" => $midX, "y" => $midY };
	my $pinLineP2 = { "x" => $endP{"x"}, "y" => $endP{"y"} };

	# find maximal verticall distance from bend border to pcb profile

	my $distMin  = undef;
	my $distMinX = undef;
	my $distMinY = undef;

	for ( my $i = 0 ; $i < 4 ; $i++ ) {

		my $profP1 = $i == 0 ? $pointsLim[3] : $pointsLim[ $i - 1 ];
		my $profP2 = $pointsLim[$i];

		my $isIntersec = SegmentLineIntersection->SegLineIntersection( $pinLineP1, $pinLineP2, $pointsLim[ $i - 1 ], $pointsLim[$i] );

		if ( $isIntersec == 1 ) {

			my %pIntersect = SegmentLineIntersection->GetLineIntersection( $pinLineP1, $pinLineP2, $pointsLim[ $i - 1 ], $pointsLim[$i] );

			my $l = sqrt( ( $pIntersect{"x"} - $midX )**2 + ( $midY - $pIntersect{"y"} )**2 );
			if ( ( !defined $distMin || $l < $distMin ) ) {
				$distMin  = $l;
				$distMinX = $pIntersect{"x"};
				$distMinY = $pIntersect{"y"};

			}

		}
	}

	$distMin -= 1;    # -1mm becouse coverlay rout 2mm should not rout beyound PCB profile

	return $distMin;

}

sub __PutPinMarks {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $messMngr = shift;

	# Ask for put cu to flex layers

	my $stackup = Stackup->new($inCAM, $jobId);

	my @cores  = $stackup->GetAllCores(1);
	my @layers = JobHelper->GetCoverlaySigLayers($jobId);

	my @mess = (@messHead);
	push( @mess, "Vložit nyní značky \"coverlay piny\" do signálových vrstev flexi jader?\n" );
	push( @mess, " - Jádra: " . join( "; ", map { "jádro " . $_->GetCoreNumber() } @cores ) );
	push( @mess, " - Cu vrstvy: " . join( "; ", @layers ) );

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess, [ "Nyní nevkládat", "Ano vložit" ] );

	if ( $messMngr->Result() == 1 ) {

		my $pinParser = CoverlayPinParser->new( $inCAM, $jobId, $step, "CW" );

		CamLayer->AffectLayers( $inCAM, \@layers );

		# Delete old pin marks
		my $f = FeatureFilter->new( $inCAM, $jobId, undef, \@layers );
		$f->AddIncludeAtt( ".string", PinEnums->PinString_SIGLAYERMARKS );

		if ( $f->Select() ) {
			CamLayer->DeleteFeatures($inCAM);
		}

		# All symbols in signal layers have .string att: PinEnums->PinString_SIGLAYERMARKS
		CamSymbol->ResetCurAttributes($inCAM);
		CamSymbol->AddCurAttribute( $inCAM, $jobId, ".string", PinEnums->PinString_SIGLAYERMARKS );

		# 1) Add negative background under all marks (protective border from profile fill )
		foreach my $bendArea ( $pinParser->GetBendAreas() ) {

			# Draw surface from pin areas
			foreach my $pinGuid ( $bendArea->GetPinsGUID() ) {

				my @envelop = $bendArea->GetPinEnvelop($pinGuid);

				CamSymbolSurf->AddSurfacePolyline( $inCAM, \@envelop, undef, "negative" );
			}
		}

		# 2) Add register pad
		foreach my $f ( $pinParser->GetRegisterPads() ) {

			CamSymbol->AddPad( $inCAM, "r" . ( $CUREGPADSIZE * 1000 ), { "x" => $f->{"x1"}, "y" => $f->{"y1"} } );
		}

		# 3) Add solder lines
		foreach my $f ( $pinParser->GetSolderLines() ) {

			CamSymbol->AddLine( $inCAM, { "x" => $f->{"x1"}, "y" => $f->{"y1"} }, { "x" => $f->{"x2"}, "y" => $f->{"y2"} }, "r300", "positive" );
		}

		# 4) Add Cu square, where coverlay is cutted by scissors. Border of square are lines PinString_CUTLINE + PinString_ENDLINE
		my $lTmp = GeneralHelper->GetGUID();
		CamMatrix->CreateLayer( $inCAM, $jobId, $lTmp, "document", "positive", 0 );
		CamLayer->WorkLayer( $inCAM, $lTmp );
		my @features = ( $pinParser->GetCutLines(), $pinParser->GetEndLines() );

		my $cuSquareOverlap = 2;

		foreach my $bendArea ( $pinParser->GetBendAreas() ) {

			# Draw surface from pin areas
			foreach my $pinGuid ( $bendArea->GetPinsGUID() ) {

				my @lines =
				  grep { $_->{"att"}->{"feat_group_id"} eq $pinGuid } @features;

				my @line1 = LineTransform->ParallelSegmentLine( { "x" => $lines[0]->{"x1"}, "y" => $lines[0]->{"y1"} },
																{ "x" => $lines[0]->{"x2"}, "y" => $lines[0]->{"y2"} },
																$cuSquareOverlap, "left" );
				my @line2 = LineTransform->ParallelSegmentLine( { "x" => $lines[1]->{"x1"}, "y" => $lines[1]->{"y1"} },
																{ "x" => $lines[1]->{"x2"}, "y" => $lines[1]->{"y2"} },
																$cuSquareOverlap, "right" );

				my @points = ();

				push( @points, { "x" => $line1[0]->{"x"}, "y" => $line1[0]->{"y"} } );
				push( @points, { "x" => $line1[1]->{"x"}, "y" => $line1[1]->{"y"} } );
				push( @points, { "x" => $line2[1]->{"x"}, "y" => $line2[1]->{"y"} } );
				push( @points, { "x" => $line2[0]->{"x"}, "y" => $line2[0]->{"y"} } );

				CamSymbolSurf->AddSurfacePolyline( $inCAM, \@points );
			}
		}

		$inCAM->COM( "sel_resize", "size" => 2 * $cuSquareOverlap * 1000, "corner_ctl" => "no" );    # Resize Cu square 1000µm

		CamLayer->ClipAreaByProf( $inCAM, $lTmp, 200, 1 );                                           # 200µm min distance cu from profile
		CamLayer->WorkLayer( $inCAM, $lTmp );

		CamLayer->CopySelOtherLayer( $inCAM, \@layers );

		CamSymbol->ResetCurAttributes($inCAM);

		CamLayer->DisplayLayers( $inCAM, \@layers );

		CamMatrix->DeleteLayer( $inCAM, $jobId, $lTmp );

		$inCAM->PAUSE("Zkontroluj vytvorene znacky ve vnitrnich signalovych vrstvach.");
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::Flex::DoCoverlayPins';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';

	my $inCAM = InCAM->new();

	my $jobId = "d222769";

	my $notClose = 0;

	my $res = DoCoverlayPins->CreateCoverlayPins( $inCAM, $jobId, "o+1" );

}

1;

