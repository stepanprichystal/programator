#-------------------------------------------------------------------------------------------#
# Description: App which automatically create ODB file of jobs, which are not in format DXXXXXX
# Store it to special archive folder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::CleanJobDbApp::CleanJobDbApp;
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
use aliased 'Enums::EnumsApp';
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $appName = EnumsApp->App_CLEANJOBDB;
	my $self = $class->SUPER::new( $appName, @_ );

	#my $self = {};
	bless $self;

	$self->_SetLogging();

	# All controls

	$self->{"inCAM"}         = undef;
	$self->{"processedJobs"} = 0;
	$self->{"maxLim"}        = 20;
	$self->{"notEditedDays"}        = 30; # archive jobs which are not edited more than X days

	return $self;
}

# -----------------------------------------------
# Public method, implements interface IServiceApp
#------------------------------------------------
sub Run {
	my $self = shift;

	eval {

		# 1) Get jobs to archvie
		my @jobs = $self->__GetJob2Archive();

		if ( scalar(@jobs) ) {

			$self->{"logger"}->debug("Before get InCAM");

			# we need incam do request for incam
			unless ( defined $self->{"inCAM"} ) {
				$self->{"inCAM"} = $self->_GetInCAM();
			}

			$self->{"logger"}->debug("After get InCAM");

			foreach my $jobId (@jobs) {

				$self->{"logger"}->info("Process job: $jobId");

				$self->__RunJob($jobId);

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
	my $self  = shift;
	my $jobId = shift;

	eval {

		$self->__ProcessJob($jobId)

	};
	if ($@) {

		my $eStr = $@;
		my $e    = $@;

		if ( ref($e) && $e->can("Error") ) {

			$eStr = $e->Error();
		}

		my $err = "Process job id: \"$jobId\" exited with error: \n $eStr";

		$self->__ProcessError( $jobId, $err );

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
	my $self  = shift;
	my $jobId = shift;

	$jobId = lc($jobId);

	my $inCAM = $self->{"inCAM"};

	# 1) Test if job is not open and not checked out by someone

	my $errMess = "";
	my $inUse = $self->__JobInUse( $jobId, \$errMess );

	if ($inUse) {

		# if in log error, but dont store error to db, just skip archivation
		$self->{"logger"}->error($errMess);
		return 0;
	}
	
 

	# 2) Try to create odb file
	my $odbCreated = $self->__CreateODB($jobId);

	# 3) if ODB was created, delete job from incam db
	if ($odbCreated) {
 
		$self->__DeleteJob($jobId);

		$self->{"processedJobs"}++;
	}
}

# Get if job is checked out or open by user
sub __JobInUse {
	my $self  = shift;
	my $jobId = shift;
	my $mess  = shift;

	my $inCAM = $self->{"inCAM"};

	my $result = 1;

	my $usr = undef;
	my $isOpen = CamJob->IsJobOpen( $inCAM, $jobId, 1, \$usr );

	if ($isOpen) {
		$$mess .= "Unable to archive job because is open by: $usr\n";
	}

	$inCAM->COM( 'check_inout', "ent_type" => 'job', "job" => "$jobId", "mode" => 'test' );
	my $checked = $inCAM->GetReply();

	my $checkinOk = 1;
	if ( $checked ne "no" ) {

		# If job is not open, try checkin job
		if ( !$isOpen ) {

			$inCAM->HandleException(1);
			my $res = $inCAM->COM( "checkin_closed_job", "job" => "$jobId" );
			$inCAM->HandleException(0);

			# if checin is not possible, error
			if ( $res != 0 ) {
				$$mess .= "Unable to archive job bacause is checked out by: $checked\n";
				$checkinOk = 0;
			}
		}
	}

	if ( $checkinOk && !$isOpen ) {
		$result = 0;
	}

	return $result;
}

# Return all jopbs which are not "in produce"
sub __GetJob2Archive {
	my $self = shift;

	my $logger = get_logger("archiveJobs");

	 
	my @job2Archive =  grep { $_->{"name"} !~ /^d\d{6}$/ } JobHelper->GetJobListAll();

	# archive jobs which are edited before more than 3 weeks
	my $s = $self->{"notEditedDays"} *3600 * 24;

	@job2Archive = map { $_->{"name"} } grep { (time() -  $_->{"updated"}) > $s } @job2Archive;
	
 
	# limit if more than 30jobs, in order don't block  another service apps
	$logger->info( "Number of jobs to archive edited before more than ".$self->{"notEditedDays"}."  days: " . scalar(@job2Archive) . "\n" );

	return @job2Archive;
}

sub __CreateODB {
	my $self  = shift;
	my $jobId = shift;

	my $inCAM = $self->{"inCAM"};

	my $result = 0;

	my $logger = get_logger("archiveJobs");

	# 1) Get archive path by JobId format:
	my $archive = EnumsPaths->Jobs_ARCHIVREMOVED;
 
	$archive =~ s/\\/\//g;

	unless ( -e $archive ) {
		die "Archive path $archive doesn't exist.\n";
	}

	# test if job phzsically exist in incam jobdb. If not, it is "incam joblist" error
	# Check if old tgz exist and skip creating odb
	my $jobDbPath = EnumsPaths->InCAM_jobs . $jobId;

	unless ( -e $jobDbPath ) {

		# if old tgz exist - solved, else die
		if ( -e $archive . $jobId . ".tgz" ) {

			$self->{"logger"}->error("Job source directory doesn't exist, but ODB file exist");

			$result = 1;
			return $result;
		}
		else {

			die "Job source directory doesn't exist ( $jobDbPath ). Odb file in job archive doesn't exist too.\n";
		}
	}

	$inCAM->HandleException(1);

	my $exportResult = $inCAM->COM( 'export_job', job => "$jobId", path => "$archive", mode => 'tar_gzip', submode => 'full', overwrite => 'yes' );

	$inCAM->HandleException(0);

	# if export ok, do check if odb file really exist
	if ( $exportResult == 0 ) {

		my $odbFile = $archive . $jobId . ".tgz";
		unless ( -e $odbFile ) {
			die "Error during export ODB file to archive, odb file: $odbFile doesn't exist\n";
		}

		my $fileSize = -s $odbFile;
		if ( $fileSize < 200 ) {
			die "Perhaps error during export ODB file to archive, odb file: $odbFile is smaller than 200kB\n";
		}

		if ( -e $odbFile && $fileSize >= 200 ) {
			$result = 1;
		}

	}
	else {
 
		die "Error during export ODB file to archive.\n " . $inCAM->GetExceptionError() . "\n";
	}

	return $result;
}

# Delete job
# Sometimes there is problem, job is succesfully deleted, but stay in job list
# Thus try 3 attemt of deletion
sub __DeleteJob {
	my $self  = shift;
	my $jobId = shift;

	my $inCAM = $self->{"inCAM"};

	my $result = 0;

	foreach ( 1 .. 3 ) {

		$inCAM->COM( 'delete_entity', "job" => '', "type" => 'job', "name" => "$jobId" );
		unless ( CamJob->JobExist( $inCAM, $jobId ) ) {
			last;
		}

		$self->{"logger"}->error( "Job still exist after delete. Attempt number: " . $_ );
		sleep(1);
	}
}
 

# store err to logs
sub __ProcessError {
	my $self    = shift;
	my $jobId   = shift;
	my $errMess = shift;

	print STDERR $errMess;

	# log error to file
	$self->{"logger"}->error($errMess);

	# sent error to log db
	$self->{"loggerDB"}->Error( $jobId, $errMess );

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

