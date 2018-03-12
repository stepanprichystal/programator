#!/usr/bin/perl -w

use strict;
use warnings;
use Win32::Process;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );
use aliased 'Programs::Stencil::StencilCreator::StencilCreator';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::InCAMHelpers::AppLauncher::Launcher';
use aliased 'Programs::Stencil::StencilCreator::Enums';
 
 
my $jobId = "d113610";

my $app = StencilCreator->new($jobId,  Enums->StencilSource_CUSTDATA);

my $launcher = Launcher->new(56753);

$app->Init($launcher);

$app->Run();

$launcher->GetInCAM()->CloseServer();



