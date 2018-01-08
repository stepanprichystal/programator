#-------------------------------------------------------------------------------------------#
# Description: App which automatically create ODB file of jobs, which are not in produce
# Of odb is succesfully created, delete job from incam DB
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::TaskOnDemand::TaskOnDemandApp;
use base("Programs::Services::TpvService::ServiceApps::ServiceAppBase");

#use Class::Interface;
#&implements('Programs::Services::TpvService::ServiceApps::IServiceApp');

#3th party library
use strict;
use warnings;
use Data::Dump qw(dump);
use File::Basename;
use Log::Log4perl qw(get_logger);

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Connectors::TpvConnector::TaskOndemMethods';
use aliased 'Enums::EnumsApp';
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';
use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::AcquireJob';
use aliased 'Programs::Services::TpvService::ServiceApps::TaskOnDemand::Enums' => 'TaskEnums';
use aliased 'Programs::Services::TpvService::ServiceApps::TaskOnDemand::TaskOnDemand::ControlData';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $appName = EnumsApp->App_TASKONDEMAND;
	my $self = $class->SUPER::new( $appName, @_ );

	#my $self = {};
	bless $self;

	$self->_SetLogging();

	# All controls

	$self->{"inCAM"}         = undef;
	$self->{"processedJobs"} = 0;
	$self->{"maxLim"}        = 4;

	return $self;
}

# -----------------------------------------------
# Public method, implements interface IServiceApp
#------------------------------------------------
sub Run {
	my $self = shift;

	eval {

		# 1) Get jobs to archvie
		my @jobs = TaskOndemMethods->GetAllTasks();

		if ( scalar(@jobs) ) {

			$self->{"logger"}->debug("Before get InCAM");

			# we need incam do request for incam
			unless ( defined $self->{"inCAM"} ) {
				$self->{"inCAM"} = $self->_GetInCAM();
			}

			$self->{"logger"}->debug("After get InCAM");

			foreach my $jobInf (@jobs) {

				$self->{"logger"}->info(
						"Process task, jobId: " . $jobInf->{"JobId"} . " orderId: " . $jobInf->{"OrderId"} . " task type: " . $jobInf->{"TaskType"} );

				$self->__RunJob( $jobInf->{"JobId"}, $jobInf->{"OrderId"}, $jobInf->{"TaskType"}, $jobInf->{"Inserted"} );

				# check max limit of processed jobs in order app doesn't run too long
				# and block another app

				if ( $self->{"processedJobs"} >= $self->{"maxLim"} ) {
					last;
				}
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
	my $self     = shift;
	my $jobId    = shift;
	my $orderId  = shift;
	my $taskType = shift;
	my $inserted = shift;

	eval {

		$self->__ProcessJob( $jobId, $orderId, $taskType, $inserted );

	};
	if ($@) {

		my $eStr = $@;
		my $e    = $@;

		if ( ref($e) && $e->can("Error") ) {

			$eStr = $e->Error();
		}

		my $err = "Process job id: \"$jobId\" exited with error: \n $eStr";

		$self->__ProcessError( $jobId, $orderId, $taskType, $err );

		if ( CamJob->IsJobOpen( $self->{"inCAM"}, $jobId ) ) {
			$self->{"inCAM"}->COM( "check_inout", "job" => "$jobId", "mode" => "in", "ent_type" => "job" );
			$self->{"inCAM"}->COM( "close_job", "job" => "$jobId" );
		}
	}
}

## -----------------------------------------------
## Private method
##------------------------------------------------

sub __ProcessJob {
	my $self     = shift;
	my $jobId    = shift;
	my $orderId  = shift;
	my $taskType = shift;
	my $inserted = shift;

	$jobId = lc($jobId);

	my $inCAM = $self->{"inCAM"};

	# 1) Check if pcb exist in InCAM and import t InCAM
	my $jobExist = AcquireJob->Acquire( $inCAM, $jobId );
	
	my $errMess = "";
	my $result = undef;
 
	# process task
	if ( $taskType eq TaskEnums->Data_COOPERATION ) {

		my $data = ControlData->new($self, $inCAM, $jobId );
		$result = $data->Run( \$errMess, TaskEnums->Data_COOPERATION, $inserted );
		
		 
	}
	elsif ( $taskType eq TaskEnums->Data_CONTROL ) {

		my $data = ControlData->new($self, $inCAM, $jobId );
		$result = $data->Run( \$errMess, TaskEnums->Data_CONTROL, $inserted );
	}
	else {

		die "Not implemented type: $taskType"
	}
	
	if($result){
		
		$self->{"logger"}->info("Task $taskType - $jobId finish SUCCESFULL");
		
	}else{
		
		$self->{"logger"}->info("Task $taskType - $jobId FAILURE, error: $errMess");
	}

 
	if ($jobExist && CamJob->IsJobOpen($inCAM, $jobId)) {
		$inCAM->COM( "check_inout", "job" => "$jobId", "mode" => "in", "ent_type" => "job" );
		$inCAM->COM( "close_job", "job" => "$jobId" );
	}

	TaskOndemMethods->DeleteTaskPcb( $jobId, $taskType );

}

# store err to logs
sub __ProcessError {
	my $self     = shift;
	my $jobId    = shift;
	my $orderId  = shift;
	my $taskType = shift;
	my $errMess  = shift;

	print STDERR $errMess;

	# log error to file
	$self->{"logger"}->error($errMess);

	# sent error to log db
	#$self->{"loggerDB"}->Error( $jobId, $errMess );

	# remove task from db
	if ($orderId) {

		# delete order id task
	}
	else {
		TaskOndemMethods->DeleteTaskPcb( $jobId, $taskType );
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Programs::Services::TpvService::ServiceApps::ArchiveJobsApp::ArchiveJobsApp';
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

