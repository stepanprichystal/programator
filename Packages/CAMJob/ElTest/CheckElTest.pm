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
# - check Heg if el test requested
sub ElTestRequested {
	my $self  = shift;
	my $jobId = shift;

	# Load nif info
	my $nif = NifFile->new($jobId);
 
 

	if ( !defined $nif->GetValue("pocet_vrstev") || !defined $nif->GetValue("kons_trida") ) {
		die "Information from nif file is not complete (rows: pocet_vrstev; kons_trida )";
	}

	# get if test is mandatory

	my $testRequested = 0;

	if ( HegMethods->GetElTest($jobId) ) {

		$testRequested = 1;
	}
	else {

		if ( $nif->GetValue("pocet_vrstev") == 0 || ($nif->GetValue("kons_trida") <= 3 && $nif->GetValue("pocet_vrstev") == 1) ) {

			$testRequested = 0;
		}
		else {

			$testRequested = 1;
		}
	}
 
}

# Return if job el test exists
sub ElTestExists {
	my $self  = shift;
	my $jobId = shift;

	my $path = JobHelper->GetJobElTest( $jobId, 1 );

	my $elTestExist = 1;
	if ( -e $path ) {

		my @dirs = ();
		my $d;
		if ( opendir( $d, $path ) ) {
			@dirs = readdir($d);
			closedir($d);
		}

		if ( scalar( grep { $_ =~ /^A[357]_/i } @dirs ) < 1 ) {

			$elTestExist = 0;
		}
	}
	else {
		$elTestExist = 0;
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
	my $jobId = "d167723";
	my $step  = "o+1";

	my $mess = "";
	my $res = CheckElTest->ElTestRequested($jobId );

	print "$res - $mess";

}

1;
