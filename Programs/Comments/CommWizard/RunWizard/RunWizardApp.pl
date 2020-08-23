#!/usr/bin/perl -w

use strict;
use warnings;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Programs::Comments::CommWizard::RunWizard::RunCommWizard';
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';

my $jobId = $ENV{"JOB"};

my $form = RunCommWizard->new($jobId);
$form->LaunchViaAppLauncher();
