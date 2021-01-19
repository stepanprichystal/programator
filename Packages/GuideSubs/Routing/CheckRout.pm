
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Routing::CheckRout;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::GuideSubs::Routing::Check1UpChain';
use aliased 'Packages::GuideSubs::Routing::Check1UpChainTool';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Packages::Routing::RoutLayer::RoutChecks::RoutLayer';
use aliased 'CamHelpers::CamLayer';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::JobHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;
	$self->{"layer"} = shift;

	#$self->{"resultItem"} = ItemResult->new("Final result");
	$self->{"messMngr"} = MessageMngr->new( $self->{"jobId"} );

	$self->{"isPool"} = HegMethods->GetPcbIsPool( $self->{"jobId"} );

	return $self;

}

sub Check {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};
	my $layer = $self->{"layer"};

	CamHelper->SetStep( $inCAM, $step );
	CamLayer->WorkLayer( $inCAM, $layer );

	# All PCB
	my $resRoutChainAtt = 0;
	while ( !$resRoutChainAtt ) {

		my $mess = "";

		$resRoutChainAtt = RoutLayer->RoutChainAttOk( $inCAM, $jobId, $step, $layer, \$mess );

		unless ($resRoutChainAtt) {

			my @m = ($mess);

			$self->{"messMngr"}->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@m );    #  Script se zastavi

			$inCAM->PAUSE("Oprav chybu a pokracuj...");
		}
	}

	# Pool PCB only
	if ( $self->{"isPool"} ) {

		my $resOnlyBridges = 0;
		while ( !$resOnlyBridges ) {

			$resOnlyBridges = Check1UpChain->OnlyBridges( $inCAM, $jobId, $step, $layer, $self->{"messMngr"} );

			unless ($resOnlyBridges) {
				$inCAM->PAUSE("Oprav chybu a pokracuj...");
			}
		}
	}

	# Pool PCB only
	if ( $self->{"isPool"} ) {
		my $resOutsideChains = 0;
		while ( !$resOutsideChains ) {

			$resOutsideChains = Check1UpChain->OutsideChains( $inCAM, $jobId, $step, $layer, $self->{"messMngr"} );

			unless ($resOutsideChains) {
				$inCAM->PAUSE("Oprav chybu a pokracuj...");
			}

		}
	}

	# Pool PCB only
	if ( $self->{"isPool"} ) {
		my $resOutlinePoolRout = 0;
		while ( !$resOutlinePoolRout ) {

			my $mess = "";

			$resOutlinePoolRout = Check1UpChain->OutlinePoolRoutChecks( $inCAM, $jobId, $step, $layer, \$mess );

			unless ($resOutlinePoolRout) {

				my @m = ($mess);

				$self->{"messMngr"}->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@m );    #  Script se zastavi

				$inCAM->PAUSE("Oprav chybu a pokracuj...");
			}

		}
	}

	# All PCB
	my $resOutlineRout = 0;
	while ( !$resOutlineRout ) {

		my $mess = "";

		$resOutlineRout = Check1UpChain->OutlineRoutChecks( $inCAM, $jobId, $step, $layer, \$mess );

		unless ($resOutlineRout) {

			my @m = ($mess);

			$self->{"messMngr"}->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@m );    #  Script se zastavi

			$inCAM->PAUSE("Oprav chybu a pokracuj...");
		}

	}

	# Pool PCB only
	if ( $self->{"isPool"} ) {
		my $resTestFindAndDrawStarts = 0;
		while ( !$resTestFindAndDrawStarts ) {

			# test theses PCB rotations
			my $test0   = 1;
			my $test90  = 0;
			my $test180 = 0;
			my $test270 = 1;

			$resTestFindAndDrawStarts =
			  Check1UpChain->TestFindAndDrawStarts( $inCAM, $jobId, $step, $layer, $test0, $test90, $test180, $test270, 1, $self->{"messMngr"} );

			unless ($resTestFindAndDrawStarts) {

				$inCAM->PAUSE("Oprav chybu a pokracuj...");
			}

		}
	}

	# Only flex (non standard rout dir + comp + riout start)
	if ( JobHelper->GetIsFlex($jobId)  ) {
		
		# test theses PCB rotations
		my $test0   = 1;
		my $test90  = 1;
		my $test180 = 1;
		my $test270 = 1;

		# continue also if result is not success (we need specify footdowns only if FSCH will be created)
		my $resTestFindAndDrawStarts =
		  Check1UpChain->TestFindAndDrawStarts( $inCAM, $jobId, $step, $layer, $test0, $test90, $test180, $test270, 0, $self->{"messMngr"} );
	}

	# All PCB
	my $resToolsAreOrdered = 0;
	while ( !$resToolsAreOrdered ) {

		my $mess = "";

		$resToolsAreOrdered = Check1UpChainTool->ToolsAreOrdered( $inCAM, $jobId, $step, $layer, $self->{"messMngr"} );

		unless ($resToolsAreOrdered) {
			$inCAM->PAUSE("Oprav chybu a pokracuj...");
		}

	}

	# All PCB
	my $resOutlineToolIsLast = 0;
	while ( !$resOutlineToolIsLast ) {

		my $mess = "";

		$resOutlineToolIsLast = Check1UpChainTool->OutlineToolIsLast( $inCAM, $jobId, $step, $layer, \$mess );

		unless ($resOutlineToolIsLast) {

			my @m = ($mess);

			$self->{"messMngr"}->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@m );    #  Script se zastavi
			$inCAM->PAUSE("Oprav chybu a pokracuj...");
		}

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::Routing::CheckRout';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d297280";

	my $check = CheckRout->new( $inCAM, $jobId, "o+1", "f" );
	$check->Check();

}

1;

