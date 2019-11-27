#-------------------------------------------------------------------------------------------#
# Description: Prepare coverlay layers for RigidFlex
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Flex::DoPrepareBendAreaOther;

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
use aliased 'CamHelpers::CamJob';
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
push( @messHead, "<g>Průvodce osmaskováním \"bend\" area a vložení Cu do \"bend\" area</g>" );
push( @messHead, "<g>=====================================</g>\n " );

my $CUCLEAR           = 250;    #
my $SMBENDCLEARSTD    = 100;    #
my $SMBENDCLEARFLEXSM = 250;    #

# Set impedance lines
sub PrepareBendAreaOther {
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

	# 1) Put Cu to signal layers in bend area
	my @mess = (@messHead);
	push( @mess, "Vložit nyní Cu do signálových vrstev v oblastech \"bend area\"?" );

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess, [ "Přeskočit", "Ano vložit" ] );

	if ( $messMngr->Result() == 1 ) {

		my @affectLayers = ();
		FlexiBendArea->PutCuToBendArea( $inCAM, $jobId, $step, $CUCLEAR, \@affectLayers );

		if (@affectLayers) {

			CamLayer->DisplayLayers( $inCAM, \@affectLayers );
			$inCAM->PAUSE( "Zkontroluj Cu vlozene do signalovych vrstev: " . join( ",", @affectLayers ) . " v oblasti \"bedn area\"." );

			CamLayer->ClearLayers($inCAM);

		}
	}

	# 2) Unmask bend area
	my @mask = grep { $_ =~ /^m[cs]$/ } map { $_->{"gROWname"} } CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	if (@mask) {

		my @mess = (@messHead);
		push( @mess, "Odmaskovat nyní vrstvy:  " . join( "; ", @mask ) . " v oblasti \"bend area\"?" );

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess, [ "Přeskočit", "Ano odmaskovat" ] );

		if ( $messMngr->Result() == 1 ) {

			

			foreach my $maskL (@mask) {
				
				my $clearance = $SMBENDCLEARSTD;

				if (
					    $maskL =~ /^mc2?$/ && CamHelper->LayerExists( $inCAM, $jobId, "mcflex" )
					 || $maskL =~ /^ms2?$/ && CamHelper->LayerExists( $inCAM, $jobId, "msflex" )
				  )
				{
					$clearance = $SMBENDCLEARFLEXSM;
				}

				FlexiBendArea->UnMaskBendArea( $inCAM, $jobId, $step, $maskL, $clearance );
			}

			CamLayer->DisplayLayers( $inCAM, \@mask );
			$inCAM->PAUSE( "Zkontroluj odmaskovani vrstev: " . join( ",", @mask ) . " v oblasti \"bedn area\"." );

			CamLayer->ClearLayers($inCAM);
		}
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::Flex::DoPrepareBendAreaOther';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';

	my $inCAM = InCAM->new();

	my $jobId = "d251321";

	my $notClose = 0;

	my $res = DoPrepareBendAreaOther->PrepareBendAreaOther( $inCAM, $jobId, "o+1" );

}

1;

