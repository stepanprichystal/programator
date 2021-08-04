#!/usr/bin/perl -w

use strict;
use warnings;


use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );
use aliased 'Programs::Panelisation::PnlWizard::PnlWizard';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::InCAMHelpers::AppLauncher::Launcher';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";

my $jobId = "d326868"; #sada d305442
#my $jobId = "d301595";

#my @parameters = (PnlCreEnums->PnlType_CUSTOMERPNL);
my @parameters = ( PnlCreEnums->PnlType_PRODUCTIONPNL );

my $app = PnlWizard->new($jobId, @parameters);

my $launcher = Launcher->new(56753);
 
$app->Init( $launcher  );

$app->Run();

$launcher->GetInCAM()->CloseServer();

