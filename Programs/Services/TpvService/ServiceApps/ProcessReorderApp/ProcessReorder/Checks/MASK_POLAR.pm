#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::ProcessReorderApp::Reorder::Checks::MASK_POLAR;
use base('Programs::Services::TpvService::ServiceApps::ProcessReorderApp::Reorder::Checks::CheckBase');

use Class::Interface;
&implements('Programs::Services::TpvService::ServiceApps::ProcessReorderApp::Reorder::Checks::ICheck');

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';


#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# Check if mask is not negative in matrix
sub NeedChange {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $jobExist = shift; # (in InCAM db)
	my $isPool = shift;
	
	unless($jobExist){
		return 1;
	}

	my $needChange = 0;
 
	my @layers = CamJob->GetBoardLayers($inCAM, $jobId);
	
	foreach my $l (@layers){
		
		if($l->{"gROWname"} =~ /m[cs]/ && $l->{"gROWpolarity"} eq "negative"){
			
			$needChange = 1;
			last;
		}
	}

	return $needChange;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 	use aliased 'Programs::Services::TpvService::ServiceApps::ProcessReorderApp::Reorder::Checks::MASK_POLAR' => "Change";
 	use aliased 'Packages::InCAM::InCAM';
	
	my $inCAM    = InCAM->new();
	my $jobId = "f52457";
	
	my $check = Change->new();
	
	print "Need change: ".$check->NeedChange($inCAM, $jobId, 1);
}

1;

