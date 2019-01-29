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
use aliased 'Programs::Services::TpvService2::ServiceApps::TaskOnDemand::TaskOnDemandApp' => "App";
 
my $jobId    = "d113609";
my $orderId    = "d113609-01";
my $app = App->new();

my $inCAM    = InCAM->new();

$inCAM->SupressToolkitException(1);

$app->{"inCAM"} = $inCAM;

#$app->Run();

$app->__RunJob($jobId, $orderId, "cooperation_data", undef, "th");


#	my $jobId    = shift;
#	my $orderId  = shift;
#	my $taskType = shift;
#	my $inserted = shift;
#	my $loginId = shift

#$app->__ProcessJob($jobId);

print "app inited";

