#-------------------------------------------------------------------------------------------#
# Description: Set blind drill depths
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Drilling::BlindDrilling::BlindDrillTools;

#3th party library
use utf8;
use strict;
use warnings;
use Math::Trig;
use Clone qw(clone);

#local library
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAMJob::Drilling::BlindDrill::BlindDrillInfo';
use aliased 'Packages::CAMJob::Drilling::BlindDrill::BlindDrill';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsDrill';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamDTM';
use aliased 'Packages::CAMJob::Drilling::BlindDrill::Enums' => 'BlindEnums';
 
#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#
# Set blind drill depths form holes where is not defined depth yet
sub SetBlindDrills {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $layer    = shift;
	my $messMngr = shift;

	my %lInfo = ( "gROWname" => $layer );

	my $result = 0;

	while ( !$result ) {

		$result = 1;

		my $stackup = Stackup->new($inCAM, $jobId);
		CamDrilling->AddLayerStartStop( $inCAM, $jobId, [ \%lInfo ] );
		my @DTMTools = CamDTM->GetDTMTools( $inCAM, $jobId, $step, $layer, 0 );

		my @toolSet =
		  grep { defined $_->{"userColumns"}->{ EnumsDrill->DTMclmn_DEPTH } && $_->{"userColumns"}->{ EnumsDrill->DTMclmn_DEPTH } > 0 } @DTMTools;
		my @toolUnset =
		  grep { !defined $_->{"userColumns"}->{ EnumsDrill->DTMclmn_DEPTH } || $_->{"userColumns"}->{ EnumsDrill->DTMclmn_DEPTH } <= 0 } @DTMTools;

		# 1) Proces tools without depth
		my $tReport = "1) Otvory bez vyplněné hloubky vrtání:\n";

		foreach my $t (@toolUnset) {

			my $drillSize = $t->{"gTOOLdrill_size"};

			$tReport .= "<b>• Otvor: " . $drillSize . "µm</b>:";

			my %resType = ();
			my $blindType = BlindDrill->GetDrillType( $stackup, $drillSize, \%lInfo, \%resType );

			unless ($blindType) {

				my $t1 = $resType{ BlindEnums->BLINDTYPE_STANDARD };
				my $t2 = $resType{ BlindEnums->BLINDTYPE_SPECIAL };
				$tReport .= " <r>FAIL</r>: Nelze vyrobit slepý otvor pomocí žádné metody výpočtu hloubky:\n";
				$tReport .= "	" . BlindEnums->GetMethodName( BlindEnums->BLINDTYPE_STANDARD ) . ":\n";
				$tReport .=
				    "	- Aspect ratio otvoru: "
				  . ( $t1->{"arOk"} ? "<g>OK</g>" : "<r>FAIL</r>" )
				  . " (požadované: max 1.0, aktuální: "
				  . sprintf( "%.2f", $t1->{"ar"} ) . ") \n";
				$tReport .=
				    "	- Minimální izolace špičky vrtáku od Cu ("
				  . $t1->{"requestedIsolCuLayer"} . "): "
				  . ( $t1->{"isolOk"} ? "<g>OK</g>" : "<r>FAIL</r>" )
				  . " (požadovaná: "
				  . int( $t1->{"requestedIsolThick"} )
				  . " µm, aktuální: "
				  . int( $t1->{"currentIsolThick"} )
				  . " µm) \n";
				$tReport .= "	" . BlindEnums->GetMethodName( BlindEnums->BLINDTYPE_SPECIAL ) . ":\n";
				$tReport .=
				    "	- Aspect ratio otvoru: "
				  . ( $t2->{"arOk"} ? "<g>OK</g>" : "<r>FAIL</r>" )
				  . " (požadované: max 1.0, aktuální: "
				  . sprintf( "%.2f", $t2->{"ar"} ) . ") \n";
				$tReport .=
				    "	- Minimální izolace špičky vrtáku od Cu ("
				  . $t1->{"requestedIsolCuLayer"} . "): "
				  . ( $t2->{"isolOk"} ? "<g>OK</g>" : "<r>FAIL</r>" )
				  . " (požadovaná: "
				  . int( $t2->{"requestedIsolThick"} )
				  . " µm, aktuální: "
				  . int( $t2->{"currentIsolThick"} )
				  . " µm) \n\n";

				$result = 0;
			}
			else {

				my $depth = BlindDrill->ComputeDrillDepth( $stackup, $drillSize, \%lInfo, $blindType );
				$t->{"userColumns"}->{ EnumsDrill->DTMclmn_DEPTH } = sprintf( "%.2f", ( $depth / 1000 ) );

				my $typWarn = BlindEnums->GetMethodName($blindType);
				if ( $blindType eq BlindEnums->BLINDTYPE_SPECIAL ) {
					$typWarn = "<r>$typWarn - pozor nepoužívat na napojované!</r>";
				}

				$tReport .=
				    " <g>OK</g> Metoda výpočtu - $typWarn:\n"
				  . "	- Vypočítaná hloubka:  "
				  . sprintf( "%.2f", $depth )
				  . "µm \n"
				  . "	- Aspect ratio otvoru: "
				  . ( $resType{$blindType}->{"arOk"} ? "<g>OK</g>" : "<r>FAIL</r>" )
				  . " (požadované: <=1.0, vypočítané: "
				  . sprintf( "%.2f", $resType{$blindType}->{"ar"} ) . ") \n";
				$tReport .=
				    "	- Minimální izolace špičky vrtáku od Cu ("
				  . $resType{$blindType}->{"requestedIsolCuLayer"} . "): "
				  . ( $resType{$blindType}->{"isolOk"} ? "<g>OK</g>" : "<r>FAIL</r>" )
				  . " (požadovaná: "
				  . int( $resType{$blindType}->{"requestedIsolThick"} )
				  . " µm, vypočítané: "
				  . int( $resType{$blindType}->{"currentIsolThick"} )
				  . " µm) \n\n";

			}

		}

		# 2) Process tools already with depths
		$tReport .= "2) Otvory s vyplněnou hloubkou vrtání (script již hloubku nepřepíše):\n";

		foreach my $t (@toolSet) {
			my $drillSize = $t->{"gTOOLdrill_size"};

			$tReport .= "<b>• Otvor:  " . $drillSize . "µm</b>  \n";
		}

		# 3) Set tools
		my @b        = ("Nic nedělat");
		my $messType = EnumsGeneral->MessageType_QUESTION;
		if ( $result && scalar(@toolUnset) ) {

			push( @b, "Nastavit hloubky" );

		}
		elsif ( $result == 0 ) {

			push( @b, "Opravím průměry a složení" );
			$messType = EnumsGeneral->MessageType_WARNING;
		}

		$messMngr->ShowModal(
							  -1,
							  $messType,
							  [
								 "Výpočet hlopubky slepých otvorů (step: \"$step\", layer: \"$layer\"):\n",
								 "-------------------------------------------------------------------------\n",
								 $tReport,
								 "\nCo chcete udělat?"
							  ],
							  \@b
		);

		if ( $messMngr->Result() == 0 ) {
			last;
		}
		elsif ( $result && scalar(@toolUnset) && $messMngr->Result() == 1 ) {

			# Set depths
			CamDTM->SetDTMTools( $inCAM, $jobId, $step, $lInfo{"gROWname"}, \@DTMTools );
		}
		elsif ( $messMngr->Result() == 1 ) {

			# Continue, user repair tools/stackup
			$inCAM->PAUSE("Oprav slepe otvory...");
		}

	}

	return $result;
}

# Set blind drills to all layers all steps
sub SetBlindDrillsAllSteps {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $messMngr = shift;

	my $result = 1;

	my $step = 'panel';

	return 0 unless ( CamHelper->StepExists( $inCAM, $jobId, $step ) );
 

	foreach my $s ( CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, $step ) ) {

		foreach my $l (
						CamDrilling->GetNCLayersByTypes(
														 $inCAM, $jobId,
														 [
														   EnumsGeneral->LAYERTYPE_plt_bDrillTop,     EnumsGeneral->LAYERTYPE_plt_bDrillBot,
														   EnumsGeneral->LAYERTYPE_plt_bFillDrillTop, EnumsGeneral->LAYERTYPE_plt_bFillDrillBot
														 ]
						)
		  )
		{

			# set only if some hoels in layer
			my %fHist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $s->{"stepName"}, $l->{"gROWname"}, 0 );
			if ( $fHist{"total"} == 0 ) {
				next;
			}

			unless ( $self->SetBlindDrills( $inCAM, $jobId, $s->{"stepName"}, $l->{"gROWname"}, $messMngr ) ) {

				$result = 0;
			}
		}
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::Drilling::BlindDrilling::BlindDrillTools';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';

	my $messMngr = MessageMngr->new("D3333");

	my $inCAM = InCAM->new();

	my $jobId = "d326383";
	my $step  = "o+1";

	my $mess = "";

	my $res = BlindDrillTools->SetBlindDrillsAllSteps( $inCAM, $jobId, $messMngr );

}

1;

