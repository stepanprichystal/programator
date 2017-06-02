#-------------------------------------------------------------------------------------------#
# Description: "InCAM server " is server which is able to run and prepare InCAM editor
# Allow control amount of launched editor, see config file
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

use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::Services::TpvService::ServiceApps::ReOrderApp::ReOrderApp' => "App";
 
my $jobId    = "f52456-01";

my $app = App->new();

my $inCAM    = InCAM->new();



$app->{"inCAM"} = $inCAM;

$app->Run();

#$app->RunJob($jobId);

print "app inited";

