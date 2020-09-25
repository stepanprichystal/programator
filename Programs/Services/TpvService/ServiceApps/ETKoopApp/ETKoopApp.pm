#-------------------------------------------------------------------------------------------#
# Description: App which automatically export et kooperation IPC
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::ETKoopApp::ETKoopApp;
use base("Programs::Services::TpvService::ServiceApps::ServiceAppBase");

use Class::Interface;
&implements('Programs::Services::TpvService::ServiceApps::IServiceApp');

#3th party library
use strict;
use warnings;

#use File::Spec;
use File::Basename;
use Log::Log4perl qw(get_logger);
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use POSIX qw(strftime);
use List::MoreUtils qw(uniq);
use DateTime::Format::Strptime;
use DateTime;

#local library
#use aliased 'Connectors::TpvConnector::TpvMethods';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsApp';
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::Gerbers::Mdi::ExportFiles::ExportFiles';
use aliased 'Packages::ItemResult::Enums' => "ItemResEnums";
use aliased 'Packages::TifFile::TifFile::TifFile';
use aliased 'Packages::Export::PreExport::FakeLayers';
use aliased 'Packages::CAMJob::ElTest::CheckElTest';
use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::AcquireJob';
use aliased "Packages::Export::OutExport::OutMngr";

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $appName = EnumsApp->App_ETKOOPER;
	my $self = $class->SUPER::new( $appName, @_ );

	#my $self = {};
	bless $self;

	$self->_SetLogging();

	# All controls

	$self->{"inCAM"} = undef;

	return $self;
}

# -----------------------------------------------
# Public method, implements interface IServiceApp
#------------------------------------------------
sub Run {
	my $self = shift;

	eval {

		# 2) Load jobs to export MDI files
		my @jobs = $self->__GetPcb2Export();

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
			}
		}

	};
	if ($@) {

		print STDERR $@;

		my $err = "Aplication: " . $self->GetAppName() . " exited with error: \n$@";
		$self->{"logger"}->error($err);
		$self->{"loggerDB"}->Error( undef, $err );
	}
}

sub __RunJob {
	my $self  = shift;
	my $jobId = shift;

	# DEBUG DELETE
	#$self->__ProcessJob($orderId);
	#return 0;
	# DEBUG DELETE

	eval {

		# run only if tif file exist (old jobs has not tif file)
		my $tif = TifFile->new($jobId);
		unless ( $tif->TifFileExist() ) {
			print STDERR "TIF file doesn't exist\n";
			$self->{"logger"}->error("TIF file doesn't exist");
			return 0;
		}

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

		#$self->{"inCAM"}->Reconnect();

		$self->{"inCAM"}->COM("get_user_name");
		my $userName = $self->{"inCAM"}->GetReply();
		$self->__ProcessError( $jobId, $userName );

		# parameter "wholesite" has to by set, unless it noesn't work out in windows service
		if ( CamJob->IsJobOpen( $self->{"inCAM"}, $jobId, 1 ) ) {

			$self->{"inCAM"}->COM( "check_inout", "job" => "$jobId", "mode" => "in", "ent_type" => "job" );

			#$self->{"inCAM"}->COM( "check_inout", "job" => "$jobId", "mode" => "in", "ent_type" => "job" );
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

	# 1) Open Job
	my $acquireErr = "";
	my $jobExist = AcquireJob->Acquire( $inCAM, $jobId, \$acquireErr );

	if ($jobExist) {

		$self->_OpenJob( $jobId, 1 );

		$self->{"logger"}->debug("After open job: $jobId");

		# 2) Export mdi files
		my $cooperStep = CamHelper->StepExists( $inCAM, $jobId, "mpanel" ) ? "mpanel" : "o+1";
		my $mngr = OutMngr->new( $inCAM, $jobId, 0, $cooperStep, 1 );

		# export
		$mngr->Run();

		$self->{"logger"}->debug("After export IPC files: $jobId");

		# 3) save job
		$self->_CloseJob($jobId);
	}
	else {

		$self->{"logger"}->error("Error during unarchive InCAM job. Error detail: $acquireErr") unless ($jobExist);

	}

 

}



# Return pcb which not contain gerbers or xml in MDI folders
sub __GetPcb2Export {
	my $self = shift;

	my @pcb2Export = ();

	my @pcbInProduc = map { $_->{'reference_subjektu'} } HegMethods->GetOrdersByStatus(45);

	foreach my $orderId (@pcbInProduc) {

		$orderId = lc($orderId);
		my $jobId = ( $orderId =~ /^(\w\d+)-\d+$/ )[0];

		next if ( HegMethods->GetTypeOfPcb( $jobId, 1 ) =~ /^T$/i );    # stencil
		my $testRequested = CheckElTest->ElTestRequested($jobId);
		if ( defined $testRequested && $testRequested ) {

			unless ( CheckElTest->IPCPrepared($jobId,1) ) {

				my %orderInfo = HegMethods->GetAllByOrderId($orderId);

				my $pattern = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d %H:%M:%S', );

				my $dateStart = $pattern->parse_datetime( $orderInfo{"datum_zahajeni"} )->epoch();    # start order date

				# diff creattion date
				my $difCreation = undef;
				my $p           = JobHelper->GetJobArchive($jobId) . "\\$jobId.dif";
				$difCreation = ( stat($p) )[9] if ( -e $p );

				my $diff = 0;

				if ( defined $difCreation ) {

					$diff = DateTime->now( "time_zone" => 'Europe/Prague' )->epoch() - $difCreation;
				}
				else {

					$diff = DateTime->now( "time_zone" => 'Europe/Prague' )->epoch() - $dateStart;

				}

				$self->{"logger"}->debug("El test for job: $orderId doesnt exist for $diff hours");

				$diff /= 3600;    # to hours

				if ( $diff > 10 ) {

					push( @pcb2Export, $jobId );
				}
			}

		}
	}

	# limit if more than 30jobs, in order don't block  another service apps
	if ( scalar(@pcb2Export) > 10 ) {
		@pcb2Export = @pcb2Export[ 0 .. 9 ];    # oricess max 30 jobs
	}

	return @pcb2Export;
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

	#
	#	print "ee";
}

1;

