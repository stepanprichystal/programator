#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

  
use strict;
use warnings;

#use Try::Tiny;
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::InCAM::InCAM';

my $inCAM    = InCAM->new();

my $job = "d152457";

my $p = 'c:/pcb/d152457';
my $scr = 'c:/export/test/auto_identify.txt';
my $scr2 = 'c:/export/test/auto_translate.txt';
my $scr3 = 'c:/export/test/auto_report.txt';
#$inCAM->COM("input_identify","path" => $p,"job" => $job,"script_path" => $scr);


$inCAM->COM("input_auto","path" => $p,"job" => $job,"ident_script_path" => $scr, "trans_script_path" => $scr2, "report_path" => $scr3, "step" => "o");

 