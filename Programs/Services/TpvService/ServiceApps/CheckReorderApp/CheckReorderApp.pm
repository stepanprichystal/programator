#-------------------------------------------------------------------------------------------#
# Description: App unarchive jobs, do automatic changes and check changes, which are need
# to by done manually
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorderApp;
use base("Programs::Services::TpvService::ServiceApps::ServiceAppBase");

#use Class::Interface;
#&implements('Programs::Services::TpvService::ServiceApps::IServiceApp');

#3th party library
use strict;
use warnings;

#use File::Spec;
use File::Basename;
use Log::Log4perl qw(get_logger);

#local library
#use aliased 'Connectors::TpvConnector::TpvMethods';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsApp';
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsIS';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Programs::Services::Helpers::AutoProcLog';
use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::AcquireJob';

use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::ChangeFile';
use aliased 'Packages::Reorder::ChangeReorder::ChangeReorder';
use aliased 'Packages::Reorder::CheckReorder::CheckReorder';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $appName = EnumsApp->App_CHECKREORDER;
	my $self = $class->SUPER::new( $appName, @_ );

	#my $self = {};
	bless $self;

	$self->_SetLogging();

	$self->{"logger"}->debug("after logg");

	$self->{"checks"} = undef;    # contain classes implement ICHeck

	$self->{"inCAM"} = undef;

	$self->{"logger"}->debug("reorder init");

	return $self;
}

# -----------------------------------------------
# Public method, implements interface IServiceApp
#------------------------------------------------
sub Run {
	my $self = shift;

	$self->{"logger"}->debug("Check reorder run");

	eval {

		$self->{"logger"}->debug("In eval");

		# 2) Load Reorder pcb
		my @reorders = grep { !defined $_->{"aktualni_krok"} || $_->{"aktualni_krok"} eq "" } HegMethods->GetReorders();

		if ( scalar(@reorders) ) {

			$self->{"logger"}->debug("Before get InCAM");

			# we need incam do request for incam
			unless ( defined $self->{"inCAM"} ) {
				$self->{"inCAM"} = $self->_GetInCAM();
			}

			$self->{"logger"}->debug("After get InCAM");

			#my %hash = ( "reference_subjektu" => "f52456-01" );
			#@reorders = ( \%hash );

			foreach my $reorder (@reorders) {

				my $reorderId = $reorder->{"reference_subjektu"};

				$self->{"logger"}->info("Process reorder: $reorderId");

				$self->__RunJob($reorderId);
			}
		}

	};
	if ($@) {

		my $err = "Aplication: " . $self->GetAppName() . " exited with error: \n$@";
		$self->{"logger"}->error($err);
		$self->{"loggerDB"}->Error( undef, $err );
	}

	$self->{"logger"}->debug("Check reorder end");
}

sub __RunJob {
	my $self    = shift;
	my $orderId = shift;
	my ($jobId) = $orderId =~ /^(\w\d+)-\d+/i;
	$jobId = lc($jobId);

	# DEBUG DELETE
	#$self->__ProcessJob($orderId);
	#return 0;
	# DEBUG DELETE

	eval {

		$self->__ProcessJob($orderId)

	};
	if ($@) {

		my $eStr = $@;
		my $e    = $@;

		if ( ref($e) && $e->can("Error") ) {

			$eStr = $e->Error();
		}

		my $err = "Process order id: \"$orderId\" exited with error: \n $eStr";

		$self->__ProcessJobResult( $orderId, EnumsIS->CurStep_CHECKREORDERERROR, $err );

		# if job is open by server, close and checkin job after error (other server block job)

		if ( CamJob->IsJobOpen( $self->{"inCAM"}, $jobId ) ) {

			$self->{"inCAM"}->COM( "save_job",    "job" => "$jobId" );
			$self->{"inCAM"}->COM( "check_inout", "job" => "$jobId", "mode" => "in", "ent_type" => "job" );
			$self->{"inCAM"}->COM( "close_job",   "job" => "$jobId" );
		}

	}
}

## -----------------------------------------------
## Private method
##------------------------------------------------

sub __ProcessJob {
	my $self    = shift;
	my $orderId = shift;

	my $inCAM = $self->{"inCAM"};

	my ($jobId) = $orderId =~ /^(\w\d+)-\d+/i;
	$jobId = lc($jobId);

	# 1) Check if pcb exist in InCAM
	 
	$self->__CheckAncestor($jobId, $orderId);

	my $jobExist = AcquireJob->Acquire( $inCAM, $jobId );

	$self->_OpenJob($jobId);

	my @manCh = ();

	# 2) Check if job is former pool and now is standard
	my $isPool = HegMethods->GetPcbIsPool($jobId);
	my $pnlExist = CamHelper->StepExists( $inCAM, $jobId, "panel" );

	if ( !( !$isPool && !$pnlExist ) ) {

		#  Do all automatic changes
		if ($jobExist) {

			my $changeReorder = ChangeReorder->new( $inCAM, $jobId );
			my $errMess       = "";
			my $res           = $changeReorder->RunChanges( \$errMess );
			$self->{"inCAM"}->COM( "save_job", "job" => "$jobId" );

			unless ($res) {
				die $errMess;
			}
		}
	}

	# 3) Do all controls and return check which are neet to be repair manualz bz tpv user
	my $checkReorder = CheckReorder->new( $inCAM, $jobId );
	@manCh = $checkReorder->RunChecks();

	if ($jobExist) {
		$inCAM->COM( "check_inout", "job" => "$jobId", "mode" => "in", "ent_type" => "job" );
		$inCAM->COM( "close_job", "job" => "$jobId" );
	}

	# 4) set order state

	my $orderState = EnumsIS->CurStep_ZPRACOVANIAUTO;

	if ( scalar(@manCh) > 0 ) {

		$orderState = EnumsIS->CurStep_ZPRACOVANIMAN;

		ChangeFile->Create( $jobId, \@manCh );    # create changes file to archive

	}
	else {

		ChangeFile->Delete($jobId);
	}

	$self->__ProcessJobResult( $orderId, $orderState, undef );
}


#
sub __CheckAncestor {
	my $self  = shift;
	my $jobId = shift;
	my $orderId = shift;

	my $process = 1;

	my $inCAM = $self->{"inCAM"};

	# if reorder is -01 number and contain ancestor , Acquire ancestor first and copz to new JobId
	my $ancestor = "";

	if ($ancestor ) {

		if ( HegMethods->GetInfMasterSlave( HegMethods->GetPcbOrderNumber($ancestor) ) eq "M" ) {

			if ( AcquireJob->Acquire( $inCAM, $ancestor ) ) {
				CamJob->CopyJob( $ancestor, $jobId );
			}
			else {
				die "Unable Acquire ancestor job: $ancestor";
			}
		}
		else {

			die "Reorder $orderId contains \"ancestor\" which is not mother pcb";
		}
	}else{
		
		$process = 0;
	}
	
	return $process
}

sub __ProcessJobResult {
	my $self       = shift;
	my $orderId    = shift;
	my $orderState = shift;
	my $errMess    = shift;

	my ($jobId) = $orderId =~ /^(\w\d+)-\d+/i;
	$jobId = lc($jobId);

	# 1) if state is error, set error message
	if ( $orderState eq EnumsIS->CurStep_CHECKREORDERERROR ) {

		# log error to file
		$self->{"logger"}->error($errMess);

		# sent error to log db
		$self->{"loggerDB"}->Error( $jobId, $errMess );

		# store error to job archive
		AutoProcLog->Create( $self->GetAppName(), $jobId, $errMess );
	}
	else {
		AutoProcLog->Delete($jobId);
	}

	# 2) set state

	HegMethods->UpdatePcbOrderState( $orderId, $orderState );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorderApp';
	#
	#	#	use aliased 'Packages::InCAM::InCAM';
	#	#
	#
	#	my $sender = MailSender->new();
	#
	#	$sender->Run();
	#
	#	print "ee";
}

1;

