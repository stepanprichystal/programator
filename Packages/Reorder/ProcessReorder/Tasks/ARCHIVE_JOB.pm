#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ProcessReorder::Tasks::ARCHIVE_JOB;
use base('Packages::Reorder::ProcessReorder::Tasks::ChangeBase');

use Class::Interface;
&implements('Packages::Reorder::ProcessReorder::Tasks::ITask');

#3th party library
use strict;
use warnings;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use POSIX qw(strftime);

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'Helpers::JobHelper';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# Check if mask is not negative in matrix
sub Run {
	my $self = shift;
	my $mess = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;
 
	# Script zip script files and save to backup dir
	my $fname = "Premnozeni_" . ( strftime "%Y_%m_%d", localtime ) . ".zip";

	my $archive = JobHelper->GetJobArchive($jobId);

	my $zip = Archive::Zip->new();

	my $dir;
	if ( opendir( $dir, $archive ) ) {

		my $tgz = $archive . "\\" . $jobId . ".tgz";

		if ( -e $tgz ) {
			$zip->addFile( $tgz, $jobId . ".tgz" );
		}

		my $nif = $archive . "\\" . $jobId . ".nif";

		if ( -e $nif ) {
			$zip->addFile( $nif, $jobId . ".nif" );
		}

		my $dif = $archive . "\\" . $jobId . ".dif";

		if ( -e $dif ) {
			$zip->addFile( $dif, $jobId . ".dif" );
		}

		my $pdf = $archive . "\\zdroje\\" . "$jobId-control.pdf";

		if ( -e $pdf ) {
			$zip->addFile( $pdf, "$jobId-control.pdf" );
		}

		# add nc directory
		$zip->addDirectory("nc");

		my $nc = $archive . "\\nc\\";
		my $dir2;
		if ( opendir( $dir2, $nc ) ) {

			while ( ( my $f = readdir($dir2) ) ) {

				next unless $f =~ /^[a-z]/i;

				$zip->addFile( $nc . "\\" . $f, "nc\\" . $f );

			}

			close($dir2);
		}
		
		# add old gerber files
		$zip->addDirectory("zdroje");

		my $dirZdroje = $archive . "\\zdroje\\";
		my $dir3;

		if ( opendir( $dir3, $dirZdroje ) ) {

			while ( ( my $f = readdir($dir3) ) ) {

				next unless $f =~ /\.ger$/i;

				$zip->addFile( $dirZdroje . "\\" . $f, "zdroje\\" . $f );

			}

			close($dir3);
		}

		close $dir;
	}

	unless ( $zip->writeToFileNamed( $archive . "zdroje\\$fname" ) == AZ_OK ) {
		die "Zip job archive failed.";
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::ProcessReorder::Tasks::ARCHIVE_JOB';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d152457";

	my $check = ARCHIVE_JOB->new( "key", $inCAM, $jobId );

	my $mess = "";
	print "Change result: " . $check->Run( \$mess );
}

1;

