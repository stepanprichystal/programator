#-------------------------------------------------------------------------------------------#
# Description: Close zombified InCAM server running on specific port or port range
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use strict;
use warnings;
 


#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#use local library;
use aliased 'Helpers::Win32Helper';
use aliased "Enums::EnumsPaths";



my $output = shift(@_);    # save here output message
my $cmds   = shift(@_);    # all parameters, which are passed to construcotr of SystemCall class
 
 
my $runingCnt = Win32Helper->GetRunningInstanceCnt("InCAMServerScript.pl");
 
$output->{"runInstanceCnt"} = $runingCnt;


