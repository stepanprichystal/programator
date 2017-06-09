
#-------------------------------------------------------------------------------------------#
# Description: Example
# Author:SPR
#-------------------------------------------------------------------------------------------#

#  ============  HOW to use system call ====================

#	my $script = "../Packages/SystemCall/Exmaple.pl";
#	my %hash   = ( "k" => "1" );
#	my @cmds   = ( "par1", "par2", \%hash );
#
#	my $call = SystemCall->new( $script, \@cmds );
#	my $result = $call->Run();
#
#	my $result = $call->GetOutput();

#3th party library

use strict;
use warnings;
use Win32::Process;

#-------------------------------------------------------------------------------------------#
#  Script code
#-------------------------------------------------------------------------------------------#

my $output = shift(@_);    # save here output message (hash reference)
my $cmds   = shift(@_);    # all parameters, which are passed to construcotr of SystemCall class (array reference)

DoTask();

sub DoTask {
	my $inCAMPath  = $cmds->[0];
	my $parameters  =  $cmds->[1];
	
	print STDERR "incampath is: $inCAMPath";
	print STDERR "parameters is: $parameters";

	my $processObj;

	Win32::Process::Create( $processObj, $inCAMPath, $parameters, 1, THREAD_PRIORITY_NORMAL | CREATE_NEW_CONSOLE, "c:/tmp" )
	  || die "$!\n";

	my $pidInCAM = $processObj->GetProcessID();
	$output->{"pidInCAM"} = $pidInCAM;

	# do some staff..

}

1;
