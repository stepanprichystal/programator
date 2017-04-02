#-------------------------------------------------------------------------------------------#
# Description: Contain listo of all tools in layer, regardless it is tool from surface, pad,
# lines..
# Responsible for tools are unique (diameter + typeProc)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::FlattenRout::SRFlatten::SRStep::SRNestedStep;

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

use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';
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

	$self->{"stepName"} = shift;
	$self->{"angle"} = shift;
	$self->{"routLayer"} = GeneralHelper->GetGUID();

	$self->{"uniRTM"}   = undef;
	$self->{"userFoot"} = undef;
 
	return $self;
}


## If layer contain SR steps, flatten and sort tools
#sub __InitSortSRTool {
#	my $self  = shift;
#	my $inCAM = shift;
#	my $jobId = shift;
#
#	my $resMngr = ItemResultMngr->new();
#
#	my $stepList = StepList->new( $inCAM, $jobId, $self->{"stepName"}, $self->{"layer"}, 1 );
#	$stepList->Init();
#	my $toolOrder = ToolsOrder->new( $inCAM, $jobId, $stepList, $self->{"routLayer"} );
#	my $routStart = RoutStart->new( $inCAM, $jobId, $stepList, $self->{"routLayer"} );
#
#	my %convTable = ();
#
#	$resMngr->AddItem( $routStart->CreteFlatLayer( \%convTable ) );
#
#	my $toolOrderStart = 1;
#
#	$resMngr->AddItem( $toolOrder->SetInnerOrder( \%convTable, \$toolOrderStart ) );
#
#	$resMngr->AddItem( $toolOrder->SetOutlineOrder( \%convTable, \$toolOrderStart ) );
#
#	$resMngr->AddItem( $toolOrder->ToolRenumberCheck() );
#
#	unless ( $resMngr->Succes() ) {
#		die $resMngr->GetErrorStr() . $resMngr->GetWarningStr();
#	}
#
#}

sub SetUniRTM {
	my $self = shift;
	my $type = shift;

	$self->{"uniRTM"} = $type;
}

sub GetUniRTM {
	my $self = shift;

	return $self->{"uniRTM"};
}

sub GetRoutLayer {
	my $self = shift;

	return $self->{"routLayer"};
}

sub GetAngle {
	my $self = shift;

	return $self->{"angle"};
}

 
sub GetStepName {
	my $self = shift;

	return $self->{"stepName"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

