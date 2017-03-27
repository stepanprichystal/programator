#-------------------------------------------------------------------------------------------#
# Description: Contain listo of all tools in layer, regardless it is tool from surface, pad,
# lines..
# Responsible for tools are unique (diameter + typeProc)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ExportPool::Routing::StepList::StepRotation;

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

#use aliased 'Helpers::FileHelper';
#use aliased 'CamHelpers::CamHelper';
#use aliased 'Packages::CAM::UniDTM::PilotDef::PilotDef';

use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';
use aliased 'Packages::ExportPool::Routing::StepList::StepPlace';
use aliased 'CamHelpers::CamLayer';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"stepName"} = shift;

	#$self->{"workStep"} = shift;
	$self->{"layer"} = shift;
	$self->{"angle"} = shift;

	$self->{"uniRTM"}   = undef;
	$self->{"userFoot"} = undef;
	$self->{"footFind"} = undef;

	$self->{"routLayer"} = undef;

	my @steps = ();
	$self->{"stepPlaces"} = \@steps;

	return $self;
}

sub Init {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $targetStep = shift;
	my @placement  = @{ shift(@_) };

	# Prepare rout work layer
	$self->{"routLayer"} = GeneralHelper->GetGUID();

	$inCAM->COM(
				 'copy_layer',
				 "source_job"   => $jobId,
				 "source_step"  => $self->{"stepName"},
				 "source_layer" => $self->{"layer"},
				 "dest"         => 'layer_name',
				 "dest_layer"   => $self->{"routLayer"},
				 "mode"         => 'replace',
				 "invert"       => 'no'
	);

	if ( $self->{"angle"} > 0 ) {

		CamLayer->WorkLayer( $inCAM, $self->{"routLayer"} );
		$inCAM->COM( "sel_transform", "direction" => "ccw", "x_anchor" => 0, "y_anchor" => 0, "oper" => "rotate", "angle" => $self->{"angle"} );

	}

	# Init step placement
	foreach my $plc (@placement) {

		my $stepPlc = StepPlace->new( $plc->{"originX"}, $plc->{"originY"}, $plc->{"gREPEATxmin"}, $plc->{"gREPEATymin"}, $plc->{"gREPEATxMax"},,
									  $plc->{"gREPEATyMax"} );
		push( @{ $self->{"stepPlaces"} }, $stepPlc );

	}

	# Load uniRTM
	$self->{"uniRTM"} = UniRTM->new( $inCAM, $jobId, $targetStep, $self->{"routLayer"} );

	# Load foots..

	# Load step placement

}

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

sub UserFootExist {
	my $self = shift;

}

sub GetStepPlaces {
	my $self = shift;

	return @{ $self->{"stepPlaces"} };
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

