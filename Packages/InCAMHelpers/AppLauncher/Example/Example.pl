 #!/usr/bin/perl -w
 
 
#-------------------------------------------------------------------------------------------#
# Description: Example of App launcher usage
#
# Author:SPR
#-------------------------------------------------------------------------------------------#
 
#3th party library
use threads;
use strict;
use warnings;
 
#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts ); 
 
#local library 
 
use aliased 'Packages::InCAMHelpers::AppLauncher::AppLauncher';
use aliased 'Packages::InCAMHelpers::AppLauncher::Enums';
use aliased 'Helpers::GeneralHelper';
#-------------------------------------------------------------------------------------------#
#  Script code
#-------------------------------------------------------------------------------------------#
 
 
 	my $appName = 'Packages::InCAMHelpers::AppLauncher::Example::ExampleApp'; # has to implement IAppLauncher
 	
 	my $launcher = AppLauncher->new($appName, "param1", "param2");
 	
 	$launcher->SetWaitingFrm("Titulek", "text", Enums->WaitFrm_CLOSEMAN);
 	
 	my $logPath =   GeneralHelper->Root() . "\\Packages\\InCAMHelpers\\AppLauncher\\Example\\Logger.conf";
 	
 	$launcher->SetLogConfig($logPath);
 	
 	$launcher->RunFromInCAM();
 
  

1;
