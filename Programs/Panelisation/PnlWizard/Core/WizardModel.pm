#-------------------------------------------------------------------------------------------#
# Description: This class load/compute default values which consum ExportChecker.
# Here are placed values, which take long time for computation, thus here will be computed
# only once, when ExporterChecker starts.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Core::WizardModel;

#3th party library
use strict;
use warnings;

#local library
#use aliased 'Packages::Tests::Test';
#use aliased 'Enums::EnumsGeneral';
#use aliased 'Packages::Stackup::Enums' => 'StackupEnums';
#use aliased 'CamHelpers::CamJob';
#use aliased 'Packages::Stackup::Stackup::Stackup';
#use aliased 'Packages::Stackup::StackupNC::StackupNC';
#use aliased 'Packages::Routing::PlatedRoutArea';
#use aliased 'CamHelpers::CamDrilling';
#use aliased 'CamHelpers::CamHelper';
#use aliased 'CamHelpers::CamStep';
#use aliased 'CamHelpers::CamAttributes';
#use aliased 'Packages::Scoring::ScoreChecker::ScoreChecker';
#use aliased 'Connectors::HeliosConnector::HegMethods';
#use aliased 'Packages::Technology::EtchOperation';
#use aliased 'Packages::Other::CustomerNote';
#use aliased 'Packages::Tooling::PressfitOperation';
#use aliased 'Packages::Tooling::TolHoleOperation';
#use aliased 'Packages::Stackup::StackupOperation';
#use aliased 'Helpers::JobHelper';
#use aliased 'Packages::Technology::DataComp::SigLayerComp';
#use aliased 'Packages::Technology::DataComp::NCLayerComp';
#use aliased 'Packages::CAMJob::Technology::LayerSettings';
#use aliased 'Programs::Comments::Comments';
#use aliased 'Packages::CAMJob::Stackup::StackupCode';

  #-------------------------------------------------------------------------------------------#
  #  Package methods
  #-------------------------------------------------------------------------------------------#

  sub new {
	my $class = shift;
	my $jobId = shift;
	my $step  = shift // "panel";

	my $self = {};
	bless $self;

	$self->{"jobId"} = $jobId;
	$self->{"step"}  = $step;
	$self->{"init"}  = 0;

	# Defaul values
	#$self->{"pcbType"}         = undef;
 

	return $self;
}

sub Init {
	my $self = shift;

	# Do not store InCAM object as Object property,
	# becase if is Defalt info used in child thread, InCAM don't work
	my $inCAM = shift;

	$self->__Init($inCAM);

}


#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __Init {
	my $self  = shift;
	my $inCAM = shift;

	#$self->{"pcbType"} = JobHelper->GetPcbType( $self->{"jobId"} );

	
}

1;