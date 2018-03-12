#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

 

#use Try::Tiny;
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::InCAM::InCAM';

my $inCAM    = InCAM->new();

my $job = "d152457";

my $p = 'c:/pcb/f76142/f76143';
my $scr = 'c:/export/test/test.txt';

$inCAM->COM("input_identify","path" => $p,"job" => $job,"script_path" => $scr);

 


use strict;
use warnings;

#use Try::Tiny;
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::InCAM::InCAM';

my $inCAM    = InCAM->new();

my $job = "d152457";

my $p = 'c:/pcb/f76142/f76143';
my $scr = 'c:/export/test/test.txt';

$inCAM->COM("input_identify","path" => $p,"job" => $job,"script_path" => $scr);


drill_size.tab