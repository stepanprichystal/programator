
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
use threads;
use strict;
use warnings;

#-------------------------------------------------------------------------------------------#
#  Script code
#-------------------------------------------------------------------------------------------#

my $output = shift(@_);    # save here output message (hash reference)
my $cmds   = shift(@_);    # all parameters, which are passed to construcotr of SystemCall class (array reference)

DoTask($cmds);

sub DoTask {

	my $cmds = shift;
	
	$output->{"myResult"} = "abc";

	# do some staff..

}
 
 

1;
