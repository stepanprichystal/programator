#!/usr/bin/perl -w

use strict;
use warnings;
use Win32::Process;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );
use aliased 'Packages::Reorder::ReorderApp::ReorderApp';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::InCAMHelpers::AppLauncher::Launcher';
 
 
my $jobId = "d095908";

my $app = ReorderApp->new($jobId);

my $launcher = Launcher->new(56753);

$app->Init($launcher);

$app->Run();

