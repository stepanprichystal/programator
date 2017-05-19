#-------------------------------------------------------------------------------------------#
# Description: Simple Win service, responsible for checking error log DB and processing
# new logs
# Author:SPR

#3th party library
use strict;
use warnings;
use Log::Log4perl qw(get_logger :levels);
use Try::Tiny;

#use lib qw( y:\server\site_data\scripts );
use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Programs::Services::LogService::MailSender::MailSender';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Other::AppConf';
use aliased 'Connectors::TpvConnector::TpvMethods';
use aliased 'Programs::Services::Helper';
use aliased 'Packages::InCAMCall::InCAMCall';
use aliased 'Enums::EnumsPaths';
 
my $paskageName = "Packages::InCAMCall::Example";
my @par1        = ( "k" => "1" );
my %par2        = ( "par1", "par2" );

 

my $inCAMPath = GeneralHelper->GetLastInCAMVersion();
$inCAMPath .= "bin\\InCAM.exe";

unless ( -f $inCAMPath )    # does it exist?
{
	die "InCAM does not exist on path: " . $inCAMPath;
}

my $fIndicator = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();

my $script = 'c:\Perl\site\lib\TpvScripts\Scripts\pom5.pl';

my $cmd = "$inCAMPath -s" . $script;

 print  $cmd;

#use Config;
#my $perl = $Config{perlpath};

#$inCAMPath = 'c:\opt\InCAM\3.01SP1\bin\InCAM.exe';
use Win32::Process;
my $processObj;
#Win32::Process::Create( $processObj, $inCAMPath, $cmd, 0, THREAD_PRIORITY_NORMAL, "." )
#  || die " run process $!\n";

#my $pidInCAM = $processObj->GetProcessID();

#$processObj->Wait(INFINITE);

system($cmd);

1;
