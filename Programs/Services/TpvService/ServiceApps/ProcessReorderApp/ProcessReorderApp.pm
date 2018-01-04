#-------------------------------------------------------------------------------------------#
# Description: App which process automatically reorders
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::ProcessReorderApp::ProcessReorderApp;
use base("Programs::Services::TpvService::ServiceApps::ServiceAppBase");

#use Class::Interface;
#&implements('Programs::Services::TpvService::ServiceApps::IServiceApp');

#3th party library
use strict;
use warnings;
use File::Copy;

#use File::Spec;
use File::Basename;
use Log::Log4perl qw(get_logger);

#local library
#use aliased 'Connectors::TpvConnector::TpvMethods';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsApp';
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Programs::Services::TpvService::ServiceApps::ProcessReorderApp::Enums';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Programs::Services::Helpers::AutoProcLog';
use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::ChangeFile';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsIS';
use aliased 'Packages::Reorder::ProcessReorder::ProcessReorder';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $appName = EnumsApp->App_PROCESSREORDER;
	my $self = $class->SUPER::new( $appName, @_ );

	#my $self = {};
	bless $self;

	$self->_SetLogging();

	# All controls

	$self->{"checks"} = undef;    # contain classes implement ICHeck
	$self->{"inCAM"}  = undef;

	#$self->__LoadChecks();

	return $self;
}

# -----------------------------------------------
# Public method, implements interface IServiceApp
#------------------------------------------------
sub Run {
	my $self = shift;

	eval {

		# 2) Load orders to auto process
		my @reorders = grep { defined $_->{"aktualni_krok"} && $_->{"aktualni_krok"} eq EnumsIS->CurStep_ZPRACOVANIAUTO } HegMethods->GetReorders();

		if ( scalar(@reorders) ) {

			$self->{"logger"}->debug("Before get InCAM");

			# we need incam do request for incam
			unless ( defined $self->{"inCAM"} ) {
				$self->{"inCAM"} = $self->_GetInCAM();
			}

			$self->{"logger"}->debug("After get InCAM");

			#my %hash = ( "reference_subjektu" => "f52457-02" );
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
}

sub __RunJob {
	my $self    = shift;
	my $orderId = shift;
	my ($jobId) = $orderId =~ /^(\w\d+)-\d+/i;
	$jobId = lc($jobId);

	# temp cond
	# if pcb is poool
	#my $isPool = HegMethods->GetPcbIsPool($jobId);

	#unless($isPool){
	#	return 0;
	#}

	#return 0;

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

		$self->__ProcessJobResult( $orderId, EnumsIS->CurStep_PROCESSREORDERERR, $err );
		
		# if job is open by server, close and checkin job after error (other server block job)
		 
		if(CamJob->IsJobOpen($self->{"inCAM"}, $jobId)){
			
			$self->{"inCAM"}->COM( "check_inout", "job" => "$jobId", "mode" => "in", "ent_type" => "job" );
			$self->{"inCAM"}->COM( "close_job", "job" => "$jobId" );
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
	
	# Unless job exist, give to order "empty" status again. Than Order will be properly processed by CheckReorderApp
	unless(CamJob->JobExist($inCAM, $jobId)){
		
		$self->{"logger"}->info("Job doesn't exist: $jobId");
		$self->__ProcessJobResult( $orderId, EnumsIS->CurStep_EMPTY);
		return 0;
	}

	# 1) Open Job

	$self->_OpenJob($jobId);

	# 2) Do automatic changes

	my $errMess        = "";
	my $processReorder = ProcessReorder->new( $inCAM, $jobId );
	my $result         = $processReorder->RunTasks( \$errMess );

	# 4) save job

	$self->_CloseJob($jobId);

	# 5) After close job
	# If pcb is standard, move prepared "export file" to dir checked by "ExportUtility"
	my $exportFile = EnumsPaths->Client_INCAMTMPOTHER . "processReorder\\$jobId";

	if ( -e $exportFile ) {
		unless ( move( $exportFile, EnumsPaths->Client_EXPORTFILES . "$jobId" ) ) {
			die "Unable to move export file $exportFile\n";
		}
	}

	# 6) set order state
	my $isPool = HegMethods->GetPcbIsPool($jobId);

	my $orderState = EnumsIS->CurStep_PROCESSREORDERERR;

	if ( $result == 1 && $isPool) {

		$orderState = EnumsIS->CurStep_KPANELIZACI;

	}
	elsif ( $result == 1 ) {

		$orderState = EnumsIS->CurStep_PROCESSREORDEROK;
	}

	$self->__ProcessJobResult( $orderId, $orderState, $errMess );

}

sub __ProcessJobResult {
	my $self       = shift;
	my $orderId    = shift;
	my $orderState = shift;
	my $errMess    = shift;

	my ($jobId) = $orderId =~ /^(\w\d+)-\d+/i;
	$jobId = lc($jobId);

	# 1) if state is error, set error message
	if ( $orderState eq EnumsIS->CurStep_PROCESSREORDERERR ) {

		# log error to file
		$self->{"logger"}->error($errMess);

		# sent error to log db
		$self->{"loggerDB"}->Error( $jobId, $errMess );

		# store error to job archive
		AutoProcLog->Create( $self->GetAppName(), $jobId, $errMess );
	}
	else {
		AutoProcLog->Delete($jobId);
		ChangeFile->Delete($jobId);

	}

	# 2) set state

	HegMethods->UpdatePcbOrderState( $orderId, $orderState );

}

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Programs::Services::TpvService::ServiceApps::ProcessReorderApp::ProcessReorderApp';
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

