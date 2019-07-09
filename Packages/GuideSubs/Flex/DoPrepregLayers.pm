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

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

my @messHead = ();
push( @messHead, "<g>=====================================</g>" );
push( @messHead, "<g>Průvodce vytvořením prepreg vrstev</g>" );
push( @messHead, "<g>=====================================</g>\n" );

my $CLEARANCEP1 = 700;    # Default clearance of first (closer to flex core) prepreg from rigin/flex transition
my $CLEARANCEP2 = 300;    # Default clearance of second (closer to rigid core) prepreg from rigin/flex transition. Overlap with coverlay 200µm

# Set impedance lines
sub PreparePrepregLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;

	my $result = 1;

	my $messMngr = MessageMngr->new($jobId);

	my $type = JobHelper->GetPcbFlexType($jobId);
	return 0 if ( $type ne EnumsGeneral->PcbFlexType_RIGIDFLEXI && $type ne EnumsGeneral->PcbFlexType_RIGIDFLEXO );

	CamHelper->SetStep( $inCAM, $step );

	my $stackup = Stackup->new($jobId);

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

	my $prereglName = "fprepreg1";
	my $refLayer    = "coverlaypins";
	my $clearance   = $CLEARANCEP1;

	if ( CamHelper->LayerExists( $inCAM, $jobId, $prereglName ) ) {

		$messMngr->ShowModal( -1,
							  EnumsGeneral->MessageType_ERROR,
							  [ @messHead,     "Vrstva: \"$prereglName\" již existují, chceš ji vygenerovat znovu?" ],
							  [ "Přeskočit", "Ano, vygenerovat" ] );

		return 0 if ( $messMngr->Result() == 0 );
	}

	# When only top coverlay on outer RigidFlex (without pins)
	if ( $coverlayType{"top"} && !$coverlayType{"bot"} && $type eq EnumsGeneral->PcbFlexType_RIGIDFLEXO ) {
		$refLayer  = "bend";
		$clearance = $CLEARANCEP2;
	}

	my @mess = (@messHead);

	my $bendParser;

	if ( $refLayer eq "coverlaypins" ) {

		$bendParser = CoverlayPinParser->new( $inCAM, $jobId, $step, PolyEnums->Dir_CW, 2 * $clearance );

	}
	elsif ( $refLayer eq "bend" ) {

		$bendParser = BendAreaParser->new( $inCAM, $jobId, $step, PolyEnums->Dir_CW, 2 * $clearance );
	}

	my $errMess = "";

	while ( !$bendParser->CheckBendArea($errMess) ) {

		$messMngr->ShowModal( -1,
							  EnumsGeneral->MessageType_ERROR,
							  [ @messHead, "Vrstva \"$refLayer\" není správně připravené", "Detail chyby:", $errMess ],
							  [ "Konec",   "Opravím" ] );

		return 0 if ( $messMngr->Result() == 0 );

		$inCAM->PAUSE("Oprav vrstvu: \"$refLayer\"");

		$errMess = "";
	}

	FlexiBendArea->PrepareRoutPrepreg( $inCAM, $jobId, $step, $prereglName, 2 * $clearance, $refLayer );
	CamLayer->WorkLayer( $inCAM, $prereglName );
	$inCAM->PAUSE("Zkontroluj pripravenou frezovaci vrstvu pro PREPREG 1 a uprav co je treba.");
}

sub __PreparePreregNo2 {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $type     = shift;
	my $messMngr = shift;

	my %coverlayType = HegMethods->GetCoverlayType($jobId);

	my $prereglName = "fprepreg2";
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

	FlexiBendArea->PrepareRoutPrepreg( $inCAM, $jobId, $step, $prereglName, 2 * $CLEARANCEP2, $refLayer );
	CamLayer->WorkLayer( $inCAM, $prereglName );
	$inCAM->PAUSE("Zkontroluj pripravenou frezovaci vrstvu pro PREPREG 2 a uprav co je treba.");
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

	my $jobId = "d241421";

	my $notClose = 0;

	my $res = DoPrepregLayers->PreparePrepregLayers( $inCAM, $jobId, "o+1" );

}

1;

