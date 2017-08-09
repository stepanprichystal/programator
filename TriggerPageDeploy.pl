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
use aliased 'Packages::TriggerFunction::MDIFiles';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::TriggerFunction::NCFiles';
use aliased 'Connectors::HeliosConnector::HegMethods';

my $orderId     = shift;    # job order for process


my $logConfig = "c:\\Apache24\\htdocs\\tpv\\Logger.conf";
Log::Log4perl->init($logConfig);

my $logger = get_logger("trigger"); 

$logger->debug("Trigger page run");

# old way is only job id f123645
# new way is ordefr id f12345-01
#if old way get the biggest order id

unless( $orderId =~ /^(\w\d+)-.*$/){
	
	my $orderNum = HegMethods->GetPcbOrderNumber($orderId);
	$orderId .= "-".$orderNum;
}
 
my $processed = 1;


# 1) change some lines in MDI xml files eval
eval {

	MDIFiles->AddPartsNumber($orderId);

};
if ($@) {

	$processed = 0;
	$logger->error( "\n Error when processing \"MDI files\" job: $orderId.\n" . $@, 1 );
}

# 2) change drilled number in NC files
eval {

	NCFiles->ChangePcbOrderNumber($orderId);
};
if ($@) {

	$processed = 0;
	$logger->error( "\n Error when processing \"NC files\" job: $orderId.\n" . $@, 1 );
}

 

# Log

if ($processed) {
	
	$logger->info("$orderId - Processed ");

}
else {
 
	$logger->info("$orderId - Processed with ERRORS ");
}
 
