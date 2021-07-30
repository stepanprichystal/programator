#!/usr/bin/perl -w

# Temporarz launch script for run panelisation from old panelisation script

use strict;
use warnings;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Programs::Panelisation::PnlWizard::PnlWizard';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::InCAMHelpers::AppLauncher::Launcher';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
 
 



use aliased 'Programs::Panelisation::PnlWizard::RunPnlWizard::RunPnlWizard';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
 



my $jobId = shift // $ENV{"JOB"};

#my $pnlType = PnlCreEnums->PnlType_CUSTOMERPNL;
my $pnlType =  PnlCreEnums->PnlType_PRODUCTIONPNL;

die "Panel type is not defined" unless(defined $pnlType);
die "Job is not defined" unless(defined $pnlType);




my $form = RunPnlWizard->new($jobId, $pnlType);
$form->LaunchViaAppLauncher();





