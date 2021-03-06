#-------------------------------------------------------------------------------------------#
# Description: App unarchive jobs, do automatic changes and check changes, which are need
# to by done manually
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorderApp;
use base("Programs::Services::TpvService::ServiceApps::ServiceAppBase");

use Class::Interface;
&implements('Programs::Services::TpvService::ServiceApps::IServiceApp');

#3th party library
use utf8;
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
use aliased 'Enums::EnumsIS';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Programs::Services::Helpers::AutoProcLog';
use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::AcquireJob';
use aliased 'Enums::EnumsApp';
use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::ChangeFile';
use aliased 'Packages::Reorder::ChangeReorder::ChangeReorder';
use aliased 'Packages::Reorder::CheckReorder::CheckReorder';
use aliased 'Packages::Reorder::Enums'  => 'ReorderEnums';
use aliased 'Packages::Reorder::Helper' => 'ReorderHelper';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $appName = EnumsApp->App_CHECKREORDER;
	my $self = $class->SUPER::new( $appName, @_ );

	#my $self = {};
	bless $self;

	$self->_SetLogging();

	$self->{"logger"}->debug("after logg");

	$self->{"checks"} = undef;    # contain classes implement ICHeck

	$self->{"inCAM"} = undef;

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

		# 1) Check all reorders which has error status
		# If there is  "joblist.xml" error, set empty status in order pcb reorder service run another attempt
		$self->__CheckStuckedJobs();

		# 2) Load Reorder pcb
		my @reorders = $self->__GetReorders();

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

		# if job is open by server, close and checkin job after error (other server block job)

		if ( CamJob->IsJobOpen( $self->{"inCAM"}, $jobId, 1 ) ) {

			$self->{"inCAM"}->COM( "save_job",    "job" => "$jobId" );
			$self->{"inCAM"}->COM( "check_inout", "job" => "$jobId", "mode" => "in", "ent_type" => "job" );
			$self->{"inCAM"}->COM( "close_job",   "job" => "$jobId" );
		}

	}
}

## -----------------------------------------------
## Private method
##------------------------------------------------

sub __ProcessJob {
	my $self    = shift;
	my $orderId = shift;

	my $inCAM = $self->{"inCAM"};

	my ($jobId) = $orderId =~ /^(\w\d+)-(\d+)/i;
	$jobId = lc($jobId);

	# 1) Check if pcb exist in InCAM

	$self->__CheckAncestor( $jobId, $orderId );
	my $errMess = "";
	my $jobExist = AcquireJob->Acquire( $inCAM, $jobId, \$errMess );

	my @tasks      = ();
	my $orderState = EnumsIS->CurStep_ZPRACOVANIAUTO;    # default state

	# Check if PCB is i

	if ( !$jobExist ) {

		my $errText = "Nepoda??il se dohledat nebo naimportovat zarchivovan?? TGZ soubor pro opakovanopu objedn??vku.";
		$errText .= "Detail chyby: $errMess";

		push( @tasks, { "text" => $errText, "critical" => 1 } );
	}
	else {

		$self->_OpenJob($jobId);

		# 2) Determine Reorder type

		my $isPool      = HegMethods->GetPcbIsPool($jobId);
		my $pnlExist    = CamHelper->StepExists( $inCAM, $jobId, "panel" );
		my $reorderType = ReorderHelper->GetReorderType( $inCAM, $orderId );

		die "Reorder type was not found for order id: $orderId" unless ( defined $reorderType );

		# 3) Check if job is former pool and now is standard

		my $changeReorder = ChangeReorder->new( $inCAM, $jobId, $orderId, $reorderType );
		my $errMess       = "";
		my $infoMess       = "";
		my $res           = $changeReorder->RunChanges( \$errMess, \$infoMess );
		push( @tasks, { "text" => $infoMess, "critical" => 1 } ) if($infoMess ne "");
		
		$self->{"inCAM"}->COM( "save_job", "job" => "$jobId" );

		die "Error during reorder processing: $errMess" unless ($res);

		# 4) Do all controls and return check which are neet to be repair manualz bz tpv user
		my $checkReorder = CheckReorder->new( $inCAM, $jobId, $orderId, $reorderType );
		@tasks = $checkReorder->RunChecks();

		$inCAM->COM( "check_inout", "job" => "$jobId", "mode" => "in", "ent_type" => "job" );
		$inCAM->COM( "close_job", "job" => "$jobId" );

	}

	# 5) set order state
	if ( scalar(@tasks) > 0 ) {

		$orderState = EnumsIS->CurStep_ZPRACOVANIMAN;

		ChangeFile->Create( $jobId, \@tasks );    # create changes file to archive

	}
	else {

		ChangeFile->Delete($jobId);
	}

	$self->__ProcessJobResult( $orderId, $orderState, undef );
}

# Copy pool mother pcb
sub __CheckAncestor {
	my $self    = shift;
	my $jobId   = shift;
	my $orderId = shift;

	my $inCAM = $self->{"inCAM"};

	# if reorder is -01  it means pcb has pool-mother ancestor. Copy pool mother job

	if ( $orderId =~ /-01/ ) {

		my $ancestor = HegMethods->GetPcbAncestor($jobId)->{"reference_subjektu"};

		die "Ancestor pool-mother has to be defined" unless ( defined $ancestor );
		$ancestor = lc($ancestor);

		if ( !CamJob->JobExist( $inCAM, $jobId ) ) {

			die "Unable Acquire ancestor job: $ancestor" unless ( AcquireJob->Acquire( $inCAM, $ancestor ) );

			CamJob->CopyJob( $inCAM, $ancestor, $jobId );
			CamJob->CheckInJob( $inCAM, $ancestor );
			CamJob->CloseJob( $inCAM, $ancestor );

			$self->{"logger"}->debug("Reorder with ancestor: $ancestor => $orderId");
		}
	}
}

# Return all reorders to process
sub __GetReorders {
	my $self = shift;

	my @reorders = ();

	# 1) reorders are orders which has number larger than 1

	push( @reorders, grep { !defined $_->{"aktualni_krok"} || $_->{"aktualni_krok"} eq "" } HegMethods->GetReorders() );

	# check if 01 order is already processed (is not predvyrobni priprava)
	for ( my $i = scalar(@reorders) - 1 ; $i >= 0 ; $i-- ) {

		my $jobId = $reorders[$i]->{"deska_reference_subjektu"};

		# if 01 is still on predvzrobni priprava, skip reorder
		if ( HegMethods->GetStatusOfOrder( $jobId . "-01" ) == 2 ) {

			splice @reorders, $i, 1;
		}
	}

	# 2) Reorders are orders with number -01, which has ancestor POOL mother

	my @res = HegMethods->GetOrdersWithAncestor( [2] );    # orders on predvzrobni priprava
	@res = grep { $_->{"reference_subjektu"} =~ /-01/ && $_->{"pooling"} eq 'A' } @res;    # only -01 numbers and type pool

	my @formerPoolMother = ();

	# only ancestor which their last order was pool-mother
	foreach my $order (@res) {

		my $ancestorNumber = HegMethods->GetPcbOrderNumber( $order->{"ancestor_pcb"} );
		my $ancestorOrder  = $order->{"ancestor_pcb"} . "-" . $ancestorNumber;

		if ( HegMethods->GetInfMasterSlave($ancestorOrder) eq "M" ) {

			push( @reorders, $order );
		}
	}

	# olny zpracovani-auto
	@reorders = grep { !defined $_->{"aktualni_krok"} || $_->{"aktualni_krok"} eq "" } @reorders;

	return @reorders;
}

# Check all reorders which has error status
# If there is  "joblist.xml" error, set empty status in order pcb reorder service run another attempt
sub __CheckStuckedJobs {
	my $self = shift;

	my @reorders = ();

	push( @reorders, HegMethods->GetReorders() );

	# olny zpracovani-auto
	@reorders = grep {
		defined $_->{"aktualni_krok"}
		  && (    $_->{"aktualni_krok"} eq EnumsIS->CurStep_PROCESSREORDERERR
			   || $_->{"aktualni_krok"} eq EnumsIS->CurStep_CHECKREORDERERROR )
	} @reorders;

	foreach my $reorder (@reorders) {

		my $jobId = ( $reorder->{"reference_subjektu"} =~ /^(\w\d+)/ )[0];

		if ( AutoProcLog->Exist($jobId) ) {

			my @lines = AutoProcLog->Load($jobId);

			my $jobListErr = scalar( grep { $_ =~ /InCAM error, unable to read database jobs from joblist.xml/i } @lines ) > 0 ? 1 : 0;

			# Try to empty status
			if ($jobListErr) {

				HegMethods->UpdatePcbOrderState(  $reorder->{"reference_subjektu"}, EnumsIS->CurStep_EMPTY );
			}
		}

	}
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

	# 2) set state

	HegMethods->UpdatePcbOrderState( $orderId, $orderState );

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

