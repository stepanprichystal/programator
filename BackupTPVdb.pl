#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;
use POSIX qw(strftime);


my $fname =  strftime "%Y_%m_%d", localtime;

 
$fname  = "c:\\BackupDb\\".$fname.".sql";
my @cmd = ('C:\Program Files\MySQL\MySQL Server 5.7\bin\mysqldump.exe', "-e -utpv_log -p1234 -hlocalhost tpv_log > ".$fname);


system(@cmd);

