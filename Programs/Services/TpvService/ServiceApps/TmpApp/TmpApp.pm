#-------------------------------------------------------------------------------------------#
# Description: App which automatically export jetprint files of missing job
# Second purpose is delete old files (pcb are not in produce) from Jetprint folder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::TmpApp::TmpApp;
use base("Programs::Services::TpvService::ServiceApps::ServiceAppBase");

#use Class::Interface;
#&implements('Programs::Services::TpvService::ServiceApps::IServiceApp');

#3th party library
use strict;
use warnings;

#use File::Spec;
use File::Basename;
use Log::Log4perl qw(get_logger);
use POSIX qw(strftime);
use File::Copy;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsApp';
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Programs::Services::TpvService::ServiceApps::JetprintDataApp::Enums';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::Gerbers::Jetprint::ExportFiles';
use aliased 'Packages::ItemResult::Enums' => "ItemResEnums";
use aliased 'Packages::TifFile::TifFile::TifFile';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $appName = EnumsApp->App_JETPRINTDATA;
	my $self = $class->SUPER::new( $appName, @_ );

	#my $self = {};
	bless $self;

	$self->__SetLogging();

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

		my $err = "Aplication: " . $self->GetAppName() . " exited with error: \n$@";
		print STDERR $err;
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

	use Path::Tiny qw(path);
	use File::Basename;

	unless ( -e EnumsPaths->Jobs_AOITESTSFUSIONDB . "\\" . $jobId ) {

		# copy from ot folder to new fusion folder

		my $arch = JobHelper->GetJobArchive($jobId) . "\\zdroje\\ot";

		my $dir;
		if ( opendir( $dir, $arch ) ) {
			while ( my $file = readdir($dir) ) {

				next if ( $file =~ /^\.$/ );
				next if ( $file =~ /^\.\.$/ );

				my $arch = JobHelper->GetJobArchive($jobId) . "\\zdroje\\ot";
				my $ori  = JobHelper->GetJobArchive($jobId) . "\\zdroje\\ot\\" . $file;

				my $oriTmp = $ori . "_test";
				copy( $ori, $oriTmp );

				# replace trezxt
				my $fileOt = path($oriTmp);

				my $data = $fileOt->slurp_utf8;
				$data =~ s/(RULE_FILE = )DISCOVERY-6/$1FUSION-20/i;
				$fileOt->spew_utf8($data);

				move( $oriTmp, EnumsPaths->Jobs_AOITESTSFUSION . "//" . $file );
			}

			closedir($dir);
		}

	}
}

# handler for mdi export results
sub __OnExportLayer {
	my $self = shift;
	my $item = shift;

	if ( $item->Result() eq ItemResEnums->ItemResult_Fail ) {

		push( @{ $self->{"errResults"} }, $item->GetErrorStr() );
	}
}

# Return pcb which are in produce, contain silk and doesn't contain gerbers
sub __GetPcb2Export {
	my $self = shift;

	my @pcbInProduc = HegMethods->GetPcbsInProduceMDI();    # get pcb "Ve vyrobe"

	@pcbInProduc = map { $_->{"reference_subjektu"} } @pcbInProduc;

	return @pcbInProduc;
}

sub __DeleteOldJetFiles {
	my $self = shift;

	my @pcbInProduc = HegMethods->GetPcbsByStatus( 2, 4, 25, 35 );    # get pcb "Ve vyrobe" + "Na predvyrobni priprave" + Na odsouhlaseni + Schvalena
	@pcbInProduc = map { $_->{"reference_subjektu"} } @pcbInProduc;

	if ( scalar(@pcbInProduc) < 100 ) {

		$self->{"logger"}->debug( "No pcb in produc (count : " . scalar(@pcbInProduc) . "), error?" );
	}

	unless ( scalar(@pcbInProduc) ) {
		return 0;
	}

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

	$self->{"logger"}->info("Number of deleted job from Jetprint folder: $deletedFiles");
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

	$self->{"logger"} = get_logger("jetprintData");

	$self->{"logger"}->debug("test of logging");

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Programs::Services::TpvService::ServiceApps::JetprintDataApp::JetprintDataApp';
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

