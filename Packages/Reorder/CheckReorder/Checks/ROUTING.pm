#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::ROUTING;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAM::UniRTM::UniRTM';
use aliased 'Enums::EnumsRout';
use aliased 'Enums::EnumsDrill';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamStep';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Reorder::Enums';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Packages::CAMJob::Drilling::NPltDrillCheck';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# Check if exist new version of nif, if so it means it is from InCAM
sub Run {
	my $self = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $orderId     = $self->{"orderId"};
	my $reorderType = $self->{"reorderType"};

	# 1) Check if rout is on bridges and attribute "routOnBridges" is not set.
	my $isPool = HegMethods->GetOrderIsPool($orderId);
	if ($isPool) {

		my $unitRTM = UniRTM->new( $inCAM, $jobId, "o+1", "f" );

		my @outlines = $unitRTM->GetOutlineChainSeqs();

		my @chains = $unitRTM->GetChains();
		my $onBridges = CamAttributes->GetStepAttrByName( $inCAM, $jobId, "o+1", "rout_on_bridges" );

		# If not exist outline rout, check if pcb is on bridges
		if ( !scalar(@outlines) && $onBridges eq "no" ) {

			$self->_AddChange(
							   "Vypad?? to, ??e dps m?? fr??zu na m??stky, ale nen?? nastaven atribut stepu o+1: \"Rout on bridges\" - \"yes\"\n"
								 . "Ov???? to a nastav atribut nebo oprav obrysovou fr??zu.",
							   1
			);
		}
	}

	# Check if pcb is routed on bridge and order has more than 50 pieces
	my %orderInfo = HegMethods->GetAllByOrderId($orderId);

	if ( $orderInfo{"kusy_pozadavek"} > 50 ) {

		my @steps = ();

		if ( CamHelper->StepExists( $inCAM, $jobId, "panel" ) ) {

			if ( CamStepRepeat->GetStepAndRepeatDepth( $inCAM, $jobId, "panel" ) == 1 ) {

				my @s = CamStepRepeatPnl->GetUniqueStepAndRepeat( $inCAM, $jobId );
				push( @steps, map { $_->{"stepName"} } @s ) if ( scalar(@s) );
			}

		}
		else {

			push( @steps, "o+1" );
		}

		if ( scalar(@steps) ) {

			my $stepsOnBridges = 0;

			foreach my $s (@steps) {
				$stepsOnBridges++ if ( CamAttributes->GetStepAttrByName( $inCAM, $jobId, $s, "rout_on_bridges" ) =~ /^yes$/i );
			}

			if ( $stepsOnBridges == scalar(@steps) ) {

				$self->_AddChange(   "DPS obsahuje fr??zu na m??stky a z??rove?? po??adavek na po??et kus?? ("
								   . $orderInfo{"kusy_pozadavek"}
								   . ") je v??t???? ne?? 50. Komunikuj s O??." );
			}
		}

	}

	if ( $reorderType eq Enums->ReorderType_STD ) {

		# check all plt+nplt blind rout/drill if we have still all special tools
		my @types = (
					  EnumsGeneral->LAYERTYPE_nplt_bMillTop, EnumsGeneral->LAYERTYPE_nplt_bMillBot,
					  EnumsGeneral->LAYERTYPE_plt_bMillTop,  EnumsGeneral->LAYERTYPE_plt_bMillBot
		);

		foreach my $l ( CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, \@types ) ) {

			my $unitDTM = UniDTM->new( $inCAM, $jobId, "panel", $l->{"gROWname"}, 1 );

			my @tools = grep { $_->GetDrillSize() > 6000 } $unitDTM->GetUniqueTools();

			if (@tools) {

				my $str = join( ";", map { $_->GetDrillSize() } @tools );

				$self->_AddChange( "Vrstva: \""
						 . $l->{"gROWname"}
						 . "\" obsahuje speci??ln?? n??stroje ($str) v??t???? jak 6.5mm, kter?? ji?? nem??me."
						 . " Pokud n??stroj fr??zuje \"countersink\", pou??ij jin?? pr??m??r.\n"
						 . "Dej pozor, jestli nov?? n??stroj bude sta??it na pr??m??r \"countersinku\", jestli ne tak p??ed??lej na pojezd/surface" );

				if ( grep { !defined $_->GetMagazine() } $unitDTM->GetUniqueTools() ) {

					$self->_AddChange(
								  "Vrstva: \"" . $l->{"gROWname"} . "\" obsahuje speci??ln?? n??stroje ($str), kter?? nemaj?? definovan?? magaz??n" );
				}

			}

		}
	}

	# Check if rout doesn't contain tool size smaller than 1000
	# (do not consider rout pilot holes)
	{

		my $unMaskedCntRef   = 0;
		my $unMaskAttrValRef = "";

		my $maxTool  = 1000;
		my $pltLayer = "m";

		if ( CamHelper->LayerExists( $inCAM, $jobId, $pltLayer ) ) {

			my @childs = CamStep->GetJobEditSteps( $inCAM, $jobId );
			my @nplt =
			  map { $_->{"gROWname"} }
			  CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_nMill, EnumsGeneral->LAYERTYPE_nplt_nDrill ] );

			foreach my $s (@childs) {

				foreach my $npltLayer (@nplt) {

					my $checkRes = {};
					unless ( NPltDrillCheck->SmallNPltHoleCheck( $inCAM, $jobId, $s, $npltLayer, $pltLayer, $maxTool, $checkRes ) ) {

						$self->_AddChange(
								 "Step: $s, NC vrstva: $npltLayer obsahuje n??stroje men???? jak "
								   . $maxTool
								   . "??m, kter?? by m??ly b??t p??esunuty do prokoven?? vrta??ky. "
								   . "\n- Seznam pou??it??ch n??stroj?? indikovan??ch otvor??: "
								   . join( "; ", map { $_ . "??m" } uniq( @{ $checkRes->{"padTools"} } ) )
								   . "\n- Seznam \"features Id\" pad??, kter?? maj?? b??t p??esunuty: "
								   . join( "; ", @{ $checkRes->{"padFeatures"} } )
								   . "\nPozor, otvory obsahuj??c?? atribut \".pilot_hole\" a otvory s nastavenou toleranc?? v DTM se nep??esouvaj??!",
								 0
						);
					}
				}
			}
		}
	}

	# Check if rout doesn't contain tool size smaller than 1000
	# (do not consider rout pilot holes)
	{
		my @depthLayers = CamDrilling->GetNCLayersByTypes(
														   $inCAM, $jobId,
														   [
															  EnumsGeneral->LAYERTYPE_nplt_bstiffcMill, EnumsGeneral->LAYERTYPE_nplt_bstiffcMill,
															  EnumsGeneral->LAYERTYPE_nplt_bMillTop,    EnumsGeneral->LAYERTYPE_nplt_bMillBot
														   ]
		);

		my @steps = CamStep->GetJobEditSteps( $inCAM, $jobId );

		foreach my $l (@depthLayers) {

			foreach my $s (@steps) {

				my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $s, $l->{"gROWname"}, 0 );
				last if ( $hist{"surf"} == 0 );
				my %pnlLAtt = CamAttributes->GetLayerAttr( $inCAM, $jobId, $s, $l->{"gROWname"} );
				if ( !defined $pnlLAtt{"zaxis_rout_calibration_coupon"} || $pnlLAtt{"zaxis_rout_calibration_coupon"} =~ /none/i ) {

					$self->_AddChange(
						"Ve stepu: \"${s}\", vrstv??: \"" . $l->{"gROWname"}
						  . "\" byla nalezena hloubkov?? fr??za surfacem, ale nen?? po??adov??no vytvo??en?? Z-axis kuponu."
						  . "Opravdu nepo??aduje?? vytvo??en?? zaxis kuponu, kter?? zaru???? po??adovanou hloubku od z??kazn??ka?"
						  . "Pokud po??aduje??, spus?? pr??vodce na vytvo??en?? z-axis kuponu (ZaxisCouponScript.pl)"
					);

				}

			}

		}
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::CheckReorder::Checks::ROUTING' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM   = InCAM->new();
	my $jobId   = "d322953";
	my $orderId = "d322953-01";

	my $check = Change->new( "key", $inCAM, $jobId, $orderId, Enums->ReorderType_STD );

	my $mess = "";
	print "Change result: " . $check->Run( \$mess );

	die;

}

1;

