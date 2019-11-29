#-------------------------------------------------------------------------------------------#
# Description: App which automatically create ODB file of jobs, which are not in produce
# Of odb is succesfully created, delete job from incam DB
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService2::ServiceApps::JobsReExport::JobsReExportApp;
use base("Programs::Services::TpvService2::ServiceApps::ServiceAppBase");

#use Class::Interface;
#&implements('Programs::Services::TpvService2::ServiceApps::IServiceApp');

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
use aliased 'Programs::Services::TpvService2::ServiceApps::TaskOnDemand::Enums' => 'TaskEnums';

use aliased 'Managers::AsyncJobMngr::Enums' => "EnumsJobMngr";
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Unit::Units';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupBuilder::StandardBuilder';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::GroupTable::GroupTables';
use aliased 'Programs::Exporter::ExportUtility::DataTransfer::DataTransfer';
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';
use aliased 'Programs::Exporter::ExportUtility::DataTransfer::Enums' => 'EnumsTransfer';
use aliased 'Programs::Exporter::ExportChecker::Enums'               => 'CheckerEnums';
use aliased 'Packages::NifFile::NifFile';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Unit::Helper' => "UnitHelper";

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $appName = EnumsApp->App_JOBSREEXPORT;
	my $self = $class->SUPER::new( $appName, @_ );

	#my $self = {};
	bless $self;

	$self->_SetLogging();

	# All controls

	$self->{"inCAM"}         = undef;
	$self->{"processedJobs"} = 0;
	$self->{"maxLim"}        = 5;

	return $self;
}

# -----------------------------------------------
# Public method, implements interface IServiceApp
#------------------------------------------------
sub Run {
	my $self = shift;

	eval {

		# 1) Get jobs to archvie
		my @jobs = $self->__GetJob2ReExport();

		if ( scalar(@jobs) ) {

			$self->{"logger"}->debug("Before get InCAM");

			# we need incam do request for incam
			unless ( defined $self->{"inCAM"} ) {
				$self->{"inCAM"} = $self->_GetInCAM();
			}

			$self->{"logger"}->debug("After get InCAM");

			foreach my $job (@jobs) {

				$self->{"logger"}->info( "Process task, jobId: " . $job . "\n" );

				$self->__RunJob($job);

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

		$self->__ProcessJob($jobId);

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

sub __GetJob2ReExport {
	my $self = shift;

	my $p = EnumsPaths->Jobs_JOBSREEXPORT . "JobList.txt";

	my @lines = @{ FileHelper->ReadAsLines($p) };

	my @jobs = ();
	foreach my $line (@lines) {

		$line =~ s/\s//g;

		next if ( $line =~ /#/ || $line eq "" );

		if ( $line =~ /^\w\d+$/i ) {

			push( @jobs, lc($line) );
		}

	}

	return @jobs;
}

sub __GetSelectedExportUnits {
	my $self = shift;

	my $p = EnumsPaths->Jobs_JOBSREEXPORT . "JobList.txt";

	my @lines = @{ FileHelper->ReadAsLines($p) };

	my @units = ();
	foreach my $line (@lines) {

		$line =~ s/\s//g;

		if ( $line =~ /^#UNIT(\w+)=1$/i ) {

			push( @units, $1 );
		}

	}

	die "No export groups defined" unless ( scalar(@units) );

	return @units;
}

sub __RemoveFromJoblist {
	my $self         = shift;
	my $jobId        = shift;
	my $notProcessed = shift;

	my $p = EnumsPaths->Jobs_JOBSREEXPORT . "JobList.txt";

	my @lines = @{ FileHelper->ReadAsLines($p) };

	my @jobs = ();

	for ( my $i = scalar(@lines) - 1 ; $i >= 0 ; $i-- ) {

		if ( $lines[$i] =~ /$jobId/i ) {

			if ($notProcessed) {

				$lines[$i] =~ s/\s*//g;

				$lines[$i] .= " - not processed, see JobsReExport log\n";
			}
			else {
				splice @lines, $i, 1;
			}

		}
	}

	FileHelper->WriteLines( $p, \@lines );

}

sub __ProcessJob {
	my $self  = shift;
	my $jobId = shift;
 
	my $inCAM = $self->{"inCAM"};

	# 1) Open Job

	unless ( CamJob->JobExist( $inCAM, $jobId ) ) {
		 
		$self->__ProcessError( $jobId, "Job doesn't exist: $jobId" );
		$self->__RemoveFromJoblist( $jobId, 1 );
		return 0;
	}

	$self->_OpenJob( $jobId, 1 );
	$self->{"logger"}->debug("After open job: $jobId");

	# 2) Check before export
	my $errMess = "";
 
	my $check = $self->__CheckBeforeExport( $jobId, \$errMess );
	
	# Save and close job
	$self->_CloseJob($jobId);
	
	if ($check) {

		$self->__PrepareExportFile($jobId);
		$self->__RemoveFromJoblist($jobId);

	}
	else {

		print STDERR "chyba $errMess";
		$self->__ProcessError( $jobId, $errMess );
		$self->__RemoveFromJoblist( $jobId, 1 );
	}

	$self->{"logger"}->debug("Job is done: $jobId");

	

	# If error during export, send err log to db

}

sub __CheckBeforeExport {
	my $self    = shift;
	my $jobId   = shift;
	my $units   = shift;
	my $errMess = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	my @unitsReq = $self->__GetSelectedExportUnits();
	push( @unitsReq, "pre" );    # pre unit has to by present always
	
	 
	$self->{"logger"}->debug("Exported groups for job: $jobId, are: ".join("; ",@unitsReq));
	 

	$self->{"units"} = UnitHelper->PrepareUnits( $inCAM, $jobId );

	foreach my $u ( @{ $self->{"units"}->{"units"} } ) {

		print STDERR "Set gorup:".$u->GetUnitId()."\n";
	
		if (  grep { $_ eq  $u->GetUnitId()} @unitsReq) {

			$u->SetGroupState( CheckerEnums->GroupState_ACTIVEON );
		}
		else {

			$u->SetGroupState( CheckerEnums->GroupState_ACTIVEOFF );
		}
	}

	# filter by selected unit in joblistfile
	print STDERR "\n\n\nActive units: "
	  . scalar( grep { $_->GetGroupState() eq CheckerEnums->GroupState_ACTIVEON } @{ $self->{"units"}->{"units"} } );
	
	foreach my $unit ( grep { $_->GetGroupState() eq CheckerEnums->GroupState_ACTIVEON } @{ $self->{"units"}->{"units"} } ) {

		my $resultMngr = -1;
		my $succes = $unit->CheckBeforeExport( $inCAM, \$resultMngr );

		my $title = UnitEnums->GetTitle( $unit->GetUnitId() );

		unless ( $resultMngr->Succes(1) ) {

			$result = 0;

			if ( $resultMngr->GetErrorsCnt() ) {

				$$errMess .= $resultMngr->GetErrorsStr(1);
			}
			if ( $resultMngr->GetWarningsCnt() ) {

				$$errMess .= $resultMngr->GetErrorsStr(1);
			}
		}
	}

	return $result;
}

sub __PrepareExportFile {
	my $self  = shift;
	my $jobId = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	my $pathExportFile = EnumsPaths->Jobs_EXPORTFILESPCB . $jobId;

	my $dataTransfer = DataTransfer->new( $jobId, EnumsTransfer->Mode_WRITE, $self->{"units"}, undef, $pathExportFile );
	my @orders = ( $jobId . "-" . HegMethods->GetPcbOrderNumber($jobId) );

	$dataTransfer->SaveData( EnumsJobMngr->TaskMode_ASYNC, 0, undef, undef, \@orders );

	unless ( -e $pathExportFile ) {
		die "Error during preparing \"export file\" ($pathExportFile) for  job: $jobId";

	}

	return $result;
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

	#	use aliased 'Programs::Services::TpvService2::ServiceApps::ArchiveJobsApp::ArchiveJobsApp';
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

