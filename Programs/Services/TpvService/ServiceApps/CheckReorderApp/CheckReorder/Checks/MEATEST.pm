#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::Checks::MEATEST;
use base('Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::Checks::ICheck');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

sub NeedChange {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $jobExist = shift; # (in InCAM db)
	my $isPool = shift;

	my $needChange = 0;

	my $custInfo = HegMethods->GetCustomerInfo($jobId);

	# Kadlec customer
	if (    $custInfo->{"reference_subjektu"} eq "05052"  )
	{

		$needChange = 1;

	}

	return $needChange;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

# 	use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::Checks::PICKERING_ORDER_NUM' => "Change";
# 	use aliased 'Packages::InCAM::InCAM';
#	
#	my $inCAM    = InCAM->new();
#	my $jobId = "f52457";
#	
#	my $check = Change->new();
#	
#	print "Need change: ".$check->NeedChange($inCAM, $jobId, 1);
}

1;

