#-------------------------------------------------------------------------------------------#
# Description: Load job to incam db
#
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::AcquireJob;

#3th party library
use strict;
use warnings;
use Log::Log4perl qw(get_logger);
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove);
 use File::Path qw(make_path);

#local library
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#




# Try acquire job and import to inCAM
# return 1 if job is prepared in incam
# return 0, if job in InCAM doesnt exist
# Note.: Works only for job id in format: Dxxxxxx (6-number id)
sub Acquire {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $result = 1;
	
	if($jobId !~ /^D\d{6}$/i){
		die "Jobid ($jobId) is invalid."
	}

	my $logger = get_logger("checkReorder");

	unless ( CamJob->JobExist( $inCAM, $jobId ) ) {

		$result = 0;

		# check if tgz exist
		my $path = JobHelper->GetJobArchive($jobId) . $jobId . ".tgz";

		# Check if it is former job from old archive. If so get path to old archive
		my $oldPath  = undef;
		my $oldPcbId = undef;

		my $moveOldArchive = 0;

		if ( JobHelper->FormerPcbId( $jobId, \$oldPath, \$oldPcbId ) && !( -e $path ) ) {
			$path = $oldPath . $oldPcbId . ".tgz";
 			
 			$moveOldArchive = 1;
		}

		if ( -e $path ) {

			my $importSucc = 1;       # tell if job was succesfully imported
			my $importErr  = undef;

			# try to import job to InCAM three times
			my $importOk = undef;
			foreach ( 1 .. 3 ) {

				$logger->debug("Attem number: $_ to import job");

				$importOk = $self->__ImportJob( $inCAM, $path, $jobId, \$importErr );

				# if succes ( == 0)
				# sometomes happen that import fail, but job is imported properly, thus test if job already exist
				if ( $importOk == 0 || CamJob->JobExist( $inCAM, $jobId ) ) {

					$importOk = 0;
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
				
				if($moveOldArchive){
					$self->MoveOldArchive($jobId); # move old archive data to new and rename
				}

			}
			else {

				# import was not succ, die - send log to db
				die "Error during import job to InCAM db. $importErr";

				#$self->{"loggerDB"}->Error($importErr);
			}

		}
		else {

			die "Error during import job to InCAM db. TGZ file doesn't exist at $path "
			  . ( defined $oldPcbId ? "(PcbId: $jobId => former Pcbid: $oldPcbId)" : "" );
		}
	}

	return $result;
}


# Try acquire job and import to inCAM
# return 1 if job is prepared in incam
# return 0, if job in InCAM doesnt exist
# Note.: Works for job id in new format: Dxxxxxx (6-number id) and old format Dxxxxx (5-number id)
# Job is loaded to incam always in new format
sub Acquire2 {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	if($jobId =~ /^[df]\d{5}$/i){
		
		$jobId = JobHelper->ConvertJobIdOld2New($jobId);
	}
	 
	# Supress all toolkit exception/error windows
	$inCAM->SupressToolkitException(1);
	my $result = $self->Acquire($inCAM, $jobId);
	$inCAM->SupressToolkitException(0);
	
	return $result
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

# Move old archive of job (for  5-digit pcbi id )to new archive (for  6-digit pcbid)
# Rename all files (replace old pcbid to new)
sub MoveOldArchive {
	my $self     = shift;
	my $newPcbId = shift;

	my $newPath  = JobHelper->GetJobArchive($newPcbId);
	my $oldPath  = undef;
	my $oldPcbId = undef;

	if ( !JobHelper->FormerPcbId( $newPcbId, \$oldPath, \$oldPcbId ) ) {
		die "PcbId: $newPcbId is not \"former\" pcb id";
	}
 
 
	unless ( -e $newPath ) {

		$newPath = uc($newPath);
		 make_path($newPath);
	}

	my $copyCnt = dircopy( $oldPath, $newPath );

	if ($copyCnt) {
	
		# rename folis in new archiv - old pcbid to new pcb id
		RenameFiles( $newPath, $oldPcbId, $newPcbId );
	}

}

sub RenameFiles {
	my $path    = shift;
	my $oldName = shift;
	my $newName = shift;

	opendir( DIR, $path );
	my @list_of_files = readdir(DIR);
	foreach (@list_of_files) {

		if ( $_ ne "." && $_ ne ".." ) {

			if ( -d "$path/$_" ) {
				RenameFiles( "$path/$_", $oldName, $newName );
			}
			else {
 
				next if ( $_ !~ /$oldName/i );

				my $fName    = $_;
				my $fNameNew = $_;

				$fNameNew =~ s/^$oldName/$newName/i;
				rename "$path/$_", "$path/" . "$fNameNew";
			}
		}
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {
	
	use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::AcquireJob';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	
	# 1) # zkontroluje jestli jib existuje v InCAM, pokud ne odarchivuje a nahraje do InCAM
	# 2) # pokud se jedna o job ze stareho archivu, tak nahraje job do InCAMu z neho
	#my $result = AcquireJob->Acquire($inCAM,"d142003"); 


	AcquireJob->MoveOldArchive("d142003");
}

1;

