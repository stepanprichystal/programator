#-------------------------------------------------------------------------------------------#
# Description: Prepare prepreg rout layers for RigidFlex
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Flex::DoPrepregLayers;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamSymbol';
use aliased 'Helpers::JobHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::CAMJob::FlexiLayers::BendAreaParser::BendAreaParser';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::CAMJob::FlexiLayers::CoverlayPinParser::CoverlayPinParser';
use aliased 'Packages::CAMJob::FlexiLayers::FlexiBendArea';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Polygon::Enums' => 'PolyEnums';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

my @messHead = ();
push( @messHead, "<g>=====================================</g>" );
push( @messHead, "<g>Průvodce vytvořením prepreg vrstev</g>" );
push( @messHead, "<g>=====================================</g>\n" );

my $CLEARANCEP1 = 1000;    # Default clearance of first (closer to flex core) prepreg from rigin/flex transition
my $CLEARANCEP2 = 300;     # Default clearance of second (closer to rigid core) prepreg from rigin/flex transition. Overlap with coverlay 200µm
my $PINRADIUS   = 1000;    # 2000 µm radius of coveraly pins
my $ROUTTOOL    = 2000;    # default prepreg rout tool

# Set impedance lines
sub PreparePrepregLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;

	my $result = 1;

	my $messMngr = MessageMngr->new($jobId);

	my $type = JobHelper->GetPcbType($jobId);
	return 0 if ( $type ne EnumsGeneral->PcbType_RIGIDFLEXI && $type ne EnumsGeneral->PcbType_RIGIDFLEXO );

	CamHelper->SetStep( $inCAM, $step );

	# Prepreg No1

	$self->__PreparePreregNo1( $inCAM, $jobId, $step, $type, $messMngr );

	# Prepreg No1

	$self->__PreparePreregNo2( $inCAM, $jobId, $step, $type, $messMngr );

	return $result;

}

sub __PreparePreregNo1 {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $type     = shift;
	my $messMngr = shift;

	my %coverlayType = HegMethods->GetCoverlayType($jobId);

	my $prereglName = "fprprg1";
	if ( CamHelper->LayerExists( $inCAM, $jobId, $prereglName ) ) {

		$messMngr->ShowModal( -1,
							  EnumsGeneral->MessageType_ERROR,
							  [ @messHead,     "Vrstva: \"$prereglName\" již existují, chceš ji vygenerovat znovu?" ],
							  [ "Přeskočit", "Ano, vygenerovat" ] );

		return 0 if ( $messMngr->Result() == 0 );
	}


	# Search for prepreg type 1 in stackup
	my $stackup = Stackup->new( $inCAM, $jobId );
	my @P1 = grep { $_->GetType() eq StackEnums->MaterialType_PREPREG && $_->GetIsNoFlow() && $_->GetNoFlowType() eq StackEnums->NoFlowPrepreg_P1 }
	  $stackup->GetAllLayers();

	return 0 unless ( scalar(@P1) );

	# When only top coverlay on outer RigidFlex (without pins)
		my $pins = 1;
	if ( !CamHelper->LayerExists( $inCAM, $jobId, "cvrlpins" ) ) {
		$pins = 0;
	}

	# Check bend area
	my $bendParser;

	if ($pins) {

		$bendParser = CoverlayPinParser->new( $inCAM, $jobId, $step, PolyEnums->Dir_CW );
	}
	else {

		$bendParser = BendAreaParser->new( $inCAM, $jobId, $step, PolyEnums->Dir_CW );
	}

	my $errMess = "";
	while ( !$bendParser->CheckBendArea($errMess) ) {

		$messMngr->ShowModal( -1,
							  EnumsGeneral->MessageType_ERROR,
							  [ @messHead, "Vrstva \"" . $bendParser->GetLayerName() . "\" není správně připravené", "Detail chyby:", $errMess ],
							  [ "Konec",   "Opravím" ] );

		return 0 if ( $messMngr->Result() == 0 );

		$inCAM->PAUSE( "Oprav vrstvu: \"" . $bendParser->GetLayerName() . "\"" );

		$errMess = "";
	}

	# Create rout layer
	my $routLayerOk = 0;
	while ( !$routLayerOk ) {

		if ($pins) {

			my $clearance = $CLEARANCEP1;
			my $bendParser = BendAreaParser->new( $inCAM, $jobId, $step, PolyEnums->Dir_CW, 2 * $clearance );

			my @mess = (@messHead);
			push( @mess, "Vytvoření frézovací vrstvy: $prereglName" );
			push( @mess, "----------------------------------------------------\n" );
			push( @mess, "\nVrstva bude obsahovat vyfrézování pro coverlay piny" );
			push( @mess, "Zkotroluj, popřípadě uprav parametry" );

			my $parOverlap = $messMngr->GetNumberParameter( "Velikost odfrézování prepregu v \"rigid části\" DPS [µm]", $clearance );
			my $parTool    = $messMngr->GetNumberParameter( "Velikost frézovacího nástroje [µm]",                         $ROUTTOOL );
			my $parRadius  = $messMngr->GetNumberParameter( "Radius frézy, kterým je pin připojen k coverlay [µm]",       $PINRADIUS );
			my @params = ( $parOverlap, $parTool, $parRadius );

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess, undef, undef, \@params );

			FlexiBendArea->PrepareRoutPrepreg( $inCAM, $jobId, $step, $prereglName,
											   2 * $parOverlap->GetResultValue(1),
											   $bendParser->GetLayerName(),
											   $parTool->GetResultValue(1),
											   $parRadius->GetResultValue(1) );

		}
		else {

			my $clearance = $CLEARANCEP2;
			my $bendParser = BendAreaParser->new( $inCAM, $jobId, $step, PolyEnums->Dir_CW, 2 * $clearance );

			my @mess = (@messHead);
			push( @mess, "Vytvoření frézovací vrstvy: $prereglName" );
			push( @mess, "----------------------------------------------------\n" );
			push( @mess, "\nVrstva <b>nebude</b> obsahovat vyfrézování pro coverlay piny" );
			push( @mess, "Zkotroluj, popřípadě uprav parametry" );

			my $parOverlap = $messMngr->GetNumberParameter( "Velikost odfrézování prepregu v \"rigid části\" DPS [µm]", $clearance );
			my $parTool = $messMngr->GetNumberParameter( "Velikost frézovacího nástroje [µm]", $ROUTTOOL );
			my @params = ( $parOverlap, $parTool );

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess, undef, undef, \@params );

			FlexiBendArea->PrepareRoutPrepreg( $inCAM, $jobId, $step, $prereglName,
											   2 * $parOverlap->GetResultValue(1),
											   $bendParser->GetLayerName(),
											   $parTool->GetResultValue(1) );

		}
		CamLayer->WorkLayer( $inCAM, $prereglName );
		$inCAM->PAUSE("Zkontroluj pripravenou frezovaci vrstvu pro PREPREG 1 a uprav co je treba.");

		my @mess = (@messHead);
		push( @mess, "Vytvoření frézovací vrstvy: $prereglName" );
		push( @mess, "----------------------------------------------------\n" );
		push( @mess, "\nJe frézovací vrstva ok?" );

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess, [ "Vytvořit znovu", "Ok" ] );

		$routLayerOk = 1 if ( $messMngr->Result() == 1 );

	}
}

sub __PreparePreregNo2 {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $type     = shift;
	my $messMngr = shift;

	my %coverlayType = HegMethods->GetCoverlayType($jobId);

	my $prereglName = "fprprg2";
	my $refLayer    = "bend";

	if ( CamHelper->LayerExists( $inCAM, $jobId, $prereglName ) ) {

		$messMngr->ShowModal( -1,
							  EnumsGeneral->MessageType_ERROR,
							  [ @messHead,     "Vrstva: \"$prereglName\" již existují, chceš ji vygenerovat znovu?" ],
							  [ "Přeskočit", "Ano, vygenerovat" ] );

		return 0 if ( $messMngr->Result() == 0 );
	}

	my @mess       = (@messHead);
	my $bendParser = BendAreaParser->new( $inCAM, $jobId, $step, PolyEnums->Dir_CW, 2 * $CLEARANCEP2 );
	my $errMess    = "";

	while ( !$bendParser->CheckBendArea($errMess) ) {

		$messMngr->ShowModal( -1,
							  EnumsGeneral->MessageType_ERROR,
							  [ @messHead, "Vrstva \"$refLayer\" není správně připravené", "Detail chyby:", $errMess ],
							  [ "Konec",   "Opravím" ] );

		return 0 if ( $messMngr->Result() == 0 );

		$inCAM->PAUSE("Oprav vrstvu: \"$refLayer\"");

		$errMess = "";
	}

	# Create rout layer
	my $routLayerOk = 0;
	while ( !$routLayerOk ) {

		my @mess = (@messHead);
		push( @mess, "Vytvoření frézovací vrstvy: $prereglName" );
		push( @mess, "----------------------------------------------------\n" );
		push( @mess, "\nZkotroluj, popřípadě uprav parametry" );

		my $parOverlap = $messMngr->GetNumberParameter( "Velikost odfrézování prepregu v \"rigid části\" DPS [µm]", $CLEARANCEP2 );
		my $parTool = $messMngr->GetNumberParameter( "Velikost frézovacího nástroje [µm]", $ROUTTOOL );
		my @params = ( $parOverlap, $parTool );

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess, undef, undef, \@params );

		FlexiBendArea->PrepareRoutPrepreg( $inCAM, $jobId, $step, $prereglName,
										   2 * $parOverlap->GetResultValue(1),
										   $bendParser->GetLayerName(),
										   $parTool->GetResultValue(1) );
		CamLayer->WorkLayer( $inCAM, $prereglName );
		$inCAM->PAUSE("Zkontroluj pripravenou frezovaci vrstvu pro PREPREG 2 a uprav co je treba.");

		@mess = (@messHead);
		push( @mess, "Vytvoření frézovací vrstvy: $prereglName" );
		push( @mess, "----------------------------------------------------\n" );
		push( @mess, "\nJe frézovací vrstva ok?" );

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess, [ "Vytvořit znovu", "Ok" ] );

		$routLayerOk = 1 if ( $messMngr->Result() == 1 );
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::Flex::DoPrepregLayers';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';

	my $inCAM = InCAM->new();

	my $jobId = "d283335";

	my $notClose = 0;

	my $res = DoPrepregLayers->PreparePrepregLayers( $inCAM, $jobId, "o+1" );

}

1;

