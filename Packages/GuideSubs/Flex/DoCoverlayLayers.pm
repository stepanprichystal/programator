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

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

my @messHead = ();
push( @messHead, "<g>=====================================</g>" );
push( @messHead, "<g>Průvodce vytvořením coverlay vrstev</g>" );
push( @messHead, "<g>=====================================</g>\n" );

my $COVERLAYOVERLAP = 500;     # Ovelrap of coverlay to rigid area
my $ROUTOOL         = 2000;    # 2000µm rout tool
my $REGPINSIZE      = 1500;    # 1500µm or register pin hole

# Set impedance lines
sub PrepareCoverlayLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;

	my $result = 1;

	my $messMngr = MessageMngr->new($jobId);

	CamHelper->SetStep( $inCAM, $step );

	my $type    = JobHelper->GetPcbFlexType($jobId);
	my $stackup = Stackup->new($jobId);

	my %coverlayType = HegMethods->GetCoverlayType($jobId);

	if ( $coverlayType{"top"} ) {

		my $pins = $type eq EnumsGeneral->PcbFlexType_RIGIDFLEXI ? 1 : 0;

		my $sigLayer;

		if ( $type eq EnumsGeneral->PcbFlexType_RIGIDFLEXO ) {

			$sigLayer = "c";
		}
		else {
			# find flexible inner layers
			my $core = ( $stackup->GetAllCores(1) )[0];
			$sigLayer = $core->GetTopCopperLayer()->GetCopperName();
		}

		$self->__PrepareCoverlay( $inCAM, $jobId, $step, "top", $pins, $sigLayer, $messMngr );
	}

	if ( $coverlayType{"bot"} ) {

		# find flexible inner layers
		my $core     = ( $stackup->GetAllCores(1) )[0];
		my $sigLayer = $core->GetBotCopperLayer()->GetCopperName();

		$self->__PrepareCoverlay( $inCAM, $jobId, $step, "bot", 1, $sigLayer, $messMngr );
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
	my $coverMaskL  = "coverlay" . $sigLayer;
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
		CamMatrix->CreateLayer( $inCAM, $jobId, $coverMaskL, "coverlay", "positive", 1,
								( $side eq "top" ? "c"      : "s" ),
								( $side eq "top" ? "before" : "after" ) );

		FlexiBendArea->UnmaskCoverlayMaskByBendArea( $inCAM, $jobId, $step, $coverMaskL );
		CamLayer->WorkLayer( $inCAM, $coverMaskL );
		$inCAM->PAUSE("Zkontroluj pripravenou coverlay masku popripade odmaskuj plosky.");
	}

	if ($pins) {

		my @mess = (@messHead);

		my $pinParser = CoverlayPinParser->new( $inCAM, $jobId, $step );

		my $errMess = "";

		while ( !$pinParser->CheckBendArea($errMess) ) {

			$messMngr->ShowModal( -1,
								  EnumsGeneral->MessageType_ERROR,
								  [ "Vrstva \"ceovelraypins\" není správně připravené", "Detail chyby:", $errMess ],
								  [ "Konec",                                                 "Opravím" ] );

			return 0 if ( $messMngr->Result() == 0 );

			$inCAM->PAUSE("Oprav vrstvu: \"bend\"");

			$errMess = "";
		}
	}

	# Prepare coverlay rout
	my $routLayer = FlexiBendArea->PrepareRoutCoverlay( $inCAM, $jobId, $step, $sigLayer, $pins, $pins, $COVERLAYOVERLAP, $ROUTOOL, $REGPINSIZE );
	CamLayer->WorkLayer( $inCAM, $routLayer );
	$inCAM->PAUSE("Zkontroluj pripravenou coverlay frezovaci vrstvu a uprav co je treba.");

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

	my $jobId = "d222775";

	my $notClose = 0;

	my $res = DoCoverlayLayers->PrepareCoverlayLayers( $inCAM, $jobId, "o+1" );

}

1;

