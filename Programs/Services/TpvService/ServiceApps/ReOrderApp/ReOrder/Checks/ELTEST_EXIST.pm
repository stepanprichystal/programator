#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::ReOrderApp::ReOrder::Checks::ELTEST_EXIST;
use base('Programs::Services::TpvService::ServiceApps::ReOrderApp::ReOrder::Checks::CheckBase');

use Class::Interface;
&implements('Programs::Services::TpvService::ServiceApps::ReOrderApp::ReOrder::Checks::ICheck');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::JobHelper';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# if electric test directory doesn't contain dir at least fo one machine
sub NeedChange {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $jobExist = shift; # (in InCAM db)
	my $isPool = shift;

	my $needChange = 0;

	if($isPool){
		return 0;
	}

	my $path = JobHelper->GetJobElTest($jobId);
 
	if ( -e $path ) {

		my @dirs = ();
		
		if ( opendir( DIR, $path ) ) {
			@dirs = readdir(DIR);
			closedir(DIR);
		}

		if ( scalar( grep { $_ =~ /^A[357]_/i } @dirs ) < 1 ) {

			$needChange = 1;
		}

	}
	else {
		$needChange = 1;
	}
	
	return $needChange;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 	use aliased 'Programs::Services::TpvService::ServiceApps::ReOrderApp::ReOrder::Checks::ELTEST_EXIST' => "Change";
 	use aliased 'Packages::InCAM::InCAM';
	
	my $inCAM    = InCAM->new();
	my $jobId = "d10355";
	
	my $check = Change->new();
	
	print "Need change: ".$check->NeedChange($inCAM, $jobId, 1);
}

1;

