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
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamSymbolSurf';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Packages::Polygon::Line::LineTransform';
use aliased 'Packages::Polygon::Line::SegmentLineIntersection';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAM::FeatureFilter::Enums'                     => 'EnumsFiltr';
use aliased 'Packages::CAMJob::FlexiLayers::CoverlayPinParser::Enums' => 'PinEnums';
use aliased 'Packages::CAMJob::FlexiLayers::CoverlayPinParser::CoverlayPinParser';
use aliased 'Packages::CAMJob::FlexiLayers::BendAreaParser::BendAreaParser';
use aliased 'Packages::CAMJob::FlexiLayers::BendAreaParser::Enums' => "BendEnums";
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveLine';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveArcSCE';
use aliased 'Packages::CAM::SymbolDrawing::Point';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

my $OPTIMALPINLENGTH   = 11;      # 11mm
my $OPTIMALPINOUTWIDTH = 2.5;     # 2.5mm (holder type IN)
my $OPTIMALPININWIDTH  = 8.5;     # 6.5mm (holder type OUT)
my $PINREGISTERDIST    = 3.25;    # 3.25mm from flex part
my $PINSOLDDIST1       = 0.5;     # 0.5mm from flex part
my $PINCUTDIST2        = 6;       # 6mm from flex part
my $CUREGPADSIZE       = 1.2;     # 1.2mm pad in signal flex layers

#	PinString_REGISTER   => "pin_register",      # pad which is used for register coverlay with flex core
#	PinString_SOLDERLINE => "pin_solderline",    # between PinString_SOLDERPIN and PinString_CUTPIN lines is place for soldering
#	PinString_CUTLINE    => "pin_cutline",       # this line marks the area where coverlaz pin should be cutted
#	PinString_ENDLINE    => "pin_endline",       # line marks end border of pin
#	PinString_SIDELINE   => "pin_sideline",      # lines mark side border of pin
#	PinString_BENDLINE   => "pin_bendline"       # lines marks border of bend area

# Pin types
my $PINT_HOLDEROUT_REGPAD = "HOLDER OUT + REGISTER PAD";
my $PINT_HOLDEROUT        = "HOLDER IN only";
my $PINT_REGPAD           = "REGISTER PAD only";

my @messHead = ();
push( @messHead, "<b>=======================================================</b>" );
push( @messHead, "<b>Pr??vodce vytvo??en??m coverlay pin??. Vrstva: coverlaypins</b>" );
push( @messHead, "<b>=======================================================</b> \n" );

# Set impedance lines
sub CreateCoverlayPins {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;

	my $result = 1;

	my $messMngr = MessageMngr->new($jobId);

	my $lName = "cvrlpins";

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
	push( @mess, "Vrstva \"$lName\" ji?? existuje, chce?? ji vytvo??it znovu?" );

	if ( CamHelper->LayerExists( $inCAM, $jobId, $lName ) ) {

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess, [ "Ne", "Ano, vytvo??it" ] );

		$createLayer = 0 if ( $messMngr->Result() == 0 );
	}

	# 1) Create default coverlay pin layer without pins

	if ($createLayer) {

		my @mess = (@messHead);
		push( @mess, "Vrstva s obrysem ohebn?? ????sti PCB \"bend\" mus?? existovat. Vytvo?? ji" );

		while ( !CamHelper->LayerExists( $inCAM, $jobId, "bend" ) ) {
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess, [ "Konec", "Vytvo????m" ] );

			return 0 if ( $messMngr->Result() == 0 );
		}

		my $errMess = "";

		my $parser = BendAreaParser->new( $inCAM, $jobId, $step );

		while ( !$parser->CheckBendArea( \$errMess ) ) {

			my @mess = (@messHead);
			push( @mess, "Vrstva \"bend\" nen?? spr??vn?? p??ipraven??", "Detail chyby:", $errMess );

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess, [ "Konec", "Oprav??m" ] );

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
				$p = PrimitiveArcSCE->new( Point->new( $f->{"x1"}, $f->{"y1"} ),
										   Point->new( $f->{"xmid"}, $f->{"ymid"} ),
										   Point->new( $f->{"x2"},   $f->{"y2"} ),
										   $f->{"oriDir"}, $f->{"symbol"} );
			}
			else {

				die "Not supported feature type: " . $f->{"type"};
			}

			#$p->AddAttribute( ".string", $f->{"att"}->{".string"} );
			$p->AddAttribute("transition_zone") if ( defined $f->{"att"}->{"transition_zone"} );

			$draw->AddPrimitive($p);

		}
		CamLayer->WorkLayer( $inCAM, $lName );
		$draw->Draw();

		# 2) Check default preprepared coverlaypin layer by user
		my $skipMess = 0;
		while (1) {

			my @rules = ();
			push( @rules, "<b>Pravidla pro jednotliv?? coverlay ????sti + piny:</b>" );
			push( @rules, " - Ka??d?? coverlay ????st by m??la m??t alespo?? 2 k??id??lka" );
			push( @rules, " - Ka??d?? coverlay ????st by m??la m??t alespo?? 2 registra??n?? pady" );
			push( @rules, " - Na ka??d??ch 40mm coverlay ????sti vlo??it 1 k??id??lko + 1 registra??n?? pad" );
			push( @rules,
				      " - Registra??n?? pady vkl??dat rovnom??rn?? a co nejbl????e flexibiln?? ????sti, nejbl????e v??ak:"
					. ( $PINREGISTERDIST - $CUREGPADSIZE / 2 )
					. "mm" );
			push( @rules, "" );
			push( @rules, "<b>Pravidla pro slu??ov??n?? coverlay ????sti:</b>" );
			push( @rules, " - ????m m??n?? je coverlay ????st?? na DPS, t??m je rychlej???? a snadn??j???? v??roba" );
			push( @rules, " - Slou??it pokud to tvar DPS umo????uje a z??rove?? slou??en??m ????st?? neztrat??m vyu??it?? panelu" );
			push( @rules, " - Pravidla pro vkl??d??n?? k??id??lek a registra??n??ch pad?? se nem??n??" );
			push( @rules, "" );
			push( @rules, "<b>Pravidla pro v??b??r typu pin??:</b>" );
			push( @rules, " - Pro samostatn?? coverlay ????sti pou????t piny typu..." );
			push( @rules, " - Pro slou??en?? coverlay ????sti pou????t piny typu..." );

			# First part of layer preparing
			my @mess1 = (@messHead);
			push( @mess1, "??prava tvaru coverlay ????st?? + vkl??d??n?? pin??:" );
			push( @mess1, "=========================================\n" );
			push( @mess1, "<g>Nyn?? je t??eba upravit tvar vyfr??zovan??ch coverlay ????st??. podle pravidel:</g>\n" );
			push( @mess1, @rules );

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess1 ) unless ($skipMess);
			$inCAM->PAUSE("Uprav coverlay casti podle pravidel.");

			# Second part of layer preparing

			my @mess2 = (@messHead);
			push( @mess2, "??prava tvaru coverlay ????st?? + vkl??d??n?? pin??:" );
			push( @mess2, "=========================================\n" );
			push( @mess2, "<g>Jsou coverlay ????sti p??ipraveny podle pravidel?</g>\n" );
			push( @mess2, @rules );

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess2, [ "Ne, je??t?? uprav??m", "Ano, vlo??it piny" ] );

			my $reply = $messMngr->Result();

			if ( $messMngr->Result() == 0 ) {

				$skipMess = 1;
			}
			elsif ( $messMngr->Result() == 1 ) {
				last;
			}
		}

		# Set bend line attribute to all features (so far there are no pins)
		CamAttributes->SetFeaturesAttribute( $inCAM, $jobId, ".string", PinEnums->PinString_BENDLINE );

		# 3) Put pins

		my $nextPin = 1;
		while ($nextPin) {

			my $pinCreated = 0;

			CamLayer->WorkLayer( $inCAM, $lName );
			my @mess = (@messHead);
			push( @mess, "Vyber typ pinu, kter?? chce?? vlo??it:" );
			push( @mess, " - <b>$PINT_HOLDEROUT_REGPAD</b> = k??id??lko vn?? coverlay ????sti + registra??n?? pad uvnit?? k??id??lka" );
			push( @mess, " - <b>$PINT_HOLDEROUT</b> = k??id??lko uvnit?? coverlay ????sti bez registra??n??ho pinu" );
			push( @mess, " - <b>$PINT_REGPAD</b> = pouze registra??n?? pad" );

			my @option = ( $PINT_HOLDEROUT_REGPAD, $PINT_HOLDEROUT, $PINT_REGPAD );
			my $aPinType = $messMngr->GetOptionParameter( "Typ pinu", $option[0], \@option );

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess, undef, undef, [$aPinType] );

			if ( $aPinType->GetResultValue(1) eq $PINT_HOLDEROUT_REGPAD ) {
				$pinCreated = $self->__CreatePin_HOLDEROUT( $inCAM, $jobId, $step, 1, $messMngr );
			}
			elsif ( $aPinType->GetResultValue(1) eq $PINT_HOLDEROUT ) {
				$pinCreated = $self->__CreatePin_HOLDERIN( $inCAM, $jobId, $step, 0, $messMngr );
			}
			elsif ( $aPinType->GetResultValue(1) eq $PINT_REGPAD ) {
				$pinCreated = $self->__CreatePin_REGPAD( $inCAM, $jobId, $step, $messMngr );
			}

			# In case edit coverlay shape (add new line/arc) add attribut bend line to this line
			my $f = FeatureFilter->new( $inCAM, $jobId, $lName );
			$f->AddExcludeAtt(".string");
			if ( $f->Select() ) {
				CamAttributes->SetFeaturesAttribute( $inCAM, $jobId, ".string", PinEnums->PinString_BENDLINE );
			}
			
			my @mess1 = (@messHead);
			push( @mess1, "Vytvo??it dal???? pin?" );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess1, [ "Ano, vyvto??it dal???? pin", "Hotovo" ] );

			if ( $messMngr->Result() == 1 ) {
				last;
			}
		}
	}

	# Put pin marks to copper layers
	if ($putPinMarks) {

		$self->__PutPinMarks( $inCAM, $jobId, $step, $messMngr );

	}
}

sub __CreatePin_HOLDEROUT {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $step        = shift;
	my $registerPad = shift;

	my $messMngr = shift;

	my $result = 1;

	my $lName = "cvrlpins";

	CamLayer->WorkLayer( $inCAM, $lName );

	#$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, ["Ozna?? lajnu, kde si p??eje?? vytvo??it coverlay pin"] );
	$inCAM->PAUSE("Oznac lajnu kde bude vytvoren OUTER pin");

	while ( !CamLayer->GetSelFeaturesCnt($inCAM) ) {

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["Nen?? ozna??en?? ????dn?? lajna"] );

		$inCAM->PAUSE("Oznac lajnu kde bude vytvoren OUTER pin");
	}

	my $f = Features->new();

	#$f->Parse( $inCAM, $jobId, $step, $lName, 0, 0 );

	$f->Parse( $inCAM, $jobId, $step, $lName, 0, 1 );

	my $selLineId = ( $f->GetFeatures() )[0]->{"id"};

	my $pinParser = CoverlayPinParser->new( $inCAM, $jobId, $step, "CW" );
	my $selLine   = $pinParser->GetBendAreaLineByLineId($selLineId);
	my $maxPinLen = $self->__GetPinLBendEdge2ProfLim( $inCAM, $jobId, $step, $selLine );

	my @mess = (@messHead);
	push( @mess, "Tvar OUTER pinu:" );
	push( @mess, "=========================================\n" );
	push( @mess, " <b>Navrhnut?? d??lka:</b>" );
	push( @mess, " - a) Vlastn??" );
	push( @mess, " - b) D??lka podle profilu: " . sprintf( "%.1f", $maxPinLen ) . "mm" );
	push( @mess, " - c) Optim??ln?? d??lka: " . $OPTIMALPINLENGTH . "mm" );

	if ( $maxPinLen < $OPTIMALPINLENGTH ) {

		push( @mess,
			  "\n<r>Pozor d??lka podle profilu je men???? ne?? doporu??en??. Pokud vybere?? doporu??enou, rozestupy mezi DPS mus?? b??t alespo??: "
				. sprintf( "%.1f", 4.5 + 2 * ( $OPTIMALPINLENGTH - $maxPinLen ) )
				. "mm</r>" );
	}

	push( @mess, "" );
	push( @mess, " <b> Navrhnut?? ??????ka </b> (nezapome??, ??e u coverlay se k ??????ce pinu p??ipo??te p??esah coverlay do rigid ????sti):" );
	push( @mess, " - $OPTIMALPINOUTWIDTH mm" );
	push( @mess, "" );
	push( @mess, " Zvol jednu z mo??nost?? pop????pad?? uprav ??????ku pinu." );

	my @params          = ();
	my $parCustPinLen   = $messMngr->GetTextParameter( "Vlastn?? d??lka pinu [mm]", $OPTIMALPINLENGTH );
	my $parCustPinWidth = $messMngr->GetTextParameter( "??????ka pinu [mm]", $OPTIMALPINOUTWIDTH );

	push( @params, $parCustPinLen, $parCustPinWidth );

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION,
						  \@mess, [ "Znovu vytvo??it pin", "a) Vlastn?? d??lka", "b) D??lka podle profilu", "c) Optim??ln?? d??lka" ],
						  undef, \@params );

	my $reply = $messMngr->Result();

	if ( $reply == 0 ) {

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

			$len = $maxPinLen;

		}
		elsif ( $reply == 3 ) {

			$len = $OPTIMALPINLENGTH;
		}

		my $width = $parCustPinWidth->GetValueChanged() ? $parCustPinWidth->GetResultValue() : $OPTIMALPINOUTWIDTH;

		my %pinGeometry = $self->__GetPinGeometry( $selLine, $len, $width, PinEnums->PinHolder_OUT );

		$self->__DrawPin( $inCAM, $jobId, PinEnums->PinHolder_OUT, \%pinGeometry );

		@mess = (@messHead);
		push( @mess, "Kontrola pinu" );
		push( @mess, "--------------\n" );
		push( @mess, "Je coverlay pin OK? Zkontroluj:\n" );
		push( @mess, "- d??lku pinu vzhledem k profilu" );
		push( @mess, "- pozici pinu, zda nezasahuje do desky" );
		push( @mess, "- ide??ln?? um??st??n?? pinu je st??edu hrany (z obou stran) pru??n?? ????sti ????sti" );

		if ( $len > $maxPinLen ) {
			push( @mess,
				      "\n<r>Pozor pin bude zasahovat mimo desku. Nastav v panelu rozestupy mezi DPS alespo??: "
					. sprintf( "%.1f", 4.5 + 2 * ( $len - $maxPinLen ) )
					. "mm</r>" );
		}

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess );

		$inCAM->PAUSE("Zkontroluj popripade upravi tvar pinu");

		@mess = (@messHead);

		push( @mess, "Pin je OK?" );

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess, [ "Ne, vytvo??it pin znovu", "Ano" ] );

		if ( $messMngr->Result() == 0 ) {

			CamLayer->WorkLayer( $inCAM, $lName );
			$result = 0;

		}
		elsif ( $messMngr->Result() == 1 ) {

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

sub __CreatePin_HOLDERIN {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $step        = shift;
	my $registerPad = shift;
	my $messMngr    = shift;

	my $result = 1;

	my $lName = "cvrlpins";

	CamLayer->WorkLayer( $inCAM, $lName );

	#$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, ["Ozna?? lajnu, kde si p??eje?? vytvo??it coverlay pin"] );
	$inCAM->PAUSE("Oznac lajnu kde bude vytvoren INNER pin");

	while ( !CamLayer->GetSelFeaturesCnt($inCAM) ) {

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["Nen?? ozna??en?? ????dn?? lajna"] );

		$inCAM->PAUSE("Oznac lajnu kde bude vytvoren INNER pin");
	}

	my $f = Features->new();

	#$f->Parse( $inCAM, $jobId, $step, $lName, 0, 0 );

	$f->Parse( $inCAM, $jobId, $step, $lName, 0, 1 );

	my $selLineId = ( $f->GetFeatures() )[0]->{"id"};

	my $pinParser      = CoverlayPinParser->new( $inCAM, $jobId, $step, "CW" );
	my $selLine        = $pinParser->GetBendAreaLineByLineId($selLineId);
	my $bendAreaParser = BendAreaParser->new( $inCAM, $jobId, $step, "CW" );
	my @bendAreas      = $bendAreaParser->GetBendAreas();

	my $maxPinLen = $self->__GetPinLCvrlEdge2BendEdge( $inCAM, $jobId, $step, $selLine, \@bendAreas );

	my @mess = (@messHead);
	push( @mess, "Tvar INNER pinu:" );
	push( @mess, "=========================================\n" );
	push( @mess, " D??lka:" );
	push( @mess, " - Maxim??ln?? omezen?? flexi ????stmi: " . ( defined $maxPinLen ? sprintf( "%.1fmm", $maxPinLen ) : "nedefinov??no" ) );
	push( @mess, " - Optim??ln??: " . $OPTIMALPINLENGTH . "mm" );

	if ( defined $maxPinLen && $maxPinLen < $OPTIMALPINLENGTH ) {
		push( @mess,
			      "\n<r>Pozor maxim??ln?? d??lka pinu omezen?? flexi ????stmi je men???? ne?? doporu??en??."
				. " Zva?? jin?? um??st??n?? pinu nebo roz??????en?? coverlay ????sti." );
	}

	push( @mess, " Zvol jednu z mo??nost?? pop????pad?? uprav parametry pinu." );

	my @params          = ();
	my $parCustPinLen   = $messMngr->GetTextParameter( "D??lka pinu [mm]", $OPTIMALPINLENGTH );
	my $parCustPinWidth = $messMngr->GetTextParameter( "??????ka pinu [mm]", $OPTIMALPININWIDTH );

	push( @params, $parCustPinLen, $parCustPinWidth );

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess, [ "Za????t znovu vytv????et pin", "Ok, pokra??ovat" ], undef, \@params );

	my $reply = $messMngr->Result();

	if ( $reply == 0 ) {

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

		my $len = $parCustPinLen->GetResultValue(1);
		my $width = $parCustPinWidth->GetValueChanged() ? $parCustPinWidth->GetResultValue() : $OPTIMALPININWIDTH;

		my %pinGeometry = $self->__GetPinGeometry( $selLine, $len, $width, PinEnums->PinHolder_IN );

		unless ($registerPad) {
			$pinGeometry{"pinRegister"}    = undef;
			$pinGeometry{"pinSolderLines"} = undef;
		}

		$self->__DrawPin( $inCAM, $jobId, PinEnums->PinHolder_IN, \%pinGeometry );

		@mess = (@messHead);
		push( @mess, "Kontrola pinu" );
		push( @mess, "-----------------\n" );
		push( @mess, "Je coverlay pin OK? Zkontroluj:\n" );
		push( @mess, "- d??lku pinu vzhledem k profilu" );
		push( @mess, "- pozici pinu a d??lku, zda nezasahuje do desky" );
		push( @mess, "- ide??ln?? um??st??n?? pinu je rovnom??rn?? po obvod?? coverlay ????sti" );

		if ( defined $maxPinLen && $len > $maxPinLen ) {
			push( @mess, "\n<r>Pozor pin zasahuje do desky. Uprav tvar/pozici pinu" );
		}

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess );

		$inCAM->PAUSE("Zkontroluj popripade upravi tvar pinu");

		@mess = (@messHead);

		push( @mess, "Pin je OK?" );

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess, [ "Ne, vytvo??it pin znovu", "Ano" ] );

		if ( $messMngr->Result() == 0 ) {

			CamLayer->WorkLayer( $inCAM, $lName );
			$result = 0;

		}
		elsif ( $messMngr->Result() == 1 ) {

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

sub __CreatePin_REGPAD {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $messMngr = shift;

	my $result = 1;

	my $lName = "cvrlpins";

	# Prepare working layer
	my $workLayer = GeneralHelper->GetGUID();
	CamMatrix->CreateLayer( $inCAM, $jobId, $workLayer, "document", "positive", 0 );
	CamLayer->WorkLayer( $inCAM, $lName );
	CamLayer->CopySelOtherLayer( $inCAM, [$workLayer] );

	# Preparing of helper register pad layer
	my $padLayer = "register_pads";
	CamMatrix->DeleteLayer( $inCAM, $jobId, $padLayer );
	CamMatrix->CreateLayer( $inCAM, $jobId, $padLayer, "document", "positive", 0 );
	my $parser = BendAreaParser->new( $inCAM, $jobId, $step, "CW" );
	my @bendAreas = $parser->GetBendAreas();

	CamLayer->WorkLayer( $inCAM, $padLayer );

	foreach my $bendFeat ( grep { $_->{"att"}->{ BendEnums->BendArea_TRANZONEATT } } map { $_->GetFeatures() } @bendAreas ) {

		my $bendLP1 = { "x" => $bendFeat->{"x1"}, "y" => $bendFeat->{"y1"} };
		my $bendLP2 = { "x" => $bendFeat->{"x2"}, "y" => $bendFeat->{"y2"} };

		my @prlLine = LineTransform->ParallelSegmentLine( $bendLP1, $bendLP2, $PINREGISTERDIST, "left" );

		CamSymbol->AddLine( $inCAM, $prlLine[0], $prlLine[1], "r10", "positive" );
		my $padCnt = 1;    # pad cnt per line
		for ( my $i = 0 ; $i < $padCnt ; $i++ ) {
			my $l =
			  sqrt( ( $prlLine[0]->{"x"} - $prlLine[1]->{"x"} )**2 + ( $prlLine[0]->{"y"} - $prlLine[1]->{"y"} )**2 );
			my $dist = $l / ( $padCnt + 1 ) * ( $i + 1 );

			my $endP = LineTransform->ExtendSegmentLine( $prlLine[0], $prlLine[1], -$dist );

			CamSymbol->AddPad( $inCAM, "r" . ( $CUREGPADSIZE * 1000 ), $endP );
		}
	}

	CamLayer->DisplayLayers( $inCAM, [ "bend", $lName, $padLayer ] );
	$inCAM->COM( 'work_layer', name => $padLayer );

	my @mess = (@messHead);
	push( @mess, "Vlo??en?? register pad??" );
	push( @mess, "-----------------\n" );
	push( @mess, "<b>Pravidla pro vkl??d??n?? register pad??:</b>\n" );
	push( @mess, " - Ka??d?? coverlay ????st by m??la m??t alespo?? 2 registra??n?? pady" );
	push( @mess, " - Na ka??d??ch 40mm coverlay ????sti vlo??it  registra??n?? pad" );
	push( @mess,
		      " - Registra??n?? pady vkl??dat rovnom??rn?? a co nejbl????e flexibiln?? ????sti, nejbl????e v??ak:"
			. ( $PINREGISTERDIST - $CUREGPADSIZE / 2 )
			. "mm" );
	push( @mess, "" );
	push( @mess, "<b>Jak vlo??it register pady:</b>" );
	push( @mess, "- a) ozna??it navrhovan?? pad(y) v pomocn?? vrsvt?? 'register_pads'" );
	push( @mess, "- b) vlo??it a ozna??it pad r" . ( $CUREGPADSIZE * 1000 ) . "??m ru??n?? v pomocn?? vrsvt?? 'register_pads'" );

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess );

	$inCAM->PAUSE( "Oznac/vloz pady registracni pady: r" . ( $CUREGPADSIZE * 1000 ) );

	my $padsOk   = 0;
	my $f        = Features->new();
	my @features = ();
	while ( !$padsOk ) {

		$f->Parse( $inCAM, $jobId, $step, $padLayer, 0, 1 );
		@features = grep { $_->{"symbol"} eq "r" . ( $CUREGPADSIZE * 1000 ) } $f->GetFeatures();

		if ( scalar(@features) ) {
			last;
		}

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, [ "Nejsou ozna??en?? ????dn?? pady: r" . ( $CUREGPADSIZE * 1000 ) ] );
		$inCAM->PAUSE( "Oznac/vloz pady registracni pady: r" . ( $CUREGPADSIZE * 1000 ) );
	}

	CamLayer->WorkLayer( $inCAM, $workLayer );

	foreach my $f (@features) {

		my %pinGeometry = ();
		$pinGeometry{"pinRegister"}->{"x"} = $f->{"x1"};
		$pinGeometry{"pinRegister"}->{"y"} = $f->{"y1"};

		$self->__DrawPin( $inCAM, $jobId, undef, \%pinGeometry );

	}

	my @mess2 = (@messHead);
	push( @mess2, "Kontrola pinu" );
	push( @mess2, "-----------------\n" );
	push( @mess2, "<g>Po??et vybran??ch registr pad??: " . scalar(@features) . ". Zkontroluj zda jsou pady v po????dku?</g>\n" );
	push( @mess2, "<b>Pravidla pro vkl??d??n?? register pad??:</b>\n" );
	push( @mess2, " - Ka??d?? coverlay ????st by m??la m??t alespo?? 2 registra??n?? pady" );
	push( @mess2, " - Na ka??d??ch 40mm coverlay ????sti vlo??it  registra??n?? pad" );
	push( @mess2,
		      " - Registra??n?? pady vkl??dat rovnom??rn?? a co nejbl????e flexibiln?? ????sti, nejbl????e v??ak:"
			. ( $PINREGISTERDIST - $CUREGPADSIZE / 2 )
			. "mm" );

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess2 );

	$inCAM->PAUSE("Zkontroluj popripade upravi umisteni register padu");

	my @mess3 = (@messHead);
	push( @mess3, "Jsou registr pady v po????dku?" );

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess3, [ "Za????t znovu vytv????et pin", "Ok, dokon??it pin" ] );

	my $reply = $messMngr->Result();

	if ( $messMngr->Result() == 0 ) {

		CamLayer->WorkLayer( $inCAM, $lName );
		$result = 0;

	}
	elsif ( $messMngr->Result() == 1 ) {

		CamLayer->WorkLayer( $inCAM, $lName );
		$inCAM->COM("sel_clear_feat");
		CamLayer->DeleteFeatures($inCAM);
		CamLayer->WorkLayer( $inCAM, $workLayer );
		CamLayer->CopySelOtherLayer( $inCAM, [$lName] );

	}

	CamLayer->WorkLayer( $inCAM, $lName );
	CamMatrix->DeleteLayer( $inCAM, $jobId, $workLayer );

	return $result;
}

sub __DrawPin {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $type        = shift;
	my %pinGeometry = %{ shift(@_) };

	CamSymbol->ResetCurAttributes($inCAM);

	CamSymbol->AddCurAttribute( $inCAM, $jobId, "feat_group_id", GeneralHelper->GetGUID() );

	# Add pin side lines
	if ( defined $pinGeometry{"pinSideLines1"} ) {
		for ( my $i = 0 ; $i < scalar( @{ $pinGeometry{"pinSideLines1"} } ) ; $i++ ) {
			CamSymbol->AddCurAttribute( $inCAM, $jobId, ".string", PinEnums->PinString_SIDELINE1 );
			CamSymbol->AddLine( $inCAM, $pinGeometry{"pinSideLines1"}->[$i][0], $pinGeometry{"pinSideLines1"}->[$i][1], "s400", "positive" );
		}
	}

	# Add pin side lines
	if ( defined $pinGeometry{"pinSideLines2"} ) {
		for ( my $i = 0 ; $i < scalar( @{ $pinGeometry{"pinSideLines2"} } ) ; $i++ ) {
			CamSymbol->AddCurAttribute( $inCAM, $jobId, ".string", PinEnums->PinString_SIDELINE2 );
			CamSymbol->AddLine( $inCAM, $pinGeometry{"pinSideLines2"}->[$i][0], $pinGeometry{"pinSideLines2"}->[$i][1], "s400", "positive" );
		}
	}

	# Add pin end line
	if ( defined $pinGeometry{"pinEndLine"} ) {
		if ( $type eq PinEnums->PinHolder_OUT ) {
			CamSymbol->AddCurAttribute( $inCAM, $jobId, ".string", PinEnums->PinString_ENDLINEOUT );

		}
		elsif ( $type eq PinEnums->PinHolder_IN ) {
			CamSymbol->AddCurAttribute( $inCAM, $jobId, ".string", PinEnums->PinString_ENDLINEIN );
		}
		CamSymbol->AddLine( $inCAM, $pinGeometry{"pinEndLine"}->[0], $pinGeometry{"pinEndLine"}->[1], "s400", "positive" );
	}

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

}

# Holder type OUT
#      | F  A|
#  ----| L  R|
# | pin  E  E|
#  ----| X  A|
#      | I   |
#
# Holder type IN
#  |       F  A|
#  |----   L  R|
#   pin |  E  E|
#  |----   X  A|
#  |       I   |
sub __GetPinGeometry {
	my $self      = shift;
	my $selLine   = shift;
	my $pinLength = shift;
	my $pinWidth  = shift;
	my $type      = shift;

	my $midX = ( $selLine->{"x1"} + $selLine->{"x2"} ) / 2;
	my $midY = ( $selLine->{"y1"} + $selLine->{"y2"} ) / 2;

	my %endP = LineTransform->GetVerticalSegmentLine( { "x" => $midX, "y" => $midY },
													  { "x" => $selLine->{"x2"}, "y" => $selLine->{"y2"} },
													  $pinLength, ( $type eq PinEnums->PinHolder_OUT ? "left" : "right" ) );

	my $pinLineP1 = { "x" => $midX, "y" => $midY };
	my $pinLineP2 = { "x" => $endP{"x"}, "y" => $endP{"y"} };

	my @sideLine2L =
	  LineTransform->ParallelSegmentLine( $pinLineP1, $pinLineP2, $pinWidth / 2, ( $type eq PinEnums->PinHolder_OUT ? "left" : "right" ) );
	my @sideLine2R =
	  LineTransform->ParallelSegmentLine( $pinLineP1, $pinLineP2, $pinWidth / 2, ( $type eq PinEnums->PinHolder_OUT ? "right" : "left" ) );

	my @sideLine1L = ( { "x" => $selLine->{"x1"}, "y" => $selLine->{"y1"} }, { "x" => $sideLine2L[0]->{"x"}, "y" => $sideLine2L[0]->{"y"} } );
	my @sideLine1R = ( { "x" => $selLine->{"x2"}, "y" => $selLine->{"y2"} }, { "x" => $sideLine2R[0]->{"x"}, "y" => $sideLine2R[0]->{"y"} } );

	my @line3 =
	  ( { "x" => $sideLine2L[1]->{"x"}, "y" => $sideLine2L[1]->{"y"} }, { "x" => $sideLine2R[1]->{"x"}, "y" => $sideLine2R[1]->{"y"} } );

	my %res = ();
	$res{"pinSideLines1"} = [ \@sideLine1L, \@sideLine1R ];
	$res{"pinSideLines2"} = [ \@sideLine2L, \@sideLine2R, ];
	$res{"pinEndLine"}    = \@line3;

	if ( $pinLength > $PINREGISTERDIST ) {
		my %regP =
		  LineTransform->GetVerticalSegmentLine( { "x" => $midX, "y" => $midY },
												 { "x" => $selLine->{"x2"}, "y" => $selLine->{"y2"} },
												 $PINREGISTERDIST, ( $type eq PinEnums->PinHolder_OUT ? "left" : "right" ) );
		$res{"pinRegister"} = \%regP;
	}

	if ( $pinLength > $PINSOLDDIST1 ) {

		my @cutLine1 = LineTransform->ParallelSegmentLine(
														   { "x" => $sideLine2L[0]->{"x"}, "y" => $sideLine2L[0]->{"y"} },
														   { "x" => $sideLine2R[0]->{"x"}, "y" => $sideLine2R[0]->{"y"} },
														   $PINSOLDDIST1,
														   ( $type eq PinEnums->PinHolder_OUT ? "left" : "right" )
		);
		$res{"pinSolderLines"} = \@cutLine1;
	}

	if ( $pinLength > $PINCUTDIST2 ) {

		my @cutLine2 = LineTransform->ParallelSegmentLine(
														   { "x" => $sideLine2L[0]->{"x"}, "y" => $sideLine2L[0]->{"y"} },
														   { "x" => $sideLine2R[0]->{"x"}, "y" => $sideLine2R[0]->{"y"} },
														   $PINCUTDIST2,
														   ( $type eq PinEnums->PinHolder_OUT ? "left" : "right" )
		);
		$res{"pinCutLines"} = \@cutLine2;
	}

	return %res;
}

sub __GetPinLBendEdge2ProfLim {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $selLine = shift;

	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );

	my @pointsLim = ();

	push( @pointsLim, { "x" => $lim{"xMin"}, "y" => $lim{"yMin"} } );
	push( @pointsLim, { "x" => $lim{"xMin"}, "y" => $lim{"yMax"} } );
	push( @pointsLim, { "x" => $lim{"xMax"}, "y" => $lim{"yMax"} } );
	push( @pointsLim, { "x" => $lim{"xMax"}, "y" => $lim{"yMin"} } );

	my $midX = ( $selLine->{"x1"} + $selLine->{"x2"} ) / 2;
	my $midY = ( $selLine->{"y1"} + $selLine->{"y2"} ) / 2;

	my %endP =
	  LineTransform->GetVerticalSegmentLine( { "x" => $midX, "y" => $midY }, { "x" => $selLine->{"x2"}, "y" => $selLine->{"y2"} }, 200 );

	my $pinLineP1 = { "x" => $midX, "y" => $midY };
	my $pinLineP2 = { "x" => $endP{"x"}, "y" => $endP{"y"} };

	# find maximal verticall distance from bend border to pcb profile

	my $distMin  = undef;
	my $distMinX = undef;
	my $distMinY = undef;

	for ( my $i = 0 ; $i < 4 ; $i++ ) {

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

sub __GetPinLCvrlEdge2BendEdge {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $selLine   = shift;
	my $bendAreas = shift;

	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );

	my @pointsLim = ();

	push( @pointsLim, { "x" => $lim{"xMin"}, "y" => $lim{"yMin"} } );
	push( @pointsLim, { "x" => $lim{"xMin"}, "y" => $lim{"yMax"} } );
	push( @pointsLim, { "x" => $lim{"xMax"}, "y" => $lim{"yMax"} } );
	push( @pointsLim, { "x" => $lim{"xMax"}, "y" => $lim{"yMin"} } );

	my $midX = ( $selLine->{"x1"} + $selLine->{"x2"} ) / 2;
	my $midY = ( $selLine->{"y1"} + $selLine->{"y2"} ) / 2;

	my %endP =
	  LineTransform->GetVerticalSegmentLine( { "x" => $midX, "y" => $midY }, { "x" => $selLine->{"x2"}, "y" => $selLine->{"y2"} }, 1000, "right" );

	my $pinLineP1 = { "x" => $midX, "y" => $midY };
	my $pinLineP2 = { "x" => $endP{"x"}, "y" => $endP{"y"} };

	# find maximal verticall distance from coverlay border to bend border

	my $maxLen = undef;

	#my $distMinX = undef;
	#my $distMinY = undef;

	foreach my $bendArea ( @{$bendAreas} ) {

		foreach my $bendLine ( grep { $_->{"type"} eq "L" } $bendArea->GetFeatures() ) {

			my $bendP1 = { "x" => $bendLine->{"x1"}, "y" => $bendLine->{"y1"} };
			my $bendP2 = { "x" => $bendLine->{"x2"}, "y" => $bendLine->{"y2"} };

			my $isIntersec = SegmentLineIntersection->SegLineIntersection( $pinLineP1, $pinLineP2, $bendP1, $bendP2 );

			if ( $isIntersec == 1 ) {

				my %pIntersect = SegmentLineIntersection->GetLineIntersection( $pinLineP1, $pinLineP2, $bendP1, $bendP2 );

				my $l = sqrt( ( $pIntersect{"x"} - $midX )**2 + ( $midY - $pIntersect{"y"} )**2 );
				if ( ( !defined $maxLen || $l < $maxLen ) ) {
					$maxLen = $l;

					#$distMinX = $pIntersect{"x"};
					#$distMinY = $pIntersect{"y"};

				}
			}
		}
	}

	return $maxLen;
}

sub __PutPinMarks {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $messMngr = shift;

	# Ask for put cu to flex layers

	my $stackup = Stackup->new( $inCAM, $jobId );

	my @cores  = $stackup->GetAllCores(1);
	my @layers = JobHelper->GetCoverlaySigLayers($jobId);

	my @mess = (@messHead);
	push( @mess, "Vlo??it nyn?? zna??ky \"coverlay piny\" do sign??lov??ch vrstev flexi jader?\n" );
	push( @mess, " - J??dra: " . join( "; ", map { "j??dro " . $_->GetCoreNumber() } @cores ) );
	push( @mess, " - Cu vrstvy: " . join( "; ", @layers ) );

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess, [ "Nyn?? nevkl??dat", "Ano vlo??it" ] );

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
			foreach my $pin ( $bendArea->GetAllPins() ) {

				if ( $pin->GetHolderType() ne PinEnums->PinHolder_NONE ) {

					my @envelop = $pin->GetHolderEnvelop();
					CamSymbolSurf->AddSurfacePolyline( $inCAM, \@envelop, undef, "negative" );
				}
				else {

					my $feat = $pin->GetREGISTERFeat();
					CamSymbol->AddPad( $inCAM, "r" . ( $feat->{"thick"} + 2000 ), { "x" => $feat->{"x1"}, "y" => $feat->{"y1"} }, 0, "negative" );
				}
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
			foreach my $pin ( grep { $_->GetHolderType() ne PinEnums->PinHolder_NONE } $bendArea->GetAllPins() ) {

				my $ENDLINE = $pin->GetENDLINEFeat();
				my $CUTLINE = $pin->GetCUTLINEFeat();

				my @line1 = LineTransform->ParallelSegmentLine(
																{ "x" => $ENDLINE->{"x1"}, "y" => $ENDLINE->{"y1"} },
																{ "x" => $ENDLINE->{"x2"}, "y" => $ENDLINE->{"y2"} },
																$cuSquareOverlap,
																( $pin->GetHolderType() eq PinEnums->PinHolder_OUT ? "right" : "left" )
				);
				my @line2 = LineTransform->ParallelSegmentLine(
																{ "x" => $CUTLINE->{"x1"}, "y" => $CUTLINE->{"y1"} },
																{ "x" => $CUTLINE->{"x2"}, "y" => $CUTLINE->{"y2"} },
																$cuSquareOverlap,
																( $pin->GetHolderType() eq PinEnums->PinHolder_OUT ? "left" : "right" )
				);

				my @points = ();

				push( @points, { "x" => $line1[0]->{"x"}, "y" => $line1[0]->{"y"} } );
				push( @points, { "x" => $line1[1]->{"x"}, "y" => $line1[1]->{"y"} } );
				push( @points, { "x" => $line2[1]->{"x"}, "y" => $line2[1]->{"y"} } );
				push( @points, { "x" => $line2[0]->{"x"}, "y" => $line2[0]->{"y"} } );
				push( @points, { "x" => $line1[0]->{"x"}, "y" => $line1[0]->{"y"} } );

				CamSymbolSurf->AddSurfacePolyline( $inCAM, \@points );
			}
		}

		$inCAM->COM( "sel_resize", "size" => 2 * $cuSquareOverlap * 1000, "corner_ctl" => "no" );    # Resize Cu square 1000??m

		CamLayer->ClipAreaByProf( $inCAM, $lTmp, 200, 1 );                                           # 200??m min distance cu from profile
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

	my $jobId = "d266566";

	my $notClose = 0;

	my $res = DoCoverlayPins->CreateCoverlayPins( $inCAM, $jobId, "o+1" );

}

1;

