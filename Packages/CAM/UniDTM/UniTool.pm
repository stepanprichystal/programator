
#-------------------------------------------------------------------------------------------#
# Description:  Class represent universal tool regardless it is tool from surface, pad, slot..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniDTM::UniTool;

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

	$self->{"depth"}    = 0;     # Value of tool depth
	$self->{"magazine"} = "";    # Magazine code

	$self->{"tol+"} = 0;         # +tolerance
	$self->{"tol-"} = 0;         # -tolerance

	# -----------------------------
	# Property for type Source_DTM
	# -----------------------------

	# Type, which contain tools in standard DTM
	$self->{"typeTool"} = undef;    # TypeTool_HOLE/TypeTool_SLOT

	# Types based on purpose
	$self->{"typeUse"} = undef;     # plate/nplate/pressfit/via

	$self->{"finishSize"} = undef;  # finish size of tool

	# -----------------------------
	# Property for type Source_DTMSurf
	# -----------------------------

	$self->{"drillSize2"} = undef;    # diameter of rout pocket tool

	$self->{"surfaceId"} = undef;     # sign surface where is tool defined

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

sub SetTypeTool {
	my $self = shift;

	$self->{"typeTool"} = shift;
}

sub GetTypeTool {
	my $self = shift;

	return $self->{"typeTool"};
}

sub SetTypeUse {
	my $self = shift;

	$self->{"typeUse"} = shift;
}

sub GetTypeUse {
	my $self = shift;

	return $self->{"typeUse"};
}

sub GetDrillSize2 {
	my $self = shift;

	return $self->{"drillSize2"};
}

sub SetDrillSize2 {
	my $self = shift;

	$self->{"drillSize2"} = shift;
}

sub GetSurfaceId {
	my $self = shift;

	return $self->{"surfaceId"};
}

sub SetSurfaceId {
	my $self = shift;

	$self->{"surfaceId"} = shift;
}

sub GetFinishSize {
	my $self = shift;

	return $self->{"finishSize"};
}

sub SetFinishSize {
	my $self = shift;

	$self->{"finishSize"} = shift;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

