#-------------------------------------------------------------------------------------------#
# Description: Contain listo of all tools in layer, regardless it is tool from surface, pad,
# lines..
# Responsible for tools are unique (diameter + typeProc)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::FlattenRout::SRFlatten::SRFlatten::SRFlatten;

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
use aliased 'Packages::Routing::RoutLayer::FlattenRout::SRFlatten::SRFlatten::SRStepPos';

#use aliased 'Packages::CAM::UniDTM::PilotDef::PilotDef';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}     = shift;
	$self->{"jobId"}     = shift;
	$self->{"SRStep"}    = shift;
	$self->{"flatLayer"} = shift;

	my @stepPos = ();
	$self->{"stepPos"} = \@stepPos;

	return $self;
}

sub Init {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	CamHelper->SetStep( $inCAM, $self->{"SRStep"}->GetStep() );

	# init steps
	my @repeatsSR = CamStepRepeat->GetRepeatStep( $inCAM, $jobId, $self->{"SRStep"}->GetStep() );
	foreach my $rStep (@repeatsSR) {
		
		my $nestStep = $self->{"SRStep"}->GetNestedStep($rStep->{"stepName"}, $rStep->{"angle"});

		my $srStepPos = SRStepPos->new( $nestStep, $rStep->{"originX"}, $rStep->{"originY"} );
		push( @{ $self->{"stepPos"} }, $srStepPos );

	}
}



sub GetStepPositions {
	my $self = shift;

	return @{$self->{"stepPos"}};
}

 

sub GetStep {
	my $self = shift;

	return $self->{"SRStep"}->GetStep();
}

sub GetSourceLayer {
	my $self = shift;

	return $self->{"SRStep"}->GetSourceLayer();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

