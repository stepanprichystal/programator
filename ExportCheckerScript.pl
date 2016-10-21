#!/usr/bin/perl -w

use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Programs::Exporter::ExportChecker::RunExport::RunExportChecker';
 

my $jobId = $ENV{"JOB"};
 

my $form = RunExportChecker->new($jobId);
 
 
 
 




