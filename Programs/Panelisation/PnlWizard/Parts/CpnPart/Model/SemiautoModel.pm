
#-------------------------------------------------------------------------------------------#
# Description: Creator model
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::CpnPart::Model::SemiautoModel;
use base('Programs::Panelisation::PnlWizard::Core::WizardModelBase');

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"modelKey"} = PnlCreEnums->CpnPnlCreator_SEMIAUTO;

	# Setting values necessary for procesing panelisation
	$self->{"settings"}->{"impCpnRequired"} = 0;
	$self->{"settings"}->{"impCpnSett"}     = {};

	$self->{"settings"}->{"IPC3CpnRequired"} = 0;
	$self->{"settings"}->{"IPC3CpnSett"}     = {};

	$self->{"settings"}->{"zAxisCpnRequired"} = 0;
	$self->{"settings"}->{"zAxisCpnSett"}     = {};

	$self->{"settings"}->{"placementType"}         = Enums->CpnPlacementMode_AUTO;
	$self->{"settings"}->{"manualPlacementJSON"}   = undef;
	$self->{"settings"}->{"manualPlacementStatus"} = EnumsGeneral->ResultType_NA;

	return $self;
}

sub GetModelKey {
	my $self = shift;

	return $self->{"modelKey"};

}

# Imp coupon

sub SetImpCpnRequired {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"impCpnRequired"} = $val;
}

sub GetImpCpnRequired {
	my $self = shift;

	return $self->{"settings"}->{"impCpnRequired"};
}

sub SetImpCpnSett {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"impCpnSett"} = $val;
}

sub GetImpCpnSett {
	my $self = shift;

	return $self->{"settings"}->{"impCpnSett"};
}

# IPC3 coupon

sub SetIPC3CpnRequired {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"IPC3CpnRequired"} = $val;
}

sub GetIPC3CpnRequired {
	my $self = shift;

	return $self->{"settings"}->{"IPC3CpnRequired"};
}

sub SetIPC3CpnSett {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"IPC3CpnSett"} = $val;
}

sub GetIPC3CpnSett {
	my $self = shift;

	return $self->{"settings"}->{"IPC3CpnSett"};
}

# zAxis coupon

sub SetZAxisCpnRequired {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"zAxisCpnRequired"} = $val;
}

sub GetZAxisCpnRequired {
	my $self = shift;

	return $self->{"settings"}->{"zAxisCpnRequired"};
}

sub SetZAxisCpnSett {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"zAxisCpnSett"} = $val;
}

sub GetZAxisCpnSett {
	my $self = shift;

	return $self->{"settings"}->{"zAxisCpnSett"};
}

# Panelisation

sub SetPlacementType {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"placementType"} = $val;

}

sub GetPlacementType {
	my $self = shift;

	return $self->{"settings"}->{"placementType"};

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

