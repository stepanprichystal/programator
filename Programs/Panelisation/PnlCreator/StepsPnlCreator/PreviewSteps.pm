
#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for step placement to panel
# Import/Export settings method are meant for using class in bacground
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::StepsPnlCreator::PreviewSteps;
use base('Programs::Panelisation::PnlCreator::PnlCreatorBase');

use Class::Interface;
&implements('Programs::Panelisation::PnlCreator::StepsPnlCreator::ISteps');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Panelisation::PnlCreator::Enums';
use aliased 'Programs::Panelisation::PnlCreator::Helpers::PnlToJSON';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class   = shift;
	my $jobId   = shift;
	my $pnlType = shift;
	my $key     = Enums->StepPnlCreator_PREVIEW;

	my $self = $class->SUPER::new( $jobId, $pnlType, $key );
	bless $self;

	# Setting values necessary for procesing panelisation
	$self->{"settings"}->{"srcJobId"}              = undef;
	$self->{"settings"}->{"panelJSON"}             = undef;
	$self->{"settings"}->{"manualPlacementJSON"}   = undef;
	$self->{"settings"}->{"manualPlacementStatus"} = EnumsGeneral->ResultType_NA;

	return $self;    #
}

#-------------------------------------------------------------------------------------------#
# Interface method
#-------------------------------------------------------------------------------------------#

# Init creator class in order process panelisation
# (instead of Init method is possible init by import JSON settings)
# Return 1 if succes 0 if fail
sub Init {
	my $self     = shift;
	my $inCAM    = shift;
	my $stepName = shift;

	$self->SetStep($stepName);

	my $result = 1;

	return $result;

}

# Do necessary check before processing panelisation
# This method is called always before Process method
# Return 1 if succes 0 if fail
sub Check {
	my $self    = shift;
	my $inCAM   = shift;
	my $errMess = shift;    # reference to err message

	my $result = 1;

	# Check if source job exist
	my $srcJobExist = $self->GetSrcJobId();

	if ( !defined $srcJobExist || $srcJobExist eq "" ) {

		$result = 0;
		$$errMess .= "Source job, which panel should be coppied from is not defined.\n";
	}
	else {

		# Check if JSON exist
		my $JSON = $self->GetPanelJSON();

		if ( !defined $JSON || $JSON eq "" ) {

			$result = 0;
			$$errMess .= "Source job panel SR was not properly parsed.\n";
		}

	}

	if ( $self->GetManualPlacementStatus() eq EnumsGeneral->ResultType_OK ) {

		unless ( defined $self->GetManualPlacementJSON() ) {

			# JSON placement is not defined
			$result = 0;
			$$errMess .= "Manual panel step palcement error. Missing JSON panel placement.";
		}

	}

	return $result;

}

# Return 1 if succes 0 if fail
sub Process {
	my $self    = shift;
	my $inCAM   = shift;
	my $errMess = shift;    # reference to err message

	my $result = 1;

	$self->_CreateStep($inCAM);

	# Process specific
	my $jobId = $self->{"jobId"};
	my $step  = $self->GetStep();

	my $pnlToJSON = PnlToJSON->new( $inCAM, $jobId, $step );
	$pnlToJSON->CreatePnlByJSON( $self->GetPanelJSON(), 0, 1, 0 );

	return $result;
}

#-------------------------------------------------------------------------------------------#
# Get/Set method for adjusting settings after Init/ImportSetting
#-------------------------------------------------------------------------------------------#

sub SetSrcJobId {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"srcJobId"} = $val;
}

sub GetSrcJobId {
	my $self = shift;

	return $self->{"settings"}->{"srcJobId"};
}

sub SetPanelJSON {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"panelJSON"} = $val;
}

sub GetPanelJSON {
	my $self = shift;

	return $self->{"settings"}->{"panelJSON"};
}

sub SetManualPlacementJSON {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"manualPlacementJSON"} = $val;

}

sub GetManualPlacementJSON {
	my $self = shift;

	return $self->{"settings"}->{"manualPlacementJSON"};

}

sub SetManualPlacementStatus {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"manualPlacementStatus"} = $val;

}

sub GetManualPlacementStatus {
	my $self = shift;

	return $self->{"settings"}->{"manualPlacementStatus"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

