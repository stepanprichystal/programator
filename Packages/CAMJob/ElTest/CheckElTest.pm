#-------------------------------------------------------------------------------------------#
# Description: Function for checking electricatl test files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::ElTest::CheckElTest;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use Path::Tiny qw(path);

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::NifFile::NifFile';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Return if el test is requested:
# - class > 3
# - check IS if el test requested
# Return undef if there is no clues if EL test is requested
sub ElTestRequested {
	my $self  = shift;
	my $jobId = shift;

	my $testRequested = 0;

	# get if test is mandatory

	if ( HegMethods->GetElTest($jobId) ) {

		$testRequested = 1;
	}
	else {

		my $nif = NifFile->new($jobId);

		if ( !$nif->Exist() || !defined $nif->GetValue("pocet_vrstev") || !defined $nif->GetValue("kons_trida") ) {

			$testRequested = undef;
		}
		else {

			if ( $nif->GetValue("pocet_vrstev") == 0 || ( $nif->GetValue("kons_trida") <= 3 && $nif->GetValue("pocet_vrstev") == 1 ) ) {

				$testRequested = 0;
			}
			else {

				$testRequested = 1;
			}
		}
	}

	return $testRequested;

}

# Return if job el test is prepared by follow steps:
# Search "original" dir in el test storage
# If no original dir, search original ipc file
# (ipc file have SR steps - el test prepared
#  ipc file has not SR and panel multiple is prepared - el test prepared too)
sub ElTestPrepared {
	my $self  = shift;
	my $jobId = shift;

	my $path = JobHelper->GetJobElTest($jobId);

	my $elTestExist = 0;
	if ( -e $path ) {

		# 1) search for "original" dir
		my @dirs = ();
		my $d;
		if ( opendir( $d, $path ) ) {
			@dirs = readdir($d);
			closedir($d);
		}

		if ( scalar( grep { $_ =~ /^original$/i } @dirs ) ) {

			$elTestExist = 1;
		}

		# 2) search for ipc file
		unless ($elTestExist) {

			my $ipcFile = $path . "\\" . $jobId . "t.ipc";

			if ( -e $ipcFile ) {

				my $file = path($ipcFile);

				my $data = $file->slurp_utf8;
				if ( $data =~ /IMAGE PRIMARY/i ) {
					$elTestExist = 1;

				}
				else {

					# Load nif info
					my $nif          = NifFile->new($jobId);
					my $totalMultipl = $nif->GetValue("nasobnost");

					if ( $totalMultipl == 1 ) {
						$elTestExist = 1;
					}

				}
			}
		}
	}

	return $elTestExist;
}

# Return if job has created IPC file
# Search IPC file dir in el test storage
# If no original dir, search original ipc file
sub IPCPrepared {
	my $self   = shift;
	my $jobId  = shift;
	my $kooper = shift // 0;

	my $ipcPath = JobHelper->GetJobElTest( $jobId, $kooper );

	my $elTestExist = 0;
	if ( -e $ipcPath ) {

		my $ipcFile = $ipcPath . $jobId . "t";
		$ipcFile .= "_kooperace" if ($kooper);
		$ipcFile .= ".ipc";

		if ( -e $ipcFile ) {

			$elTestExist = 1;
		}

	}

	return $elTestExist;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::ElTest::CheckElTest';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d152457";
	my $step  = "o+1";

	my $mess = "";
	my $res  = CheckElTest->ElTestPrepared($jobId);

	print "$res - $mess";

}

1;
