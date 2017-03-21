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
#use aliased 'CamHelpers::CamHelper';
#use aliased 'Packages::CAM::UniDTM::PilotDef::PilotDef';

use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;
 
	$self->{"inCAM"} = shift;
	$self->{"jobId"}    = shift;
	
	$self->{"stepName"} = shift;
	$self->{"workStep"} = shift;
	$self->{"layer"}    = shift;

	$self->{"uniRTM"}            = undef;
	$self->{"userRoutOnBridges"} = 0;

	my @sr = ();
	$self->{"stepRotations"} = \@sr;

	return $self;
}

sub Init {
	my $self    = shift;
	
	my $inCAM   = $self->{"inCAM"};
	my $jobId   = $self->{"jobId"};
	my @repeats = @{ shift(@_) };

	# 1) Init object for all rotation

	foreach my $r (@repeats) {

		my $exist = scalar( grep { $_->GetAngle() == $r->{"angle"} } @{$self->{"stepRotations"}} );

		unless ($exist) {

			my @rotPlacement = grep { $_->{"angle"} == $r->{"angle"} } @repeats;

			my $stepRot = StepRotation->new( $self->{"stepName"},$self->{"layer"}, $r->{"angle"} );
			$stepRot->Init( $inCAM, $jobId, \@rotPlacement );
			
			push(@{$self->{"stepRotations"}}, $stepRot);

		}
	}

	# Init uniRTM
	$self->{"uniRTM"} = UniRTM->new( $inCAM, $jobId, $self->{"stepName"}, $self->{"layer"} );

	# Load necessary att

	my %att = CamAttributes->GetStepAttr( $inCAM, $jobId, $self->{"stepName"} );

	if ( defined $att{"rout_on_bridges"} && $att{"rout_on_bridges"} == 1 ) {
		$self->{"userRoutOnBridges"} = 1;
	}

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

sub GetStepRotations {
	my $self = shift;

	return @{$self->{"stepRotations"}};
}


sub UserFoot0degExist {
	my $self = shift;

	return $self->{"userFoot0degExist"};
}

sub GetUserRoutOnBridges {
	my $self = shift;

	return $self->{"userRoutOnBridges"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

