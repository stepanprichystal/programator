#-------------------------------------------------------------------------------------------#
# Description: App which automatically create ODB file of jobs, which are not in produce
# Of odb is succesfully created, delete job from incam DB
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::ArchiveJobsApp::ArchiveJobsApp;
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

	my $appName = EnumsApp->App_ARCHIVEJOBS;
	my $self = $class->SUPER::new( $appName, @_ );

	#my $self = {};
	bless $self;

	$self->__SetLogging();

	# All controls

	$self->{"inCAM"}         = undef;
	$self->{"processedJobs"} = 0;
	$self->{"maxLim"}        = 20;

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

		$self->__ProcessError( $jobId, $errMess );
		return 0;
	}

	# 2) Try to create odb file
	my $odbCreated = $self->__CreateODB($jobId);

	# 3) if ODB was created, delete job from incam db
	if ($odbCreated) {

		$self->__ClearJobDir($jobId);

		$self->__DeleteJob( $jobId);

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

	$inCAM->COM( 'check_inout', "ent_type" => 'job', "job" => "$jobId", "mode" => 'test' );
	my $checked = $inCAM->GetReply();

	if ( $checked ne "no" ) {
		$$mess .= "Unable to archive job bacause is checked out by: $checked\n";
	}

	my $usr = undef;
	my $isOpen = CamJob->IsJobOpen( $inCAM, $jobId, 1, \$usr );

	if ($isOpen) {
		$$mess .= "Unable to archive job because is open by: $usr\n";
	}

	if ( $checked eq "no" && !$isOpen ) {
		$result = 0;
	}

	return $result;
}

# Return all jopbs which are not "in produce"
sub __GetJob2Archive {
	my $self = shift;

	my $logger = get_logger("archiveJobs");

	my @job2Archive = ();
	my @list = grep { /^[df]\d{5,6}$/ } JobHelper->GetJobList();

	@list = reverse @list;

	my @pcbInProduc = HegMethods->GetPcbsByStatus( 2, 4, 12, 25, 35 )
	  ;    # get pcb "Ve vyrobe" + "Na predvyrobni priprave" + Pozastavena + "Na odsouhlaseni" + "schvalena"
	@pcbInProduc = map { $_->{"reference_subjektu"} } @pcbInProduc;
	$_ = lc for @pcbInProduc;

	# test if @pcbInProduc is not empty, sometimes it return empty array
	if ( scalar(@pcbInProduc) == 0 ) {

		$logger->error("Helios return 0 dps in produce - error?");
		return @job2Archive;
	}

	my %tmp;
	@tmp{@pcbInProduc} = ();
	@job2Archive = grep { !exists $tmp{$_} } @list;

	# limit if more than 30jobs, in order don't block  another service apps
	$logger->info( "Number of jobs to archive: " . scalar(@job2Archive) . "\n" );

	return @job2Archive;
}

sub __CreateODB {
	my $self  = shift;
	my $jobId = shift;

	my $inCAM = $self->{"inCAM"};

	my $result = 0;

	my $logger = get_logger("archiveJobs");

	# 1) Test if exist archive dir
	my $archive = JobHelper->GetJobArchive("$jobId");
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
		}else{
		
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

		# if error   store to special fiel - temporary
		# get info about user
		use aliased 'Packages::NifFile::NifFile';
		my $nif = NifFile->new($jobId);
		if ( $nif->Exist() ) {
			my $mess = "USER= " . $nif->GetValue("zpracoval") . ",  JOB= $jobId";
			get_logger("archiveJobsTemp")->info($mess);
		}

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

		$self->{"logger"}->error("Job still exist after delete. Attempt number: ".$_);
		sleep(1);
	}
}

sub __ClearJobDir {
	my $self    = shift;
	my $jobId   = shift;
	my $archive = JobHelper->GetJobArchive($jobId);

	my $poolPath = FileHelper->GetFileNameByPattern( $archive, "\.pool" );

	if ($poolPath) {

		# remove all nc files
		if ( -e $archive . "nc" ) {
			unlink FileHelper->GetFilesNameByPattern( $archive . "nc", ".*" );
		}

		# remove all gerbers
		if ( -e $archive . "zdroje" ) {
			unlink FileHelper->GetFilesNameByPattern( $archive . "zdroje", "\.ger" );
		}

		# remove all opfx
		if ( -e $archive . "zdroje" ) {
			unlink FileHelper->GetFilesNameByPattern( $archive . "zdroje", "$jobId@" );
		}

		# remove all ot files
		if ( -e $archive . "zdroje" ) {
			unlink FileHelper->GetFilesNameByPattern( $archive . "zdroje\\ot", ".*" );
		}
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

sub __SetLogging {
	my $self = shift;

	$self->{"logger"} = get_logger("archiveJobs");

	$self->{"logger"}->debug("test of logging");

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

