#!/usr/bin/perl -w

use strict;
use warnings;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Programs::PoolMerge::RunPoolMerge::RunPoolMerge';


my $exporter = RunPoolMerge->new(1);

 
#Win32::OLE->new
 
 




