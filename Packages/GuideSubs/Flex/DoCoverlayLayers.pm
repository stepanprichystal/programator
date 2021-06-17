#-------------------------------------------------------------------------------------------#
# Description: Prepare coverlay layers for RigidFlex
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Flex::DoCoverlayLayers;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Helpers::JobHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::CAMJob::FlexiLayers::CoverlayPinParser::CoverlayPinParser';
use aliased 'Packages::CAMJob::FlexiLayers::FlexiBendArea';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Routing::PilotHole';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

my @messHead = ();
push( @messHead, "<g>=====================================</g>" );
push( @messHead, "<g>Průvodce vytvořením coverlay vrstev</g>" );
push( @messHead, "<g>=====================================</g>\n" );

my $COVERLAYOVERLAP = 1000;    # Ovelrap of coverlay to rigid area
my $ROUTOOL         = 2000;    # 2000µm rout tool
my $REGPINSIZE      = 1500;    # 1500µm or register pin hole
my $PINRADIUS       = 1000;    # 2000 µm radius of coveraly pins

# Set impedance lines
sub PrepareCoverlayLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;

	my $result = 1;

	my $messMngr = MessageMngr->new($jobId);

	CamHelper->SetStep( $inCAM, $step );

	my $type = JobHelper->GetPcbType($jobId);
	my $stackup = Stackup->new( $inCAM, $jobId );

	my %coverlayType   = HegMethods->GetCoverlayType($jobId);
	my @coverSigLayers = JobHelper->GetCoverlaySigLayers($jobId);

	if ( $coverlayType{"top"} ) {

		my $pins = 1;

		# Ask user if create pins if coverlay is very top on PCB
		if ( grep { $_ eq "c" } @coverSigLayers ) {

			my @mess = (@messHead);
			push( @mess, "DPS má coverlay na straně: \"c\". Chceš vytvořit coverlay piny?" );

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess, [ "Vytvořit frézu bez pinů", "Ano vytvořit" ] );

			if ( $messMngr->Result() == 0 ) {

				$pins = 0;
			}
		}

		# find flexible inner layers
		my $core     = ( $stackup->GetAllCores(1) )[0];
		my $sigLayer = $core->GetTopCopperLayer()->GetCopperName();

		$self->__PrepareCoverlay( $inCAM, $jobId, $step, "top", $pins, $sigLayer, $messMngr );
	}

	if ( $coverlayType{"bot"} ) {

		my $pins = 1;

		# Ask user if create pins if coverlay is very top on PCB
		if ( grep { $_ eq "s" } @coverSigLayers ) {

			my @mess = (@messHead);
			push( @mess, "DPS má coverlay na straně: \"s\". Chceš vytvořit coverlay piny?" );

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess, [ "Vytvořit frézu bez pinů", "Ano vytvořit" ] );

			if ( $messMngr->Result() == 0 ) {

				$pins = 0;
			}
		}

		# find flexible inner layers
		my $core     = ( $stackup->GetAllCores(1) )[0];
		my $sigLayer = $core->GetBotCopperLayer()->GetCopperName();

		$self->__PrepareCoverlay( $inCAM, $jobId, $step, "bot", $pins, $sigLayer, $messMngr );
	}

}

sub __PrepareCoverlay {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $side     = shift;
	my $pins     = shift;
	my $sigLayer = shift;
	my $messMngr = shift;

	# Create coverlay mask layer
	my $coverMaskL  = "cvrl" . $sigLayer;
	my $createMaskL = 1;
	if ( CamHelper->LayerExists( $inCAM, $jobId, $coverMaskL ) ) {

		my @mess = (@messHead);
		push( @mess, "Vytvoření vrstvy: $coverMaskL typu \"coverlay maska\"" );
		push( @mess, "----------------------------------------------------\n" );
		push( @mess, "Vrstva \"$coverMaskL\" již existuje, cheš ji smazat a vytvořit znovu?" );

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess, [ "Nemazat a pokračovat", "Znovu vytvořit" ] );

		if ( $messMngr->Result() == 0 ) {

			$createMaskL = 0;

		}
	}

	# Prepare coverlay mask
	if ($createMaskL) {

		CamMatrix->DeleteLayer( $inCAM, $jobId, $coverMaskL );
		CamMatrix->CreateLayer( $inCAM, $jobId, $coverMaskL, "coverlay", "positive", 1, $sigLayer, ( $side eq "top" ? "before" : "after" ) );

		FlexiBendArea->UnmaskCoverlayMaskByBendArea( $inCAM, $jobId, $step, $coverMaskL );
		CamLayer->WorkLayer( $inCAM, $coverMaskL );
		$inCAM->PAUSE("Zkontroluj pripravenou coverlay masku popripade odmaskuj plosky.");
	}

	my $routLayerOk = 0;
	while ( !$routLayerOk ) {

		my $routLayer;

		if ($pins) {

			my @mess = (@messHead);

			my $pinParser = CoverlayPinParser->new( $inCAM, $jobId, $step );

			my $errMess = "";

			while ( !$pinParser->CheckBendArea( \$errMess ) ) {

				$messMngr->ShowModal( -1,
									  EnumsGeneral->MessageType_ERROR,
									  [ "Vrstva \"ceovelraypins\" není správně připravené", "Detail chyby:", $errMess ],
									  [ "Konec",                                                 "Opravím" ] );

				return 0 if ( $messMngr->Result() == 0 );

				$inCAM->PAUSE("Oprav vrstvu: \"bend\"");

				$errMess = "";
			}

			@mess = (@messHead);
			push( @mess, "Vytvoření vrstvy frézy coverlay" );
			push( @mess, "----------------------------------------------------\n" );
			push( @mess, "\nZkotroluj, popřípadě uprav parametry \"coverlay:" );

			my $parOverlap = $messMngr->GetNumberParameter( "Přesah coverlay do \"rigid části\" DPS [µm]",          $COVERLAYOVERLAP );
			my $parTool    = $messMngr->GetNumberParameter( "Velikost frézovacího nástroje [µm]",                   $ROUTOOL );
			my $parRegSize = $messMngr->GetNumberParameter( "Velikost otvoru na sesazení coverlay [µm]",              $REGPINSIZE );
			my $parRadius  = $messMngr->GetNumberParameter( "Radius frézy, kterým je pin připojen k coverlay [µm]", $PINRADIUS );
			my @params = ( $parOverlap, $parTool, $parRegSize, $parRadius );

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess, undef, undef, \@params );

			# Prepare coverlay rout
			$routLayer =
			  FlexiBendArea->PrepareRoutCoverlay( $inCAM, $jobId, $step, $sigLayer, $pins, $pins,
												  $parOverlap->GetResultValue(1),
												  $parTool->GetResultValue(1),
												  $parRegSize->GetResultValue(1),
												  $parRadius->GetResultValue(1) );

		}
		else {
			my @mess = (@messHead);
			push( @mess, "Vytvoření vrstvy frézy coverlay" );
			push( @mess, "----------------------------------------------------\n" );
			push( @mess, "\nZkotroluj, popřípadě uprav parametry:" );

			my $parTool = $messMngr->GetNumberParameter( "Velikost frézovacího nástroje [µm]", $ROUTOOL );

			my @params = ($parTool);

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess, undef, undef, \@params );

			# Prepare coverlay rout
			$routLayer = FlexiBendArea->PrepareRoutCoverlay( $inCAM, $jobId, $step, $sigLayer, $pins, $pins, undef, $parTool->GetResultValue(1) );

		}

		# Add pilot
		PilotHole->AddPilotHole( $inCAM, $jobId, $step, $routLayer, 80 );

		CamLayer->WorkLayer( $inCAM, $routLayer );
		$inCAM->PAUSE("Zkontroluj pripravenou coverlay frezovaci vrstvu a uprav co je treba.");

		my @mess = (@messHead);
		push( @mess, "Vytvoření vrstvy frézy coverlay" );
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

	use aliased 'Packages::GuideSubs::Flex::DoCoverlayLayers';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';

	my $inCAM = InCAM->new();

	my $jobId = "d266566";

	my $notClose = 0;

	my $res = DoCoverlayLayers->PrepareCoverlayLayers( $inCAM, $jobId, "o+1" );

}

1;

