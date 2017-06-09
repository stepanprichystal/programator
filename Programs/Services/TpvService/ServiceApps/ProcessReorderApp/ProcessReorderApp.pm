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

	$self->{"logger"}->debug("after logg");

	# All controls

	$self->{"checks"} = undef;    # contain classes implement ICHeck
	$self->{"inCAM"}  = undef;

	$self->{"logger"}->debug("reorder init");

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

	# 2) Archive old files
	
	
	
	# 3) Do automatic changes

	foreach my $change (@changes ) {

		$change->Run();
	}

	if ($jobExist) {
		$inCAM->COM( "check_inout", "job" => "$jobId", "mode" => "in", "ent_type" => "job" );
		$inCAM->COM( "close_job", "job" => "$jobId" );
	}
 
	# 3) set order state
	my $orderState =  Enums->Step_AUTOOK;
 
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

		if ( $_ =~ /\d\)\s*(.*)\s*-\s*(.*)/){
			
			my $key = $1;
			
			my $module = 'Programs::Services::TpvService::ServiceApps::ProcessReorderApp::ProcessReorder::Checks::' . $key;
			eval("use  $module;");
			
			push(@changes, $module->new($key));
		}
	}
	
	unless(scalar(@changes)){
		die "Unable to process reorder $jobId, because \"change_log\" file doesnt contain any automatic changes.\n";
		
	}
	
	return @changes;
}

# Try acquire job and import to inCAM
# return 1 if job is prepared in incam
# return 0, if job in InCAM doesnt exist
sub __AcquireJob {
	my $self  = shift;
	my $jobId = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	unless ( CamJob->JobExist( $inCAM, $jobId ) ) {

		$result = 0;

		# check if tgz exist
		my $path = JobHelper->GetJobArchive($jobId) . $jobId . ".tgz";

		if ( -e $path ) {

			my $importSucc = 1;       # tell if job was succesfully imported
			my $importErr  = undef;

			# try to import job to InCAM

			$inCAM->HandleException(1);

			my $importOk = $inCAM->COM( 'import_job', "db" => 'incam', "path" => $path, "name" => $jobId, "analyze_surfaces" => 'no' );

			$inCAM->HandleException(0);

			# test if import fail
			if ( $importOk != 0 ) {
				$importSucc = 0;
				$importErr  = $inCAM->GetExceptionError();
			}

			# import succes, try if job now exist
			elsif ( $importOk == 0 && !CamJob->JobExist( $inCAM, $jobId ) ) {

				$importSucc = 0;
				$importErr  = "Job import was not succes\n";
			}

			# if errors,
			if ($importSucc) {

				$result = 1;    # succesfully imported, job is prepared

			}
			else {

				# import was not succ, die - send log to db
				die "Error during import job to InCAM db. $importErr";

				#$self->{"loggerDB"}->Error($importErr);
			}

		}

	}

	return $result;
}

sub __CreateChangeFile {
	my $self   = shift;
	my $jobId  = shift;
	my @autoCh = @{ shift(@_) };
	my @manCh  = @{ shift(@_) };

	my @lines = ();

	push( @lines, "# REORDER CHECKLIST" );

	push( @lines, "# PCB ID:  $jobId" );
	push( @lines, "" );
	push( @lines, "" );

	push( @lines, "# ============ Manual tasks============ #" );
	push( @lines, "" );

	for ( my $i = 0 ; $i < scalar(@manCh) ; $i++ ) {

		push( @lines, $manCh[$i] );

	}

	push( @lines, "" );
	push( @lines, "# ========== Automatic tasks ========== #" );
	push( @lines, "" );

	for ( my $i = 0 ; $i < scalar(@autoCh) ; $i++ ) {

		push( @lines, $autoCh[$i] );

	}

	my $path = JobHelper->GetJobArchive($jobId) . "Change_log.txt";

	if ( -e $path ) {
		unlink($path);
	}

	my $f;

	if ( open( $f, "+>", $path ) ) {

		foreach my $l (@lines) {

			print $f "\n" . $l;
		}

		close($f);
	}
	else {
		die "unable to crate 'Change log' file for pcbid: $jobId";
	}

}

sub __LoadChecklist {
	my $self = shift;

	# Check if checklist is valid
	my $path  = GeneralHelper->Root() . "\\Programs\\Services\\TpvService\\ServiceApps\\ReorderApp\\Reorder\\CheckList";
	my @lines = @{ FileHelper->ReadAsLines($path) };

	# Parse

	for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {

		my $l = $lines[$i];

		next if ( $l =~ /#/ );

		if ( $l =~ m/\[(.*)\]/ ) {

			my ($desc) = $1 =~ /\s*(.*)\s*/;
			my ($key)  = $lines[ $i + 1 ] =~ / =\s*(.*)\s*/;
			my ($ver)  = $lines[ $i + 2 ] =~ / =\s*(.*)\s*/;
			my ($type) = $lines[ $i + 3 ] =~ / =\s*(.*)\s*/;
			my ($mess) = $lines[ $i + 4 ] =~ / =\s*(.*)\s*/;

			my $checkInf = CheckInfo->new( $desc, $key, $ver, $type, $mess );

			push( @{ $self->{"checklist"} }, $checkInf );

			$i += 4;
		}
	}

	# 1) Check if all check has defined type
	foreach my $checkInfo ( @{ $self->{"checklist"} } ) {

		my $t = $checkInfo->GetType();
		my $m = $checkInfo->GetMessage();

		if ( !defined $t || $t eq "" ) {
			die "Check " . $checkInfo->GetKey() . " has not defined type";
		}

		if ( $t eq "manual" && ( !defined $m || $m eq "" ) ) {

			die "Checktype " . $checkInfo->GetKey() . " has to has defined 'R' in checklist";
		}
	}

}

sub __LoadCheckClasses {
	my $self = shift;

	# 	# automatically "use"  all packages from dir "checks"
	# 	my $dir = GeneralHelper->Root() . '\Programs\Services\TpvService\ServiceApps\ReorderApp\Reorder\Checks';
	#	opendir( DIR, $dir ) or die $!;
	#
	#	while ( my $file = readdir(DIR) ) {
	#
	#		next if ( $file =~ m/^\./ );
	#
	#		$file =~ s/\.pm//;
	#
	#		my $module = 'Programs::Services::TpvService::ServiceApps::ProcessReorderApp::Reorder::Checks::' . $file;
	#		print STDERR $module."\n";
	#
	#		eval("use aliased \'$module\';");
	#	}

	my %checks = ();

	foreach my $checkInfo ( @{ $self->{"checklist"} } ) {

		my $key = $checkInfo->GetKey();

		my $module = 'Programs::Services::TpvService::ServiceApps::ProcessReorderApp::Reorder::Checks::' . $key;
		eval("use  $module;");
		$checks{$key} = $module->new($key);
	}

	$self->{"checks"} = \%checks;

	#	# auto checks
	#	$checks{"EXPORT"}     = EXPORT->new();
	#	$checks{"SCHEMA"}     = SCHEMA->new();
	#	$checks{"MASK_POLAR"} = MASK_POLAR->new();
	#
	#	# manual checks
	#	$checks{"DATACODE_IS"}          = DATACODE_IS->new();
	#	$checks{"ELTEST_EXIST"}         = ELTEST_EXIST->new();
	#	$checks{"GOLD_CONNECTOR_LAYER"} = GOLD_CONNECTOR_LAYER->new();
	#	$checks{"INCAM_JOB"}            = INCAM_JOB->new();
	#	$checks{"KADLEC_PANEL"}         = KADLEC_PANEL->new();
	#	$checks{"NIF_NAKOVENI"}         = NIF_NAKOVENI->new();
	#	$checks{"PANEL_SET"}            = PANEL_SET->new();
	#	$checks{"PICKERING_ORDER_NUM"}  = PICKERING_ORDER_NUM->new();
	#	$checks{"POOL_PATTERN"}         = POOL_PATTERN->new();

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

