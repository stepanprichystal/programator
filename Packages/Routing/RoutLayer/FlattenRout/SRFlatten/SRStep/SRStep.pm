#-------------------------------------------------------------------------------------------#
# Description: Contain listo of all tools in layer, regardless it is tool from surface, pad,
# lines..
# Responsible for tools are unique (diameter + typeProc)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::FlattenRout::SRFlatten::SRStep::SRStep;

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Packages::CAM::UniRTM::Enums';

#use aliased 'CamHelpers::CamDTM';
#use aliased 'CamHelpers::CamDTMSurf';
#use aliased 'CamHelpers::CamDrilling';
#use aliased 'Packages::CAM::UniDTM::UniTool::UniToolBase';
#use aliased 'Packages::CAM::UniDTM::UniTool::UniToolDTM';
#use aliased 'Packages::CAM::UniDTM::UniTool::UniToolDTMSURF';
#use aliased 'Packages::CAM::UniDTM::Enums';
#use aliased 'Enums::EnumsDrill';
#use aliased 'Enums::EnumsGeneral';
#use aliased 'Packages::CAM::UniDTM::UniDTM::UniDTMCheck';
#use aliased 'Connectors::HeliosConnector::HegMethods';
#use aliased 'Helpers::GeneralHelper';
#use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::Routing::RoutLayer::FlattenRout::SRFlatten::SRStep::SRNestedStep';
use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';

#use aliased 'Packages::CAM::UniDTM::PilotDef::PilotDef';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}       = shift;
	$self->{"jobId"}       = shift;
	$self->{"step"}        = shift;
	$self->{"sourceLayer"} = shift;

	my @nestedSteps = ();
	$self->{"nestedSteps"} = \@nestedSteps;

	return $self;
}

sub Init {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	CamHelper->SetStep( $inCAM, $self->{"step"} );

	# init steps

	my @repeatsSR = CamStepRepeat->GetRepeatStep( $inCAM, $jobId, $self->{"step"} );
	 
	# No nested step can have SR

	#	my @wrongSRsteps = grep { CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $_->{"stepName"} )   } @uniqueSR;
	#
	#	if(scalar(@wrongSRsteps)){
	#		die "Nested steps has not contain step and repeat\n";
	#	}

	foreach my $rStep (@repeatsSR) {

		my @repeatsSR = grep { $_->{"stepName"} eq $rStep->{"stepName"} } @repeatsSR;
		my @rotations = map  { $_->{"angle"} } @repeatsSR;
		@rotations = uniq(@rotations);

		# For each rotation create nested step
		foreach my $rot (@rotations) {

			my $nestedStep = SRNestedStep->new( $rStep->{"stepName"}, $rot );
			$nestedStep->Init($inCAM, $jobId, $self->{"sourceLayer"});
 
			push( @{ $self->{"nestedSteps"} }, $nestedStep );
		}
	}
}

sub Clean {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	#	if ( CamHelper->StepExists( $inCAM, $jobId, $self->{"workStep"} ) ) {
	#
	#		$inCAM->COM( "delete_entity", "job" => $jobId, "name" => $self->{"workStep"}, "type" => "step" );
	#	}

	my @routLayers = map {
		map { $_->GetRoutLayer() }
		  $_->GetStepRotations()
	} @{ $self->{"steps"} };

	foreach my $l (@routLayers) {

		if ( CamHelper->LayerExists( $inCAM, $jobId, $l ) ) {

			$inCAM->COM( 'delete_layer', "layer" => $l );
		}
	}

}

sub GetNestedStep {
	my $self = shift;
	my $stepName = shift;
	my $rotation = shift;

	my $step = (grep { $_->GetStepName() eq $stepName &&  $_->GetAngle() == $rotation } @{ $self->{"nestedSteps"} })[0];
	
	return $step;
}

sub GetNestedSteps {
	my $self = shift;

	return @{ $self->{"nestedSteps"} };
}

sub GetStep {
	my $self = shift;

	return $self->{"step"};
}

 

sub GetSourceLayer {
	my $self = shift;

	return $self->{"sourceLayer"};
}

sub ReloadNestedStep {
	my $self    = shift;
	my $nestedStep = shift;
	my $inCAM   = $self->{"inCAM"};
	my $jobId   = $self->{"jobId"};

	my $u = UniRTM->new( $inCAM, $jobId, $self->{"targetStep"}, $nestedStep->GetRoutLayer() );
	$nestedStep->SetUniRTM($u);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

