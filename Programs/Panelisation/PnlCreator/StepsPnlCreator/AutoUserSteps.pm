
#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for step placement to panel
# Import/Export settings method are meant for using class in bacground
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::StepsPnlCreator::AutoUserSteps;
use base('Programs::Panelisation::PnlCreator::PnlCreatorBase');

use Class::Interface;
&implements('Programs::Panelisation::PnlCreator::StepsPnlCreator::ISteps');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Panelisation::PnlCreator::Enums';
use aliased 'Packages::CAM::PanelClass::Enums' => "PnlClassEnums";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $jobId = shift;
	my $pnlType = shift;
	my $key   = Enums->StepPnlCreator_AUTOUSER;

	my $self = $class->SUPER::new( $jobId, $pnlType,  $key );
	bless $self;

	# Setting values necessary for procesing panelisation
	$self->{"settings"}->{"pcbStep"}           = undef;
	$self->{"settings"}->{"placementType"}     = PnlClassEnums->PnlClassTransform_ROTATION;
	$self->{"settings"}->{"rotationType"}      = undef;
	$self->{"settings"}->{"patternType"}       = undef;
	$self->{"settings"}->{"interlockType"}     = undef;
	$self->{"settings"}->{"spaceX"}            = undef;
	$self->{"settings"}->{"spaceY"}            = undef;
	$self->{"settings"}->{"alignType"}         = undef;
	$self->{"settings"}->{"amountType"}        = Enums->StepAmount_EXACT;
	$self->{"settings"}->{"exactQuantity"}     = undef;
	$self->{"settings"}->{"maxQuantity"}       = undef;
	$self->{"settings"}->{"autoQuantity"}      = undef;
	$self->{"settings"}->{"actionType"}        = Enums->StepPlacementMode_AUTO;
	$self->{"settings"}->{"JSONStepPlacement"} = undef;
	$self->{"settings"}->{"minUtilization"}    = undef;

	return $self;    #
}

#-------------------------------------------------------------------------------------------#
# Interface method
#-------------------------------------------------------------------------------------------#

# Init creator class in order process panelisation
# (instead of Init method is possible init by import JSON settings)
# Return 1 if succes 0 if fail
sub Init {
	my $self  = shift;
	my $inCAM = shift;

	my $result = 1;

	#	$self->{"settings"}->{"w"} = 20;
	#	$self->{"settings"}->{"h"} = 20;

	for ( my $i = 0 ; $i < 1 ; $i++ ) {

		$inCAM->COM("get_user_name");

		my $name = $inCAM->GetReply();

		print STDERR "\nHEG !! $name \n";

		sleep(1);

	}

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

	for ( my $i = 0 ; $i < 1 ; $i++ ) {

		$inCAM->COM("get_user_name");

		my $name = $inCAM->GetReply();

		print STDERR "\nChecking  HEG !! $name \n";

		sleep(1);

	}

	$result = 0;
	$$errMess .= "Nelze vytvorit";

	return $result;

}

# Return 1 if succes 0 if fail
sub Process {
	my $self    = shift;
	my $inCAM   = shift;
	my $errMess = shift;    # reference to err message

	my $result = 1;

	for ( my $i = 0 ; $i < 1 ; $i++ ) {

		$inCAM->COM("get_user_name");

		my $name = $inCAM->GetReply();

		print STDERR "\nProcessing  HEG !! $name \n";
		die "test";
		sleep(1);

	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
# Get/Set method for adjusting settings after Init/ImportSetting
#-------------------------------------------------------------------------------------------#

sub SetPCBStep {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"pcbStep"} = $val;

}

sub GetPCBStep {
	my $self = shift;

	return $self->{"settings"}->{"pcbStep"};

}

# Placement settings

sub SetPlacementType {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"placementType"} = $val;

}

sub GetPlacementType {
	my $self = shift;

	return $self->{"settings"}->{"placementType"};

}

sub SetRotationType {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"rotationType"} = $val;
}

sub GetRotationType {
	my $self = shift;

	return $self->{"settings"}->{"rotationType"};
}

sub SetPatternType {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"patternType"} = $val;
}

sub GetPatternType {
	my $self = shift;

	return $self->{"settings"}->{"patternType"};
}

sub SetInterlockType {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"interlockType"} = $val;
}

sub GetInterlockType {
	my $self = shift;

	return $self->{"settings"}->{"interlockType"};
}

# Space settings

sub SetSpaceX {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"spaceX"} = $val;

}

sub GetSpaceX {
	my $self = shift;

	return $self->{"settings"}->{"spaceX"};

}

sub SetSpaceY {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"spaceY"} = $val;

}

sub GetSpaceY {
	my $self = shift;

	return $self->{"settings"}->{"spaceY"};

}

sub SetAlignType {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"alignType"} = $val;

}

sub GetAlignType {
	my $self = shift;

	return $self->{"settings"}->{"alignType"};

}

# Amount settings

sub SetAmountType {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"amountType"} = $val;

}

sub GetAmountType {
	my $self = shift;

	return $self->{"settings"}->{"amountType"};

}

sub SetExactQuantity {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"exactQuantity"} = $val;

}

sub GetExactQuantity {
	my $self = shift;

	return $self->{"settings"}->{"exactQuantity"};

}

sub SetMaxQuantity {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"maxQuantity"} = $val;

}

sub GetMaxQuantity {
	my $self = shift;

	return $self->{"settings"}->{"maxQuantity"};

}

# Panelisation

sub SetActionType {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"actionType"} = $val;

}

sub GetActionType {
	my $self = shift;

	return $self->{"settings"}->{"actionType"};

}

sub SetJSONStepPlacement {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"JSONStepPlacement"} = $val;

}

sub GetJSONStepPlacement {
	my $self = shift;

	return $self->{"settings"}->{"JSONStepPlacement"};

}

sub SetMinUtilization {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"minUtilization"} = $val;

}

sub GetMinUtilization {
	my $self = shift;

	return $self->{"settings"}->{"minUtilization"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

