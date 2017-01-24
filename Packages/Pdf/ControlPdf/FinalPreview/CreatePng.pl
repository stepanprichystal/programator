
#-------------------------------------------------------------------------------------------#
# Description: Script convert pdf to png. Each conversion run in
# own thread. Conversion is done by imageMagick program launched by system()
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use threads;
use strict;
use warnings;

#-------------------------------------------------------------------------------------------#
#  Script code
#-------------------------------------------------------------------------------------------#

my $output = shift(@_);    # save here output message
my $cmds   = shift(@_);    # contain commands, which convert pdfs to images by imageMagick

Worker($cmds);

sub Worker {

	my $cmds = shift;

	my @threadsObj = ();

	unless ($cmds) {
		die "Parameter cmd is not defined.\n";
	}

	foreach my $cmd ( @{$cmds} ) {

		my $thr1 = threads->create( sub { __ConvertToPng($cmd) } );

		push( @threadsObj, $thr1 );
	}

	foreach (@threadsObj) {

		$_->join();
	}

}

sub __ConvertToPng {

	my $cmd = shift;

	my $systeMres = system($cmd);

}

1;
