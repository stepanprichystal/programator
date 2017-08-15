#!/usr/bin/perl -w


#-------------------------------------------------------------------------------------------#
# Description: This script only show waiting form
# Author:SPR
#-------------------------------------------------------------------------------------------#

use strict;
use warnings;
use Win32::Console;


#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

 
use aliased 'Widgets::Forms::LoadingForm';
use aliased 'Packages::InCAMHelpers::AppLauncher::Helper';
  

my $infoFile = shift; 

my @files = ($infoFile);

my @info = Helper->ParseParams( \@files );    # parse params
  
 
my $frm = LoadingForm->new(-1,  $info[0]->{"title"}, $info[0]->{"text"});

$frm->MainLoop();

 



