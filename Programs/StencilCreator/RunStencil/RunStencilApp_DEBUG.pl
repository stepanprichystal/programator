#!/usr/bin/perl -w

use strict;
use warnings;
use Win32::Process;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );
use aliased 'Programs::StencilCreator::StencilCreator';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::InCAMHelpers::AppLauncher::Launcher';
 
 
my $jobId = "f13609";

my $app = StencilCreator->new($jobId);

my $launcher = Launcher->new(56753);

$app->Init($launcher);

$app->Run();

