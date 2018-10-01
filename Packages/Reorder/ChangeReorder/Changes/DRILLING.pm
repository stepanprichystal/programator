#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for edit drilling layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ChangeReorder::Changes::DRILLING;
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
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamAttributes';
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

sub Run {
	my $self = shift;
	my $mess = shift;

	my $inCAM  = $self->{"inCAM"};
	my $jobId  = $self->{"jobId"};
	my $isPool = HegMethods->GetPcbIsPool($jobId);

	my $result = 1;

	# Add pilot holes if doesnt exist to layer f

	return $result if ($isPool);

	my @steps = map { $_->{"stepName"} } CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, 'panel' );

	my @layers = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_nMill, EnumsGeneral->LAYERTYPE_nplt_nDrill ] );

	foreach my $step (@steps) {

		foreach my $l (@layers) {

			# if there are type pressfit with tolerance, change type to non_plated and standard
	 		my @tools = CamDTM->GetDTMTools( $inCAM, $jobId, $step, $l->{"gROWname"} );
			my $change = 0;
			foreach my $t ( @tools ) {

				if ( $t->{"gTOOLtype2"} eq "press_fit" && ( $t->{"gTOOLmin_tol"} != 0 || $t->{"gTOOLmax_tol"} != 0 ) ) {

					$t->{"gTOOLtype2"} = "standard";
					$t->{"gTOOLtype"}  = "non_plated";
					$change = 1;
				}
			}
			
			if($change){
				
				CamDTM->SetDTMTools( $inCAM, $jobId, $step, $l->{"gROWname"}, \@tools );
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

	use aliased 'Packages::Reorder::ChangeReorder::Changes::DRILLING' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d152457";

	my $check = Change->new( "key", $inCAM, $jobId );

	my $mess = "";
	print "Change result: " . $check->Run( \$mess );
}

1;

