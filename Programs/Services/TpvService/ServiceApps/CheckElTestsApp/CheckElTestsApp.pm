#-------------------------------------------------------------------------------------------#
# Description: App check job data if they are not missing
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::CheckElTestsApp::CheckElTestsApp;
use base("Programs::Services::TpvService::ServiceApps::ServiceAppBase");

use Class::Interface;
&implements('Programs::Services::TpvService::ServiceApps::IServiceApp');

#3th party library
use utf8;
use strict;
use warnings;
use Data::Dump qw(dump);
use File::Basename;
use Log::Log4perl qw(get_logger);
use DateTime::Format::Strptime;
use DateTime;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsApp';
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::NifFile::NifFile';
use aliased 'Packages::CAMJob::ElTest::CheckElTest';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $appName = EnumsApp->App_CHECKELTESTS;
	my $self = $class->SUPER::new( $appName, @_ );

	#my $self = {};
	bless $self;

	$self->_SetLogging();

	# All controls

	$self->{"inCAM"}         = undef;
	$self->{"processedJobs"} = 0;

	return $self;
}

# -----------------------------------------------
# Public method, implements interface IServiceApp
#------------------------------------------------
sub Run {
	my $self = shift;

	eval {

		# 1) Get jobs to archvie
		my @ordersInProduc = map { $_->{'reference_subjektu'} } grep { $_->{"aktualni_krok"} =~ /ZADANO/i } HegMethods->GetOrdersByStatus(4);

		if ( scalar(@ordersInProduc) ) {

			#			$self->{"logger"}->debug("Before get InCAM");
			#
			#			# we need incam do request for incam
			#			unless ( defined $self->{"inCAM"} ) {
			#				$self->{"inCAM"} = $self->_GetInCAM();
			#			}
			#
			#			$self->{"logger"}->debug("After get InCAM");

			foreach my $orderId (@ordersInProduc) {

				$self->{"logger"}->info("Process job: $orderId");

				$self->__RunJob($orderId);

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

	eval {

		$self->__ProcessJob( $orderId, $jobId )

	};
	if ($@) {

		my $eStr = $@;
		my $e    = $@;

		if ( ref($e) && $e->can("Error") ) {

			$eStr = $e->Error();
		}

		my $err = "Process job id: \"$jobId\" exited with error: \n $eStr";

		$self->__ProcessError( $jobId, $err );

		#		if ( CamJob->IsJobOpen( $self->{"inCAM"}, $jobId ) ) {
		#			$self->{"inCAM"}->COM( "check_inout", "job" => "$jobId", "mode" => "in", "ent_type" => "job" );
		#			$self->{"inCAM"}->COM( "close_job", "job" => "$jobId" );
		#		}
	}
}

## -----------------------------------------------
## Private method
##------------------------------------------------

sub __ProcessJob {
	my $self    = shift;
	my $orderId = shift;
	my $jobId   = shift;

	#$jobId = "d209467";

	#my $inCAM = $self->{"inCAM"};

	# 1) Check if exist electrical test

	if ( CheckElTest->ElTestRequested($jobId) ) {

		unless ( CheckElTest->ElTestExists($jobId) ) {

			my %orderInfo = HegMethods->GetAllByOrderId($orderId);

			my $pattern = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d %H:%M:%S', );

			my $dateStart = $pattern->parse_datetime( $orderInfo{"datum_zahajeni"} )->epoch();    # start order date

			# diff creattion date
			my $difCreation = undef;
			my $p           = JobHelper->GetJobArchive($jobId) . "\\$jobId.dif";
			$difCreation = ( stat($p) )[9] if ( -e $p );

			my $diff = 0;

			if ( defined $difCreation ) {

				$diff = DateTime->now->epoch() - $difCreation;
			}
			else {

				$diff = DateTime->now->epoch() - $dateStart;

			}

			if ( $diff / 3600 > 16 ) {

				my $errText = "Elektrický test pro: $jobId neexistuje. Co nejdříve ho vytvoř!";
				my $term = $pattern->parse_datetime( $orderInfo{"termin"} )->dmy('/');    # start order date
				$errText .= "\n Termin zakázky: ".$term;

				$self->{"loggerDB"}->Warning( $jobId,  $errText);
			}
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

