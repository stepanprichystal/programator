
#-------------------------------------------------------------------------------------------#
# Description:  Class represent universal tool regardless it is tool from surface, pad, slot..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniDTM::UniTool::UniToolBase;

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"drillSize"} = shift;

	# Type, which is used mainlz ion hooks
	# tell, if tool is used for chain or hole
	$self->{"typeProcess"} = shift;    #  TypeProc_HOLE / TypeProc_CHAIN

	# Tell if tool comes from surface, or standard DTM
	# tell, if tool is used for chain or hole
	$self->{"source"} = shift;    #  Source_DTM/Source_DTMSURF

	# following parameters must be same for all tools, which has
	# same "key" created by drillSize + typeProcess

	$self->{"depth"}        = 0;        # Value of tool depth
	$self->{"magazine"}     = undef;    # Magazine code
	$self->{"magazineInfo"} = "";       # Magazine info (will be converted to magazineCode)

	$self->{"tol+"} = 0;                # +tolerance
	$self->{"tol-"} = 0;                # -tolerance

	# -----------------------------
	# Property for special tool
	# -----------------------------

	# indicate if tool is special. Special tools are defined by "magazineInfo"
	# Listo of tools are in MagazineSpec
	$self->{"special"} = 0;

	$self->{"angle"} = undef;    # angle of tool 90,120, etc..

	return $self;
}

# Check if depth value is set correctly
sub DepthIsOk {
	my $self = shift;

	# depth is in mm, so assume range > 0 and  < 10 mm
	my $depth = $self->GetDepth();

	if ( $depth <= 0 || $depth >= 10 || $depth eq "" ) {
		return 0;
	}
	else {
		return 1;
	}
}

# GET SET property

sub GetSpecial {
	my $self = shift;

	return $self->{"special"};
}

sub SetSpecial {
	my $self = shift;

	$self->{"special"} = shift;
}

sub GetAngle {
	my $self = shift;

	return $self->{"angle"};
}

sub SetAngle {
	my $self = shift;

	$self->{"angle"} = shift;
}

sub GetDrillSize {
	my $self = shift;

	return $self->{"drillSize"};
}

sub GetTypeProcess {
	my $self = shift;

	return $self->{"typeProcess"};
}

sub GetSource {
	my $self = shift;

	return $self->{"source"};
}

sub SetDepth {
	my $self  = shift;
	my $depth = shift;

	if ( defined $depth ) {
		$self->{"depth"} = $depth;
	}

}

sub GetDepth {
	my $self = shift;

	return $self->{"depth"};
}

sub SetMagazine {
	my $self     = shift;
	my $magazine = shift;

	if ( defined $magazine ) {
		$self->{"magazine"} = $magazine;
	}

}

sub GetMagazine {
	my $self = shift;

	return $self->{"magazine"};
}

sub SetMagazineInfo {
	my $self     = shift;
	my $magazine = shift;

	if ( defined $magazine ) {
		$self->{"magazineInfo"} = $magazine;
	}

}

sub GetMagazineInfo {
	my $self = shift;

	return $self->{"magazineInfo"};
}

sub SetTolPlus {
	my $self = shift;

	$self->{"tol+"} = shift;
}

sub GetTolPlus {
	my $self = shift;

	return $self->{"tol+"};
}

sub SetTolMinus {
	my $self = shift;

	$self->{"tol-"} = shift;
}

sub GetTolMinus {
	my $self = shift;

	return $self->{"tol-"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

