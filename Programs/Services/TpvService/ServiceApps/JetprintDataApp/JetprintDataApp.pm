#-------------------------------------------------------------------------------------------#
# Description: App which automatically export jetprint files of missing job
# Second purpose is delete old files (pcb are not in produce) from Jetprint folder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::JetprintDataApp::JetprintDataApp;
use base("Programs::Services::TpvService::ServiceApps::ServiceAppBase");

use Class::Interface;
&implements('Programs::Services::TpvService::ServiceApps::IServiceApp');

#3th party library
use strict;
use warnings;

#use File::Spec;
use File::Basename;
use Log::Log4perl qw(get_logger);
use POSIX qw(strftime);
use File::Path 'rmtree';

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

	# 1) Open Job

	unless ( CamJob->JobExist( $inCAM, $jobId ) ) {
		$self->{"logger"}->debug("Job doesn't exist: $jobId");
		return 0;
	}

	$self->_OpenJob( $jobId, 1 );
	$self->{"logger"}->debug("After open job: $jobId");

	# 2) Export mdi files

	my $export = ExportFiles->new( $inCAM, $jobId );
	$export->{"onItemResult"}->Add( sub { $self->__OnExportLayer(@_) } );

	my @result = ();
	$self->{"errResults"} = \@result;

	$export->Run();

	$self->{"logger"}->debug("After export jetprint files: $jobId");

	# 3) save job
	$self->_CloseJob($jobId);

	# If error during export, send err log to db
	if ( @{ $self->{"errResults"} } ) {

		my $errMess = join( "\n ", @{ $self->{"errResults"} } );

		$self->__ProcessError( $jobId, $errMess );
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

	my @pcb2Export = ();

	my @pcbInProduc = HegMethods->GetPcbsInProduceSilk();    # get pcb "Ve vyrobe" with silk
	@pcbInProduc = grep { $_->{"material_typ"} !~ /[tso]/i } @pcbInProduc;    # not sablona, slu?ba, ostatni
	@pcbInProduc = map  { $_->{"reference_subjektu"} } @pcbInProduc;

	# all files from MDI folder
	my @gerAll = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_JETPRINT, '.ger' );

	foreach my $jobId (@pcbInProduc) {
		
		$jobId = lc($jobId);

		my @ger = grep { $_ =~ /($jobId)[\w\d]+_jet/i } @gerAll;

		# if no gerbers, export them
		unless ( scalar(@ger) ) {

			push( @pcb2Export, $jobId );
		}
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

