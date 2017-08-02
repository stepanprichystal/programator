#-------------------------------------------------------------------------------------------#
# Description: Creating atuo change log file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::AutoChangeFile;

#3th party library
use strict;
use warnings;
use Log::Log4perl qw(get_logger);
use JSON;

#local library
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub Create {
	my $self   = shift;
	my $jobId  = shift;
	my @autoCh = @{ shift(@_) };

	my $path = JobHelper->GetJobArchive($jobId) . "AutoChange_log.txt";

	my $json = JSON->new();

	my $serialized = $json->pretty->encode( \@autoCh );

	#delete old file
	if ( -e $path ) {
		unless ( unlink($path) ) {
			die "Unable delete old AutoChange_log at $path";
		}
	}

	if ( open( my $f, '>', $path ) ) {
		print $f $serialized;
		close $f;
	}
	else {

		die "unable to crate 'Auto Change log' file for pcbid: $jobId";
	}

}

sub Read {
	my $self = shift;
	my $jobId  = shift;
	
	my $path = JobHelper->GetJobArchive($jobId) . "AutoChange_log.txt";
	my @data = ();

	if ( -e $path ) {

		# read from disc
		# Load data from file
		my $serializeData = FileHelper->ReadAsString( $path );

		my $json = JSON->new();

		my $d = $json->decode($serializeData);
		if(defined $d){
			@data = @{$d};
		}
 
	}else{
		
		die "'Auto Change log' file doesn§t exist";
	}
	
	return @data;
}
 

sub Delete {
	my $self  = shift;
	my $jobId = shift;

	my $chngeLog =   JobHelper->GetJobArchive($jobId) . "AutoChange_log.txt";

	if ( -e $chngeLog ) {
		unlink($chngeLog);
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

