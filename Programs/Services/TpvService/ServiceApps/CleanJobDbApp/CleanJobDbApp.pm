#-------------------------------------------------------------------------------------------#
# Description: App which automatically create ODB file of jobs, which are not in format DXXXXXX
# Store it to special archive folder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::CleanJobDbApp::CleanJobDbApp;
use base("Programs::Services::TpvService::ServiceApps::ServiceAppBase");

use Class::Interface;
&implements('Programs::Services::TpvService::ServiceApps::IServiceApp');

#3th party library
use strict;
use warnings;
use Data::Dump qw(dump);
use File::Basename;
use Log::Log4perl qw(get_logger);
use List::MoreUtils qw(uniq);
use File::Path 'rmtree';
use Win32::Process;

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

	my $appName       = EnumsApp->App_CLEANJOBDB;
	my $serverTimeout = 120;                                                  # 4 hours
	my $self          = $class->SUPER::new( $appName, $serverTimeout, @_ );

	#my $self = {};
	bless $self;

	$self->_SetLogging();

	# All controls

	$self->{"inCAM"}         = undef;
	$self->{"processedJobs"} = 0;
	$self->{"maxLim"}        = 5;
	$self->{"notEditedDays"} = 30;      # archive jobs which are not edited more than X days

	return $self;
}

# -----------------------------------------------
# Public method, implements interface IServiceApp
#------------------------------------------------
sub Run {
	my $self = shift;

	eval {

		# 1) delete mdi files of pcb which are not in produce
		$self->__DeleteOldMDIFiles();

		# 2) delete mdi files of pcb which are not in produce
		$self->__DeleteOldJetFiles();

		# 3) delete app logs, where are stored logs from failed app
		$self->__DeleteAppLogs();


		# 3) cleanup InCAM databases
		#$self->__RunDBUtil();

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

		if ( CamJob->IsJobOpen( $self->{"inCAM"}, $jobId, 1 ) ) {
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

	my @job2Archive = grep { $_->{"name"} !~ /^d\d{6}$/ } JobHelper->GetJobListAll();

	# archive jobs which are edited before more than 3 weeks
	my $s = $self->{"notEditedDays"} * 3600 * 24;

	@job2Archive = map { $_->{"name"} } grep { ( time() - $_->{"updated"} ) > $s } @job2Archive;

	# limit if more than 30jobs, in order don't block  another service apps
	$logger->info( "Number of jobs to archive edited before more than " . $self->{"notEditedDays"} . "  days: " . scalar(@job2Archive) . "\n" );

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

sub __DeleteOldMDIFiles {
	my $self = shift;

	my @pcbInProduc =
	  HegMethods->GetPcbsByStatus( 2, 4, 12, 25, 35 );   # get pcb "Ve vyrobe" + "Na predvyrobni priprave" + Na odsouhlaseni + Schvalena + Pozastavena
	@pcbInProduc = map { $_->{"reference_subjektu"} } @pcbInProduc;

	if ( scalar(@pcbInProduc) < 100 ) {

		$self->{"logger"}->debug( "No pcb in produc (count : " . scalar(@pcbInProduc) . "), error?" );
	}

	unless ( scalar(@pcbInProduc) ) {
		return 0;
	}

	my $deletedFiles = 0;
	my @deletedJobs  = ();

	my $p = EnumsPaths->Jobs_MDI;
	if ( opendir( my $dir, $p ) ) {
		while ( my $file = readdir($dir) ) {
			next if ( $file =~ /^\.$/ );
			next if ( $file =~ /^\.\.$/ );

			my ($fileJobId) = $file =~ m/^(\w\d{6})/i;

			unless ( defined $fileJobId ) {
				next;
			}

			my $inProduc = scalar( grep { $_ =~ /^$fileJobId$/i } @pcbInProduc );

			unless ($inProduc) {

				push( @deletedJobs, $fileJobId );

				if ( $file =~ /\.(ger|xml)/i ) {

					unlink $p . $file;
					$deletedFiles++;
				}
			}
		}

		closedir($dir);
	}

	# Log deleted files
	foreach my $pcbId ( uniq(@deletedJobs) ) {

		my $state = HegMethods->GetStatusOfOrder( $pcbId . "-" . HegMethods->GetPcbOrderNumber($pcbId), 1 );
		$self->{"logger"}->debug("Deleted MDI job: $pcbId - $state");
	}

	$self->{"logger"}->info("Number of deleted job from MDI folder: $deletedFiles");
}


sub __DeleteOldMDITTFiles {
	my $self = shift;

	my @pcbInProduc =
	  HegMethods->GetPcbsByStatus( 2, 4, 12, 25, 35 );   # get pcb "Ve vyrobe" + "Na predvyrobni priprave" + Na odsouhlaseni + Schvalena + Pozastavena
	@pcbInProduc = map { $_->{"reference_subjektu"} } @pcbInProduc;

	if ( scalar(@pcbInProduc) < 100 ) {

		$self->{"logger"}->debug( "No pcb in produc (count : " . scalar(@pcbInProduc) . "), error?" );
	}

	unless ( scalar(@pcbInProduc) ) {
		return 0;
	}

	my $deletedFiles = 0;
	my @deletedJobs  = ();

	my $p = EnumsPaths->Jobs_MDITT;
	if ( opendir( my $dir, $p ) ) {
		while ( my $file = readdir($dir) ) {
			next if ( $file =~ /^\.$/ );
			next if ( $file =~ /^\.\.$/ );

			my ($fileJobId) = $file =~ m/^(\w\d{6})/i;

			unless ( defined $fileJobId ) {
				next;
			}

			my $inProduc = scalar( grep { $_ =~ /^$fileJobId$/i } @pcbInProduc );

			unless ($inProduc) {

				push( @deletedJobs, $fileJobId );

				if ( $file =~ /\.(gbr|xml)/i ) {

					unlink $p . $file;
					$deletedFiles++;
				}
			}
		}

		closedir($dir);
	}

	# Log deleted files
	foreach my $pcbId ( uniq(@deletedJobs) ) {

		my $state = HegMethods->GetStatusOfOrder( $pcbId . "-" . HegMethods->GetPcbOrderNumber($pcbId), 1 );
		$self->{"logger"}->debug("Deleted MDITT job: $pcbId - $state");
	}

	$self->{"logger"}->info("Number of deleted job from MDI TT folder: $deletedFiles");
}

sub __DeleteOldJetFiles {
	my $self = shift;

	my @pcbInProduc =
	  HegMethods->GetPcbsByStatus( 2, 4, 12, 25, 35 );   # get pcb "Ve vyrobe" + "Na predvyrobni priprave" + Na odsouhlaseni + Schvalena + Pozastavena
	@pcbInProduc = map { $_->{"reference_subjektu"} } @pcbInProduc;

	if ( scalar(@pcbInProduc) < 100 ) {

		$self->{"logger"}->debug( "No pcb in produc (count : " . scalar(@pcbInProduc) . "), error?" );
	}

	unless ( scalar(@pcbInProduc) ) {
		return 0;
	}

	# delete files from EnumsPaths->Jobs_JETPRINT
	my $deletedFiles = 0;

	my $p = EnumsPaths->Jobs_JETPRINT;
	if ( opendir( my $dir, $p ) ) {
		while ( my $file = readdir($dir) ) {
			next if ( $file =~ /^\.$/ );
			next if ( $file =~ /^\.\.$/ );

			my ($fileJobId) = $file =~ m/^(\w\d+)/i;

			unless ( defined $fileJobId ) {
				next;
			}

			my $inProduc = scalar( grep { $_ =~ /^$fileJobId$/i } @pcbInProduc );

			unless ($inProduc) {
				if ( $file =~ /\.ger/i ) {

					unlink $p . $file;
					$deletedFiles++;
				}
			}
		}

		closedir($dir);
	}

	$self->{"logger"}->info("Number of deleted job from Jetprint folder $p: $deletedFiles");

	# Delete working folders from jetprint machine folder Jobs_JETPRINTMACHINE

	my $deletedFolders = 0;

	my $p2 = EnumsPaths->Jobs_JETPRINTMACHINE;
	if ( opendir( my $dir, $p2 ) ) {
		while ( my $workDir = readdir($dir) ) {
			next if ( $workDir =~ /^\.$/ );
			next if ( $workDir =~ /^\.\.$/ );

			my ($folderJobId) = $workDir =~ m/^(\w\d+)\w+_jet$/i;

			unless ( defined $folderJobId ) {
				next;
			}

			my $inProduc = scalar( grep { $_ =~ /^$folderJobId$/i } @pcbInProduc );

			unless ($inProduc) {

				if ( rmtree( $p2 . $workDir ) ) {
					$deletedFolders++;
				}
				else {

					$self->{"logger"}->error( "Cannot rmtree " . $p2 . $workDir );
				}
			}
		}

		closedir($dir);
	}

	$self->{"logger"}->info("Number of deleted jobs from Jetprint machine folder $p2: $deletedFolders");
}

# Remove old app logs from applogs path
sub __DeleteAppLogs {
	my $self = shift;

	my $appLog = EnumsPaths->Jobs_APPLOGS;
	opendir( DIR, $appLog ) or die $!;

	my $totalLogDeleted = 0;

	while ( my $dir = readdir(DIR) ) {

		next if ( $dir =~ /^\.$/ );
		next if ( $dir =~ /^\.\.$/ );

		my $dir = $appLog . $dir;

		my @stats = stat($dir);

		# remove older than 3 months
		if ( -d $dir && ( time() - $stats[10] ) > 1 * 60 * 60 * 24 * 30 ) {

			$totalLogDeleted++;

			rmdir($dir);
		}
	}

	$self->{"logger"}->info("Number of deleted log DIRs from: $appLog is: $totalLogDeleted");

	close(DIR);
}



#sub __RunDBUtil {
#	my $self = shift;
#
#	my $DBUtilPath = GeneralHelper->GetLastInCAMVersion();
#
#	$DBUtilPath .= "bin\\dbutil.exe";
#
#	if ( -f $DBUtilPath )    # does it exist?
#	{
#
#		my $log = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();
#
#		$self->{"logger"}->info("Run dbutil.exe from: $DBUtilPath ");
#
#		system($DBUtilPath." check y 2>$log");
#

#
#		if(-f $log){
#
#			my $str = FileHelper->ReadAsString($log);
#			unlink($log);
#
#			$self->{"logger"}->info("DBUTIL error message:\n\n $str");
#
#		}
#	}
#	else {
#
#		$self->{"logger"}->error(" DButil at path: $DBUtilPath doesn't exist");
#	}
#}

# store err to logs
sub __ProcessError {
	my $self    = shift;
	my $jobId   = shift;
	my $errMess = shift;

	print STDERR $errMess;

	# log error to file
	$self->{"logger"}->error($errMess);

	# sent error to log db
	#$self->{"loggerDB"}->Error( $jobId, $errMess );

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

