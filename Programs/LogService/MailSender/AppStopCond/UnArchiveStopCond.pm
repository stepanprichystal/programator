#-------------------------------------------------------------------------------------------#
# Description: Class for unarchive jobs script

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::LogService::MailSender::AppStopCond::UnArchiveStopCond;


use Class::Interface;
&implements('Programs::LogService::MailSender::AppStopCond::IStopCond');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsPaths';
 

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
	my $self = shift;
	my $pcbId = shift;
	
	my $result = 1;
	
	my $path = EnumsPaths->InCAM_jobsdb1.$pcbId;
	
	unless(-e $path){
		$result = 0;
	} 
	
	return $result;
 
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::LogService::MailSender::MailSender';

	#	use aliased 'Packages::InCAM::InCAM';
	#

	my $sender = MailSender->new();

	print "ee";
}

1;

