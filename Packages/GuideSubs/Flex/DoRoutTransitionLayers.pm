#-------------------------------------------------------------------------------------------#
# Description: Prepare prepreg rout layers for RigidFlex
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Flex::DoRoutTransitionLayers;

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
use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::CAMJob::FlexiLayers::BendAreaParser::BendAreaParser';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAMJob::FlexiLayers::CoverlayPinParser::CoverlayPinParser';
use aliased 'Packages::CAMJob::FlexiLayers::FlexiBendArea';
use aliased 'Packages::Stackup::Stackup::Stackup';

use aliased 'Packages::Stackup::Enums' => "StackEnums";
use aliased 'Packages::Polygon::Enums' => 'PolyEnums';
use aliased 'Packages::Stackup::StackupOperation';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

my @messHead = ();
push( @messHead, "<g>==========================================================</g>" );
push( @messHead, "<g>Průvodce vytvořením vrstev pro zahloubení v tranzitní zóně</g>" );
push( @messHead, "<g>==========================================================</g>\n" );

my $ROUTOVERLAP    = 0.2;    # 0.2mm Overlap of routs whcich go from top and from bot during routing PCB flexible part
my $EXTENDTRANZONE = 0.5;    # 0.5mm transition rout slots will be exteneded on both ends

# Set impedance lines
sub PrepareRoutLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;

	my $result = 1;

	my $messMngr = MessageMngr->new($jobId);

	my $type = JobHelper->GetPcbFlexType($jobId);
	return 0 if ( $type ne EnumsGeneral->PcbFlexType_RIGIDFLEXI && $type ne EnumsGeneral->PcbFlexType_RIGIDFLEXO );

	CamHelper->SetStep( $inCAM, $step );

	my $errMess = "";
	my $bendParser = BendAreaParser->new( $inCAM, $jobId, $step, PolyEnums->Dir_CW );
	while ( !$bendParser->CheckBendArea($errMess) ) {

		$messMngr->ShowModal( -1,
							  EnumsGeneral->MessageType_ERROR,
							  [ @messHead, "Vrstva \"bend\" není správně připravené", "Detail chyby:", $errMess ],
							  [ "Konec",   "Opravím" ] );

		return 0 if ( $messMngr->Result() == 0 );

		$inCAM->PAUSE("Oprav vrstvu: \"bend\"");

		$errMess = "";
	}

	# Rout transition part 1 (depth milling by vscore rout tool to rigid core)
	my $res1 = $self->__CreateRoutTransitionPart1( $inCAM, $jobId, $step, $messMngr );

	# Rout transition part 2 (depth milling by standard tool to final pcb)
	my $res2 = $self->__CreateRoutTransitionPart2( $inCAM, $jobId, $step, $messMngr );

	return $result;
}

sub __CreateRoutTransitionPart1 {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $messMngr = shift;

	my $result = 1;

	# Check if already exist layers jfzc, jfzs
	my @routLayers = ();
	my @packages   = StackupOperation->GetJoinedFlexRigidPackages($jobId);
	foreach my $joinPackgs (@packages) {

		my $topPckgs = $joinPackgs->{"packageTop"};
		my $botPckgs = $joinPackgs->{"packageBot"};

		if ( $topPckgs->{"coreType"} eq StackEnums->CoreType_RIGID ) {
			push( @routLayers, "jfzs" );
		}
		else {
			push( @routLayers, "jfzc" );
		}
	}

	for ( my $i = scalar(@routLayers) - 1 ; $i >= 0 ; $i-- ) {

		unless ( CamHelper->LayerExists( $inCAM, $jobId, $routLayers[$i] ) ) {
			splice @routLayers, $i, 1;
		}
	}

	my $recreate = 1;

	if (@routLayers) {

		$messMngr->ShowModal( -1,
							  EnumsGeneral->MessageType_ERROR,
							  [ @messHead, "Vrstvy: <b>" . join( "; ", @routLayers ) . "</b> již existují, chceš je přemazat?" ],
							  [ "Přeskočit", "Ne, vytvořit nové s indexem +1", "Ano přemazat" ] );

		return 0 if ( $messMngr->Result() == 0 );
		$recreate = 0 if ( $messMngr->Result() == 1 );
	}

	# Rout tool info
	my $toolSize         = 2;           # 2mm
	my $toolMagazineInfo = "d2.0a30";
	my $toolComp         = "none";

	FlexiBendArea->PrepareRoutTransitionZone( $inCAM,            $jobId,    $step,     1,            $toolSize,
											  $toolMagazineInfo, $toolComp, $recreate, $ROUTOVERLAP, $EXTENDTRANZONE );

	return $result;

}

sub __CreateRoutTransitionPart2 {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $messMngr = shift;

	my $result = 1;

	# Check if already exist layers fzc, fzs
	my @routLayers = ();
	my @packages   = StackupOperation->GetJoinedFlexRigidPackages($jobId);
	foreach my $joinPackgs (@packages) {

		my $topPckgs = $joinPackgs->{"packageTop"};
		my $botPckgs = $joinPackgs->{"packageBot"};

		if ( $topPckgs->{"coreType"} eq StackEnums->CoreType_RIGID ) {
			push( @routLayers, "fzs" );
		}
		else {
			push( @routLayers, "fzc" );
		}
	}

	for ( my $i = scalar(@routLayers) - 1 ; $i >= 0 ; $i-- ) {

		unless ( CamHelper->LayerExists( $inCAM, $jobId, $routLayers[$i] ) ) {
			splice @routLayers, $i, 1;
		}
	}

	my $recreate = 1;

	if (@routLayers) {

		$messMngr->ShowModal( -1,
							  EnumsGeneral->MessageType_ERROR,
							  [ @messHead, "Vrstvy: <b>" . join( "; ", @routLayers ) . "</b> již existují, chceš je přemazat?" ],
							  [ "Přeskočit", "Ne, vytvořit nové s indexem +1", "Ano přemazat" ] );

		
		return 0 if ( $messMngr->Result() == 0 );
		$recreate = 0 if ( $messMngr->Result() == 1 );
	}

	# Rout tool info
	my $toolSize         = 2;         # 2mm
	my $toolMagazineInfo = undef;
	my $toolComp         = "right";

	FlexiBendArea->PrepareRoutTransitionZone( $inCAM,            $jobId,    $step,     2,            $toolSize,
											  $toolMagazineInfo, $toolComp, $recreate, $ROUTOVERLAP, $EXTENDTRANZONE );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::Flex::DoRoutTransitionLayers';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';

	my $inCAM = InCAM->new();

	my $jobId = "d222775";

	my $notClose = 0;

	my $res = DoRoutTransitionLayers->PrepareRoutLayers( $inCAM, $jobId, "o+1" );

}

1;

