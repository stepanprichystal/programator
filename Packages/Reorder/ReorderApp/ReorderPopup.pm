
#-------------------------------------------------------------------------------------------#
# Description: Application logic of checking and processing reorder
# Logic for poup form
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ReorderApp::ReorderPopup;

#3th party library
#use strict;
use warnings;
use threads;
use threads::shared;
use Wx;
use Try::Tiny;

#use strict;

#local library

use aliased 'Packages::Reorder::ReorderApp::Forms::ReorderPopupFrm';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::Events::Event';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Reorder::ReorderApp::Enums';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsIS';
use aliased 'Packages::Reorder::ProcessReorder::ProcessReorder';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Unit::Helper' => "UnitHelper";
use aliased 'Programs::Exporter::ExportChecker::Enums'                       => 'CheckerEnums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	#Events
	#$self->{"onResultEvt"} = Event->new();
	$self->{'onClose'} = Event->new();

	$self->{"checkErrMess"}  = "";
	$self->{"checkWarnMess"} = "";
	$self->{"procErrMess"} = "";

	$self->{"type"} = undef;    # type of process job locally/on server

	$self->{"isPool"} = HegMethods->GetPcbIsPool($self->{"jobId"});

	return $self;
}

sub Init {
	my $self = shift;

	my $parentFrm = shift;

	# Main application form
	$self->{"form"} = ReorderPopupFrm->new( $parentFrm->{"mainFrm"}, $self->{"jobId"} );

	$self->__SetHandlers();

}

sub Run {
	my $self = shift;

	$self->{"type"} = shift;

	my $inCAM = $self->{"inCAM"};
	$self->{"form"}->ShowPopup();

	if ( $self->__DoCheckReorder() ) {

		$self->__DoProcessReorder();
	}

}

# ================================================================================
# PRIVATE METHODS
# ================================================================================

sub __DoCheckReorder {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $errCnt  = 0;
	my $warnCnt = 0;

	my $result = 1;

	# Check if type is "on server"
	if ( $self->{"type"} eq Enums->Process_SERVER ) {

		if ( $self->{"isPool"} ) {

		}
		else {

			$self->{"checkErrMess"} = "";

			my $units = UnitHelper->PrepareUnits( $inCAM, $jobId );

			my @activeOnUnits = grep { $_->GetGroupState() eq CheckerEnums->GroupState_ACTIVEON } @{ $units->{"units"} };

			foreach my $unit (@activeOnUnits) {

				my $resultMngr = -1;
				my $succes = $unit->CheckBeforeExport( $inCAM, \$resultMngr );

				if ( $resultMngr->GetErrorsCnt() ) {

					$errCnt += $resultMngr->GetErrorsCnt();
					$result = 0;
					$self->{"checkErrMess"} .= $resultMngr->GetErrorsStr(1);
				}

				if ( $resultMngr->GetWarningsCnt() ) {

					$warnCnt += $resultMngr->GetWarningsCnt();
					$result = 0;
					$self->{"checkWarnMess"} .= $resultMngr->GetWarningsStr(1);
				}
			}
		}
	}

	$self->{"form"}->CheckReorderEnd( $errCnt, $warnCnt );

	unless ($result) {

		my $messMngr = $self->{"form"}->_GetMessageMngr();
		my @mess = ( "There are errors that need to be repaired.", $self->{"checkErrMess"}, $self->{"checkWarnMess"} );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );

	}

	if ( $errCnt > 0 ) {

		$self->{"form"}->SetResult( EnumsGeneral->ResultType_FAIL, 0, 1 );

	}
	elsif ( $errCnt == 0 && $warnCnt > 0 ) {

		$self->{"form"}->SetResult( EnumsGeneral->ResultType_FAIL, 1, 1 );
	}

	return $result;
}

sub __DoProcessReorder {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;

	my $messMngr = $self->{"form"}->_GetMessageMngr();

	$self->{"form"}->ProcessReorderStart();

	# Need to exception during process job
	eval {

		# 3) Process job
		if ( $self->{"type"} eq Enums->Process_LOCALLY ) {

			$result = $self->__ProcessLocally();

		}
		elsif ( $self->{"type"} eq Enums->Process_SERVER ) {

			$result = $self->__ProcessServer();
		}

	};
	if ($@) {

		my $err = $@;

		$self->{"procErrMess"} = $err;

		my @mess = ( "Error during process reorder. Detail: " . $err );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );

		$result = 0;
	}

	$self->{"form"}->ProcessReorderEnd( $result ? 0 : 1 );

	if ($result) {
		$self->{"form"}->SetResult( EnumsGeneral->ResultType_OK, 0, 1 );
	}
	else {
		$self->{"form"}->SetResult( EnumsGeneral->ResultType_FAIL, 0, 1 );
	}

	# Show warning to export pcb manualy
	if ( $self->{"type"} eq Enums->Process_LOCALLY && !$self->{"isPool"} && $result ) {

		my @mess = ("Nezapomen nyni job jeste vyexportovat.");
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess );

	}
	return $result;
}

sub __ProcessLocally {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $errMess = "";
	my $processReorder = ProcessReorder->new( $inCAM, $jobId );

	unless ( $self->{"isPool"} ) {
		unless ( $processReorder->ExcludeChange("EXPORT") ) {
			die "Unable to exclude automatic change \"EXPORT\"";
		}
	}

	my $result = $processReorder->RunChanges( \$errMess );

	if ($result) {

		# 2) Set state

		my $orderState = EnumsIS->CurStep_PROCESSREORDEROK;

		if ( $self->{"isPool"} ) {

			$orderState = EnumsIS->CurStep_KPANELIZACI;

		}

		my @orders = HegMethods->GetPcbReorders($jobId);
		@orders = grep { $_->{"aktualni_krok"} eq EnumsIS->CurStep_ZPRACOVANIMAN } @orders;    # filter only order zpracovani-rucni

		foreach (@orders) {

			HegMethods->UpdatePcbOrderState( $_->{"reference_subjektu"}, $orderState );
		}
	}

	unless ($result) {

		die $errMess;
	}

	return 1;

}

sub __ProcessServer {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1) Close job

	$self->{"inCAM"}->COM( "save_job",    "job" => "$jobId" );
	$self->{"inCAM"}->COM( "check_inout", "job" => "$jobId", "mode" => "in", "ent_type" => "job" );
	$self->{"inCAM"}->COM( "close_job",   "job" => "$jobId" );

	# 2) Set IS state

	my @orders = HegMethods->GetPcbReorders( $self->{"jobId"} );
	@orders = grep { $_->{"aktualni_krok"} eq EnumsIS->CurStep_ZPRACOVANIMAN } @orders;    # filter only order zpracovani-rucni

	foreach (@orders) {

		HegMethods->UpdatePcbOrderState( $_->{"reference_subjektu"}, EnumsIS->CurStep_ZPRACOVANIAUTO );
	}

	return 1;

}

sub __SetHandlers {
	my $self = shift;

	$self->{"form"}->{"checkIndicatorClick"}->Add( sub { $self->__OnCheckIndicatorClick(@_) } );
	$self->{"form"}->{'procIndicatorClick'}->Add( sub  { $self->__OnProcIndicatorClick(@_) } );
	$self->{"form"}->{'continueClick'}->Add( sub       { $self->__OnContinueClick(@_) } );
	$self->{"form"}->{'okClick'}->Add( sub             { $self->__OnOkClick(@_) } );
}

# ================================================================================
# FORM HANDLERS
# ================================================================================

sub __OnCheckIndicatorClick {
	my $self = shift;
	my $type = shift;

	my $messMngr = $self->{"form"}->_GetMessageMngr();

	if ( $type eq EnumsGeneral->MessageType_ERROR ) {

		my @mess = ( $self->{"checkErrMess"} );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );

	}
	elsif ( $type eq EnumsGeneral->MessageType_WARNING ) {

		my @mess = ( $self->{"checkWarnMess"} );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess );

	}
}

sub __OnProcIndicatorClick {
	my $self = shift;
	my $type = shift;

	my $messMngr = $self->{"form"}->_GetMessageMngr();

	my @mess = ( $self->{"procErrMess"} );
	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );

}

sub __OnContinueClick {
	my $self = shift;

	$self->__DoProcessReorder();

}

sub __OnOkClick {
	my $self = shift;

	$self->{"form"}->{"mainFrm"}->Hide();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::ExportChecker';

	#my $form = ExportChecker->new();

}

1;

