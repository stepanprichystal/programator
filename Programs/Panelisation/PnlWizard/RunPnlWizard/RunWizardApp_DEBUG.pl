#!/usr/bin/perl -w

use strict;
use warnings;
use Win32::Process;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );
use aliased 'Programs::Panelisation::PnlWizard::PnlWizard';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::InCAMHelpers::AppLauncher::Launcher';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";

my $jobId = "d222606";

#my @parameters = (PnlCreEnums->PnlType_CUSTOMERPNL);
my @parameters = (PnlCreEnums->PnlType_PRODUCTIONPNL);

my $app = PnlWizard->new($jobId);

my $launcher = Launcher->new(56753);

$app->Init($launcher, @parameters);

$app->Run();

$launcher->GetInCAM()->CloseServer();



