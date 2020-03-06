#-------------------------------------------------------------------------------------------#
# Description: Prepare prepreg rout layers for RigidFlex
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Flex::DoFlexiMaskLayer;

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
push( @messHead, "<g>============================================</g>" );
push( @messHead, "<g>Průvodce vytvořením vrstvy pro UV flex masku</g>" );
push( @messHead, "<g>============================================</g>\n" );

my $OVERLAP2RIGID = 500;    # Overlap of flexi solder mask to rigid boards

# Set impedance lines
sub PrepareFlexiMaskLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;

	my $result = 1;

	my $messMngr = MessageMngr->new($jobId);

	my %flexType = HegMethods->GetFlexSolderMask($jobId);

	return 0 if ( !$flexType{"top"} && !$flexType{"bot"} );

	CamHelper->SetStep( $inCAM, $step );

	if ( $flexType{"top"} ) {
		$self->__PrepareFlexiMask( $inCAM, $jobId, $step, "top", $messMngr );
	}

	if ( $flexType{"bot"} ) {
		$self->__PrepareFlexiMask( $inCAM, $jobId, $step, "bot", $messMngr );
	}

	return $result;
}

sub __PrepareFlexiMask {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $type     = shift;    # top/bot
	my $messMngr = shift;

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

	my $stdMakL = "m" . ( $type eq "top" ? "c" : "s" );
	my $flexMaskL = $stdMakL . "flex";

	# Unmask standard solder mask in bend area
	if ( CamHelper->LayerExists( $inCAM, $jobId, $stdMakL ) ) {
		FlexiBendArea->UnMaskBendArea( $inCAM, $jobId, $step, $stdMakL );
	}

	# Create flex solder mask in bend area
	FlexiBendArea->PrepareFlexMask( $inCAM, $jobId, $step, $flexMaskL, $OVERLAP2RIGID );

	CamLayer->WorkLayer( $inCAM, $flexMaskL );
	$inCAM->PAUSE("Zkontroluj pripravenou flexi masku: $flexMaskL");

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::Flex::DoFlexiMaskLayer';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';

	my $inCAM = InCAM->new();

	my $jobId = "d274012";

	my $notClose = 0;

	my $res = DoFlexiMaskLayer->PrepareFlexiMaskLayers( $inCAM, $jobId, "o+1" );

}

1;

