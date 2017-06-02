#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
#use FindBin;
#use lib "$FindBin::Bin/../";
#use PackagesLib;

use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::Exporter::ExportUtility::Groups::PlotExport::PlotExportTmp';
 
my $inCAM    = InCAM->new("port" => "1234");

$inCAM->COM("get_user_name");
my $user =  $inCAM->GetReply();

print "odpoved je $user";

 