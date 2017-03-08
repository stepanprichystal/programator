#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;
use utf8;

#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packagesff
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Packages::InCAM::InCAM';


my $inCAM = InCAM->new();
 
$inCAM->COM("get_work_layer");



my $layer = $inCAM->GetReply();

print "\n\n\n\n $layer ========= \n\n\n\n";