
#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for coupon step placement to panel
# Import/Export settings method are meant for using class in bacground
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::CpnPnlCreator::SemiautoCpn;

use Class::Interface;
&implements('Programs::Panelisation::PnlCreator::CpnPnlCreator::ICpn');

#3th party library
use strict;
use warnings;
use List::Util qw[max min first];
use Try::Tiny;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Panelisation::PnlCreator::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class   = shift;
	my $jobId   = shift;
	my $pnlType = shift;
	my $key     = Enums->CpnPnlCreator_SEMIAUTO;

	my $self = $class->SUPER::new( $jobId, $pnlType, $key );
	bless $self;

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

	my $result = 1;

	my $jobId = $self->{'jobId'};

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

	return $result;

}

# Do necessary check before processing panelisation
# This method is called always before Process method
# Return 1 if succes 0 if fail
sub Check {
	my $self    = shift;
	my $inCAM   = shift;
	my $errMess = shift;    # reference to err message

	my $jobId = $self->{"jobId"};
	my $step  = $self->GetStep();

	my $result = 1;

	return $result;

}

# Return 1 if succes 0 if fail
sub Process {
	my $self    = shift;
	my $inCAM   = shift;
	my $errMess = shift;    # reference to err message

	my $result = 1;

	my $jobId = $self->{"jobId"};
	my $step  = $self->GetStep();

	return $result;
}

#-------------------------------------------------------------------------------------------#
# Get/Set method for adjusting settings after Init/ImportSetting
#-------------------------------------------------------------------------------------------#

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

