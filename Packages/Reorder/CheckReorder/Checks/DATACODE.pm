#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::DATACODE;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::CAMJob::Marking::MarkingDataCode';
use aliased 'Packages::Reorder::Enums';

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
sub Run {
	my $self = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $reorderType = $self->{"reorderType"};

	# check if datacode id
	my $datacodeL = HegMethods->GetDatacodeLayer($jobId);

	if ( defined $datacodeL && $datacodeL ne "" ) {

		my $step = CamHelper->StepExists( $inCAM, $jobId, "panel" ) ? "panel" : "o+1";

		$datacodeL = lc($datacodeL);
		unless ( MarkingDataCode->DatacodeExists( $inCAM, $jobId, $step, $datacodeL ) ) {

			$self->_AddChange("V Heliosu je datakód (vrstva: $datacodeL), ale v jobu nebyl dohledán dynamický datakód.");
		}
	}
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

