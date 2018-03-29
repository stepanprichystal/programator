#-------------------------------------------------------------------------------------------#
# Description:  Class fotr testing application

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::LogService::MailSender::AppStopCond::ElTestStopCond;

use Class::Interface;
&implements('Programs::Services::LogService::MailSender::AppStopCond::IStopCond');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAMJob::ElTest::CheckElTest';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	return $self;
}

sub ProcessLog {
	my $self  = shift;
	my $jobId = shift;

	if ( CheckElTest->ElTestRequested($jobId) ) {

		unless ( CheckElTest->ElTestExists($jobId) ) {

			return 1;
		}
	}
	
	return 0;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	print "ee";
}

1;

