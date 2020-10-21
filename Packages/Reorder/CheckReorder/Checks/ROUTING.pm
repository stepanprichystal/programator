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
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Reorder::Enums';
use aliased 'Packages::Polygon::Features::Features::Features';

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
							   "Vypadá to, že dps má frézu na můstky, ale není nastaven atribut stepu o+1: \"Rout on bridges\" - \"yes\"\n"
								 . "Ověř to a nastav atribut nebo oprav obrysovou frézu.",
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

				$self->_AddChange(   "DPS obsahuje frézu na můstky a zároveň požadavek na počet kusů ("
								   . $orderInfo{"kusy_pozadavek"}
								   . ") je větší než 50. Komunikuj s OÚ." );
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
						 . "\" obsahuje speciální nástroje ($str) větší jak 6.5mm, které již nemáme."
						 . " Pokud nástroj frézuje \"countersink\", použij jiný průměr.\n"
						 . "Dej pozor, jestli nový nástroj bude stačit na průměr \"countersinku\", jestli ne tak předělej na pojezd/surface" );

				if ( grep { !defined $_->GetMagazine() } $unitDTM->GetUniqueTools() ) {

					$self->_AddChange(
								  "Vrstva: \"" . $l->{"gROWname"} . "\" obsahuje speciální nástroje ($str), které nemají definovaný magazín" );
				}

			}

		}
	}

	# Check if rout doesn't contain tool size smaller than 1000
	# (do not consider rout pilot holes)
	if ( CamHelper->LayerExists( $inCAM, $jobId, "m" ) ) {

		my $step = ();
		if ( CamHelper->StepExists( $inCAM, $jobId, "panel" ) ) {

			$step = "panel";

		}
		else {

			$step = "o+1";

		}

		foreach
		  my $l ( CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_nMill, EnumsGeneral->LAYERTYPE_nplt_nDrill ] ) )
		{

			my $uniDTM = UniDTM->new( $inCAM, $jobId, $step, $l->{"gROWname"}, 1 );
			my @tools = grep { $_->GetTypeProcess() eq EnumsDrill->TypeProc_HOLE } $uniDTM->GetUniqueTools();
			if ( scalar( grep { $_->GetDrillSize() <= 1000 } @tools ) ) {

				# There are holes smaller than 1000µm, check if anz of tham are not pilot holes

				my $f = Features->new();

				$f->Parse( $inCAM, $jobId, $step, $l->{"gROWname"}, 1 );

				my @features =
				  map { $_->{"thick"} }
				  grep { $_->{"type"} eq "P" && $_->{"thick"} <= 1000 && !defined $_->{"att"}->{".pilot_hole"} } $f->GetFeatures();

				if ( scalar(@features) ) {

					$self->_AddChange(
									   "Frézovací vrstva: "
										 . $l->{"gROWname"}
										 . " obsahuje nástroje menší jak 1000µm (netýká se pilot holes / předvrtání ). "
										 . " Seznam nástrojů pro přesunutí do prokoveného vrtání: "
										 . join( "; ", map { $_ . "µm" } uniq(@features) ),
									   0
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

}

1;

