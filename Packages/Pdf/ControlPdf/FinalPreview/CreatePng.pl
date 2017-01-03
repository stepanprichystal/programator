
#-------------------------------------------------------------------------------------------#
# Description: Class provide function for loading / saving tif file
# TIF - technical info file - contain onformation important for produce, for technical list,
# another support script use this file
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use threads;
use strict;
use warnings;



 
#-------------------------------------------------------------------------------------------#
#  Script code
#-------------------------------------------------------------------------------------------#

 
#my @paramFiles = ();
#while ( my $p = shift ) {
#	push( @paramFiles, $p );
#}
# 
#my $systemCall = SystemCallScript->new(&Worker, );
#


#my @parsed = $systemCall->ParseParams(\@paramFiles);


my $output = shift(@_);; # save here output message
my $cmds = shift(@_);

#print "\n param: $cmds\n";

#foreach (@{$cmds}){
	#print STDERR "\n Param: ".$_."\n";
#}
 

Worker($cmds);

sub Worker {

	my $cmds = shift;

	my @threadsObj = ();

	unless ($cmds) {
		die "Parameter cmd is not defined.\n";
	}

	foreach my $allCmd ( @{$cmds} ) {

		my $thr1 = threads->create( sub { __ConvertToPng($allCmd) } );

		push( @threadsObj, $thr1 );
	}

	foreach (@threadsObj) {

		$_->join();
	}

}

sub __ConvertToPng {

	my @cmds = @{ shift(@_) };

	foreach my $cmd (@cmds) {

		my $systeMres = system($cmd);

	}

}

1;
