#!/usr/bin/perl -w

#-------------------------------------------------------------------------------------------#
# Description: Script zip script files and save to backup dr
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use strict;
use warnings;
use POSIX qw(strftime);
use File::Basename;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Path 'rmtree';

# Input parameters

my $sourceDir = shift;                                      # source dir to backup
my $backupDir = shift;                                      # destination dir
my $fname     = shift // strftime "%Y_%m_%d", localtime;    # Option backup file name
my $deleteLog = shift // 12;                                # delete logs older than 12 month

die "Source dir is not defined"     if ( !defined $sourceDir );
die "Backup dir dir is not defined" if ( !defined $backupDir );

# Backup sript

__BackupDir();
__DeleteOldBackups();


# Script subroutines

sub __BackupDir {
	my $backupFile = $backupDir . "\\" . $fname;

	my $i           = 1;
	my $basckupPath = $backupFile . ".zip";
	while ( -e $basckupPath ) {

		$basckupPath = $backupFile . "_v" . $i . ".zip";

		$i++;

	}

	print "Create backup: $basckupPath:\n\n";

	opendir( DIR, $sourceDir ) or die $!;
	my @files = ();
	while ( my $file = readdir(DIR) ) {

		# do not add .git; .settings etc.
		next if ( $file =~ m/^\./ );
		push( @files, $sourceDir . $file );

	}

	closedir(DIR);

	my $zip = Archive::Zip->new();

	my $pred = sub {

		return 1;

	};    # do no include .git dir
	foreach my $f (@files) {

		#print "Source file: $f\n";
		my $n = basename($f);

		my $target = "Scripts\\$n";

		print "- $f\n";

		if ( -d $f ) {
			$zip->addTree( $f, "Scripts\\$n", $pred );
		}
		else {
			$zip->addFile( $f, "Scripts\\$n" );
		}
	}

	unless ( $zip->writeToFileNamed($basckupPath) == AZ_OK ) {

		die "Cannot zip files";
	}
}

# Remove backups older than
sub __DeleteOldBackups {

	print "\nDelete old backups (older than: $deleteLog months):\n\n";

	opendir( DIR, $backupDir ) or die $!;

	my $totalBackDel = 0;

	while ( my $f = readdir(DIR) ) {

		next if ( $f =~ /^\.$/ );
		next if ( $f =~ /^\.\.$/ );

		my $path = $backupDir . $f;

		my @stats = stat($path);

		# remove older than $olderThan months
		if ( ( time() - $stats[10] ) > $deleteLog * 60 * 60 * 24 * 30 ) {

			$totalBackDel++;

			print "- $path\n";

			unlink($path);
		}
	}
	close(DIR);

}

1;

