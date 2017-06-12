#-------------------------------------------------------------------------------------------#
# Description: Represent Universal Drill tool manager
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::ProcessReorderApp::ProcessReorderApp;
use base("Programs::Services::TpvService::ServiceApps::ServiceAppBase");

#use Class::Interface;
#&implements('Programs::Services::TpvService::ServiceApps::IServiceApp');

#3th party library
use strict;
use warnings;

#use File::Spec;
use File::Basename;
use Log::Log4perl qw(get_logger);
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

use POSIX qw(strftime);

#local library
#use aliased 'Connectors::TpvConnector::TpvMethods';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsApp';
use aliased 'Helpers::GeneralHelper';

use aliased 'Helpers::FileHelper';
use aliased 'Programs::Services::TpvService::ServiceApps::ProcessReorderApp::Enums';
use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::Enums' => 'EnumsCheck';

use aliased 'Helpers::JobHelper';
use aliased 'Programs::Services::TpvService::ServiceApps::ProcessReorderApp::Reorder::CheckInfo';
use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $appName = EnumsApp->App_PROCESSREORDER;
	my $self = $class->SUPER::new( $appName, @_ );

	#my $self = {};
	bless $self;

	$self->__SetLogging();

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
		my @reorders = grep { defined $_->{"aktualni_krok"} && $_->{"aktualni_krok"} eq EnumsCheck->Step_AUTO } HegMethods->GetReorders();

		if ( scalar(@reorders) ) {

			# we need incam do request for incam
			unless ( defined $self->{"inCAM"} ) {
				$self->{"inCAM"} = $self->_GetInCAM();
			}

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
}

sub __RunJob {
	my $self    = shift;
	my $orderId = shift;
	my ($jobId) = $orderId =~ /^(\w\d+)-\d+/i;
	$jobId = lc($jobId);

	eval {

		$self->__ProcessJob($orderId)

	};
	if ($@) {

		my $eStr = $@;
		my $e    = $@;

		if ( ref($e) && $e->can("Error") ) {

			$eStr = $e->Error();
		}

		my $err = "Aplication: " . $self->GetAppName() . ", orderid: \"$orderId\" exited with error: \n $eStr";
		$self->{"logger"}->error($err);
		$self->{"loggerDB"}->Error( $jobId, $err );

		HegMethods->UpdatePcbOrderState( $orderId, Enums->Step_ERROR );
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

	# Check if change log file exist and read checks
	my @changes = $self->__LoadChanges($jobId);

	# 1) Open Job

	my $usr = undef;
	if ( CamJob->IsJobOpen( $self->{"inCAM"}, $jobId, 1, \$usr ) ) {
		die "Unable to process reorder, because job $jobId is open by user: $usr";
	}

	# open job if exist
	if ($jobExist) {
		$inCAM->COM( "open_job", job => "$jobId", "open_win" => "yes" );
		$inCAM->COM( "check_inout", "job" => "$jobId", "mode" => "out", "ent_type" => "job" );
	}
	else {

		die "Job $jobId doesn't exist";
	}

	# 2) Archive old files

	$self->__ArchiveJob($jobId);

	# 3) Do automatic changes

	
	my $result = 1;
	my $errMess = "";
	foreach my $change (@changes) {
		
		unless($change->Run($jobId, \$errMess)){
			
			$result = 0;
			last;
		}
	}

	

	# 4) save jopb

	$inCAM->COM( "check_inout", "job" => "$jobId", "mode" => "in", "ent_type" => "job" );
	$inCAM->COM( "close_job", "job" => "$jobId" );

	# 5) set order state
	my $isPool = HegMethods->GetPcbIsPool($jobId);
 
	my $orderState = undef;
	
	if($orderState == 1){
		
		$orderState = Enums->Step_AUTOOK;
		
		if($isPool){
			$orderState = Enums->Step_PANELIZATION;
		}
		
	}
	
	
	
	
	Step_PANELIZATION

	HegMethods->UpdatePcbOrderState( $orderId, $orderState );
}

sub __LoadChanges {
	my $self  = shift;
	my $jobId = shift;

	my $path = JobHelper->GetJobArchive($jobId) . "Change_log.txt";

	unless ( -e $path ) {
		die "Unable to process reorder $jobId, because \"change_log\" file doesnt exist in archive at: $path.\n";
	}

	my @changes = ();
	my @lines   = @{ FileHelper->ReadAsLines($path) };

	my $autoChanges = 0;

	foreach (@lines) {

		unless ($autoChanges) {

			if ( $_ =~ /Automatic task/i ) {
				$autoChanges = 1;
			}
			else {
				next;
			}
		}

		if ( $_ =~ /\d\)\s*(.*)\s*-\s*(.*)/ ) {

			my $key = $1;

			my $module = 'Programs::Services::TpvService::ServiceApps::ProcessReorderApp::ProcessReorder::Changes::' . $key;
			eval("use  $module;");

			push( @changes, $module->new($key) );
		}
	}

	unless ( scalar(@changes) ) {
		die "Unable to process reorder $jobId, because \"change_log\" file doesnt contain any automatic changes.\n";

	}

	return @changes;
}

sub __ArchiveJob {
	my $self  = shift;
	my $jobId = shift;

	# Script zip script files and save to backup dir
	my $fname = "Premnozeni_" . ( strftime "%Y_%m_%d", localtime ) . ".zip";

	my $archive = JobHelper->GetJobArchive($jobId);

	my $zip = Archive::Zip->new();

	my $dir;
	if ( opendir( $dir, $archive ) ) {

		my $tgz = $archive . "\\" . $jobId . ".tgz";

		if ( -e $tgz ) {
			$zip->addFile( $tgz, $jobId . ".tgz" );
		}

		my $nif = $archive . "\\" . $jobId . ".nif";

		if ( -e $nif ) {
			$zip->addFile( $nif, $jobId . ".nif" );
		}

		my $dif = $archive . "\\" . $jobId . ".dif";

		if ( -e $dif ) {
			$zip->addFile( $nif, $jobId . ".dif" );
		}

		my $pdf = $archive . "\\zdroje\\" . "$jobId-control.pdf";

		if ( -e $pdf ) {
			$zip->addFile( $pdf, "$jobId-control.pdf" );
		}

		$zip->addDirectory("nc");

		my $nc = $archive . "\\nc\\";

		if ( opendir( $dir, $nc ) ) {

			while ( ( my $f = readdir($dir) ) ) {

				next unless $f =~ /^[a-z]/i;

				$zip->addFile( $nc . "\\" . $f, "nc\\" . $f );

			}

			close($dir);
		}

		close $dir;
	}

	unless ( $zip->writeToFileNamed( $archive . "zdroje\\$fname" ) == AZ_OK ) {
		die "Zip job archive failed.";
	}

}

sub __SetLogging {
	my $self = shift;

	# 2) Load log4perl logger config
	#my $appDir = dirname(__FILE__);
	#Log::Log4perl->init("$appDir\\Logger.conf");

	my $dir = EnumsPaths->Client_INCAMTMPLOGS . "processReorder";

	unless ( -e $dir ) {
		mkdir($dir) or die "Can't create dir: " . $dir . $_;
	}

	$self->{"logger"} = get_logger("processReorder");

	$self->{"logger"}->debug("test of logging");

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

