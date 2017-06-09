#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::ProcessReorderApp::Reorder::Checks::POOL_PATTERN;
use base('Programs::Services::TpvService::ServiceApps::ProcessReorderApp::Reorder::Checks::CheckBase');

use Class::Interface;
&implements('Programs::Services::TpvService::ServiceApps::ProcessReorderApp::Reorder::Checks::ICheck');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Routing::PlatedRoutArea';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);
	
	
	return $self;
}

# if pcb is pool, check if plated rout areaa is exceed for tenting
sub NeedChange {
	my $self = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $jobExist = shift; # (in InCAM db)
	my $isPool = shift;
	
	unless($jobExist){
		return 1;
	}
	
	my $needChange = 0;
	
 
 
	if($isPool && PlatedRoutArea->PlatedAreaExceed($inCAM, $jobId, "o+1")){
		
		$needChange = 1;
	}
	
	return $needChange;
 
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
 	use aliased 'Programs::Services::TpvService::ServiceApps::ProcessReorderApp::Reorder::Checks::POOL_PATTERN' => "Change";
 	use aliased 'Packages::InCAM::InCAM';
	
	my $inCAM    = InCAM->new();
	my $jobId = "f52456";
	
	my $check = Change->new();
	
	print "Need change: ".$check->NeedChange($inCAM, $jobId, 1);
}

1;

