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
use aliased 'CamHelpers::CamNetlist';

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


		if( $report->Result()){
			
			 my @mess = ( "Netlistová kontrola stepu: \"$s\" proběhla <b>ÚSPĚŠNĚ</b>.", 
			 ,  " - kontrolované stepy:  ". $report->GetStepRef() . " (originál) vs "  . $report->GetStep()." (upravený)");
		 	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess );
		 	
		 	CamHelper->SetStep($inCAM, $s);
		 	
		 	CamNetlist->RemoveNetlistSteps( $inCAM, $jobId, $s);
 		 	 
		}else {

			$result = 0;

			my @mess = (
						 "Dps <b>NEPROŠLA</b> netlistovou kontrolou pro step: \"$s\"!",
						   " - ".$report->GetShorts()
						   . " shorts, "
						   . $report->GetBrokens()
						   . " brokens",
						  ,  " - kontrolované stepy:  ". $report->GetStepRef() . " (originál) vs "  . $report->GetStep()." (upravený)",
						 " - Pro informaci o způsobu kontroly netlistů => OneNote - Netlist kontrola"
			);

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );
		}
	}
 
	return $result;
}

# check if exist helper panel "o+1_panel"
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
			  (   "Step \"o+1\" namá stejné rozměry jako \"$ref\", tedy \"o+1\" je flatennovaný panel.\n"
				. "Pomocný panel \"o+1_panel\ ale neexistuje, nelze porovnat netlisty. Vytvoř ho nebo porovnej alespoň \"o+1_single\" s \"$ref\""
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

	my $jobId = "f52457";

	my $res = NetlistControl->DoControl( $inCAM, $jobId );

}

1;

