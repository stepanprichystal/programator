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
	my @steps = CamStep->GetJobEditSteps( $inCAM, $jobId );

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

				my $restValType = Packages::CAMJob::Microsection::CouponZaxisMill::CPNTYPE_MATERIALRESTVAL;
				my $depthMillType = Packages::CAMJob::Microsection::CouponZaxisMill::CPNTYPE_DEPTHMILLINGVAL;

				my @cpnType = (
								"-",
								$restValType,
								$depthMillType
				);
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

	while (1) {

		# Generate coupons
		my @cpnStep = $cpnZAxis->CreateCoupons();

		# Let user to put coupon to panel
		my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, "panel" );
		my $sr = SRStep->new( $inCAM, $jobId, "panel" );

		for ( my $i = 0 ; $i < scalar(@cpnStep) ; $i++ ) {

			$sr->AddSRStep( $cpnStep[$i], $i * 20, $lim{"yMax"} + 10, 0, 1, 1, 1, 1 );
		}

		my @mess = (@messHead);
		push( @mess,
			      "1) Přesuň vygenerované stepy ideálně do aktivní oblasti přířezu, "
				. "pokud to nejde, umísti je do technologického okolí" );
		push( @mess,
			      "2) Pokud je na přířezu volné místo, duplikuj kupóny a umísti je na panel "
				. "ještě do další oblasti (ideálně jedna sada v horní polovině panelu, druhá ve spodní)" );
		push( @mess, $errMess );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess );

		CamHelper->SetStep( $inCAM, "panel" );

		$inCAM->PAUSE("Rozmisti kupony na panelu");

		my @allSteps = map { $_->{"stepName"} } CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, "panel" );

		my $cpnExist = 1;
		foreach my $cpnStep (@cpnStep) {

			my $exist = first { $_ eq $cpnStep } @allSteps;

			unless ($exist) {
				my @mess = (@messHead);
				push( @mess, "Ve stepu panel není umístěn kupon step: \"" . $cpnStep . "\"" );
				push( @mess, "Kupony budou nagenerovány znovu" );

				$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );
				$cpnExist = 0;
				last;
			}
		}

		last if ($cpnExist);

	}

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

	my $jobId = "d322953";

	my $res = DoZaxisCoupon->GenerateZaxisCoupons( $inCAM, $jobId );

}

1;

