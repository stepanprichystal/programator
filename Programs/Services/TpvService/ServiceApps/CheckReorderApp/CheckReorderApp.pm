#-------------------------------------------------------------------------------------------#
# Description: App which unarchvoe and do revision of reorders
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorderApp;
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
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::FileHelper';
use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::Enums';
use aliased 'Enums::EnumsIS';
use aliased 'Helpers::JobHelper';
use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::CheckInfo';
use aliased 'CamHelpers::CamJob';
use aliased 'Programs::Services::Helpers::AutoProcLog';
use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::AcquireJob';
use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::AutoChangeFile';
use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::ChangeFile';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $appName = EnumsApp->App_CHECKREORDER;
	my $self = $class->SUPER::new( $appName, @_ );

	#my $self = {};
	bless $self;

	$self->__SetLogging();

	$self->{"logger"}->debug("after logg");

	# All controls
	my @controls = ();
	$self->{"controls"} = \@controls;

	my @chList = ();
	$self->{"checklist"} = \@chList;

	$self->{"checks"} = undef;    # contain classes implement ICHeck

	$self->{"inCAM"} = undef;

	# 1) Load and check checklist
	$self->__LoadChecklist();

	# Load all check class
	$self->__LoadCheckClasses();

	$self->{"logger"}->debug("reorder init");

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
		my @reorders = grep { !defined $_->{"aktualni_krok"} || $_->{"aktualni_krok"} eq "" } HegMethods->GetReorders();

		if ( scalar(@reorders) ) {

			$self->{"logger"}->debug("Before get InCAM");

			# we need incam do request for incam
			unless ( defined $self->{"inCAM"} ) {
				$self->{"inCAM"} = $self->_GetInCAM();
			}

			$self->{"logger"}->debug("After get InCAM");

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

	$self->{"logger"}->debug("Check reorder end");
}

sub __RunJob {
	my $self    = shift;
	my $orderId = shift;
	my ($jobId) = $orderId =~ /^(\w\d+)-\d+/i;
	$jobId = lc($jobId);

	# DEBUG DELETE
	#$self->__ProcessJob($orderId);
	#return 0;
	# DEBUG DELETE

	eval {

		$self->__ProcessJob($orderId)

	};
	if ($@) {

		my $eStr = $@;
		my $e    = $@;

		if ( ref($e) && $e->can("Error") ) {

			$eStr = $e->Error();
		}

		my $err = "Process order id: \"$orderId\" exited with error: \n $eStr";

		$self->__ProcessJobResult( $orderId, EnumsIS->CurStep_CHECKREORDERERROR, $err );
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

	# list of necesary changes
	my @autoCh = ();
	my @manCh  = ();

	# 1) Check if pcb exist in InCAM
	my $jobExist = AcquireJob->Acquire( $inCAM, $jobId );

	$self->_OpenJob($jobId);

	my $isPool  = HegMethods->GetPcbIsPool($jobId);
	my $pcbInfo = HegMethods->GetBasePcbInfo($jobId);

	my $revize = $pcbInfo->{"stav"} eq 'R' ? 1 : 0;    # indicate if pcb need user-manual process before go to produce

	if ($revize) {

		push( @manCh, "1) Deska je ve stavu \"revize\", uprav data jobu podle požadavkù zákazníka/výroby." );
	}

	foreach my $checkInfo ( @{ $self->{"checklist"} } ) {

		my $key    = $checkInfo->GetKey();
		my $type   = $checkInfo->GetType();
		my $detail = "";                               # Contain specifying message about manual task
		my %data   = ();                               # Contain detail data, for process automatic task

		if ( $self->{"checks"}->{$key}->NeedChange( $inCAM, $jobId, $jobExist, $isPool, \$detail, \%data ) ) {

			my $str = undef;

			if ( $type eq Enums->Check_AUTO ) {

				my %taskInf = ( "key" => $checkInfo->GetKey(), "data" => \%data );
				push( @autoCh, \%taskInf );

			}
			elsif ( $type eq Enums->Check_MANUAL ) {

				if ( defined $detail && $detail ne "" ) {
					$detail = "\n Detail: " . $detail;
				}

				$str = ( scalar(@manCh) + 1 ) . ") " . $checkInfo->GetMessage() . $detail;
				push( @manCh, $str );
			}
		}
	}

	if ($jobExist) {
		$inCAM->COM( "check_inout", "job" => "$jobId", "mode" => "in", "ent_type" => "job" );
		$inCAM->COM( "close_job", "job" => "$jobId" );
	}

	# 2) create changes file to archive (auto + manual changes file)
	if ( scalar(@autoCh) > 0 ) {

		AutoChangeFile->Create( $jobId, \@autoCh );
	}

	if ( scalar(@manCh) > 0 ) {

		ChangeFile->Create( $jobId, \@manCh );

	}
	else {

		ChangeFile->Delete($jobId);
	}

	# 3) set order state
	my $orderState = undef;

	if ( scalar(@autoCh) > 0 ) {
		$orderState = EnumsIS->CurStep_ZPRACOVANIAUTO;
	}

	if ( scalar(@manCh) > 0 ) {
		$orderState = EnumsIS->CurStep_ZPRACOVANIMAN;
	}

	if ( scalar(@autoCh) == 0 && scalar(@manCh) == 0 ) {

		if ($isPool) {
			$orderState = EnumsIS->CurStep_KPANELIZACI;
		}
		else {

			die "no changes in pcb reorder $jobId";
		}
	}

	if ($revize) {

		$orderState = EnumsIS->CurStep_ZPRACOVANIREV;
	}

	$self->__ProcessJobResult( $orderId, $orderState, undef );
}

sub __ProcessJobResult {
	my $self       = shift;
	my $orderId    = shift;
	my $orderState = shift;
	my $errMess    = shift;

	my ($jobId) = $orderId =~ /^(\w\d+)-\d+/i;
	$jobId = lc($jobId);

	# 1) if state is error, set error message
	if ( $orderState eq EnumsIS->CurStep_CHECKREORDERERROR ) {

		# log error to file
		$self->{"logger"}->error($errMess);

		# sent error to log db
		$self->{"loggerDB"}->Error( $jobId, $errMess );

		# store error to job archive
		AutoProcLog->Create( $self->GetAppName(), $jobId, $errMess );
	}
	else {
		AutoProcLog->Delete($jobId);
	}

#	# delete change log
#	if (    $orderState ne EnumsIS->CurStep_ZPRACOVANIMAN
#		 && $orderState ne EnumsIS->CurStep_ZPRACOVANIREV )
#	{
#
#		ChangeFile->Delete($jobId);
#	}
#
#	if ( $orderState ne EnumsIS->CurStep_ZPRACOVANIAUTO ) {
#
#		AutoChangeFile->Delete($jobId);
#	}

	# 2) set state

	HegMethods->UpdatePcbOrderState( $orderId, $orderState );
}

sub __LoadChecklist {
	my $self = shift;

	# Check if checklist is valid
	my $path  = GeneralHelper->Root() . "\\Programs\\Services\\TpvService\\ServiceApps\\CheckReorderApp\\CheckReorder\\CheckList";
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
	#		my $module = 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::Checks::' . $file;
	#		print STDERR $module."\n";
	#
	#		eval("use aliased \'$module\';");
	#	}

	my %checks = ();

	foreach my $checkInfo ( @{ $self->{"checklist"} } ) {

		my $key = $checkInfo->GetKey();

		my $module = 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::Checks::' . $key;
		eval("use  $module;");
		$checks{$key} = $module->new($key);
	}

	$self->{"checks"} = \%checks;

}

sub __SetLogging {
	my $self = shift;

	# 2) Load log4perl logger config
	#my $appDir = dirname(__FILE__);
	#Log::Log4perl->init("$appDir\\Logger.conf");

	#	my $dir = EnumsPaths->Client_INCAMTMPLOGS . "checkReorder";
	#
	#	unless ( -e $dir ) {
	#		mkdir($dir) or die "Can't create dir: " . $dir . $_;
	#	}

	$self->{"logger"} = get_logger("checkReorder");

	$self->{"logger"}->debug("test of logging");

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorderApp';
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

