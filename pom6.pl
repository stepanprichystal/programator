#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
#use FindBin;
#use lib "$FindBin::Bin/../";
#use PackagesLib;

use aliased "Helpers::FileHelper";
use aliased "Enums::EnumsPaths";
use Data::Dump qw(dump);

use aliased 'Packages::InCAM::InCAM';

my $inCAM = InCAM->new();

use aliased "CamHelpers::CamJob";

my @lines = GetJobList();

#dump(@lines);

my @lines2 = CamJob->GetJobList($inCAM);

#dump(@lines2);

print "Job list = " . scalar(@lines) . "\n";
print "Job list 2 = " . scalar(@lines2) . "\n";

my %tmp;
@tmp{@lines} = ();
my @notIn1list = grep { !exists $tmp{$_} } @lines2;

print "number which not in 1st list = " . scalar(@notIn1list) . "\n";
dump(@notIn1list);

sub GetJobList {
	my $dbName = shift;

	unless ( defined $dbName ) {
		$dbName = "incam";
	}

	my $path  = EnumsPaths->InCAM_server . "config\\joblist.xml";
	my @lines = @{ FileHelper->ReadAsLines($path) };

	@lines = grep { $_ =~ /dbName=\"$dbName\"/ } @lines;

	@lines = map { m/name=\"(\w\d+)\"/ } @lines;

	return @lines;

}
