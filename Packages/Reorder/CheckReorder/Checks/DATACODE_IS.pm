#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::DATACODE_IS;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::CAMJob::Marking::Marking';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# check if datacode is in helios
sub NeedChange {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $jobExist = shift;    # (in InCAM db)
	my $isPool   = shift;
	my $detail   = shift;    # reference on detail message when change is needed
	

	my $needChange = 0;

	# check if datacode id
	my $datacodeL = HegMethods->GetDatacodeLayer($jobId);

	if ( defined $datacodeL && $datacodeL ne "" ) {

		if ($jobExist) {

			my $step = $isPool ? "o+1" : "panel";

			$datacodeL = lc($datacodeL);
			unless ( Marking->DatacodeExists( $inCAM, $jobId, $step, $datacodeL ) ) {
				$needChange = 1;
			}
		}
		else {

			$needChange = 1;
		}
	}

	return $needChange;
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::CheckReorder::Checks::DATACODE_IS' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52456";

	my $check = Change->new();

	print "Need change: " . $check->NeedChange( $inCAM, $jobId, 1 );

}

1;

