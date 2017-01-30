#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;
use POSIX qw(strftime);


my $fname =  strftime "%Y_%m_%d", localtime;

 
$fname  = "c:\\BackupTpvDb\\".$fname.".sql";


my $cmd = "c:\\BackupTpvDb\\script\\mysqldump.exe";
my $param = " -e -uroot -p1234 -hlocalhost tpv_log > ".$fname;


system( $cmd  .$param);

