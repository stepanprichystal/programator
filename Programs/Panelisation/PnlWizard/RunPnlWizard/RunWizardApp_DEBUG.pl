#!/usr/bin/perl -w

use strict;
use warnings;


use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );
use aliased 'Programs::Panelisation::PnlWizard::PnlWizard';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::InCAMHelpers::AppLauncher::Launcher';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";

my $jobId = "d304342";

my @parameters = (PnlCreEnums->PnlType_CUSTOMERPNL);
#my @parameters = ( PnlCreEnums->PnlType_PRODUCTIONPNL );

my $app = PnlWizard->new($jobId);

my $launcher = Launcher->new(56753);

$app->Init( $launcher, @parameters );

$app->Run();

$launcher->GetInCAM()->CloseServer();

