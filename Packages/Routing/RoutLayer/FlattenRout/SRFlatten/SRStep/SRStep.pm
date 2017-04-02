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
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
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

	CamHelper->SetStep( $inCAM, $self->GetStep() );

	# init steps

	my @repeatsSR = CamStepRepeat->GetRepeatStep( $inCAM, $jobId, $self->{"step"} );

	# No nested step can have SR

	#	my @wrongSRsteps = grep { CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $_->{"stepName"} )   } @uniqueSR;
	#
	#	if(scalar(@wrongSRsteps)){
	#		die "Nested steps has not contain step and repeat\n";
	#	}

	foreach my $rStep (@repeatsSR) {

		my $alreadyInit =  scalar(grep { $_->GetStepName() eq $rStep->{"stepName"} && $_->GetAngle() eq $rStep->{"angle"} } $self->GetNestedSteps());
 
 		unless($alreadyInit){
 			my $nestedStep = SRNestedStep->new( $rStep->{"stepName"}, $rStep->{"angle"} );
			$self->__InitNestedStep($nestedStep);

			push( @{ $self->{"nestedSteps"} }, $nestedStep );
 		}
 
		 
	}
}

sub __InitNestedStep {
	my $self       = shift;
	my $nestedStep = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Prepare rout work layer

	$inCAM->COM(
		'copy_layer',
		"source_job"   => $jobId,
		"source_step"  => $nestedStep->GetStepName(),
		"source_layer" => $self->{"sourceLayer"},
		"dest"         => 'layer_name',
		"dest_layer"   => $nestedStep->GetRoutLayer(),
		"mode"         => 'replace',
		"invert"       => 'no'

	);

	# move to zero

	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $nestedStep->GetStepName(), 1 );

	if ( $lim{"xMin"} < 0 || $lim{"yMin"} < 0 ) {

		CamLayer->WorkLayer( $inCAM, $nestedStep->GetRoutLayer() );
		$inCAM->COM(
					 "sel_transform",
					 "oper"      => "",
					 "x_anchor"  => "0",
					 "y_anchor"  => "0",
					 "angle"     => "0",
					 "direction" => "ccw",
					 "x_scale"   => "1",
					 "y_scale"   => "1",
					 "x_offset"  => -$lim{"xMin"},
					 "y_offset"  => -$lim{"yMin"},
					 "mode"      => "anchor",
					 "duplicate" => "no"
		);
	}

	if ( $nestedStep->GetAngle() > 0 ) {

		CamLayer->WorkLayer( $inCAM, $nestedStep->GetRoutLayer() );
		$inCAM->COM(
					 "sel_transform",
					 "direction" => "ccw",
					 "x_anchor"  => 0,
					 "y_anchor"  => 0,
					 "oper"      => "rotate",
					 "angle"     => $nestedStep->GetAngle()
		);
	}

	# Load uniRTM
	my $uniRTM = UniRTM->new( $inCAM, $jobId, $self->GetStep(), $nestedStep->GetRoutLayer() );
	$nestedStep->SetUniRTM($uniRTM);

}

sub Clean {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @routLayers = map { $_->GetRoutLayer() } @{ $self->{"nestedSteps"} };

	foreach my $l (@routLayers) {

		if ( CamHelper->LayerExists( $inCAM, $jobId, $l ) ) {

			$inCAM->COM( 'delete_layer', "layer" => $l );
		}
	}

}

sub GetNestedStep {
	my $self     = shift;
	my $stepName = shift;
	my $rotation = shift;

	my $step = ( grep { $_->GetStepName() eq $stepName && $_->GetAngle() == $rotation } @{ $self->{"nestedSteps"} } )[0];

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

sub ReloadStepUniRTM {
	my $self       = shift;
	my $nestedStep = shift;
	my $inCAM      = $self->{"inCAM"};
	my $jobId      = $self->{"jobId"};

	my $u = UniRTM->new( $inCAM, $jobId, $self->GetStep(), $nestedStep->GetRoutLayer() );
	$nestedStep->SetUniRTM($u);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

