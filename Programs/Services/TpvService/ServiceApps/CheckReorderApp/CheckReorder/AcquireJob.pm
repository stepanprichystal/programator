#-------------------------------------------------------------------------------------------#
# Description: Represent Universal Drill tool manager

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::AcquireJob;

#3th party library
use strict;
use warnings;
use Log::Log4perl qw(get_logger);

#local library
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

# Try acquire job and import to inCAM
# return 1 if job is prepared in incam
# return 0, if job in InCAM doesnt exist
sub Acquire {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $result = 1;
 

	my $logger = get_logger("checkReorder");

	unless ( CamJob->JobExist( $inCAM, $jobId ) ) {

		$result = 0;

		# check if tgz exist
		my $path = JobHelper->GetJobArchive($jobId) . $jobId . ".tgz";

		if ( -e $path ) {

			my $importSucc = 1;       # tell if job was succesfully imported
			my $importErr  = undef;

			# try to import job to InCAM three times
			my $importOk = undef;
			foreach ( 1 .. 3 ) {

				$logger->debug("Attem number: $_ to import job");

				$importOk = $self->__ImportJob( $inCAM, $path, $jobId, \$importErr );

				# if succes ( == 0)
				if ( $importOk == 0 ) {
					last;
				}

				$logger->debug("Attem number: $_ to import job FAIL");
				sleep(2);
			}

			# test if import fail
			if ( $importOk != 0 ) {
				$importSucc = 0;

			}

			# import succes, try if job now exist
			elsif ( $importOk == 0 && !CamJob->JobExist( $inCAM, $jobId ) ) {

				$importSucc = 0;
				$importErr  = "Job import was not succes\n";
			}

			# if errors,
			if ($importSucc) {

				$result = 1;    # succesfully imported, job is prepared

			}
			else {

				# import was not succ, die - send log to db
				die "Error during import job to InCAM db. $importErr";

				#$self->{"loggerDB"}->Error($importErr);
			}

		}
	}

	return $result;
}

sub __ImportJob {
	my $self      = shift;
	my $inCAM     = shift;
	my $path      = shift;
	my $jobId     = shift;
	my $importErr = shift;

	$inCAM->HandleException(1);

	my $importOk = $inCAM->COM( 'import_job', "db" => 'incam', "path" => $path, "name" => $jobId, "analyze_surfaces" => 'no' );

	$inCAM->HandleException(0);

	# test if import fail
	if ( $importOk != 0 ) {

		$$importErr = $inCAM->GetExceptionError();
	}

	return $importOk

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

