#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Packages::GuideSubs::Scoring::DoFlattenScore';
use aliased 'Packages::InCAM::InCAM';



my $jobId = $ENV{"JOB"};
my $inCAM = InCAM->new();
 
 
  DoFlattenScore->FlattenMpanelScore( $inCAM, $jobId );

