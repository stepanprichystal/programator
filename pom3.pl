

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