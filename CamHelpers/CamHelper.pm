#-------------------------------------------------------------------------------------------#
# Description: Helper, which contains only the simplest operation over InCAM
# Such as LayerExist, StepExist etc.. No complex operation here!
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamHelper;

#use lib qw(.. C:/Vyvoj/Perl/test);

#3th party library
use strict;
use warnings;

#loading of locale modules

use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsGeneral';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

#Open job and step in genesis
sub Pause {

	my $self  = shift;
	my $inCAM = shift;
	my $mess  = shift;

	$inCAM->PAUSE($mess);

	my $res = $inCAM->{"PAUSANS"};

	if ( !defined $res || $res eq "" ) {
		return 0;

	}
	else {

		return 1;
	}

}

# Open given job
sub OpenJob {

	my $self    = shift;
	my $inCam   = shift;
	my $jobName = shift;

	$inCam->COM(
				 "clipb_open_job",
				 job              => "$jobName",
				 update_clipboard => "view_job"
	);
	$inCam->COM( "open_job", job => "$jobName", "open_win" => "yes" );

	$inCam->AUX( 'set_group', group => $inCam->{COMANS} );

}




#Open job and step in genesis
sub OpenJobAndStep {

	my $self     = shift;
	my $inCam    = shift;
	my $jobName  = shift;
	my $stepName = shift;

	$inCam->COM(
				 "clipb_open_job",
				 job              => "$jobName",
				 update_clipboard => "view_job"
	);
	$inCam->COM( "open_job", job => "$jobName", "open_win" => "yes" );
	$inCam->COM(
				 "open_entity",
				 job  => "$jobName",
				 type => "step",
				 name => $stepName
	);

	$inCam->AUX( 'set_group', group => $inCam->{COMANS} );

}

#Open job and step in genesis
sub OpenStep {

	my $self     = shift;
	my $inCam    = shift;
	my $jobName  = shift;
	my $stepName = shift;

	$inCam->COM(
				 "open_entity",
				 job  => "$jobName",
				 type => "step",
				 name => $stepName
	);
}


# Open given job
sub SaveAndCloseJob {
	my $self    = shift;
	my $inCam   = shift;
	my $jobName = shift;

	$inCam->COM( "save_job","job"              => "$jobName");
	$inCam->COM( "close_job","job"              => "$jobName");
}

#Return if step exists
sub StepExists {

	my $self     = shift;
	my $inCAM    = shift;
	my $jobName  = shift;
	my $stepName = shift;

	$inCAM->INFO(
				  entity_type => 'step',
				  entity_path => "$jobName/$stepName",
				  data_type   => 'exists'
	);

	if ( $inCAM->{doinfo}{gEXISTS} eq "yes" ) {
		return 1;
	}
	else {
		return 0;
	}
}

# reset filter and clear affected layers
sub ClearEditor {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobName = shift;

	$inCAM->AUX( 'set_group', group => $inCAM->{COMANS} );
	$inCAM->COM( 'units', type => 'mm' );
	$inCAM->COM( 'affected_layer', name => "", mode => "all", affected => "no" );
	$inCAM->COM('clear_layers');
}

#Return if layer exists
sub LayerExists {

	my $self    = shift;
	my $inCAM   = shift;
	my $jobName = shift;
	#my $stepName  = shift; # param isn't need
	my $layerName = shift;

	$inCAM->INFO(
				  units           => 'mm',
				  angle_direction => 'ccw',
				  entity_type     => 'matrix',
				  entity_path     => "$jobName/matrix",
				  data_type       => 'ROW',
				  parameters      => "name"
	);

	my @layers = @{ $inCAM->{doinfo}{gROWname} };

	if ( scalar( grep { $_ eq $layerName } @layers ) ) {
		return 1;
	}
	else {
		return 0;
	}
}

#Return type of layer
# type such as: rout, drill, signal..
sub LayerType {

	my $self    = shift;
	my $inCAM   = shift;
	my $jobName = shift;
	#my $stepName  = shift;  # param isn't need
	my $layerName = shift;

	$inCAM->INFO(
				  units           => 'mm',
				  angle_direction => 'ccw',
				  entity_type     => 'matrix',
				  entity_path     => "$jobName/matrix",
				  data_type       => 'ROW',
				  parameters      => "layer_type+name"
	);

	my @layers = @{ $inCAM->{doinfo}{gROWname} };
	my @types  = @{ $inCAM->{doinfo}{gROWlayer_type} };

	my $idx = ( grep { $layerName eq $layers[$_] } 0 .. $#layers )[0];

	if ( defined $idx ) {

		return $types[$idx];
	}
}

#Return user name of logged user
sub GetUserName {
	my $self  = shift;
	my $inCAM = shift;

	$inCAM->COM("get_user_name");

	return $inCAM->GetReply();
}

#Return real type of pcb based on Helios and CAM information
# Type can be all from: EnumsGeneral->PcbTyp_xxx
sub GetPcbType {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $type;
	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	if ( HegMethods->GetTypeOfPcb($jobId) eq 'Neplatovany' ) {

		$type = EnumsGeneral->PcbTyp_NOCOPPER;
	}
	else {
		if ( $layerCnt == 1 ) {

			$type = EnumsGeneral->PcbTyp_ONELAYER;

		}
		elsif ( $layerCnt == 2 ) {

			$type = EnumsGeneral->PcbTyp_TWOLAYER;

		}
		else {

			$type = EnumsGeneral->PcbTyp_MULTILAYER;
		}
	}

	return $type;
}

1;
