#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::InCAM::InCAM';
my $pcbName = "abcdefg";

my $jobId = "d322016";

my $inCAM = InCAM->new();
$pcbName = substr($pcbName, 0, length($pcbName) -1 );

$inCAM->COM("get_step_name");
print STDERR "Step:".$inCAM->GetReply()."\n";

CamHelper->SetStep( $inCAM,  "o+1" );

CamHelper->SetStep( $inCAM,  "o+1" );

$inCAM->COM("get_step_name");
 
print STDERR "Step:".$inCAM->GetReply()."\n";

CamHelper->SetStep( $inCAM,  "panel" );

$inCAM->COM("get_step_name");
 
print STDERR "Step:".$inCAM->GetReply()."\n";

die;

print $pcbName;