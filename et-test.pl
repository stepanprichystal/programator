#!/usr/bin/perl-w

use Time::localtime;



#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );


use aliased 'Packages::CAMJob::JobLog::JobLogReport';



#my $hostName = $ENV{HOST};

JobLogReport->Export_LogFile('Radim input');



