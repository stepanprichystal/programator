#-------------------------------------------------------------------------------------------#
# Description: Floatten score in SR steps to mpanel
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Netlist::NetlistControl;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::CAM::Netlist::NetlistCompare';
use aliased 'CamHelpers::CamNetlist';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamLayer';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub DoControl {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $notClose = shift;

	my $result = 1;

	my $messMngr = MessageMngr->new($jobId);

	my $O1_pnlExist = 0;
	unless ( $self->__CheckO1Panel( $inCAM, $jobId, $messMngr, \$O1_pnlExist ) ) {

		return 0;
	}

	my $pnlExist = CamHelper->StepExists( $inCAM, $jobId, "panel" );

	my @steps = ();

	if ($pnlExist) {

		# Standard
		@steps = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueStepAndRepeat( $inCAM, $jobId );

	}
	else {

		# Pool
		@steps = ("o+1");
	}

	my @troubleL = $self->__IdentifyTroubleLayers( $inCAM, $jobId );

	my $nc = NetlistCompare->new( $inCAM, $jobId );

	for ( my $i = 0 ; $i < scalar(@steps) ; $i++ ) {

		my $s = $steps[$i];

		my $report        = undef;
		my $repeatTesting = 1;
		my $trblLCreated  = 0;

		while ($repeatTesting) {

			if ( CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $s ) ) {

				$report = $nc->ComparePanel($s);
			}
			else {

				if ( $s eq "o+1" && $O1_pnlExist ) {
					$report = $nc->Compare1Up( "o+1", "o+1_panel" );
				}
				else {
					$report = $nc->Compare1Up($s);
				}
			}

			if ( $report->Result() ) {

				$result        = 1;
				$repeatTesting = 0;
				my @mess = (
							 "Netlistov?? kontrola stepu: \"$s\" prob??hla <b>??SP????N??</b>.",
							 , " - kontrolovan?? stepy:  " . $report->GetStepRef() . " (origin??l) vs " . $report->GetStep() . " (upraven??)"
				);

				if ($trblLCreated) {
					push( @mess,
						      "\n<r>Probl??mov?? vrstvy: "
							. join( "; ", map { $_->{"gROWname"} } @troubleL )
							. " budou zp??t nastaveny jako \"board\".</r>" );
				}

				$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess, [ "Nezav??rat job", "Ok" ] );

				if ( defined $$notClose ) {

					$$notClose = $messMngr->Result() == 0 ? 1 : 0;
				}

				CamHelper->SetStep( $inCAM, $s );

				$inCAM->COM( 'rv_tab_empty', report => 'netlist_compare', is_empty => 'yes' );
				CamNetlist->RemoveNetlistSteps( $inCAM, $jobId, $s );

			}
			else {

				$result        = 0;
				$repeatTesting = 0;

				my @mess = (
							 "Dps <b>NEPRO??LA</b> netlistovou kontrolou pro step: \"$s\"!",
							 " - " . $report->GetShorts() . " shorts, " . $report->GetBrokens() . " brokens",
							 ,
							 " - kontrolovan?? stepy:  " . $report->GetStepRef() . " (origin??l) vs " . $report->GetStep() . " (upraven??)",
							 " - Pro informaci o zp??sobu kontroly netlist?? => OneNote - Netlist kontrola"
				);

				if ($trblLCreated) {
					push( @mess,
						      "\n<r>Probl??mov?? vrstvy: "
							. join( "; ", map { $_->{"gROWname"} } @troubleL )
							. " budou zp??t nastaveny jako \"board\".</r>" );
				}

				if ( @troubleL && !$trblLCreated ) {
					push( @mess, "\n" );
					push( @mess,
						      "V jobu byly nalezeny NC vrstvy, kter?? m????ou zp??sobit p??eru??en??: <b>"
							. join( "; ", map { $_->{"gROWname"} } @troubleL )
							. "</b>." );
					push( @mess, "Chce?? nastavit do??asn?? vrstvy jako \"non board\" a spustit netlist test znovu?" );
					push( @mess, "\n<r>Pozor, u hloubkov?? fr??zy s ??hlov??m vrt??kem. Fyzicky m????e opravdu zasahovat do motivu!</r>" );

					$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR,
										  \@mess, [ "Ne, ukon??it test", "Ano, nastavit \"non board\" a zkusit znovu" ] );

					if ( $messMngr->Result() == 1 ) {

						$trblLCreated  = 1;
						$repeatTesting = 1;

						foreach my $l (@troubleL) {
							CamLayer->SetLayerContextLayer( $inCAM, $jobId, $l->{"gROWname"}, "misc" );
						}
					}
				}
				else {

					$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );

				}

			}

		}

		# Set trouble layers back as board
		if ($trblLCreated) {

			foreach my $l (@troubleL) {
				CamLayer->SetLayerContextLayer( $inCAM, $jobId, $l->{"gROWname"}, "board" );
			}
		}

	}

	return $result;
}

# check if exist helper panel " o + 1_panel "
sub __CheckO1Panel {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $messMngr = shift;
	my $pnlExist = shift;    # Ref o+1_panel, if exist

	$$pnlExist = CamHelper->StepExists( $inCAM, $jobId, "o+1_panel" );

	my $ref = CamStep->GetReferenceStep( $inCAM, $jobId, "o+1" );

	my %limO1  = CamJob->GetProfileLimits2( $inCAM, $jobId, "o+1" );
	my %limRef = CamJob->GetProfileLimits2( $inCAM, $jobId, $ref );

	my $o1W  = abs( $limO1{"xMax"} - $limO1{"xMin"} );
	my $o1H  = abs( $limO1{"yMax"} - $limO1{"yMin"} );
	my $refW = abs( $limRef{"xMax"} - $limRef{"xMin"} );
	my $refH = abs( $limRef{"yMax"} - $limRef{"yMin"} );

	# if dimension of o+1 and ref are differnet,
	# search panel o+1_panel which o+1 was created from
	if ( abs( $o1W - $refW ) > 0.01 || abs( $o1H - $refH ) > 0.01 ) {

		unless ($$pnlExist) {

			my @mess =
			  (   " Step \"o+1\" nam?? stejn?? rozm??ry jako \"$ref\", tedy \"o+1\" je flatennovan?? panel.\n"
				. "Pomocn?? panel \"o+1_panel\ ale neexistuje, nelze porovnat netlisty. Vytvo?? ho nebo porovnej alespo?? \"o+1_single\" s \"$ref\""
			  );

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );

			return 0;

		}
	}

	return 1;
}

sub __RemoveNetlistSteps {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	foreach my $step ( JobHelper->GetNetlistStepNames() ) {

		CamStep->DeleteStep( $inCAM, $jobId, $step );
	}
}

# Return NC layers which can cause trouble
# Depths with angle tool, stencil NC layers which go through signal layers..
sub __IdentifyTroubleLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my @troubleL = CamDrilling->GetNCLayersByTypes(
													$inCAM, $jobId,
													[
													   EnumsGeneral->LAYERTYPE_nplt_bMillTop, EnumsGeneral->LAYERTYPE_nplt_bMillBot,
													   EnumsGeneral->LAYERTYPE_nplt_lcMill,   EnumsGeneral->LAYERTYPE_nplt_lsMill,
													]
	);

	@troubleL = grep { $_->{"gROWcontext"} eq "board" } @troubleL;

	return @troubleL;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::Netlist::NetlistControl';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';

	my $inCAM = InCAM->new();

	my $jobId = "d272278";

	my $notClose = 0;

	my $res = NetlistControl->DoControl( $inCAM, $jobId, \$notClose );

}

1;

