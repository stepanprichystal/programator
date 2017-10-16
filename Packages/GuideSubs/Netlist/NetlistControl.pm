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
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::CAM::Netlist::NetlistCompare';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub DoControl {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

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
		@steps = map { $_->{"stepName"} } CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, "panel" );

	}
	else {

		# Pool
		@steps = ("o+1");
	}

	my $nc = NetlistCompare->new( $inCAM, $jobId );

	for ( my $i = 0 ; $i < scalar(@steps) ; $i++ ) {

		my $s = $steps[$i];

		my $report = undef;

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

		unless ( $report->Result() ) {

			$result = 0;

			my @mess = (
						 "Dps neprošla kontrolou netlistů ("
						   . $report->GetShorts()
						   . " shorts, "
						   . $report->GetBrokens()
						   . " brokens). Kontrolované stepy: "
						   . $report->GetStep() . ", "
						   . $report->GetStepRef(),
						 "Pro informaci o způsobu kontroly netlistů => OneNote - Netlist kontrola"
			);

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );
		}

		if ( $i + 1 != scalar(@steps) ) {
			$inCAM->PAUSE( "Pokraracovat v kontrole netlistů pro další step: " . $steps[ $i + 1 ] );
		}

	}
	
	# test if exist helper netlist steps
	# If so, delete after user check compare netlist result
	my @netlistSteps = JobHelper->GetNetlistStepNames();
	for(my $i = scalar (@netlistSteps)-1; $i >= 0; $i--){
		my $s = $netlistSteps[$i];
		
		if(! CamHelper->StepExists(  $inCAM, $jobId, $s) ){
			
			splice @netlistSteps, $i, 1;
		}	
	}
	
	if(@netlistSteps){
		$inCAM->PAUSE( "Smazat pomocne netlist stepy: " . join(",", @netlistSteps) );
		$self->__RemoveNetlistSteps( $inCAM, $jobId);
	}

	return $result;
}

# check if
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
			  (   "Step \"o+1\" nemá stejné rozměry jako \"$ref\", tedy \"o+1\" je flatennovaný panel.\n"
				. "Pomocný panel \"o+1_panel\ ale neexistuje, nelze porovnat netlisty. Vytvoř ho nebo porovnej alespoň  \"o+1_single\" s \"$ref\""
			  );

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );

			return 0;

		}
	}

	return 1;
}

sub __RemoveNetlistSteps {
	my $self = shift;
	my $inCAM = shift;
	my $jobId = shift;

	foreach my $step ( JobHelper->GetNetlistStepNames() ) {

		CamStep->DeleteStep( $inCAM, $jobId, $step );
	}
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

	my $jobId = "f52456";

	my $res = NetlistControl->DoControl( $inCAM, $jobId );

}

1;

