#-------------------------------------------------------------------------------------------#
# Description: Contain listo of all tools in layer, regardless it is tool from surface, pad,
# lines..
# Responsible for tools are unique (diameter + typeProc)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniRTM::UniRTM::UniChain;

#3th party library
use strict;
use warnings;
use XML::Simple;

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

#use aliased 'Packages::CAM::UniDTM::PilotDef::PilotDef';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}      = shift;
	$self->{"jobId"}      = shift;
	$self->{"parentStep"} = shift;
	$self->{"layer"}      = shift;
	$self->{"workStep"}   = "work_" . $self->{"parentStep"};

	my @steps = ();
	$self->{"steps"} = \@steps;    # features, wchich chain is created from

	return $self;
}

sub Init {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# create work step
	#delete if step already exist
	unless ( CamHelper->StepExists( $inCAM, $jobId, $self->{"workStep"} ) ) {

		$inCAM->COM(
					 "create_entity",
					 "job"     => $jobId,
					 "name"    => $self->{"workStep"},
					 "db"      => "",
					 "is_fw"   => "no",
					 "type"    => "step",
					 "fw_type" => "form"
		);
	}
	
	CamHelper->SetStep($inCAM, $self->{"workStep"});

	# init steps

	my @repeatsSR = CamAttributes->GetRepeatStep( $inCAM, $jobId, $self->{"parentStep"} );
	my @uniqueSR = CamAttributes->GetUniqueStepAndRepeat( $inCAM, $jobId, $self->{"parentStep"} );

	foreach my $uStep (@uniqueSR) {

		my @rep = grep { $_->{"stepName"} eq $uStep->{"stepName"} } @repeatsSR;

		my $step = Step->new( $inCAM, $jobId, $uStep->{"stepName"},$self->{"workStep"} , $self->{"layer"} );

		$step->Init(\@rep );

		push( @{ $self->{"steps"} }, $step );
	}
}

sub Clean {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	if ( CamHelper->StepExists( $inCAM, $jobId, $self->{"workStep"} ) ) {

		$inCAM->COM( "delete_entity", "job" => $jobId, "name" => $self->{"workStep"}, "type" => "step" );
	}

	my @routLayers = map {
		map { $_->GetGetRoutLayer() }
		  $_->GetStepRotations()
	} @{ $self->{"steps"} };

	foreach my $l (@routLayers) {

		if ( CamHelper->LayerExists( $inCAM, $jobId, $l ) ) {

			$inCAM->COM( 'delete_layer', "layer" => $l );
		}
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

