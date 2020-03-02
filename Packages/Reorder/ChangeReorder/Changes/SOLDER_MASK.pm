#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ChangeReorder::Changes::SOLDER_MASK;
use base('Packages::Reorder::ChangeReorder::Changes::ChangeBase');

use Class::Interface;
&implements('Packages::Reorder::ChangeReorder::Changes::IChange');

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Reorder::Enums';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::CAMJob::SolderMask::UnMaskNC';
use aliased 'CamHelpers::CamStepRepeatPnl';

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
sub Run {
	my $self = shift;
	my $mess = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $reorderType = $self->{"reorderType"};

	my $result = 1;

	my @layers = CamJob->GetBoardLayers( $inCAM, $jobId );

	foreach my $l (@layers) {

		if ( $l->{"gROWname"} =~ /m[cs]/ && $l->{"gROWpolarity"} eq "negative" ) {

			CamLayer->SetLayerPolarityLayer( $inCAM, $jobId, $l->{"gROWname"}, "positive" );
		}
	}

	# 1) unmask all through holes
	my @steps = ();
	if ( CamHelper->StepExists( $inCAM, $jobId, "panel" ) ) {

		@steps = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueDeepestSR( $inCAM, $jobId );
	}
	else {

		@steps = ("o+1");
	}

	foreach my $s (@steps) {

		my $unMaskedCntRef   = 0;
		my $unMaskAttrValRef = "";

		my $resize          = undef;    # default - copy drill smaller about 50µm to solder mask
		my $minDistHole2Pad = undef;    # default - 500µm minimal distance of through hole to pad

		unless ( UnMaskNC->UnMaskThroughHoleNearBGA( $inCAM, $jobId, $s, $resize, $minDistHole2Pad ) ) {
			$result = 0;
		}

		return $result;
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::ChangeReorder::Changes::MASK_POLAR' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d273354";

	my $check = Change->new( "key", $inCAM, $jobId );

	my $mess = "";
	print "Change result: " . $check->Run( \$mess );
}

1;

