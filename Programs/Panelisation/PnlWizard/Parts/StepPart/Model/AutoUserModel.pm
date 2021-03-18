#-------------------------------------------------------------------------------------------#
# Description: Creator model
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::StepPart::Model::AutoUserModel;
use base('Programs::Panelisation::PnlWizard::Core::WizardModelBase');

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'Programs::Panelisation::PnlWizard::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"modelKey"}    = PnlCreEnums->StepPnlCreator_AUTOUSER;
	 
	$self->{"settings"}->{"pcbStep"}      = undef;
	$self->{"settings"}->{"placementType"}     = PnlCreEnums->StepPlacement_ROTATION;
	$self->{"settings"}->{"rotationType"}      = undef;
	$self->{"settings"}->{"patternType"}       = undef;
	$self->{"settings"}->{"interlockType"}     = undef;
	$self->{"settings"}->{"spaceX"}            = undef;
	$self->{"settings"}->{"spaceY"}            = undef;
	$self->{"settings"}->{"alignType"}         = undef;
	$self->{"settings"}->{"amountType"}        = PnlCreEnums->StepAmount_EXACT;
	$self->{"settings"}->{"exactQuantity"}     = undef;
	$self->{"settings"}->{"maxQuantity"}       = undef;
	$self->{"settings"}->{"autoQuantity"}      = undef;
	$self->{"settings"}->{"actionType"}        = PnlCreEnums->StepPlacementMode_AUTO;
	$self->{"settings"}->{"JSONStepPlacement"} = undef;
	$self->{"settings"}->{"minUtilization"}    = undef;
	 
	return $self;
}

sub GetModelKey {
	my $self = shift;

	return $self->{"modelKey"};

}


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

