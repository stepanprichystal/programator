#!/usr/bin/perl -w

use strict;
use warnings;
use Win32::Process;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );
use aliased 'Programs::Coupon::CpnWizard::CpnWizard';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::InCAMHelpers::AppLauncher::Launcher';
use aliased 'Programs::Stencil::StencilCreator::Enums';
 
 
my $jobId = "d152456";

my $app = CpnWizard->new($jobId);

my $launcher = Launcher->new(56753);

$app->Init($launcher);

$app->Run();

$launcher->GetInCAM()->CloseServer();

my $pom = 0;

#Error during generating coupon



