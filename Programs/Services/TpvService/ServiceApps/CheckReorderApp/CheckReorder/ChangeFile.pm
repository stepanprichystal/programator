#-------------------------------------------------------------------------------------------#
# Description: Represent Universal Drill tool manager

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::ChangeFile;

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


sub Create {
	my $self   = shift;
	my $jobId  = shift;
	my @manCh  = @{ shift(@_) };

	my @lines = ();

	push( @lines, "# REORDER CHECKLIST" );

	push( @lines, "# PCB ID:  $jobId" );
	push( @lines, "" );
	push( @lines, "" );

	push( @lines, "# ============ Manual tasks ============ #" );
	push( @lines, "" );

	for ( my $i = 0 ; $i < scalar(@manCh) ; $i++ ) {

		push(@lines, "# ".($i+1).")\n");

		push( @lines, $manCh[$i]->{"text"}."\n\n" );

	}

	push( @lines, "" );
 
	my $path = JobHelper->GetJobArchive($jobId) . "Change_log.txt";

	if ( -e $path ) {
		unlink($path);
	}

	my $f;

	if ( open( $f, "+>:utf8", $path ) ) {

		foreach my $l (@lines) {

			print $f "\n" . $l;
		}

		close($f);
	}
	else {
		die "unable to crate 'Change log' file for pcbid: $jobId";
	}

}

sub Delete {
	my $self   = shift;
	my $jobId  = shift;
	
	my $chngeLog = JobHelper->GetJobArchive($jobId) . "Change_log.txt";
	
	if( -e $chngeLog){
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

