#-------------------------------------------------------------------------------------------#
# Description: Creator model
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::StepPart::Model::MatrixModel;
use base('Programs::Panelisation::PnlWizard::Core::WizardModelBase');

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'Enums::EnumsGeneral';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"modelKey"} = PnlCreEnums->StepPnlCreator_MATRIX;

	$self->{"settings"}->{"pcbStepsList"}          = [];
	$self->{"settings"}->{"pcbStep"}               = undef;
	$self->{"settings"}->{"pcbStepProfile"}        = PnlCreEnums->PCBStepProfile_STANDARD;
	$self->{"settings"}->{"stepMultiX"}            = undef;
	$self->{"settings"}->{"stepMultiX"}            = undef;
	$self->{"settings"}->{"stepMultiY"}            = undef;
	$self->{"settings"}->{"stepSpaceX"}            = undef;
	$self->{"settings"}->{"stepSpaceY"}            = undef;
	$self->{"settings"}->{"stepRotation"}          = undef;
	$self->{"settings"}->{"manualPlacementJSON"}   = undef;
	$self->{"settings"}->{"manualPlacementStatus"} = EnumsGeneral->ResultType_NA;

	return $self;
}

sub GetModelKey {
	my $self = shift;

	return $self->{"modelKey"};

}

sub SetPCBStepsList {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"pcbStepsList"} = $val;

}

sub GetPCBStepsList {
	my $self = shift;

	return $self->{"settings"}->{"pcbStepsList"};

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

sub SetPCBStepProfile {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"pcbStepProfile"} = $val;

}

sub GetPCBStepProfile {
	my $self = shift;

	return $self->{"settings"}->{"pcbStepProfile"};

}

sub SetStepMultiplX {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"stepMultiX"} = $val;
}

sub GetStepMultiplX {
	my $self = shift;

	return $self->{"settings"}->{"stepMultiX"};
}

sub SetStepMultiplY {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"stepMultiY"} = $val;
}

sub GetStepMultiplY {
	my $self = shift;

	return $self->{"settings"}->{"stepMultiY"};
}

sub SetStepSpaceX {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"stepSpaceX"} = $val;
}

sub GetStepSpaceX {
	my $self = shift;

	return $self->{"settings"}->{"stepSpaceX"};
}

sub SetStepSpaceY {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"stepSpaceY"} = $val;
}

sub GetStepSpaceY {
	my $self = shift;

	return $self->{"settings"}->{"stepSpaceY"};
}

sub SetStepRotation {
	my $self = shift;
	my $val  = shift;
	$self->{"settings"}->{"stepRotation"} = $val;
}

sub GetStepRotation {
	my $self = shift;

	return $self->{"settings"}->{"stepRotation"};
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

