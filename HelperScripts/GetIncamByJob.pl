#!/usr/bin/perl -w


use Win32::Process;
use Wx;
use Config;
use Win32::GuiTest qw(FindWindowLike GetWindowText);


#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

my $jobId = "f49968";



my @jobId = GetWindowTitle($jobId); 

print @jobId;

foreach my $pid (@jobId){
	
	Win32::Process::KillProcess( $pid, 0 );
}

 
 

 # Return InCAM editor PIDS, based on jobId in windows title
sub GetWindowTitle {
	#my $self = shift;
	my $jobId  = shift;
	
	my @pids = ();

	my @windows = FindWindowLike( 0, $jobId );
	for (@windows) {

		my $title = GetWindowText($_);
		my ($pid) = $title =~ /PID: \s*(\d*)/;

		 push(@pids, $pid);

	}
	
	return @pids;
}
