#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for edit routing layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ChangeReorder::Changes::ROUTING;
use base('Packages::Reorder::ChangeReorder::Changes::ChangeBase');

use Class::Interface;
&implements('Packages::Reorder::ChangeReorder::Changes::IChange');

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Packages::Routing::PilotHole';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Enums::EnumsGeneral';
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

# Delete and add new schema
sub Run {
	my $self = shift;
	my $mess = shift;

	my $inCAM  = $self->{"inCAM"};
	my $jobId  = $self->{"jobId"};
	my $isPool = HegMethods->GetPcbIsPool($jobId);

	my $result = 1;

	# Add pilot holes if doesnt exist to layer f

	my @steps = "o+1";

	unless ($isPool) {

		@steps = map { $_->{"stepName"} } CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, 'panel' );
	}

	my @layers = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_nplt_nMill );

	foreach my $step (@steps) {

		foreach my $l (@layers) {

			# check if step contain pilot holes
			my %attHist = CamHistogram->GetAttHistogram( $inCAM, $jobId, $step, $l->{"gROWname"} );
			unless ( exists $attHist{".pilot_hole"} ) {

				PilotHole->AddPilotHole( $inCAM, $jobId, $step, $l->{"gROWname"} );
			}
		}
	}

	return $result;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::ChangeReorder::Changes::ROUTING' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d152456";

	my $check = Change->new( "key", $inCAM, $jobId );

	my $mess = "";
	print "Change result: " . $check->Run( \$mess );
}

1;

