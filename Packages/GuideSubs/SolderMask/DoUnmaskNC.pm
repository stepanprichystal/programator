#-------------------------------------------------------------------------------------------#
# Description: Solder mask design editing
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::SolderMask::DoUnmaskNC;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::CAMJob::SolderMask::PreparationLayout';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

# Split rout cycle in rout layers: plated and noplated rout
sub UnMaskBGAThroughHole {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $result = 1;

	my $messMngr = MessageMngr->new($jobId);

	my $step = "o+1";

	# 1) Check if BGA exist
	my @bgaLayers = CamJob->GetSignalLayerNames( $inCAM, $jobId, 0, 1 );
	my $bgaExist = 0;
	foreach my $l (@bgaLayers) {

		my %att = CamHistogram->GetAttHistogram( $inCAM, $jobId, "o+1", $l );
		if ( $att{".bga"} ) {
			$bgaExist = 1;
			last;
		}
	}

	if ($bgaExist) {

		my $mess = "Na desce bylo nalezeno BGA. Prokovené otvory skrz budou odmaskovány, je to ok?";
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, [$mess], [ "Ne, neodmaskovat", "Ano, odmaskovat" ] );

		if ( $messMngr->Result() == 0 ) {

			$result = 0;
		}
		else {

			$result = PreparationLayout->UnmaskThroughHole( $inCAM, $jobId, $step )

		}
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::SolderMask::DoUnmaskNC';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';

	my $inCAM = InCAM->new();

	my $jobId = "d270070";

	my $notClose = 0;

	my $res = DoUnmaskNC->UnMaskBGAThroughHole( $inCAM, $jobId );

}

1;

