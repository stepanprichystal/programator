#-------------------------------------------------------------------------------------------#
# Description: Contain listo of all tools in layer, regardless it is tool from surface, pad,
# lines..
# Responsible for tools are unique (diameter + typeProc)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::FlattenRout::SRFlatten::SRFlatten::SRStepPos;

#3th party library
use strict;
use warnings;

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
use aliased 'Helpers::GeneralHelper';
#use aliased 'CamHelpers::CamStepRepeat';

#use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamHelper';
#use aliased 'Packages::CAM::UniDTM::PilotDef::PilotDef';

#use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';
#use aliased 'Packages::Routing::RoutLayer::FlattenRout::StepList::StepPlace';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
#use aliased 'Packages::Routing::RoutLayer::FlattenRout::RoutStart::RoutStart';


#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"SRStep"} = shift;
	$self->{"posX"} = shift;
	$self->{"posY"} = shift;
	
	$self->{"id"}  = GeneralHelper->GetGUID();
 
	return $self;
}

 sub GetStepId {
	my $self = shift;
	
	return $self->{"id"};
}

sub GetPosX {
	my $self = shift;
	
	return $self->{"posX"};
}

sub GetPosY {
	my $self = shift;
	
	return $self->{"posY"};
}


# =======================================
# SRStep methods 
# =======================================

sub GetAngle {
	my $self = shift;

	return $self->{"SRStep"}->GetAngle();
}

sub GetRoutLayer {
	my $self = shift;

	return $self->{"SRStep"}->GetRoutLayer();
}

sub GetUniRTM {
	my $self = shift;

	return $self->{"SRStep"}->GetUniRTM();
}


sub GetStepName {
	my $self = shift;

	return $self->{"SRStep"}->GetStepName();
}
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

