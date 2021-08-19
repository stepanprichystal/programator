#-------------------------------------------------------------------------------------------#
# Description: Create zaxis coupons if depth milling exist
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Coupons::DoZaxisCoupon;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use List::Util qw(first);

#local library

use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::CAMJob::Microsection::CouponZaxisMill';
use aliased 'Packages::CAMJob::Panelization::SRStep';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#
my @messHead = ();
push( @messHead, "<g>=====================================</g>" );
push( @messHead, "<g>Průvodce vytvořením Z-Axis kuponů</g>" );
push( @messHead, "<g>=====================================</g>\n" );

sub GenerateZaxisCoupons {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $result = 1;

	my $messMngr = MessageMngr->new($jobId);

	my @depthLayers = CamDrilling->GetNCLayersByTypes(
													   $inCAM, $jobId,
													   [
														  EnumsGeneral->LAYERTYPE_nplt_bstiffcMill, EnumsGeneral->LAYERTYPE_nplt_bstiffcMill,
														  EnumsGeneral->LAYERTYPE_nplt_bMillTop,    EnumsGeneral->LAYERTYPE_nplt_bMillBot,
													   ]
	);

	return 0 if ( scalar(@depthLayers) == 0 );

	my @steps = CamStep->GetJobEditSteps( $inCAM, $jobId );

	my $cpnRequired = 0;    # indicatior if user require cpn

	foreach my $l (@depthLayers) {

		foreach my $s (@steps) {

			while (1) {

				# Check if there is surface, if not, skip
				my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $s, $l->{"gROWname"}, 0 );
				last if ( $hist{"surf"} == 0 );

				my @mess = (@messHead);
				push( @mess, "Ve stepu: \"" . $s . "\", vrstvě: <r>\"" . $l->{"gROWname"} . "\" </r>bylo nalezeno zahloubení surfacem." );
				push( @mess, "Přeješ si vytvořit kupon pro odladění hloubkové frézy dle <b>požadavků zákazníka</b>?\n" );
				push( @mess, "Pokud ano, zadej typ z-axis kupónu, případně tloušťku zbytku materiálu (pouze u typu \"MaterialRestValue\")" );
				push( @mess,
					      "- <i>"
						. Packages::CAMJob::Microsection::CouponZaxisMill::CPNTYPE_MATERIALRESTVAL
						. "</i>: Odladeni požadovaného zbytku materiálu" );
				push( @mess,
					      "- <i>"
						. Packages::CAMJob::Microsection::CouponZaxisMill::CPNTYPE_DEPTHMILLINGVAL
						. "</i>: Odladění požadované hloubky zahloubení" );

				my %pnlLAtt = CamAttributes->GetLayerAttr( $inCAM, $jobId, $s, $l->{"gROWname"} );

				my $parCpnRequiredDefVal = 0;
				if ( defined $pnlLAtt{"zaxis_rout_calibration_coupon"} && $pnlLAtt{"zaxis_rout_calibration_coupon"} !~ /none/i ) {
					$parCpnRequiredDefVal = 1;
				}

				my $parCpnRequired = $messMngr->GetCheckParameter( "Požaduji kupón", $parCpnRequiredDefVal );

				my $restValType   = Packages::CAMJob::Microsection::CouponZaxisMill::CPNTYPE_MATERIALRESTVAL;
				my $depthMillType = Packages::CAMJob::Microsection::CouponZaxisMill::CPNTYPE_DEPTHMILLINGVAL;

				my @cpnType = ( "-", $restValType, $depthMillType );
				my $parCpnTypeDefVal = $cpnType[0];
				if ( defined $pnlLAtt{"zaxis_rout_calibration_coupon"} && $pnlLAtt{"zaxis_rout_calibration_coupon"} !~ /none/i ) {
					$parCpnTypeDefVal = $pnlLAtt{"zaxis_rout_calibration_coupon"};
				}

				my $parCpnType = $messMngr->GetOptionParameter( "Typ z-axis kupónu", $parCpnTypeDefVal, \@cpnType );

				my $parThickDefVal = 0;
				if ( defined $pnlLAtt{"final_pcb_thickness"} && $pnlLAtt{"final_pcb_thickness"} != 0 ) {
					$parThickDefVal = $pnlLAtt{"final_pcb_thickness"};
				}
				my $parThick = $messMngr->GetTextParameter( "Celková tl. desky po odfrézování [um]", $parThickDefVal );

				my @params = ( $parCpnRequired, $parCpnType, $parThick );

				$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess, undef, undef, \@params );

				if ( $parCpnRequired->GetResultValue(1) ) {
					$cpnRequired = 1;
				}

				# Check if coupo is not required
				unless ( $parCpnRequired->GetResultValue(1) ) {

					my @mess = (@messHead);
					push( @mess, "Opravdu nepožaduješ vytvoření kupónu i když je ve vrstvě zahloubení surfacem?" );
					$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess, [ "Nepožaduji", "Požaduji" ] );
					if ( $messMngr->Result() == 0 ) {
						last;
					}
					else {
						next;
					}
				}

				# Check if coupon type is set
				if ( $parCpnRequired->GetResultValue(1) && ( !defined $parCpnType->GetResultValue(1) || $parCpnType->GetResultValue(1) =~ /-/ ) ) {

					my @mess = (@messHead);
					push( @mess, "Není zadán typ z-axis kupónu." );
					$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess, ["Opravím"] );
					next;
				}

				# Check if final PCB thickness is set
				use constant MINPCBTHICKNESS => 100;    # 100µm
				if ( $parCpnType->GetResultValue(1) =~ /^$restValType$/
					 && ( !defined $parThick->GetResultValue(1) || $parThick->GetResultValue(1) < MINPCBTHICKNESS ) )
				{

					my @mess = (@messHead);
					push( @mess, "Celková tloušťka DPS po odfrázování musí být větší než " . MINPCBTHICKNESS . "µm" );
					$messMngr->ShowModal( -1, EnumsGeneral->MessageType_QUESTION, \@mess, ["Opravím"] );
					next;

				}

				# Set coupon settings for layer
				CamAttributes->SetLayerAttribute( $inCAM,
												  "zaxis_rout_calibration_coupon",
												  $parCpnType->GetResultValue(1),
												  $jobId, $s, $l->{"gROWname"} );

				my $finalThick = 0;

				if ( $parCpnType->GetResultValue(1) =~ /^$restValType$/i ) {
					$finalThick = $parThick->GetResultValue(1);

				}
				CamAttributes->SetLayerAttribute( $inCAM, "final_pcb_thickness", $finalThick, $jobId, $s, $l->{"gROWname"} );

				last;

			}

		}

	}

	return 0 unless ($cpnRequired);

	# This step require Stackup if vv
	while (1) {

		my $res = 1;
		if ( CamJob->GetSignalLayerCnt( $inCAM, $jobId ) > 2 && !JobHelper->StackupExist($jobId) ) {
			$res = 0;
		}

		unless ($res) {

			my @mess = (@messHead);
			push( @mess, "Při vytvoření kupónu je nutné, aby existovalo složení" );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );

			$inCAM->PAUSE("Vytvor slozeni");
		}
		else {
			last;
		}
	}

	# Do final check before generate coupons
	my $cpnZAxis = CouponZaxisMill->new( $inCAM, $jobId );

	my $errMess = "";
	while ( !$cpnZAxis->CheckSpecifications( \$errMess ) ) {

		my @mess = (@messHead);
		push( @mess, "Chyba při kontrole nastavení Z-axis kupónů pomocí atributů vrstvy. Detail:" );
		push( @mess, $errMess );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );

		$errMess = "";

		$inCAM->PAUSE("Oprav chybu");
	}

	# Exit if no coupon specification
	return 0 if ( scalar( $cpnZAxis->GetAllSpecifications() ) == 0 );
	
	my @cpnStep = $cpnZAxis->CreateCoupons();

	 
	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::Coupons::DoZaxisCoupon';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';

	my $inCAM = InCAM->new();

	my $jobId = "d323981";

	my $res = DoZaxisCoupon->GenerateZaxisCoupons( $inCAM, $jobId );

}

1;

