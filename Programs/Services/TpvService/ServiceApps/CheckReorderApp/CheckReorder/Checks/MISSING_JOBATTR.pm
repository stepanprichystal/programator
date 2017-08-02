#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::Checks::MISSING_JOBATTR;
use base('Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::Checks::ICheck');

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamAttributes';


#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# Check if requested job attributes exist
sub NeedChange {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $jobExist = shift; # (in InCAM db)
	my $isPool = shift;
	my $detail   = shift;    # reference on detail message (manual task)
	my $data     = shift;    # reference on data for process automatic task
	
	unless($jobExist){
		return 1;
	}

	my $needChange = 0;
	
	my @attr = ();
	
	my $userName = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "user_name" );    # zakaznicky panel
	
	if(!defined $userName || $userName eq "" || $userName =~ /none/i){
		push(@attr, "user_name");
		$needChange = 1;
	}
	
	my $pcbClass = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "pcb_class" );    # zakaznicky panel
	
	if(!defined $pcbClass || $pcbClass eq ""  || $pcbClass < 3 ){
		push(@attr, "pcb_class");
		$needChange = 1;
	} 

	$data->{"attributes"} = \@attr;

	return $needChange;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 	use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::Checks::MASK_POLAR' => "Change";
 	use aliased 'Packages::InCAM::InCAM';
	
	my $inCAM    = InCAM->new();
	my $jobId = "f52457";
	
	my $check = Change->new();
	
	print "Need change: ".$check->NeedChange($inCAM, $jobId, 1);
}

1;

