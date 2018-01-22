#-------------------------------------------------------------------------------------------#
# Description: App which automatically export jetprint files of missing job
# Second purpose is delete old files (pcb are not in produce) from Jetprint folder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService2::ServiceApps::TmpApp::TmpApp;
use base("Programs::Services::TpvService2::ServiceApps::ServiceAppBase");

#use Class::Interface;
#&implements('Programs::Services::TpvService2::ServiceApps::IServiceApp');

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
use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::AcquireJob';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $appName = EnumsApp->App_TEST;
	my $self = $class->SUPER::new( $appName, @_ );

	#my $self = {};
	bless $self;

	$self->_SetLogging();

	# All controls

	$self->{"inCAM"}         = undef;
	$self->{"processedJobs"} = 0;
	$self->{"maxLim"}        = 15;

	return $self;
}

# -----------------------------------------------
# Public method, implements interface IServiceApp
#------------------------------------------------
sub Run {
	my $self = shift;

	$self->{"logger"}->debug("Check reorder run");

	eval {

		$self->{"logger"}->debug("In eval");

		# 2) Load Reorder pcb
		my @pcbInProduc = HegMethods->GetPcbsInProduc();        # get pcb "Ve vyrobe"

		@pcbInProduc = map { $_->{"reference_subjektu"} } @pcbInProduc;
		
		my @pcb = ();
		foreach my $jobId (@pcbInProduc) {
			
			my $tmp = lc($jobId);
			my $archive = JobHelper->GetJobArchive($tmp);
			unless( -e $archive){
				push(@pcb, $jobId);
			}
			
		}
		
		$self->{"logger"}->debug("Pcb to unarchove:" . scalar(@pcb));

		if ( scalar(@pcb) ) {

			$self->{"logger"}->debug("Before get InCAM");

			# we need incam do request for incam
			unless ( defined $self->{"inCAM"} ) {
				$self->{"inCAM"} = $self->_GetInCAM();
			}

			$self->{"logger"}->debug("After get InCAM");

			#my %hash = ( "reference_subjektu" => "f52456-01" );
			#@reorders = ( \%hash );

			foreach my $jobId (@pcb) {
				
				my $tmp = lc($jobId);
				
			 
					
					$self->{"logger"}->info("Process reorder: $jobId");

					$self->__RunJob($jobId);
				}
 	
			 
		}

	};
	if ($@) {

		my $err = "Aplication: " . $self->GetAppName() . " exited with error: \n$@";
		$self->{"logger"}->error($err);
		$self->{"loggerDB"}->Error( undef, $err );
	}

	$self->{"logger"}->debug("Check reorder end");
}

sub __RunJob {
	my $self    = shift;
	my $jobId = shift;
	#my ($jobId) = $orderId =~ /^(\w\d+)-\d+/i;
	$jobId = lc($jobId);
	
	if(!defined $jobId ||  $jobId eq ""){
		die;
	}

	# DEBUG DELETE
	#$self->__ProcessJob($orderId);
	#return 0;
	# DEBUG DELETE

	eval {

		$self->__ProcessJob($jobId)

	};
	if ($@) {

		my $eStr = $@;
		my $e    = $@;

		if ( ref($e) && $e->can("Error") ) {

			$eStr = $e->Error();
		}

		my $err = "Process order id: \"$jobId\" exited with error: \n $eStr";

	 
		# if job is open by server, close and checkin job after error (other server block job)
		 
		if(CamJob->IsJobOpen($self->{"inCAM"}, $jobId)){
			
			$self->{"inCAM"}->COM( "save_job", "job" => "$jobId" );
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
	my $jobId = shift;

	my $inCAM = $self->{"inCAM"};

 
	$jobId = lc($jobId);
 

	# 1) Check if pcb exist in InCAM
	my $jobExist = AcquireJob->Acquire( $inCAM, $jobId );
 

	$self->_OpenJob($jobId);
 

 
	if ($jobExist) {
		$inCAM->COM( "check_inout", "job" => "$jobId", "mode" => "in", "ent_type" => "job" );
		$inCAM->COM( "close_job", "job" => "$jobId" );
	}

 
}
 

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Programs::Services::TpvService2::ServiceApps::CheckReorderApp::CheckReorderApp';
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

