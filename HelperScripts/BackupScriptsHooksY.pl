#!/usr/bin/perl -w

#-------------------------------------------------------------------------------------------#
# Description: Script do backup of hook scripts on server
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use strict;
use warnings;
 
use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Helpers::GeneralHelper';


# Script zip script files and save to backup dir
 
my $sourceDir = "\\\\incam\\incam\\server\\site_data\\hooks\\";
my $backupDir = "r:\\pcb\\pcb\\Scripts_backup\\Site_Hooks\\";

local @ARGV = ( $sourceDir, $backupDir, undef );

my $backScript = GeneralHelper->Root()."\\HelperScripts\\BackupScripts\\BackupScripts.pl";
require $backScript;


