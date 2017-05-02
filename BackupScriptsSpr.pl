#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;
use POSIX qw(strftime);


# Script zip script files and save to backup dr


my $fname = strftime "%Y_%m_%d", localtime;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Path 'rmtree';

my $sourceDir = "c:\\Perl\\site\\lib\\TpvScripts\\Scripts";
my $backupDir = "z:\\sys\\Scripts_backup\\SPR_Scripts\\" . $fname;


my $i           = 1;
my $basckupPath = $backupDir. ".zip";
while ( -e $basckupPath ) {

	$basckupPath = $backupDir . "_v" . $i. ".zip";
	
	$i++;
}
 

my $zip = Archive::Zip->new();

my $pred = sub { /\.*/ };
$zip->addTree( $sourceDir, 'Scripts', $pred );
 

unless ( $zip->writeToFileNamed($basckupPath) == AZ_OK ) {

	die "Cannot zip files";
}

