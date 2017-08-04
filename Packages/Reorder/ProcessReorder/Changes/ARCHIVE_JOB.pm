#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ProcessReorder::Changes::ARCHIVE_JOB;
use base('Packages::Reorder::ProcessReorder::Changes::ChangeBase');

use Class::Interface;
&implements('Packages::Reorder::ProcessReorder::Changes::IChange');

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
			$zip->addFile( $nif, $jobId . ".dif" );
		}

		my $pdf = $archive . "\\zdroje\\" . "$jobId-control.pdf";

		if ( -e $pdf ) {
			$zip->addFile( $pdf, "$jobId-control.pdf" );
		}

		$zip->addDirectory("nc");

		my $nc = $archive . "\\nc\\";

		if ( opendir( $dir, $nc ) ) {

			while ( ( my $f = readdir($dir) ) ) {

				next unless $f =~ /^[a-z]/i;

				$zip->addFile( $nc . "\\" . $f, "nc\\" . $f );

			}

			close($dir);
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

	use aliased 'Packages::Reorder::ProcessReorder::Changes::MASK_POLAR' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52457";

	my $check = Change->new( "key", $inCAM, $jobId );

	my $mess = "";
	print "Change result: " . $check->Run( \$mess );
}

1;

