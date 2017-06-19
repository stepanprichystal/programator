#-------------------------------------------------------------------------------------------#
# Description: Helper
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::Helpers::AutoProcLog;

#3th party library
use strict;
use warnings;
 
#local library

 
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#
 
sub Create{
	my $self = shift;
	my $appName = shift;
	my $jobId = shift;
	my $message = shift;
	
	$appName = uc($appName);	
 
	my @lines = ();

	push( @lines, "# APPLICATION NAME:  $appName" );

	push( @lines, "# PCB ID:  $jobId" );
	push( @lines, "" );
	push( @lines, "" );

	push( @lines, "# ============ Message ============ #" );
	push( @lines, "" );

	push( @lines, $message );

 
	my $path = JobHelper->GetJobArchive($jobId) . "AutoProcess_log.txt";

	if ( -e $path ) {
		unlink($path);
	}

	my $f;

	if ( open( $f, "+>", $path ) ) {

		foreach my $l (@lines) {

			print $f "\n" . $l;
		}

		close($f);
	}
	else {
		die "unable to crate 'Auto process log' file for pcbid: $jobId";
	}
 
}

sub Delete{
	my $self = shift;
	my $jobId = shift;
	
	my $path = JobHelper->GetJobArchive($jobId) . "AutoProcess_log.txt";
	
	if(-e $path){
		unlink( $path);
	}
}

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

		use aliased 'Programs::Services::Helpers::AutoProcLog';
	 
	 
	 	#my $log = AutoProcLog->Create("test", "F52457", "ahoj\ntest");
	 	
	 	AutoProcLog->Delete("F52457");
	 	
	 
	 
}

1;