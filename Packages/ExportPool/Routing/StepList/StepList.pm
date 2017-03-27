#-------------------------------------------------------------------------------------------#
# Description: Contain listo of all tools in layer, regardless it is tool from surface, pad,
# lines..
# Responsible for tools are unique (diameter + typeProc)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ExportPool::Routing::StepList::StepList;

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
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::ExportPool::Routing::StepList::Step';
use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';




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
	$self->{"targetStep"} = shift;
	$self->{"layer"}      = shift;
	#$self->{"workStep"}   = "work_" . $self->{"targetStep"};

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
#	unless ( CamHelper->StepExists( $inCAM, $jobId, $self->{"workStep"} ) ) {
#
#		$inCAM->COM(
#					 "create_entity",
#					 "job"     => $jobId,
#					 "name"    => $self->{"workStep"},
#					 "db"      => "",
#					 "is_fw"   => "no",
#					 "type"    => "step",
#					 "fw_type" => "form"
#		);
#	}
#	
	CamHelper->SetStep($inCAM, $self->{"targetStep"});

	# init steps

	my @repeatsSR = CamStepRepeat->GetRepeatStep( $inCAM, $jobId, $self->{"targetStep"} );
	my @uniqueSR = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $self->{"targetStep"} );

	foreach my $uStep (@uniqueSR) {

		my @rep = grep { $_->{"stepName"} eq $uStep->{"stepName"} } @repeatsSR;

		my $step = Step->new( $uStep->{"stepName"} , $self->{"layer"} );

		$step->Init( $inCAM, $jobId, \@rep, $self->{"targetStep"} );

		push( @{ $self->{"steps"} }, $step );
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

sub GetSteps{
	my $self = shift;
	
	return @{$self->{"steps"}};	
}

sub GetStep{
	my $self = shift;
	
	return  $self->{"targetStep"};	
}
 
 
sub GetAllStepPlaces{
	my $self = shift;
	
	my @all =  map { $_->GetStepPlaces() } (map{ $_->GetStepRotations() } $self->GetSteps());  
	
	return @all;	
} 
 
sub GetLayer{
	my $self = shift;
	
	return  $self->{"layer"};	
}
 
 
sub ReloadStepRotation {
	my $self = shift;
	my $stepRot = shift;
	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
 
	my $u = UniRTM->new( $inCAM, $jobId, $self->{"targetStep"}, $stepRot->GetRoutLayer() );
	$stepRot->SetUniRTM($u)
} 
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

