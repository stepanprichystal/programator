#-------------------------------------------------------------------------------------------#
# Description: Prepare coverlay layers for RigidFlex
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Flex::DoSolderTemplateLayers;

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
push( @messHead, "<g>Průvodce vytvořením šablony pro registraci inner coverlay</g>" );
push( @messHead, "<g>=====================================</g>\n" );

my $HOLEDIAMETER = 9;    # Size of final routed hole in template

# Set impedance lines
sub PrepareTemplateLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;

	my $result = 1;

	my $messMngr = MessageMngr->new($jobId);

	my $type = JobHelper->GetPcbType($jobId);
	return 0 if ( $type ne EnumsGeneral->PcbType_RIGIDFLEXI && $type ne EnumsGeneral->PcbType_RIGIDFLEXO );

	CamHelper->SetStep( $inCAM, $step );

	my $stackup = Stackup->new($inCAM, $jobId);

	my %coverlayType = HegMethods->GetCoverlayType($jobId);

	if (  CamHelper->LayerExists($inCAM, $jobId, "cvrlpins") ) {

		$self->__PrepareTemplate( $inCAM, $jobId, $step, $messMngr );
	}

}

sub __PrepareTemplate {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;

	my $messMngr = shift;

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

	my $lName    = "fsoldc";
	my $recreate = 0;

	if ( CamHelper->LayerExists( $inCAM, $jobId, $lName ) ) {

		$messMngr->ShowModal( -1,
							  EnumsGeneral->MessageType_ERROR,
							  [ @messHead, "Vrstva:  <b> \"$lName\"</b> již existuje, chceš ji přemazat?" ],
							  [ "Přeskočit", "Ne, vytvořit novou s indexem +1", "Ano přemazat" ] );

		return 0 if ( $messMngr->Result() == 0 );
		$recreate = 0 if ( $messMngr->Result() == 1 );
		$recreate = 1 if ( $messMngr->Result() == 2 );

		# Find new template layer name
		unless ($recreate) {
			my $i = 1;
			while (1) {

				unless ( CamHelper->LayerExists( $inCAM, $jobId, $lName . $i ) ) {
					$lName = $lName . $i;
					last;
				}

				$i++;
			}
		}
	}

	# Prepare coverlay rout
	FlexiBendArea->PrepareCoverlayTemplate( $inCAM, $jobId, $step, $lName, 2, $HOLEDIAMETER );
	CamLayer->WorkLayer( $inCAM, $lName );
	$inCAM->PAUSE("Zkontroluj pripravenou vrstvu sablony a uprav co je treba.");

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::Flex::DoSolderTemplateLayers';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';

	my $inCAM = InCAM->new();

	my $jobId = "d266566";

	my $notClose = 0;

	my $res = DoSolderTemplateLayers->PrepareTemplateLayers( $inCAM, $jobId, "o+1" );

}

1;

