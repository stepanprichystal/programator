#!/usr/bin/perl -w

#-------------------------------------------------------------------------------------------#
# Description: This script only run exporter utility in tray mode
# Author:SPR
#-------------------------------------------------------------------------------------------#

use strict;
use warnings;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::FileHelper';


print STDERR "\n\n========= SCRIPT UPDATE NC INFO=================\n\n";


my $jobId   = shift;
my $infoStrPath = shift;


print STDERR "\n\n========= SCRIPT UPDATE NC INFO======$jobId===========\n\n";
print STDERR "\n\n========= SCRIPT UPDATE NC INFO======$infoStrPath===========\n\n";
my $infoStr = FileHelper->ReadAsString($infoStrPath);


my $result = 1;

$result = HegMethods->UpdateNCInfo( $jobId, $infoStr );

#unlink $infoStrPath;

 

