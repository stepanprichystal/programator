#!/usr/bin/perl -w
#
#-------------------------------------------------------------------------------------------#
# Description: Script launch some packages, when job goes to produce
# This script is launched by tpv-server by script c:\inetpub\wwwroot\tpv\StartTrigger.pl
# See c:\inetpub\wwwroot\tpv\Log.txt, whih jobs go to produce or for errors
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use POSIX 'strftime';
use File::Basename;
use Try::Tiny;
use Log::Log4perl qw(get_logger :levels);

#local library
use lib qw( \\\\incam\\InCAM\\server\\site_data\\scripts);

#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
#use FindBin;
#use lib "$FindBin::Bin/../";
#use PackagesLib;

#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );
use aliased 'Packages::TriggerFunction::MDIFiles';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::TriggerFunction::NCFiles';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::TriggerFunction::Travelers';
use aliased 'Programs::Services::TpvService2::ServiceApps::TaskOnDemand::Enums' => 'TaskEnums';
use aliased 'Connectors::TpvConnector::TaskOndemMethods';
 
my $orderId  = shift;    # job order for process (Dxxxxxx-xx-Jx Core - Dxxxxxx-xx Order)
my $taskType = shift;    # type of task to process
my $loginId  = shift;    # user which do request
my $extraId  = shift;    # extra order id (number of extra product - dodelavka)

#$orderId = "d270787-03";
#$taskType = TaskEnums->PCB_TOPRODUCE;

my $logConfig = "c:\\Apache24\\htdocs\\tpv\\Logger.conf";
Log::Log4perl->init($logConfig);

my $logger = get_logger("trigger");

$logger->debug("Trigger page run");

$logger->debug("Params before set default values. Order id: $orderId, Task type: $taskType, LoginId: $loginId, ExtraId: $extraId");

# Set default values for params

if ( $taskType eq "not_defined" ) {

	$taskType = TaskEnums->PCB_TOPRODUCE;
}

$logger->debug("Params after set default values. Order id: $orderId, Task type: $taskType");

my $processed = 1;

# Order Id can have following formats
# - Dxxxxxx-xx-Jx Core
# - Dxxxxxx-xx Order
# Run only orders
if ( $orderId =~ /^\w\d{6}-\d{2}$/ ) {

	if ( $taskType eq TaskEnums->PCB_TOPRODUCE ) {

		__PcbToProduce();

	}
	elsif ( $taskType eq TaskEnums->Data_COOPERATION ) {

		__DataCooperation();

	}
	elsif ( $taskType eq TaskEnums->Data_CONTROL ) {

		__DataControl();

	}
}
else {
	
	$processed = 0;
}

# Log

if ($processed) {

	$logger->info("$orderId - Processed ");

}
else {

	$logger->info("$orderId - Processed with ERRORS ");
}

#-------------------------------------------------------------------------------------------#
# Func to process requsted tasks
#-------------------------------------------------------------------------------------------#

sub __PcbToProduce {

	# 1) Convert stackup trevellers template to pdf
	eval {

		$logger->debug( "Before process trevelers template files --" . $orderId . "--" );
		Travelers->StackupTemplate2PDF( $orderId, $extraId );
		$logger->debug( "After process trevelers template files --" . $orderId . "--" );

	};
	if ($@) {

		$processed = 0;
		$logger->error( "\n Error when processing \"stackup trevelers template\" job: $orderId.\n" . $@, 1 );
	}

	# 2) Convert peel stencil trevellers template to pdf
	eval {

		$logger->debug( "Before process trevelers template files --" . $orderId . "--" );
		Travelers->PeelStnclTemplate2PDF( $orderId, $extraId );
		$logger->debug( "After process trevelers template files --" . $orderId . "--" );

	};
	if ($@) {

		$processed = 0;
		$logger->error( "\n Error when processing \"peel stencil trevelers template\" job: $orderId.\n" . $@, 1 );
	}

	# 3) Convert peel stencil trevellers template to pdf
	eval {

		$logger->debug( "Before process trevelers template files --" . $orderId . "--" );
		Travelers->CvrlStnclTemplate2PDF( $orderId, $extraId );
		$logger->debug( "After process trevelers template files --" . $orderId . "--" );

	};
	if ($@) {

		$processed = 0;
		$logger->error( "\n Error when processing \"cvrl stencil trevelers template\" job: $orderId.\n" . $@, 1 );
	}

	# Process only if order go to produce first time
	if ( !defined $extraId || $extraId == 0 ) {

		# 2) change some lines in MDI xml files eval
		eval {

			$logger->debug( "Before process MDI files --" . $orderId . "--" );
			MDIFiles->AddPartsNumber($orderId);
			$logger->debug( "After process MDI files --" . $orderId . "--" );

		};
		if ($@) {

			$processed = 0;
			$logger->error( "\n Error when processing \"MDI files\" job: $orderId.\n" . $@, 1 );
		}

		# 3) change drilled number in NC files
		eval {

			NCFiles->ChangePcbOrderNumber($orderId);
		};
		if ($@) {

			$processed = 0;
			$logger->error( "\n Error when processing \"NC files\" (change pcb drilled nuimber) job: $orderId.\n" . $@, 1 );
		}

		# 4) Add rout speed to NC rout operation
		eval {

			NCFiles->CompleteRoutFeed($orderId);
		};
		if ($@) {

			$processed = 0;
			$logger->error( "\n Error when processing \"NC files\" (add rout speed) job: $orderId.\n" . $@, 1 );
		}
	}
}

sub __DataCooperation {

	my ($jobId) = $orderId =~ /^(\w\d+)-\d+/i;
	$jobId = lc($jobId);

	# Insert new request to tpv database. Window services process theses request
	eval {

		$logger->info("Data cooperation $jobId.");
		TaskOndemMethods->InsertTaskPcb( $jobId, TaskEnums->Data_COOPERATION, $loginId );

	};
	if ($@) {

		$processed = 0;
		$logger->error( "\n Error when processing task: " . TaskEnums->Data_COOPERATION . " for job: $orderId.\n" . $@, 1 );
	}

}

sub __DataControl {

	my ($jobId) = $orderId =~ /^(\w\d+)-\d+/i;
	$jobId = lc($jobId);

	# Insert new request to tpv database. Window services process theses request
	eval {

		$logger->info("Data control $jobId.");
		TaskOndemMethods->InsertTaskPcb( $jobId, TaskEnums->Data_CONTROL, $loginId );

	};
	if ($@) {

		$processed = 0;
		$logger->error( "\n Error when processing task: " . TaskEnums->Data_CONTROL . " for job: $orderId.\n" . $@, 1 );
	}

}

