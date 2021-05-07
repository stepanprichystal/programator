#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for edit drilling layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ChangeReorder::Changes::DRILLING;
use base('Packages::Reorder::ChangeReorder::Changes::ChangeBase');

use Class::Interface;
&implements('Packages::Reorder::ChangeReorder::Changes::IChange');

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Packages::Routing::PilotHole';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Enums::EnumsGeneral';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Reorder::Enums';
use aliased 'Packages::CAMJob::Drilling::MoveDrillHoles';
use aliased 'Packages::CAMJob::Drilling::NPltDrillCheck';
use aliased 'Packages::Other::CustomerNote';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

sub Run {
	my $self = shift;
	my $mess = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $reorderType = $self->{"reorderType"};

	my $result = 1;
	my @steps  = ();

	if ( CamHelper->StepExists( $inCAM, $jobId, "panel" ) ) {
		@steps = map { $_->{"stepName"} } CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, "panel" );
	}
	else {
		@steps = ("o+1");
	}

	# Change type at pressfit holes
	my @layers = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_nMill, EnumsGeneral->LAYERTYPE_nplt_nDrill ] );

	foreach my $step (@steps) {

		foreach my $l (@layers) {

			# if there are type pressfit with tolerance, change type to non_plated and standard
			my @tools = CamDTM->GetDTMTools( $inCAM, $jobId, $step, $l->{"gROWname"} );
			my $change = 0;
			foreach my $t (@tools) {

				if ( $t->{"gTOOLtype2"} eq "press_fit" && ( $t->{"gTOOLmin_tol"} != 0 || $t->{"gTOOLmax_tol"} != 0 ) ) {

					$t->{"gTOOLtype2"} = "standard";
					$t->{"gTOOLtype"}  = "non_plated";
					$change            = 1;
				}
			}

			if ($change) {

				CamDTM->SetDTMTools( $inCAM, $jobId, $step, $l->{"gROWname"}, \@tools );
			}
		}
	}

	# Movesmall NPTH holes to plated layer
	{
		my $unMaskedCntRef   = 0;
		my $unMaskAttrValRef = "";

		my $maxTool  = 1000;
		my $pltLayer = "m";

		my $customer = HegMethods->GetCustomerInfo($jobId);
		my $note     = CustomerNote->new( $customer->{"reference_subjektu"} );

		if ( !( defined $note->SmallNpth2Pth() && $note->SmallNpth2Pth() == 0 ) ) {

			if ( CamHelper->LayerExists( $inCAM, $jobId, $pltLayer ) ) {

				my @childs = CamStep->GetJobEditSteps( $inCAM, $jobId );
				my @nplt =
				  map { $_->{"gROWname"} }
				  CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_nMill, EnumsGeneral->LAYERTYPE_nplt_nDrill ] );

				foreach my $s (@childs) {

					foreach my $npltLayer (@nplt) {

						my $checkRes = {};
						unless ( NPltDrillCheck->SmallNPltHoleCheck( $inCAM, $jobId, $s, $npltLayer, $pltLayer, $maxTool, $checkRes ) ) {

							my $movedHoleCntRef     = -1;
							my $movedHoleAttrValRef = -1;
							my $res = MoveDrillHoles->MoveSmallNpth2Pth( $inCAM, $jobId, $s, $npltLayer, $pltLayer, $maxTool, \$movedHoleCntRef,
																		 \$movedHoleAttrValRef );
							unless ($res) {
								$$mess .= "Error during move small npth holes from: $npltLayer to plated layer: $pltLayer";
								$result = 0;
							}
						}
					}
				}
			}
		}
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::ChangeReorder::Changes::DRILLING' => "Change";
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Packages::Reorder::Enums';

	my $inCAM = InCAM->new();
	my $jobId = "d134574";
	my $orderId = "d134574-01";
 
	my $check = Change->new( "DRILLING", $inCAM, $jobId, $orderId, Enums->ReorderType_STD );

	my $mess = "";
	print "Change result: " . $check->Run( \$mess );
	print "Mess:" . $mess;
}

1;

