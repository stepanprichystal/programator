#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Helpers::FileHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::InCAM::InCAM';
use aliased 'CamHelpers::CamHelper';

my $jobListP = 'c:\Export\pcb\desky.txt';

my @jobsSrc   = @{ FileHelper->ReadAsLines($jobListP) };
my @jobsFinal = ();

for ( my $i = 0 ; $i < scalar(@jobsSrc) ; $i++ ) {

	if ( $jobsSrc[$i] =~ m/^(\w\d{6})/ ) {

		my $jobId = $1;

		$jobId = lc($jobId);
		push( @jobsFinal, $jobId );
	}
}

print "Total job number: " . scalar(@jobsFinal) . "\n\n";

#sleep(5);

__CheckFsch( \@jobsFinal );

sub __CheckFsch {
	my @jobs = @{ shift(@_) };

	my $inCAM = InCAM->new();

	my $fsch = 0;

	my $jobListP = 'r:\AutoExport\JobList.txt';

	foreach my $jobId (@jobs) {

		CamHelper->OpenJob( $inCAM, $jobId );
		if ( CamHelper->LayerExists( $inCAM, $jobId, "fsch" ) ) {

			$inCAM->COM( "check_inout", "job" => $jobId, "mode" => "out", "ent_type" => "job" );

			use aliased 'Packages::Routing::RoutLayer::FlattenRout::CreateFsch';

			my $fsch = CreateFsch->new( $inCAM, $jobId );

			$fsch->{"onItemResult"}->Add( sub { __ProcesResults(@_) } );

			print $fsch->Create();

			$inCAM->COM( "save_job", "job" => "$jobId" );
			$inCAM->COM( "check_inout", "job" => $jobId, "mode" => "in", "ent_type" => "job" );

			$fsch++;

			print " \n- Job :$jobId  FSCH  ($fsch)";

			open( my $fh, '>>', $jobListP ) or die "Could not open file '$jobListP' $!";
			say $fh "$jobId\n";
			close $fh;
		}

		$inCAM->COM( "close_job", "job" => "$jobId" );

	}

}

sub __ProcesResults {

	my $res = shift;

	print STDERR $res->GetErrorStr();

}

#__DeleteNCPrograms( \@jobsFinal );

sub __DeleteNCPrograms {
	my @jobs = @{ shift(@_) };

	foreach my $jobId (@jobs) {
		my $NCP = JobHelper->GetJobArchive($jobId) . "nc\\";

		#get all files from path
		my $dir;
		opendir( $dir, $NCP ) or die $!;
		while ( my $file = readdir($dir) ) {

			my $fileDrillFC  = $jobId . "_fc";
			my $fileDrillFS  = $jobId . "_fs";
			my $fileDrillFZS = $jobId . "_fzs";

			if ( $file =~ /$fileDrillFC/i || $file =~ /$fileDrillFS/i || $file =~ /$fileDrillFZS/i ) {

				print " \n- Delete file:  " . $NCP . $file;
				unlink( $NCP . $file );
			}
		}

		closedir($dir);

	}
}

