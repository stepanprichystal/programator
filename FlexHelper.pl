#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
#use FindBin;
#use lib "$FindBin::Bin/../";
#use PackagesLib;

use aliased 'Packages::CAMJob::SignalLayer::FlexiBendArea';
use aliased 'Packages::InCAM::InCAM';

my $inCAM = InCAM->new();

my $jobId = "$ENV{JOB}";

 
$jobId = "d222774" unless(defined $jobId);
my $step = "o+1";

my $mess = "";



my $result = FlexiBendArea->PutCuToBendArea( $inCAM, $jobId,$step );

 
