#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::INCAM_JOB;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# Check if exist new version of nif, if so it means it is from InCAM
sub NeedChange {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $jobExist = shift;    # (in InCAM db)
	my $isPool = shift;

	my $needChange = 0;

	my $nifPath = JobHelper->GetJobArchive($jobId) . $jobId . ".nif";

	 
	# First test, if job is imported (exist) in incam db
	unless($jobExist){
		$needChange = 1;
	}

	unless ($isPool) {
		if ( -e $nifPath ) {

			my @lines = @{ FileHelper->ReadAsLines($nifPath) };

			# new nif contain = on first row
			if ( $lines[0] !~ /=/ ) {

				$needChange = 1;
			}

		}
		else {

			$needChange = 1;
		}
	}

	return $needChange;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::CheckReorder::Checks::INCAM_JOB' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d10355";

	my $check = Change->new();

	print "Need change: " . $check->NeedChange( $inCAM, $jobId, 1 );
}

1;

