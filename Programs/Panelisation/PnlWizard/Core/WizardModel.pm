#-------------------------------------------------------------------------------------------#
# Description: This class load/compute default values which consum ExportChecker.
# Here are placed values, which take long time for computation, thus here will be computed
# only once, when ExporterChecker starts.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Core::WizardModel;
use base('Programs::Panelisation::PnlWizard::Core::WizardModelBase');

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

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
	my $self = $class->SUPER::new(@_);
	bless $self;

	$self->{"step"}  = undef;
	$self->{"parts"} = {};

	# Defaul values
	#$self->{"pcbType"}         = undef;

	return $self;
}


sub GetStep {
	my $self   = shift;
 
	return $self->{"step"};

}

sub SetStep {
	my $self   = shift;
	my $val = shift;
	 

	$self->{"step"} =  $val;

}

sub GetPartModelById {
	my $self   = shift;
	my $partId = shift;

	return $self->{"parts"}->{$partId};

}

sub SetPartModelById {
	my $self   = shift;
	my $partId = shift;
	my $model  = shift;

	$self->{"parts"}->{$partId} = $model;

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
