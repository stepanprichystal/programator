#!/usr/bin/perl -w

use strict;
use warnings;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Programs::Panelisation::PnlWizard::RunPnlWizard::RunPnlWizard';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
 


my $pnlType = shift;

my $jobId = $ENV{"JOB"};
 

#my $pnlType = PnlCreEnums->PnlType_CUSTOMERPNL;
my $pnlType =  PnlCreEnums->PnlType_PRODUCTIONPNL;

die "Panel type is not defined" unless(defined $pnlType);

my $form = RunPnlWizard->new($jobId, $pnlType);
 
