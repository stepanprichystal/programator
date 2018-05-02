#!/usr/bin/perl-w
#################################
#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );


use aliased 'Packages::Technology::EtchOperation';

print EtchOperation->GetCompensation(35,6,0);


